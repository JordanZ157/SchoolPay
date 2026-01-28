<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Invoice;
use App\Models\Transaction;
use App\Models\Receipt;
use App\Services\MidtransService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class MidtransController extends Controller
{
    protected MidtransService $midtransService;

    public function __construct(MidtransService $midtransService)
    {
        $this->midtransService = $midtransService;
    }

    /**
     * Handle Midtrans callback/webhook
     */
    public function handleCallback(Request $request): JsonResponse
    {
        $payload = $request->all();

        // Verify signature
        if (!$this->midtransService->verifySignature($payload)) {
            return response()->json([
                'success' => false,
                'message' => 'Invalid signature',
            ], 401);
        }

        $orderId = $payload['order_id'] ?? null;
        $transactionStatus = $payload['transaction_status'] ?? null;
        $paymentType = $payload['payment_type'] ?? null;
        $fraudStatus = $payload['fraud_status'] ?? null;

        if (!$orderId) {
            return response()->json([
                'success' => false,
                'message' => 'Missing order_id',
            ], 400);
        }

        // Find transaction
        $transaction = Transaction::where('order_id', $orderId)->first();

        if (!$transaction) {
            return response()->json([
                'success' => false,
                'message' => 'Transaction not found',
            ], 404);
        }

        // Map Midtrans status to our status
        $status = $this->mapTransactionStatus($transactionStatus, $fraudStatus);

        // Update transaction
        $transaction->update([
            'status' => $status,
            'payment_type' => $paymentType,
            'transaction_time' => isset($payload['transaction_time']) ? \Carbon\Carbon::parse($payload['transaction_time']) : now(),
            'settlement_time' => isset($payload['settlement_time']) ? \Carbon\Carbon::parse($payload['settlement_time']) : null,
            'reference_number' => $payload['approval_code'] ?? $payload['bank'] ?? null,
            'raw_payload' => $payload,
        ]);

        // Update invoice if payment successful
        if (in_array($status, ['settlement', 'capture'])) {
            $invoice = $transaction->invoice;
            $newPaidAmount = $invoice->paid_amount + $transaction->gross_amount;

            $invoice->update([
                'paid_amount' => $newPaidAmount,
                'status' => $newPaidAmount >= $invoice->total_amount ? 'paid' : 'partial',
            ]);

            // Create receipt if fully paid
            if ($invoice->status === 'paid') {
                Receipt::create([
                    'invoice_id' => $invoice->id,
                    'receipt_number' => Receipt::generateReceiptNumber(),
                    'issued_at' => now(),
                    'metadata' => [
                        'transaction_id' => $transaction->id,
                        'order_id' => $orderId,
                        'payment_type' => $paymentType,
                    ],
                ]);
            }
        }

        // Handle expired/cancelled/denied
        if (in_array($status, ['expire', 'cancel', 'deny'])) {
            // Optionally update invoice status
        }

        return response()->json([
            'success' => true,
            'message' => 'Callback processed',
        ]);
    }

    /**
     * Map Midtrans transaction status
     */
    private function mapTransactionStatus(?string $status, ?string $fraudStatus): string
    {
        if ($status === 'capture') {
            return $fraudStatus === 'accept' ? 'capture' : 'deny';
        }

        return match ($status) {
            'settlement' => 'settlement',
            'pending' => 'pending',
            'deny' => 'deny',
            'cancel' => 'cancel',
            'expire' => 'expire',
            'refund', 'partial_refund' => 'refund',
            default => 'pending',
        };
    }
}
