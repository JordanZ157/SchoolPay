import '../models/user.dart';
import '../models/student.dart';
import '../models/invoice.dart';
import '../models/transaction.dart';
import '../models/fee_category.dart';

/// Mock data for demo purposes
/// This will be replaced with actual API calls when backend is ready
class MockData {
  // Demo Users
  static final List<User> users = [
    User(
      id: 'u1',
      email: 'admin@sekolah.id',
      name: 'Administrator',
      role: UserRole.admin,
    ),
    User(
      id: 'u2',
      email: 'bendahara@sekolah.id',
      name: 'Ibu Siti Rahayu',
      role: UserRole.bendahara,
    ),
    User(
      id: 'u3',
      email: 'budi.siswa@sekolah.id',
      name: 'Budi Santoso',
      role: UserRole.siswa,
      studentId: 's1',
    ),
    User(
      id: 'u4',
      email: 'orangtua.budi@gmail.com',
      name: 'Pak Santoso',
      role: UserRole.orangTua,
      studentId: 's1',
    ),
  ];

  // Demo Students
  static final List<Student> students = [
    Student(
      id: 's1',
      nis: '2024001',
      name: 'Budi Santoso',
      className: 'XII',
      major: 'TKJ',
      parentName: 'Pak Santoso',
      parentPhone: '081234567890',
      parentEmail: 'orangtua.budi@gmail.com',
    ),
    Student(
      id: 's2',
      nis: '2024002',
      name: 'Ani Wijaya',
      className: 'XII',
      major: 'TKR',
      parentName: 'Bu Wijaya',
      parentPhone: '081234567891',
    ),
    Student(
      id: 's3',
      nis: '2024003',
      name: 'Citra Dewi',
      className: 'XI',
      major: 'TKJ',
      parentName: 'Pak Dewi',
      parentPhone: '081234567892',
    ),
    Student(
      id: 's4',
      nis: '2024004',
      name: 'Doni Pratama',
      className: 'XI',
      major: 'TKR',
      parentName: 'Bu Pratama',
      parentPhone: '081234567893',
    ),
    Student(
      id: 's5',
      nis: '2024005',
      name: 'Eka Putri',
      className: 'X',
      major: 'TKJ',
      parentName: 'Pak Putri',
      parentPhone: '081234567894',
    ),
  ];

  // Demo Fee Categories
  static final List<FeeCategory> feeCategories = [
    FeeCategory(
      id: 'fc1',
      name: 'SPP',
      description: 'Sumbangan Pembinaan Pendidikan bulanan',
      type: FeeType.akademik,
      frequency: FeeFrequency.monthly,
      baseAmount: 500000,
    ),
    FeeCategory(
      id: 'fc2',
      name: 'Uang Gedung',
      description: 'Dana Pengembangan Sekolah (sekali bayar/cicilan)',
      type: FeeType.akademik,
      frequency: FeeFrequency.once,
      baseAmount: 5000000,
      allowInstallment: true,
      maxInstallments: 12,
    ),
    FeeCategory(
      id: 'fc3',
      name: 'Ujian Semester',
      description: 'Biaya pelaksanaan ujian UTS/UAS',
      type: FeeType.akademik,
      frequency: FeeFrequency.semester,
      baseAmount: 250000,
    ),
    FeeCategory(
      id: 'fc4',
      name: 'Kegiatan OSIS',
      description: 'Iuran kegiatan ekstrakulikuler dan OSIS',
      type: FeeType.nonAkademik,
      frequency: FeeFrequency.yearly,
      baseAmount: 200000,
    ),
    FeeCategory(
      id: 'fc5',
      name: 'Seragam',
      description: 'Pembelian seragam sekolah',
      type: FeeType.nonAkademik,
      frequency: FeeFrequency.once,
      baseAmount: 750000,
    ),
    FeeCategory(
      id: 'fc6',
      name: 'Study Tour',
      description: 'Kunjungan wisata edukasi',
      type: FeeType.insidental,
      frequency: FeeFrequency.once,
      baseAmount: 1500000,
      allowInstallment: true,
      maxInstallments: 3,
    ),
    FeeCategory(
      id: 'fc7',
      name: 'Wisuda',
      description: 'Biaya acara kelulusan dan wisuda',
      type: FeeType.insidental,
      frequency: FeeFrequency.once,
      baseAmount: 500000,
    ),
    FeeCategory(
      id: 'fc8',
      name: 'Denda Keterlambatan',
      description: 'Denda pembayaran lewat jatuh tempo',
      type: FeeType.administratif,
      frequency: FeeFrequency.once,
      baseAmount: 50000,
    ),
  ];

