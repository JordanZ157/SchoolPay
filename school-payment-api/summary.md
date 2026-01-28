## Ringkasan Proyek: School Payment System + Chatbot

**Tujuan:** Membuat aplikasi pembayaran sekolah yang **efisien**, **transparan**, **terintegrasi**, dan mendukung **dashboard**, **notifikasi**, **e-receipt**, **laporan keuangan**, integrasi **Midtrans**, serta **chatbot** untuk membantu orang tua/siswa/admin.

---

# 1) Stack Teknologi yang Dipakai

* **Backend:** Laravel (PHP) – fokus REST API + business logic
* **Frontend:** Flutter Web (cross-platform)
* **Database:** SQLite
* **ORM/DB Tool:** DrizzleORM + Drizzle Studio (untuk schema & migrasi dan manajemen DB)
* **Payment Gateway:** Midtrans (Snap + Webhook)

---

# 2) Ruang Lingkup Pembayaran yang Harus Didukung

## A. Akademik rutin (periodik/wajib)

* SPP/Iuran bulanan (tarif beda per jenjang/kelas, atau tetap)
* Uang Gedung/DPS (sekali atau cicilan)
* Uang kegiatan/OSIS/ekstrakurikuler
* Uang ujian (UTS/UAS/UKK/USBN/UNBK)
* Uang praktik/PKL/magang

## B. Non-akademik / layanan tambahan (opsional)

* Seragam/atribut
* Buku paket/LKS (semesteran)
* Koperasi/kantin digital (saldo siswa)
* Asuransi/BPJS siswa
* Transportasi/antar jemput

## C. Insidental/kegiatan khusus

* Donasi/campaign sosial (nominal fleksibel)
* Study tour/kunjungan industri (bisa cicilan + reminder)
* Uang kelas/iuran khusus (wali kelas/bendahara kelas)
* Wisuda/perpisahan/kenaikan kelas

## D. Administratif & digital

* Cetak rapor/leglisasi dokumen
* PPDB/pendaftaran online
* Layanan LMS premium/sertifikasi
* Denda keterlambatan pembayaran / denda perpustakaan

---

# 3) Peran Sistem (Role-Based Access)

Minimal role:

* **Admin sekolah**
* **Bendahara**
* **Wali kelas / petugas**
* **Siswa**
* **Orang tua/wali**
* (Opsional) **Unit koperasi/kantin**

Akses dibatasi sesuai role + audit trail.

---

# 4) Fitur Utama yang Wajib Ada

## Untuk Siswa/Orang Tua

* Dashboard tagihan (status PAID/UNPAID/PARTIAL)
* Detail tagihan + item
* Riwayat transaksi
* Unduh/lihat **e-receipt**
* Tombol **Bayar** → Midtrans

## Untuk Admin/Bendahara

* Master data siswa & kelas
* Master kategori pembayaran & tarif
* Generate invoice otomatis (SPP bulanan, dll)
* Buat invoice event (insidental) + opsi cicilan
* Laporan:

  * kas harian
  * per kategori
  * per siswa
  * tunggakan/piutang
  * ekspor (opsional PDF/Excel)
* Audit log perubahan data (transparansi)

## Notifikasi

* Notifikasi tagihan baru + pengingat jatuh tempo
* Notifikasi pembayaran berhasil
* Channel: WhatsApp/email (implementasi bisa bertahap)

---

# 5) Konsep Data & Entity (Database Model)

Wajib ada tabel/entitas berikut:

1. **students**

* id, nis, nama, kelas, jurusan, status, wali/orangtua (relasi)

2. **users**

* login + role + relasi ke student/parent/admin

3. **fee_categories**

* SPP, DPS, Ujian, Seragam, Donasi, dll (tipe: akademik/non-akademik/insidental/admin)

4. **fee_rates**

* category_id, jenjang/kelas, tahun ajaran, nominal, frekuensi (monthly/once/semester/year), aturan cicilan (jika ada)

5. **invoices**

* student_id, category_id, period (bulan/tahun), due_date, status (UNPAID/PAID/PARTIAL/EXPIRED), total_amount, created_by

6. **invoice_items**

* invoice_id, deskripsi item, amount, qty (jika perlu)

