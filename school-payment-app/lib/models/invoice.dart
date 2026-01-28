enum InvoiceStatus {
  unpaid,
  paid,
  partial,
  expired,
  cancelled,
}

class InvoiceItem {
  final String id;
  final String description;
  final double amount;
  final int quantity;

  InvoiceItem({
    required this.id,
    required this.description,
    required this.amount,
    this.quantity = 1,
  });

  double get total => amount * quantity;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'amount': amount,
      'quantity': quantity,
    };
  }

  factory InvoiceItem.fromJson(Map<String, dynamic> json) {
    return InvoiceItem(
      id: json['id']?.toString() ?? '',
      description: json['description'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      quantity: json['quantity'] ?? 1,
    );
  }
}

class Invoice {
  final String id;
  final String invoiceNumber;
  final String studentId;
  final String studentName;
  final String categoryId;
  final String categoryName;
  final String period; // e.g., "Januari 2024" or "2024"
  final List<InvoiceItem> items;
  final double totalAmount;
  final double paidAmount;
  final InvoiceStatus status;
  final DateTime dueDate;
  final DateTime createdAt;
  final String? notes;

  Invoice({
    required this.id,
    required this.invoiceNumber,
    required this.studentId,
    required this.studentName,
    required this.categoryId,
    required this.categoryName,
    required this.period,
    required this.items,
    required this.totalAmount,
    this.paidAmount = 0,
    required this.status,
    required this.dueDate,
    DateTime? createdAt,
    this.notes,
  }) : createdAt = createdAt ?? DateTime.now();

  double get remainingAmount => totalAmount - paidAmount;

  bool get isOverdue => status == InvoiceStatus.unpaid && DateTime.now().isAfter(dueDate);

  String get statusDisplayName {
    switch (status) {
      case InvoiceStatus.unpaid:
        return 'Belum Dibayar';
      case InvoiceStatus.paid:
        return 'Lunas';
      case InvoiceStatus.partial:
        return 'Sebagian';
      case InvoiceStatus.expired:
        return 'Kadaluarsa';
      case InvoiceStatus.cancelled:
        return 'Dibatalkan';
    }
  }

  Invoice copyWith({
    String? id,
    String? invoiceNumber,
    String? studentId,
    String? studentName,
    String? categoryId,
    String? categoryName,
    String? period,
    List<InvoiceItem>? items,
    double? totalAmount,
    double? paidAmount,
    InvoiceStatus? status,
    DateTime? dueDate,
    DateTime? createdAt,
    String? notes,
  }) {
    return Invoice(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      period: period ?? this.period,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      status: status ?? this.status,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt ?? this.createdAt,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'invoiceNumber': invoiceNumber,
      'studentId': studentId,
      'studentName': studentName,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'period': period,
      'items': items.map((e) => e.toJson()).toList(),
      'totalAmount': totalAmount,
      'paidAmount': paidAmount,
      'status': status.name,
      'dueDate': dueDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'notes': notes,
    };
  }

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: json['id']?.toString() ?? '',
      invoiceNumber: json['invoiceNumber'] ?? '',
      studentId: json['studentId']?.toString() ?? '',
      studentName: json['studentName'] ?? '',
      categoryId: json['categoryId']?.toString() ?? '',
      categoryName: json['categoryName'] ?? '',
      period: json['period'] ?? '',
      items: json['items'] != null 
          ? (json['items'] as List).map((e) => InvoiceItem.fromJson(e)).toList()
          : [],
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0,
      paidAmount: (json['paidAmount'] as num?)?.toDouble() ?? 0,
      status: InvoiceStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => InvoiceStatus.unpaid,
      ),
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : DateTime.now(),
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      notes: json['notes'],
    );
  }
}
