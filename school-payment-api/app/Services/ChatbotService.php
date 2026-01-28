<?php

namespace App\Services;

use App\Models\User;
use App\Models\Invoice;
use App\Models\Student;
use App\Models\Transaction;
use App\Models\ChatbotSession;

class ChatbotService
{
    /**
     * Intent patterns mapping
     */
    protected array $intentPatterns = [
        'cek_tunggakan' => ['tunggakan', 'belum bayar', 'tagihan', 'hutang', 'sisa bayar'],
        'cek_spp' => ['spp', 'iuran bulanan', 'bayar bulanan'],
        'cek_invoice' => ['invoice', 'tagihan bulan', 'bulan ini'],
        'jatuh_tempo' => ['jatuh tempo', 'deadline', 'batas waktu', 'kapan bayar'],
        'bukti_bayar' => ['bukti', 'receipt', 'kwitansi', 'struk'],
        'bayar' => ['bayar', 'transfer', 'pembayaran'],
        'total_pemasukan' => ['pemasukan', 'pendapatan', 'income', 'total hari ini'],
        'jumlah_penunggak' => ['penunggak', 'nunggak', 'belum bayar kelas'],
        'rekap' => ['rekap', 'laporan', 'report', 'summary'],
        'greeting' => ['halo', 'hai', 'hello', 'hi', 'selamat'],
        'help' => ['bantu', 'help', 'tolong', 'bisa apa', 'perintah'],
    ];

    /**
     * Process chatbot message
     */
    public function processMessage(User $user, string $message, ChatbotSession $session): array
    {
        $intent = $this->detectIntent($message);
        $isAdmin = $user->isAdmin();

        return match ($intent) {
            'cek_tunggakan' => $this->handleCekTunggakan($user, $isAdmin),
            'cek_spp' => $this->handleCekSpp($user, $isAdmin),
            'cek_invoice' => $this->handleCekInvoice($user, $isAdmin, $message),
            'jatuh_tempo' => $this->handleJatuhTempo($user, $isAdmin),
            'bukti_bayar' => $this->handleBuktiBayar($user, $isAdmin),
            'bayar' => $this->handleBayar($user, $isAdmin, $message),
            'total_pemasukan' => $this->handleTotalPemasukan($user, $isAdmin),
            'jumlah_penunggak' => $this->handleJumlahPenunggak($user, $isAdmin),
            'rekap' => $this->handleRekap($user, $isAdmin),
            'greeting' => $this->handleGreeting($user),
            'help' => $this->handleHelp($user, $isAdmin),
            default => $this->handleUnknown(),
        };
    }

    /**
     * Detect intent from message
     */
    protected function detectIntent(string $message): string
    {
        $message = strtolower($message);

        foreach ($this->intentPatterns as $intent => $patterns) {
            foreach ($patterns as $pattern) {
                if (str_contains($message, $pattern)) {
                    return $intent;
                }
            }
        }

        return 'unknown';
    }

    /**
     * Handle cek tunggakan
     */
    protected function handleCekTunggakan(User $user, bool $isAdmin): array
    {
        if ($isAdmin) {
            $totalArrears = Invoice::where('status', 'unpaid')
                ->where('due_date', '<', now())
                ->sum(\DB::raw('total_amount - paid_amount'));

            $count = Invoice::where('status', 'unpaid')
                ->where('due_date', '<', now())
                ->distinct('student_id')
                ->count('student_id');

            return [
                'intent' => 'cek_tunggakan',
                'reply' => "📊 *Laporan Tunggakan*\n\nTotal siswa menunggak: {$count}\nTotal nilai tunggakan: Rp " . number_format($totalArrears, 0, ',', '.'),
                'quick_actions' => [
                    ['label' => 'Detail per Kelas', 'action' => 'rekap per kelas'],
                    ['label' => 'Lihat Daftar', 'action' => 'daftar penunggak'],
                ],
            ];
        }

        // For student/parent
        $studentId = $user->student_id;
        if (!$studentId && $user->role === 'orang_tua') {
            $studentId = Student::where('parent_id', $user->id)->value('id');
        }

        if (!$studentId) {
            return [
                'intent' => 'cek_tunggakan',
                'reply' => '⚠️ Tidak ada data siswa terhubung dengan akun Anda.',
            ];
        }

        $invoices = Invoice::where('student_id', $studentId)
            ->where('status', 'unpaid')
            ->with('category')
            ->get();

        if ($invoices->isEmpty()) {
            return [
                'intent' => 'cek_tunggakan',
                'reply' => '✅ *Tidak ada tunggakan*\n\nSemua tagihan Anda sudah lunas. Terima kasih!',
            ];
        }

        $totalUnpaid = $invoices->sum(fn($inv) => $inv->remaining_amount);
        $details = $invoices->take(5)->map(
            fn($inv) =>
            "• {$inv->category->name} ({$inv->period}): Rp " . number_format($inv->remaining_amount, 0, ',', '.')
        )->join("\n");

        return [
            'intent' => 'cek_tunggakan',
            'reply' => "📋 *Tunggakan Anda*\n\n{$details}\n\n*Total: Rp " . number_format($totalUnpaid, 0, ',', '.') . "*",
            'quick_actions' => [
                ['label' => 'Bayar Sekarang', 'action' => 'bayar'],
                ['label' => 'Lihat Detail', 'action' => 'detail invoice'],
            ],
        ];
    }

