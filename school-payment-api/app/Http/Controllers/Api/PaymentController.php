<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Invoice;
use App\Models\Transaction;
use App\Services\MidtransService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class PaymentController extends Controller
{
    protected MidtransService $midtransService;

    public function __construct(MidtransService $midtransService)
    {
        $this->midtransService = $midtransService;
    }

    /**
     * Create Midtrans Snap token for payment
     */
    public function createSnapToken(Request $request, int $invoiceId): JsonResponse
    {
        $invoice = Invoice::with(['student', 'category', 'items'])->find($invoiceId);

        if (!$invoice) {
            return response()->json([
                'success' => false,
                'message' => 'Invoice tidak ditemukan',
            ], 404);
        }

        // Check access
        $user = $request->user();
        if (!$user->isAdmin()) {
            if ($user->student_id && $invoice->student_id !== $user->student_id) {
                return response()->json([
                    'success' => false,
                    'message' => 'Akses ditolak',
                ], 403);
            }
        }

        // Check if invoice is already paid
        if ($invoice->status === 'paid') {
            return response()->json([
                'success' => false,
                'message' => 'Invoice sudah lunas',
            ], 400);
        }

        // Calculate amount to pay
        $amountToPay = $invoice->remaining_amount;

        if ($amountToPay <= 0) {
            return response()->json([
                'success' => false,
                'message' => 'Tidak ada sisa tagihan',
            ], 400);
        }

        // Generate unique order ID
        $orderId = Transaction::generateOrderId($invoice->id);

        // Create transaction record
        $transaction = Transaction::create([
            'order_id' => $orderId,
            'invoice_id' => $invoice->id,
            'gross_amount' => $amountToPay,
            'status' => 'pending',
        ]);

        // Create Snap token
        try {
            $snapData = $this->midtransService->createSnapToken([
                'order_id' => $orderId,
                'gross_amount' => (int) $amountToPay,
                'customer_name' => $invoice->student->name,
                'customer_email' => $invoice->student->parent_email ?? $user->email,
                'item_details' => collect($invoice->items)->map(fn($item) => [
                    'id' => (string) $item->id,
                    'name' => $item->description,
                    'price' => (int) $item->amount,
                    'quantity' => $item->quantity,
                ])->toArray(),
            ]);

            return response()->json([
                'success' => true,
                'data' => [
                    'transactionId' => (string) $transaction->id,
                    'orderId' => $orderId,
                    'snapToken' => $snapData['token'],
                    'redirectUrl' => $snapData['redirect_url'],
                    'amount' => (float) $amountToPay,
                ],
            ]);
        } catch (\Exception $e) {
            // Delete failed transaction record
            $transaction->delete();

            return response()->json([
                'success' => false,
                'message' => 'Gagal membuat pembayaran: ' . $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Get payment status (also checks Midtrans API if still pending)
     */
    public function getStatus(Request $request, string $orderId): JsonResponse
    {
        $transaction = Transaction::where('order_id', $orderId)->first();

        if (!$transaction) {
            return response()->json([
                'success' => false,
                'message' => 'Transaksi tidak ditemukan',
            ], 404);
        }

        // If still pending, check Midtrans API for actual status
        if ($transaction->status === 'pending') {
            try {
                $midtransStatus = $this->midtransService->getStatus($orderId);

                if (isset($midtransStatus['transaction_status'])) {
                    $newStatus = $this->mapMidtransStatus(
                        $midtransStatus['transaction_status'],
                        $midtransStatus['fraud_status'] ?? null
                    );

                    // Update local transaction if status changed
                    if ($newStatus !== 'pending') {
                        $transaction->update([
                            'status' => $newStatus,
                            'payment_type' => $midtransStatus['payment_type'] ?? null,
                            'transaction_time' => isset($midtransStatus['transaction_time'])
                                ? \Carbon\Carbon::parse($midtransStatus['transaction_time'])
                                : null,
                            'settlement_time' => isset($midtransStatus['settlement_time'])
                                ? \Carbon\Carbon::parse($midtransStatus['settlement_time'])
                                : null,
                        ]);

                        // If settlement, update invoice status
                        if (in_array($newStatus, ['settlement', 'capture'])) {
                            $invoice = $transaction->invoice;
                            if ($invoice) {
                                $paidAmount = $invoice->paid_amount + $transaction->gross_amount;
                                $invoice->update([
                                    'paid_amount' => $paidAmount,
                                    'status' => $paidAmount >= $invoice->total_amount ? 'paid' : 'partial',
                                ]);
                            }
                        }

                        $transaction->refresh();
                    }
                }
            } catch (\Exception $e) {
                // If Midtrans API fails, just return current status
            }
        }

        return response()->json([
            'success' => true,
            'data' => [
                'orderId' => $transaction->order_id,
                'status' => $transaction->status,
                'statusDisplayName' => $transaction->status_display_name,
                'grossAmount' => (float) $transaction->gross_amount,
                'paymentType' => $transaction->payment_type,
                'transactionTime' => $transaction->transaction_time?->toIso8601String(),
                'settlementTime' => $transaction->settlement_time?->toIso8601String(),
            ],
        ]);
    }

    /**
     * Map Midtrans status to internal status
     */
    private function mapMidtransStatus(string $transactionStatus, ?string $fraudStatus): string
    {
        if ($transactionStatus === 'capture') {
            return $fraudStatus === 'accept' ? 'capture' : 'deny';
        }

        $statusMap = [
            'settlement' => 'settlement',
            'pending' => 'pending',
            'deny' => 'deny',
            'cancel' => 'cancel',
            'expire' => 'expire',
            'failure' => 'failure',
            'refund' => 'refund',
            'partial_refund' => 'partial_refund',
        ];

        return $statusMap[$transactionStatus] ?? 'pending';
    }

    /**
     * Get transactions for authenticated user
     */
    public function getTransactions(Request $request): JsonResponse
    {
        $user = $request->user();

        $query = Transaction::with(['invoice.student', 'invoice.category'])
            ->orderBy('created_at', 'desc');

        // Filter by user role
        if (!$user->isAdmin()) {
            if ($user->student_id) {
                // Student: only show their own transactions
                $query->whereHas('invoice', function ($q) use ($user) {
                    $q->where('student_id', $user->student_id);
                });
            } elseif ($user->role === 'orang_tua') {
                // Parent: show transactions for their children
                $childrenIds = \App\Models\Student::where('parent_id', $user->id)->pluck('id');
                $query->whereHas('invoice', function ($q) use ($childrenIds) {
                    $q->whereIn('student_id', $childrenIds);
                });
            }
        }

        $transactions = $query->get()->map(function ($transaction) {
            return [
                'id' => (string) $transaction->id,
                'invoiceId' => (string) $transaction->invoice_id,
                'invoiceNumber' => $transaction->invoice?->invoice_number ?? '-',
                'orderId' => $transaction->order_id,
                'paymentType' => $transaction->payment_type,
                'status' => $transaction->status,
                'grossAmount' => (double) $transaction->gross_amount,
                'settlementTime' => $transaction->settlement_time?->toIso8601String(),
                'studentId' => (string) ($transaction->invoice?->student_id ?? ''),
                'studentName' => $transaction->invoice?->student?->name ?? '-',
                'categoryName' => $transaction->invoice?->category?->name ?? '-',
                'createdAt' => $transaction->created_at->toIso8601String(),
            ];
        });

        return response()->json([
            'success' => true,
            'data' => $transactions,
        ]);
    }
}
