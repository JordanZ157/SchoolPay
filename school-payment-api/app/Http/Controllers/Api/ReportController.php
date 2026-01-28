<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Invoice;
use App\Models\Transaction;
use App\Models\Student;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ReportController extends Controller
{
    /**
     * Daily income report
     */
    public function daily(Request $request): JsonResponse
    {
        $date = $request->get('date', today()->toDateString());

        $query = Transaction::whereIn('status', ['settlement', 'capture'])
            ->with(['invoice.student', 'invoice.category']);

        // If date is 'all', get all transactions; otherwise filter by date
        if ($date !== 'all') {
            $query->whereDate('settlement_time', $date);
        }

        $transactions = $query->orderBy('settlement_time', 'desc')->get();

        // Also get total all-time income for summary
        $allTimeIncome = Transaction::whereIn('status', ['settlement', 'capture'])
            ->sum('gross_amount');

        $totalIncome = $transactions->sum('gross_amount');

        $byCategory = $transactions->groupBy(fn($tx) => $tx->invoice->category->name ?? 'Unknown')
            ->map(fn($group) => [
                'count' => $group->count(),
                'total' => $group->sum('gross_amount'),
            ]);

        $byPaymentType = $transactions->groupBy('payment_type')
            ->map(fn($group) => [
                'count' => $group->count(),
                'total' => $group->sum('gross_amount'),
            ]);

        return response()->json([
            'success' => true,
            'data' => [
                'date' => $date,
                'totalIncome' => (float) $totalIncome,
                'allTimeIncome' => (float) $allTimeIncome,
                'transactionCount' => $transactions->count(),
                'byCategory' => $byCategory,
                'byPaymentType' => $byPaymentType,
                'transactions' => $transactions->map(fn($tx) => [
                    'id' => (string) $tx->id,
                    'orderId' => $tx->order_id,
                    'amount' => (float) $tx->gross_amount,
                    'paymentType' => $tx->payment_type,
                    'settlementTime' => $tx->settlement_time?->toIso8601String(),
                    'invoiceId' => (string) ($tx->invoice->id ?? ''),
                    'invoiceNumber' => $tx->invoice->invoice_number ?? '',
                    'studentName' => $tx->invoice->student->name ?? '',
                    'className' => $tx->invoice->student->class_name ?? '',
                    'categoryName' => $tx->invoice->category->name ?? '',
                ])->toArray(),
            ],
        ]);
    }

    /**
     * Report by category
     */
    public function byCategory(Request $request): JsonResponse
    {
        $startDate = $request->get('start_date', now()->startOfMonth()->toDateString());
        $endDate = $request->get('end_date', now()->toDateString());

        $invoices = Invoice::with('category')
            ->whereBetween('created_at', [$startDate, $endDate . ' 23:59:59'])
            ->get();

        $report = $invoices->groupBy(fn($inv) => $inv->category->name ?? 'Unknown')
            ->map(function ($group) {
                return [
                    'categoryId' => (string) ($group->first()->category_id ?? 0),
                    'categoryName' => $group->first()->category->name ?? 'Unknown',
                    'invoiceCount' => $group->count(),
                    'totalBilled' => (float) $group->sum('total_amount'),
                    'totalPaid' => (float) $group->sum('paid_amount'),
                    'totalUnpaid' => (float) $group->sum(fn($inv) => $inv->remaining_amount),
                    'paidCount' => $group->where('status', 'paid')->count(),
                    'unpaidCount' => $group->where('status', 'unpaid')->count(),
                    'partialCount' => $group->where('status', 'partial')->count(),
                ];
            })->values();

        $summary = [
            'totalBilled' => (float) $invoices->sum('total_amount'),
            'totalPaid' => (float) $invoices->sum('paid_amount'),
            'totalUnpaid' => (float) $invoices->sum(fn($inv) => $inv->remaining_amount),
        ];

        return response()->json([
            'success' => true,
            'data' => [
                'startDate' => $startDate,
                'endDate' => $endDate,
                'summary' => $summary,
                'categories' => $report,
            ],
        ]);
    }

    /**
     * Report by student
     */
    public function byStudent(Request $request, int $studentId): JsonResponse
    {
        $student = Student::with(['invoices.category', 'invoices.transactions'])->find($studentId);

        if (!$student) {
            return response()->json([
                'success' => false,
                'message' => 'Siswa tidak ditemukan',
            ], 404);
        }

        $invoices = $student->invoices;

        $summary = [
            'totalBilled' => (float) $invoices->sum('total_amount'),
            'totalPaid' => (float) $invoices->sum('paid_amount'),
            'totalUnpaid' => (float) $invoices->sum(fn($inv) => $inv->remaining_amount),
            'invoiceCount' => $invoices->count(),
            'paidCount' => $invoices->where('status', 'paid')->count(),
            'unpaidCount' => $invoices->where('status', 'unpaid')->count(),
            'partialCount' => $invoices->where('status', 'partial')->count(),
            'overdueCount' => $invoices->where('status', 'unpaid')
                ->filter(fn($inv) => $inv->due_date->isPast())->count(),
        ];

        return response()->json([
            'success' => true,
            'data' => [
                'student' => [
                    'id' => (string) $student->id,
                    'nis' => $student->nis,
                    'name' => $student->name,
                    'className' => $student->class_name,
                    'major' => $student->major,
                ],
                'summary' => $summary,
                'invoices' => $invoices->map(fn($inv) => [
                    'id' => (string) $inv->id,
                    'invoiceNumber' => $inv->invoice_number,
                    'categoryName' => $inv->category->name ?? '',
                    'period' => $inv->period,
                    'totalAmount' => (float) $inv->total_amount,
                    'paidAmount' => (float) $inv->paid_amount,
                    'status' => $inv->status,
                    'dueDate' => $inv->due_date->toIso8601String(),
                ])->toArray(),
            ],
        ]);
    }

    /**
     * Arrears/tunggakan report
     */
    public function arrears(Request $request): JsonResponse
    {
        $className = $request->get('class_name');

        $query = Invoice::with(['student', 'category'])
            ->where('status', 'unpaid')
            ->where('due_date', '<', now());

        if ($className) {
            $query->whereHas('student', fn($q) => $q->where('class_name', $className));
        }

        $overdueInvoices = $query->orderBy('due_date', 'asc')->get();

        // Group by student
        $byStudent = $overdueInvoices->groupBy('student_id')
            ->map(function ($invoices) {
                $student = $invoices->first()->student;
                return [
                    'studentId' => (string) $student->id,
                    'nis' => $student->nis,
                    'name' => $student->name,
                    'className' => $student->class_name,
                    'major' => $student->major,
                    'totalArrears' => (float) $invoices->sum(fn($inv) => $inv->remaining_amount),
                    'invoiceCount' => $invoices->count(),
                    'oldestDueDate' => $invoices->min('due_date')->toIso8601String(),
                    'invoices' => $invoices->map(fn($inv) => [
                        'id' => (string) $inv->id,
                        'invoiceNumber' => $inv->invoice_number,
                        'categoryName' => $inv->category->name ?? '',
                        'period' => $inv->period,
                        'amount' => (float) $inv->remaining_amount,
                        'dueDate' => $inv->due_date->toIso8601String(),
                        'daysOverdue' => now()->diffInDays($inv->due_date),
                    ])->toArray(),
                ];
            })->values();

        // Group by class
        $byClass = $overdueInvoices->groupBy(fn($inv) => $inv->student->class_name ?? 'Unknown')
            ->map(fn($group) => [
                'className' => $group->first()->student->class_name ?? 'Unknown',
                'studentCount' => $group->unique('student_id')->count(),
                'invoiceCount' => $group->count(),
                'totalArrears' => (float) $group->sum(fn($inv) => $inv->remaining_amount),
            ])->values();

        $summary = [
            'totalArrears' => (float) $overdueInvoices->sum(fn($inv) => $inv->remaining_amount),
            'totalStudents' => $overdueInvoices->unique('student_id')->count(),
            'totalInvoices' => $overdueInvoices->count(),
        ];

        return response()->json([
            'success' => true,
            'data' => [
                'summary' => $summary,
                'byClass' => $byClass,
                'byStudent' => $byStudent,
            ],
        ]);
    }

    /**
     * Export report as CSV
     */
    public function export(Request $request): JsonResponse
    {
        $type = $request->get('type', 'daily');
        $date = $request->get('date', today()->toDateString());

        $headers = [];
        $rows = [];

        if ($type === 'daily') {
            $transactions = Transaction::whereDate('settlement_time', $date)
                ->whereIn('status', ['settlement', 'capture'])
                ->with(['invoice.student', 'invoice.category'])
                ->get();

            $headers = ['No', 'Tanggal', 'No Invoice', 'Nama Siswa', 'Kategori', 'Metode Pembayaran', 'Jumlah'];

            foreach ($transactions as $index => $tx) {
                $rows[] = [
                    $index + 1,
                    $tx->settlement_time?->format('Y-m-d H:i'),
                    $tx->invoice->invoice_number ?? '',
                    $tx->invoice->student->name ?? '',
                    $tx->invoice->category->name ?? '',
                    $tx->payment_type ?? '',
                    number_format($tx->gross_amount, 0, ',', '.'),
                ];
            }
        } elseif ($type === 'arrears') {
            $overdueInvoices = Invoice::with(['student', 'category'])
                ->where('status', 'unpaid')
                ->where('due_date', '<', now())
                ->orderBy('due_date', 'asc')
                ->get();

            $headers = ['No', 'NIS', 'Nama Siswa', 'Kelas', 'Kategori', 'Periode', 'Jatuh Tempo', 'Sisa Tagihan'];

            foreach ($overdueInvoices as $index => $inv) {
                $rows[] = [
                    $index + 1,
                    $inv->student->nis ?? '',
                    $inv->student->name ?? '',
                    $inv->student->class_name ?? '',
                    $inv->category->name ?? '',
                    $inv->period ?? '',
                    $inv->due_date?->format('Y-m-d'),
                    number_format($inv->remaining_amount, 0, ',', '.'),
                ];
            }
        }

        return response()->json([
            'success' => true,
            'data' => [
                'type' => $type,
                'date' => $date,
                'headers' => $headers,
                'rows' => $rows,
                'filename' => "laporan_{$type}_{$date}.csv",
            ],
        ]);
    }
}