    /**
     * Handle cek SPP
     */
    protected function handleCekSpp(User $user, bool $isAdmin): array
    {
        $currentMonth = now()->format('F Y');

        if ($isAdmin) {
            $sppInvoices = Invoice::whereHas('category', fn($q) => $q->where('name', 'like', '%SPP%'))
                ->where('period', 'like', "%{$currentMonth}%")
                ->get();

            $paid = $sppInvoices->where('status', 'paid')->count();
            $unpaid = $sppInvoices->where('status', 'unpaid')->count();

            return [
                'intent' => 'cek_spp',
                'reply' => "📊 *Status SPP {$currentMonth}*\n\n✅ Sudah bayar: {$paid} siswa\n⏳ Belum bayar: {$unpaid} siswa",
            ];
        }

        return $this->handleCekTunggakan($user, false);
    }

    /**
     * Handle cek invoice
     */
    protected function handleCekInvoice(User $user, bool $isAdmin, string $message): array
    {
        return $this->handleCekTunggakan($user, $isAdmin);
    }

    /**
     * Handle jatuh tempo
     */
    protected function handleJatuhTempo(User $user, bool $isAdmin): array
    {
        $studentId = $user->student_id;
        if (!$studentId && $user->role === 'orang_tua') {
            $studentId = Student::where('parent_id', $user->id)->value('id');
        }

        if (!$studentId) {
            return [
                'intent' => 'jatuh_tempo',
                'reply' => '⚠️ Tidak ada data siswa terhubung dengan akun Anda.',
            ];
        }

        $invoice = Invoice::where('student_id', $studentId)
            ->where('status', 'unpaid')
            ->orderBy('due_date')
            ->first();

        if (!$invoice) {
            return [
                'intent' => 'jatuh_tempo',
                'reply' => '✅ Tidak ada tagihan mendatang.',
            ];
        }

        $dueDate = $invoice->due_date->format('d F Y');
        $daysLeft = now()->diffInDays($invoice->due_date, false);

        $status = $daysLeft < 0 ? "⚠️ Sudah lewat " . abs($daysLeft) . " hari!" : "⏰ {$daysLeft} hari lagi";

        return [
            'intent' => 'jatuh_tempo',
            'reply' => "📅 *Jatuh Tempo Terdekat*\n\nTagihan: {$invoice->category->name}\nPeriod: {$invoice->period}\nJatuh Tempo: {$dueDate}\nStatus: {$status}",
            'quick_actions' => [
                ['label' => 'Bayar Sekarang', 'action' => 'bayar'],
            ],
        ];
    }

    /**
     * Handle bukti bayar
     */
    protected function handleBuktiBayar(User $user, bool $isAdmin): array
    {
        $studentId = $user->student_id;
        if (!$studentId && $user->role === 'orang_tua') {
            $studentId = Student::where('parent_id', $user->id)->value('id');
        }

        if (!$studentId) {
            return [
                'intent' => 'bukti_bayar',
                'reply' => '⚠️ Tidak ada data siswa terhubung dengan akun Anda.',
            ];
        }

        $lastTransaction = Transaction::whereHas('invoice', fn($q) => $q->where('student_id', $studentId))
            ->whereIn('status', ['settlement', 'capture'])
            ->orderBy('settlement_time', 'desc')
            ->with('invoice.category')
            ->first();

        if (!$lastTransaction) {
            return [
                'intent' => 'bukti_bayar',
                'reply' => '📋 Belum ada riwayat pembayaran.',
            ];
        }

        return [
            'intent' => 'bukti_bayar',
            'reply' => "🧾 *Bukti Pembayaran Terakhir*\n\nNo. Transaksi: {$lastTransaction->order_id}\nTagihan: {$lastTransaction->invoice->category->name}\nNominal: Rp " . number_format($lastTransaction->gross_amount, 0, ',', '.') . "\nTanggal: " . $lastTransaction->settlement_time->format('d F Y H:i'),
        ];
    }

    /**
     * Handle bayar
     */
    protected function handleBayar(User $user, bool $isAdmin, string $message): array
    {
        return [
            'intent' => 'bayar',
            'reply' => "💳 *Pembayaran*\n\nUntuk melakukan pembayaran, silakan:\n1. Buka menu Tagihan\n2. Pilih tagihan yang ingin dibayar\n3. Klik tombol Bayar\n\nAnda akan diarahkan ke halaman pembayaran Midtrans.",
            'quick_actions' => [
                ['label' => 'Lihat Tagihan', 'action' => 'cek tunggakan'],
            ],
        ];
    }