  // Demo Invoices for student s1 (Budi)
  static final List<Invoice> invoices = [
    // Unpaid SPP Desember
    Invoice(
      id: 'inv1',
      invoiceNumber: 'INV-2024-001',
      studentId: 's1',
      studentName: 'Budi Santoso',
      categoryId: 'fc1',
      categoryName: 'SPP',
      period: 'Desember 2024',
      items: [
        InvoiceItem(id: 'ii1', description: 'SPP Desember 2024', amount: 500000),
      ],
      totalAmount: 500000,
      status: InvoiceStatus.unpaid,
      dueDate: DateTime(2024, 12, 31),
      createdAt: DateTime(2024, 12, 1),
    ),
    // Paid SPP November
    Invoice(
      id: 'inv2',
      invoiceNumber: 'INV-2024-002',
      studentId: 's1',
      studentName: 'Budi Santoso',
      categoryId: 'fc1',
      categoryName: 'SPP',
      period: 'November 2024',
      items: [
        InvoiceItem(id: 'ii2', description: 'SPP November 2024', amount: 500000),
      ],
      totalAmount: 500000,
      paidAmount: 500000,
      status: InvoiceStatus.paid,
      dueDate: DateTime(2024, 11, 30),
      createdAt: DateTime(2024, 11, 1),
    ),
    // Partial payment Study Tour
    Invoice(
      id: 'inv3',
      invoiceNumber: 'INV-2024-003',
      studentId: 's1',
      studentName: 'Budi Santoso',
      categoryId: 'fc6',
      categoryName: 'Study Tour',
      period: 'Semester 2 2024',
      items: [
        InvoiceItem(id: 'ii3', description: 'Study Tour Bali', amount: 1500000),
      ],
      totalAmount: 1500000,
      paidAmount: 500000,
      status: InvoiceStatus.partial,
      dueDate: DateTime(2025, 1, 15),
      createdAt: DateTime(2024, 11, 15),
      notes: 'Cicilan 1/3 sudah dibayar',
    ),
    // Paid SPP October
    Invoice(
      id: 'inv4',
      invoiceNumber: 'INV-2024-004',
      studentId: 's1',
      studentName: 'Budi Santoso',
      categoryId: 'fc1',
      categoryName: 'SPP',
      period: 'Oktober 2024',
      items: [
        InvoiceItem(id: 'ii4', description: 'SPP Oktober 2024', amount: 500000),
      ],
      totalAmount: 500000,
      paidAmount: 500000,
      status: InvoiceStatus.paid,
      dueDate: DateTime(2024, 10, 31),
      createdAt: DateTime(2024, 10, 1),
    ),
    // Unpaid Ujian Semester
    Invoice(
      id: 'inv5',
      invoiceNumber: 'INV-2024-005',
      studentId: 's1',
      studentName: 'Budi Santoso',
      categoryId: 'fc3',
      categoryName: 'Ujian Semester',
      period: 'Semester 1 2024/2025',
      items: [
        InvoiceItem(id: 'ii5', description: 'Ujian Akhir Semester Ganjil', amount: 250000),
      ],
      totalAmount: 250000,
      status: InvoiceStatus.unpaid,
      dueDate: DateTime(2024, 12, 15),
      createdAt: DateTime(2024, 12, 1),
    ),
    // Invoices for other students
    Invoice(
      id: 'inv6',
      invoiceNumber: 'INV-2024-006',
      studentId: 's2',
      studentName: 'Ani Wijaya',
      categoryId: 'fc1',
      categoryName: 'SPP',
      period: 'Desember 2024',
      items: [
        InvoiceItem(id: 'ii6', description: 'SPP Desember 2024', amount: 500000),
      ],
      totalAmount: 500000,
      status: InvoiceStatus.unpaid,
      dueDate: DateTime(2024, 12, 31),
      createdAt: DateTime(2024, 12, 1),
    ),
    Invoice(
      id: 'inv7',
      invoiceNumber: 'INV-2024-007',
      studentId: 's3',
      studentName: 'Citra Dewi',
      categoryId: 'fc1',
      categoryName: 'SPP',
      period: 'Desember 2024',
      items: [
        InvoiceItem(id: 'ii7', description: 'SPP Desember 2024', amount: 500000),
      ],
      totalAmount: 500000,
      paidAmount: 500000,
      status: InvoiceStatus.paid,
      dueDate: DateTime(2024, 12, 31),
      createdAt: DateTime(2024, 12, 1),
    ),
  ];