7. **transactions**

* invoice_id, order_id (Midtrans), gross_amount, payment_type, transaction_status, transaction_time, settlement_time, raw_payload, reference_number

8. **receipts**

* invoice_id, receipt_no, issued_at, pdf_url/metadata (opsional)

9. **audit_logs**

* actor_user_id, action, entity, before/after, timestamp

Chatbot:
10. **chatbot_sessions**

* user_id, last_intent, context_json, last_active_at

11. **chatbot_logs**

* user_id, message, intent, response, created_at

---

# 6) Alur Pembayaran Midtrans (Wajib)

## Mekanisme

* Gunakan **Midtrans Snap** untuk membuat payment token / payment URL.
* **Order ID** harus unik & dipetakan ke invoice.
* Setelah user bayar, Midtrans mengirim **Webhook/Callback** ke Laravel:

  * settlement/success → set invoice PAID
  * pending → status PENDING
  * expire/cancel/deny → EXPIRED/CANCELED/FAILED

## Keamanan

* Verifikasi signature key dari payload webhook.
* Jangan update status invoice tanpa verifikasi callback yang valid.

---

# 7) Chatbot (Tambahan Sistem)

Tujuan chatbot: menurunkan beban admin & memudahkan akses info pembayaran.

## Tipe: Hybrid (rule-based + data-driven)

* Deteksi intent dari teks (keyword/pattern) → ambil data real dari DB → jawab deterministik.

## Use case chatbot:

Siswa/orang tua:

* cek tunggakan SPP
* cek invoice belum dibayar per bulan
* minta jatuh tempo
* minta bukti pembayaran terakhir
* “mau bayar SPP bulan X” → chatbot memicu alur pembuatan link Midtrans

Admin/bendahara:

* total pemasukan hari ini
* jumlah penunggak per kelas
* rekap per kategori

## Batasan chatbot:

* Tidak boleh mengubah nominal/discount
* Tidak boleh menghapus tunggakan/refund
* Hanya menampilkan data sesuai user login (RBAC)

## Endpoint chatbot (contoh):

* `POST /api/chatbot/message`
  input: `{ message: string }`
  output: `{ reply: string, quick_actions?: [] }`

---

# 8) API Laravel yang Perlu Disediakan (Minimal)

Auth:

* `POST /api/login`
* `POST /api/logout`
* `GET /api/me`

Invoices & Payments:

* `GET /api/invoices` (filter status/kategori/period)
* `GET /api/invoices/{id}`
* `POST /api/invoices/generate` (admin)
* `POST /api/pay/{invoice_id}` → create Snap token + return payment_url

Reports (admin):

* `GET /api/reports/daily`
* `GET /api/reports/category`
* `GET /api/reports/student/{student_id}`
* `GET /api/reports/arrears`

Webhook:

* `POST /api/midtrans/callback` (verifikasi signature + update invoice + simpan transaksi)

Chatbot:

* `POST /api/chatbot/message`

---

# 9) Frontend Flutter Web (Halaman Minimum)

Siswa/Orang tua:

* Login
* Dashboard tagihan
* Detail invoice
* Proses bayar (buka Snap payment URL)
* Riwayat pembayaran
* E-receipt view/download
* Halaman chat (chatbot UI)

Admin/Bendahara:

* Dashboard ringkas (pemasukan, tunggakan)
* Kelola kategori & tarif
* Generate invoice rutin
* Buat invoice event
* Laporan + export (opsional)
* Halaman chat admin (opsional)

---

# 10) Otomasi (Scheduler)

Laravel Scheduler:

* Generate SPP bulanan otomatis
* Notifikasi H-7/H-3/H-1 sebelum jatuh tempo (opsional tahap awal)
* Rekonsiliasi / pengecekan status pembayaran (opsional, webhook tetap sumber utama)

---

## Catatan Implementasi Penting

* SQLite cocok untuk tahap awal/sekolah kecil-menengah; desain schema harus mudah migrasi ke PostgreSQL bila skala membesar.
* Status invoice dan transaksi harus konsisten (source of truth: webhook Midtrans).
* Semua perubahan data penting dicatat di audit_logs untuk transparansi.