    /**
     * Handle total pemasukan (admin only)
     */
    protected function handleTotalPemasukan(User $user, bool $isAdmin): array
    {
        if (!$isAdmin) {
            return [
                'intent' => 'total_pemasukan',
                'reply' => '⛔ Anda tidak memiliki akses ke informasi ini.',
            ];
        }

        $todayIncome = Transaction::whereDate('settlement_time', today())
            ->whereIn('status', ['settlement', 'capture'])
            ->sum('gross_amount');

        $count = Transaction::whereDate('settlement_time', today())
            ->whereIn('status', ['settlement', 'capture'])
            ->count();

        return [
            'intent' => 'total_pemasukan',
            'reply' => "💰 *Pemasukan Hari Ini*\n\nTotal: Rp " . number_format($todayIncome, 0, ',', '.') . "\nJumlah transaksi: {$count}",
            'quick_actions' => [
                ['label' => 'Rekap Bulanan', 'action' => 'rekap bulan ini'],
            ],
        ];
    }

    /**
     * Handle jumlah penunggak (admin only)
     */
    protected function handleJumlahPenunggak(User $user, bool $isAdmin): array
    {
        if (!$isAdmin) {
            return [
                'intent' => 'jumlah_penunggak',
                'reply' => '⛔ Anda tidak memiliki akses ke informasi ini.',
            ];
        }

        $byClass = Invoice::where('status', 'unpaid')
            ->where('due_date', '<', now())
            ->join('students', 'invoices.student_id', '=', 'students.id')
            ->select('students.class_name', \DB::raw('COUNT(DISTINCT invoices.student_id) as count'))
            ->groupBy('students.class_name')
            ->get();

        $details = $byClass->map(fn($row) => "• {$row->class_name}: {$row->count} siswa")->join("\n");

        return [
            'intent' => 'jumlah_penunggak',
            'reply' => "📊 *Penunggak per Kelas*\n\n{$details}",
        ];
    }

    /**
     * Handle rekap
     */
    protected function handleRekap(User $user, bool $isAdmin): array
    {
        if (!$isAdmin) {
            return [
                'intent' => 'rekap',
                'reply' => '⛔ Anda tidak memiliki akses ke informasi ini.',
            ];
        }

        $thisMonth = now()->startOfMonth();
        $invoices = Invoice::where('created_at', '>=', $thisMonth)->get();

        $totalBilled = $invoices->sum('total_amount');
        $totalPaid = $invoices->sum('paid_amount');

        return [
            'intent' => 'rekap',
            'reply' => "📊 *Rekap Bulan Ini*\n\nTotal Tagihan: Rp " . number_format($totalBilled, 0, ',', '.') . "\nSudah Terbayar: Rp " . number_format($totalPaid, 0, ',', '.') . "\nBelum Terbayar: Rp " . number_format($totalBilled - $totalPaid, 0, ',', '.'),
            'quick_actions' => [
                ['label' => 'Detail per Kategori', 'action' => 'rekap per kategori'],
            ],
        ];
    }

    /**
     * Handle greeting
     */
    protected function handleGreeting(User $user): array
    {
        $hour = now()->hour;
        $greeting = match (true) {
            $hour < 12 => 'Selamat pagi',
            $hour < 15 => 'Selamat siang',
            $hour < 18 => 'Selamat sore',
            default => 'Selamat malam',
        };

        return [
            'intent' => 'greeting',
            'reply' => "👋 {$greeting}, {$user->name}!\n\nSaya adalah asisten pembayaran sekolah. Ada yang bisa saya bantu?",
            'quick_actions' => [
                ['label' => 'Cek Tunggakan', 'action' => 'cek tunggakan'],
                ['label' => 'Jatuh Tempo', 'action' => 'jatuh tempo'],
                ['label' => 'Bantuan', 'action' => 'help'],
            ],
        ];
    }

    /**
     * Handle help
     */
    protected function handleHelp(User $user, bool $isAdmin): array
    {
        $commands = "📌 *Perintah yang tersedia:*\n\n";
        $commands .= "• \"cek tunggakan\" - Lihat tagihan belum dibayar\n";
        $commands .= "• \"jatuh tempo\" - Cek jatuh tempo terdekat\n";
        $commands .= "• \"bukti bayar\" - Lihat bukti pembayaran terakhir\n";
        $commands .= "• \"bayar\" - Panduan pembayaran\n";

        if ($isAdmin) {
            $commands .= "\n*Khusus Admin:*\n";
            $commands .= "• \"pemasukan hari ini\" - Total pemasukan hari ini\n";
            $commands .= "• \"penunggak per kelas\" - Jumlah penunggak per kelas\n";
            $commands .= "• \"rekap\" - Rekap bulanan\n";
        }

        return [
            'intent' => 'help',
            'reply' => $commands,
        ];
    }

    /**
     * Handle unknown intent
     */
    protected function handleUnknown(): array
    {
        return [
            'intent' => 'unknown',
            'reply' => "🤔 Maaf, saya tidak mengerti pesan Anda.\n\nKetik \"help\" untuk melihat daftar perintah yang tersedia.",
            'quick_actions' => [
                ['label' => 'Bantuan', 'action' => 'help'],
            ],
        ];
    }
}
