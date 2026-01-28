<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Invoice;
use App\Models\InvoiceItem;
use App\Models\FeeCategory;
use App\Models\Student;
use App\Models\AuditLog;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class InvoiceController extends Controller
{
    /**
     * Get list of invoices
     */
    public function index(Request $request): JsonResponse
    {
        $query = Invoice::with(['student', 'category', 'items']);

        // Filter by status
        if ($request->has('status')) {
            $query->where('status', $request->status);
        }

        // Filter by category
        if ($request->has('category_id')) {
            $query->where('category_id', $request->category_id);
        }

        // Filter by period
        if ($request->has('period')) {
            $query->where('period', $request->period);
        }

        // Filter by student_id (for student/parent users)
        if ($request->has('student_id')) {
            $query->where('student_id', $request->student_id);
        }

        // For non-admin users, only show their own invoices
        $user = $request->user();
        if (!$user->isAdmin()) {
            if ($user->student_id) {
                $query->where('student_id', $user->student_id);
            }
        }

        $invoices = $query->orderBy('created_at', 'desc')->paginate(20);

        return response()->json([
            'success' => true,
            'data' => $invoices->items() ? collect($invoices->items())->map(fn($invoice) => $this->formatInvoice($invoice)) : [],
            'meta' => [
                'current_page' => $invoices->currentPage(),
                'last_page' => $invoices->lastPage(),
                'per_page' => $invoices->perPage(),
                'total' => $invoices->total(),
            ],
        ]);
    }

    /**
     * Get single invoice detail
     */
    public function show(Request $request, int $id): JsonResponse
    {
        $invoice = Invoice::with(['student', 'category', 'items', 'transactions'])->find($id);

        if (!$invoice) {
            return response()->json([
                'success' => false,
                'message' => 'Invoice tidak ditemukan',
            ], 404);
        }

        // Check access for non-admin users
        $user = $request->user();
        if (!$user->isAdmin()) {
            if ($user->student_id && $invoice->student_id !== $user->student_id) {
                return response()->json([
                    'success' => false,
                    'message' => 'Akses ditolak',
                ], 403);
            }
        }

        return response()->json([
            'success' => true,
            'data' => $this->formatInvoice($invoice, true),
        ]);
    }

    /**
     * Create a new invoice (admin only)
     */
    public function store(Request $request): JsonResponse
    {
        $request->validate([
            'student_id' => 'required|exists:students,id',
            'category_id' => 'required|exists:fee_categories,id',
            'period' => 'required|string|max:50',
            'due_date' => 'required|date',
            'items' => 'required|array|min:1',
            'items.*.description' => 'required|string|max:255',
            'items.*.amount' => 'required|numeric|min:0',
            'items.*.quantity' => 'sometimes|integer|min:1',
            'notes' => 'sometimes|string',
        ]);

        $category = FeeCategory::find($request->category_id);
        $student = Student::find($request->student_id);

        // Calculate total
        $totalAmount = collect($request->items)->sum(function ($item) {
            return $item['amount'] * ($item['quantity'] ?? 1);
        });

        $invoice = Invoice::create([
            'invoice_number' => Invoice::generateInvoiceNumber(),
            'student_id' => $request->student_id,
            'category_id' => $request->category_id,
            'period' => $request->period,
            'total_amount' => $totalAmount,
            'paid_amount' => 0,
            'status' => 'unpaid',
            'due_date' => $request->due_date,
            'notes' => $request->notes,
            'created_by' => $request->user()->id,
        ]);

        // Create invoice items
        foreach ($request->items as $item) {
            InvoiceItem::create([
                'invoice_id' => $invoice->id,
                'description' => $item['description'],
                'amount' => $item['amount'],
                'quantity' => $item['quantity'] ?? 1,
            ]);
        }

        // Log audit
        AuditLog::log('create', 'Invoice', $invoice->id, null, $invoice->toArray());

        $invoice->load(['student', 'category', 'items']);

        return response()->json([
            'success' => true,
            'message' => 'Invoice berhasil dibuat',
            'data' => $this->formatInvoice($invoice),
        ], 201);
    }

    /**
     * Generate routine invoices (e.g., monthly SPP)
     */
    public function generate(Request $request): JsonResponse
    {
        $request->validate([
            'category_id' => 'required|exists:fee_categories,id',
            'period' => 'required|string|max:50',
            'due_date' => 'required|date',
            'student_ids' => 'sometimes|array',
            'student_ids.*' => 'exists:students,id',
            'class_name' => 'sometimes|string',
        ]);

        // Validate period year - only allow current year and future
        $currentYear = (int) date('Y');
        $periodYear = null;

        // Extract year from period (e.g., "Januari 2026" -> 2026)
        if (preg_match('/\b(20\d{2})\b/', $request->period, $matches)) {
            $periodYear = (int) $matches[1];
        }

        if ($periodYear !== null && $periodYear < $currentYear) {
            return response()->json([
                'success' => false,
                'message' => 'Periode tidak valid. Hanya dapat memilih tahun ' . $currentYear . ' atau tahun yang akan datang.',
            ], 422);
        }

        $category = FeeCategory::findOrFail($request->category_id);


        // Get students
        $studentsQuery = Student::where('status', 'active');

        if ($request->has('student_ids') && count($request->student_ids) > 0) {
            $studentsQuery->whereIn('id', $request->student_ids);
        }

        if ($request->has('class_name')) {
            $studentsQuery->where('class_name', $request->class_name);
        }

        $students = $studentsQuery->get();
        $createdInvoices = [];

        foreach ($students as $student) {
            // Check if invoice already exists for this period
            $existingInvoice = Invoice::where('student_id', $student->id)
                ->where('category_id', $category->id)
                ->where('period', $request->period)
                ->first();

            if ($existingInvoice) {
                continue;
            }

            $invoice = Invoice::create([
                'invoice_number' => Invoice::generateInvoiceNumber(),
                'student_id' => $student->id,
                'category_id' => $category->id,
                'period' => $request->period,
                'total_amount' => $category->base_amount,
                'paid_amount' => 0,
                'status' => 'unpaid',
                'due_date' => $request->due_date,
                'created_by' => $request->user()->id,
            ]);

            // Create default invoice item
            InvoiceItem::create([
                'invoice_id' => $invoice->id,
                'description' => "{$category->name} - {$request->period}",
                'amount' => $category->base_amount,
                'quantity' => 1,
            ]);

            $createdInvoices[] = $invoice;
        }

        return response()->json([
            'success' => true,
            'message' => count($createdInvoices) . ' invoice berhasil dibuat',
            'data' => [
                'count' => count($createdInvoices),
                'invoices' => collect($createdInvoices)->map(fn($inv) => [
                    'id' => (string) $inv->id,
                    'invoiceNumber' => $inv->invoice_number,
                    'studentId' => (string) $inv->student_id,
                ]),
            ],
        ], 201);
    }

    /**
     * Format invoice for API response
     */
    private function formatInvoice(Invoice $invoice, bool $includeTransactions = false): array
    {
        $data = [
            'id' => (string) $invoice->id,
            'invoiceNumber' => $invoice->invoice_number,
            'studentId' => (string) $invoice->student_id,
            'studentName' => $invoice->student->name ?? '',
            'categoryId' => (string) $invoice->category_id,
            'categoryName' => $invoice->category->name ?? '',
            'period' => $invoice->period,
            'items' => $invoice->items->map(fn($item) => [
                'id' => (string) $item->id,
                'description' => $item->description,
                'amount' => (float) $item->amount,
                'quantity' => $item->quantity,
            ])->toArray(),
            'totalAmount' => (float) $invoice->total_amount,
            'paidAmount' => (float) $invoice->paid_amount,
            'status' => $invoice->status,
            'statusDisplayName' => $invoice->status_display_name,
            'dueDate' => $invoice->due_date->toIso8601String(),
            'createdAt' => $invoice->created_at->toIso8601String(),
            'notes' => $invoice->notes,
            'isOverdue' => $invoice->is_overdue,
        ];

        if ($includeTransactions && $invoice->transactions) {
            $data['transactions'] = $invoice->transactions->map(fn($tx) => [
                'id' => (string) $tx->id,
                'orderId' => $tx->order_id,
                'grossAmount' => (float) $tx->gross_amount,
                'paymentType' => $tx->payment_type,
                'status' => $tx->status,
                'statusDisplayName' => $tx->status_display_name,
                'transactionTime' => $tx->transaction_time?->toIso8601String(),
                'settlementTime' => $tx->settlement_time?->toIso8601String(),
            ])->toArray();
        }

        return $data;
    }
}