  // Demo Transactions
  static final List<Transaction> transactions = [
    Transaction(
      id: 't1',
      orderId: 'ORD-2024-001',
      invoiceId: 'inv2',
      invoiceNumber: 'INV-2024-002',
      studentId: 's1',
      studentName: 'Budi Santoso',
      grossAmount: 500000,
      paymentType: 'bank_transfer',
      status: TransactionStatus.settlement,
      transactionTime: DateTime(2024, 11, 15, 10, 30),
      settlementTime: DateTime(2024, 11, 15, 10, 35),
      referenceNumber: 'REF-001-2024',
    ),
    Transaction(
      id: 't2',
      orderId: 'ORD-2024-002',
      invoiceId: 'inv3',
      invoiceNumber: 'INV-2024-003',
      studentId: 's1',
      studentName: 'Budi Santoso',
      grossAmount: 500000,
      paymentType: 'gopay',
      status: TransactionStatus.settlement,
      transactionTime: DateTime(2024, 11, 20, 14, 15),
      settlementTime: DateTime(2024, 11, 20, 14, 15),
      referenceNumber: 'REF-002-2024',
    ),
    Transaction(
      id: 't3',
      orderId: 'ORD-2024-003',
      invoiceId: 'inv4',
      invoiceNumber: 'INV-2024-004',
      studentId: 's1',
      studentName: 'Budi Santoso',
      grossAmount: 500000,
      paymentType: 'qris',
      status: TransactionStatus.settlement,
      transactionTime: DateTime(2024, 10, 20, 9, 0),
      settlementTime: DateTime(2024, 10, 20, 9, 0),
      referenceNumber: 'REF-003-2024',
    ),
  ];

  // Helper methods
  static Student? getStudentById(String id) {
    try {
      return students.firstWhere((s) => s.id == id);
    } catch (e) {
      return null;
    }
  }

  static User? getUserByEmail(String email) {
    try {
      return users.firstWhere((u) => u.email == email);
    } catch (e) {
      return null;
    }
  }

  static List<Invoice> getInvoicesByStudentId(String studentId) {
    return invoices.where((i) => i.studentId == studentId).toList();
  }

  static List<Transaction> getTransactionsByStudentId(String studentId) {
    return transactions.where((t) => t.studentId == studentId).toList();
  }

  static double getTotalUnpaid(String studentId) {
    return invoices
        .where((i) => i.studentId == studentId && i.status != InvoiceStatus.paid)
        .fold(0, (sum, i) => sum + i.remainingAmount);
  }

  static double getTotalPaid(String studentId) {
    return invoices
        .where((i) => i.studentId == studentId)
        .fold(0, (sum, i) => sum + i.paidAmount);
  }

  // Admin stats
  static double getTodayIncome() {
    final today = DateTime.now();
    return transactions
        .where((t) =>
            t.isSuccessful &&
            t.settlementTime != null &&
            t.settlementTime!.year == today.year &&
            t.settlementTime!.month == today.month &&
            t.settlementTime!.day == today.day)
        .fold(0, (sum, t) => sum + t.grossAmount);
  }

  static double getMonthIncome() {
    final now = DateTime.now();
    return transactions
        .where((t) =>
            t.isSuccessful &&
            t.settlementTime != null &&
            t.settlementTime!.year == now.year &&
            t.settlementTime!.month == now.month)
        .fold(0, (sum, t) => sum + t.grossAmount);
  }

  static double getTotalArrears() {
    return invoices
        .where((i) => i.status == InvoiceStatus.unpaid || i.status == InvoiceStatus.partial)
        .fold(0, (sum, i) => sum + i.remainingAmount);
  }

  static int getArrearsCount() {
    return invoices
        .where((i) => i.status == InvoiceStatus.unpaid || i.status == InvoiceStatus.partial)
        .length;
  }
}
