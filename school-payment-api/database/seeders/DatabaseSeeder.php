<?php

namespace Database\Seeders;

use App\Models\User;
use App\Models\Student;
use App\Models\FeeCategory;
use App\Models\Invoice;
use App\Models\InvoiceItem;
use App\Models\Transaction;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class DatabaseSeeder extends Seeder
{
    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        // Create users (default password: 123456)
        $admin = User::create([
            'name' => 'Administrator',
            'email' => 'admin@school.com',
            'password' => Hash::make('123456'),
            'role' => 'admin',
            'must_change_password' => true,
        ]);

        $bendahara = User::create([
            'name' => 'Bendahara Sekolah',
            'email' => 'bendahara@school.com',
            'password' => Hash::make('123456'),
            'role' => 'bendahara',
            'must_change_password' => true,
        ]);

        $waliKelas = User::create([
            'name' => 'Wali Kelas X-A',
            'email' => 'walikelas@school.com',
            'password' => Hash::make('123456'),
            'role' => 'wali_kelas',
            'must_change_password' => true,
        ]);

        // Create fee categories
        $spp = FeeCategory::create([
            'name' => 'SPP',
            'description' => 'Sumbangan Pembinaan Pendidikan bulanan',
            'type' => 'akademik',
            'frequency' => 'monthly',
            'base_amount' => 500000,
            'is_active' => true,
        ]);

        $dps = FeeCategory::create([
            'name' => 'DPS/Uang Gedung',
            'description' => 'Dana Pengembangan Sekolah',
            'type' => 'akademik',
            'frequency' => 'once',
            'base_amount' => 5000000,
            'is_active' => true,
            'allow_installment' => true,
            'max_installments' => 6,
        ]);

        $ujian = FeeCategory::create([
            'name' => 'Ujian Semester',
            'description' => 'Biaya ujian semester',
            'type' => 'akademik',
            'frequency' => 'semester',
            'base_amount' => 200000,
            'is_active' => true,
        ]);

        $seragam = FeeCategory::create([
            'name' => 'Seragam',
            'description' => 'Pembelian seragam sekolah',
            'type' => 'non_akademik',
            'frequency' => 'once',
            'base_amount' => 750000,
            'is_active' => true,
        ]);

        $kegiatan = FeeCategory::create([
            'name' => 'Kegiatan OSIS',
            'description' => 'Iuran kegiatan OSIS',
            'type' => 'insidental',
            'frequency' => 'yearly',
            'base_amount' => 150000,
            'is_active' => true,
        ]);

        $studyTour = FeeCategory::create([
            'name' => 'Study Tour',
            'description' => 'Kunjungan industri/wisata edukasi',
            'type' => 'insidental',
            'frequency' => 'once',
            'base_amount' => 1500000,
            'is_active' => true,
            'allow_installment' => true,
            'max_installments' => 3,
        ]);

        // Create students
        $students = [
            ['nis' => '2024001', 'name' => 'Ahmad Rizki', 'class_name' => 'X-A', 'major' => 'RPL'],
            ['nis' => '2024002', 'name' => 'Siti Fatimah', 'class_name' => 'X-A', 'major' => 'RPL'],
            ['nis' => '2024003', 'name' => 'Budi Santoso', 'class_name' => 'X-B', 'major' => 'TKJ'],
            ['nis' => '2024004', 'name' => 'Dewi Lestari', 'class_name' => 'X-B', 'major' => 'TKJ'],
            ['nis' => '2024005', 'name' => 'Eko Prasetyo', 'class_name' => 'XI-A', 'major' => 'RPL'],
            ['nis' => '2024006', 'name' => 'Fitri Handayani', 'class_name' => 'XI-A', 'major' => 'RPL'],
            ['nis' => '2024007', 'name' => 'Galih Pratama', 'class_name' => 'XI-B', 'major' => 'TKJ'],
            ['nis' => '2024008', 'name' => 'Hana Safitri', 'class_name' => 'XI-B', 'major' => 'TKJ'],
            ['nis' => '2024009', 'name' => 'Irfan Maulana', 'class_name' => 'XII-A', 'major' => 'RPL'],
            ['nis' => '2024010', 'name' => 'Jihan Amelia', 'class_name' => 'XII-A', 'major' => 'RPL'],
        ];

        foreach ($students as $index => $studentData) {
            $student = Student::create([
                'nis' => $studentData['nis'],
                'name' => $studentData['name'],
                'class_name' => $studentData['class_name'],
                'major' => $studentData['major'],
                'parent_name' => 'Orang Tua ' . $studentData['name'],
                'parent_phone' => '0812345678' . $index,
                'parent_email' => 'parent' . ($index + 1) . '@email.com',
                'status' => 'active',
                'enrolled_at' => now()->subMonths(rand(1, 24)),
            ]);

            // Create user account for EVERY student (siswa + parent access same account)
            User::create([
                'name' => $studentData['name'],
                'email' => 'siswa' . ($index + 1) . '@school.com',
                'password' => Hash::make('123456'),
                'role' => 'siswa',
                'student_id' => $student->id,
                'must_change_password' => true,
                'is_active' => true,
            ]);

            // Create invoices for each student
            $months = ['Januari', 'Februari', 'Maret', 'Desember'];
            foreach ($months as $monthIndex => $month) {
                $status = $monthIndex < 2 ? 'paid' : ($monthIndex === 2 ? 'partial' : 'unpaid');
                $dueDate = now()->startOfYear()->addMonths($monthIndex)->endOfMonth();

                $invoice = Invoice::create([
                    'invoice_number' => 'INV-' . date('Ymd') . '-' . str_pad($student->id * 10 + $monthIndex, 4, '0', STR_PAD_LEFT),
                    'student_id' => $student->id,
                    'category_id' => $spp->id,
                    'period' => $month . ' 2024',
                    'total_amount' => $spp->base_amount,
                    'paid_amount' => $status === 'paid' ? $spp->base_amount : ($status === 'partial' ? $spp->base_amount / 2 : 0),
                    'status' => $status,
                    'due_date' => $dueDate,
                    'created_by' => $admin->id,
                ]);

                InvoiceItem::create([
                    'invoice_id' => $invoice->id,
                    'description' => 'SPP ' . $month . ' 2024',
                    'amount' => $spp->base_amount,
                    'quantity' => 1,
                ]);

                // Create transaction for paid invoices
                if ($status === 'paid' || $status === 'partial') {
                    Transaction::create([
                        'order_id' => 'ORDER-' . $invoice->id . '-' . now()->format('YmdHis') . '-' . strtoupper(substr(md5(rand()), 0, 6)),
                        'invoice_id' => $invoice->id,
                        'gross_amount' => $invoice->paid_amount,
                        'payment_type' => ['bank_transfer', 'gopay', 'qris'][rand(0, 2)],
                        'status' => 'settlement',
                        'transaction_time' => $dueDate->subDays(rand(1, 10)),
                        'settlement_time' => $dueDate->subDays(rand(1, 10)),
                    ]);
                }
            }
        }

        $this->command->info('Database seeded successfully!');
        $this->command->info('');
        $this->command->info('Test accounts:');
        $this->command->info('  Admin: admin@school.com / password');
        $this->command->info('  Bendahara: bendahara@school.com / password');
        $this->command->info('  Wali Kelas: walikelas@school.com / password');
        $this->command->info('  Siswa 1: siswa1@school.com / password');
        $this->command->info('  Siswa 2: siswa2@school.com / password');
        $this->command->info('  Orang Tua 1: orangtua1@school.com / password');
        $this->command->info('  Orang Tua 2: orangtua2@school.com / password');
    }
}
