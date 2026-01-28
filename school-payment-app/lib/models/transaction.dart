enum TransactionStatus {
  pending,
  settlement,
  capture,
  deny,
  cancel,
  expire,
  refund,
}

class Transaction {
  final String id;
  final String orderId;
  final String invoiceId;
  final String invoiceNumber;
  final String studentId;
  final String studentName;
  final double grossAmount;
  final String paymentType; // e.g., "bank_transfer", "gopay", "credit_card"
  final TransactionStatus status;
  final DateTime? transactionTime;
  final DateTime? settlementTime;
  final String? referenceNumber;
  final String? receiptUrl;

  Transaction({
    required this.id,
    required this.orderId,
    required this.invoiceId,
    required this.invoiceNumber,
    required this.studentId,
    required this.studentName,
    required this.grossAmount,
    required this.paymentType,
    required this.status,
    this.transactionTime,
    this.settlementTime,
    this.referenceNumber,
    this.receiptUrl,
  });

  String get statusDisplayName {
    switch (status) {
      case TransactionStatus.pending:
        return 'Menunggu';
      case TransactionStatus.settlement:
        return 'Berhasil';
      case TransactionStatus.capture:
        return 'Captured';
      case TransactionStatus.deny:
        return 'Ditolak';
      case TransactionStatus.cancel:
        return 'Dibatalkan';
      case TransactionStatus.expire:
        return 'Kadaluarsa';
      case TransactionStatus.refund:
        return 'Refund';
    }
  }

  String get paymentTypeDisplayName {
    switch (paymentType) {
      case 'bank_transfer':
        return 'Transfer Bank';
      case 'gopay':
        return 'GoPay';
      case 'shopeepay':
        return 'ShopeePay';
      case 'credit_card':
        return 'Kartu Kredit';
      case 'qris':
        return 'QRIS';
      case 'unknown':
      case '':
        return 'Belum dipilih';
      default:
        return paymentType;
    }
  }

  bool get isSuccessful => status == TransactionStatus.settlement || status == TransactionStatus.capture;

  Transaction copyWith({
    String? id,
    String? orderId,
    String? invoiceId,
    String? invoiceNumber,
    String? studentId,
    String? studentName,
    double? grossAmount,
    String? paymentType,
    TransactionStatus? status,
    DateTime? transactionTime,
    DateTime? settlementTime,
    String? referenceNumber,
    String? receiptUrl,
  }) {
    return Transaction(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      invoiceId: invoiceId ?? this.invoiceId,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      grossAmount: grossAmount ?? this.grossAmount,
      paymentType: paymentType ?? this.paymentType,
      status: status ?? this.status,
      transactionTime: transactionTime ?? this.transactionTime,
      settlementTime: settlementTime ?? this.settlementTime,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      receiptUrl: receiptUrl ?? this.receiptUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderId': orderId,
      'invoiceId': invoiceId,
      'invoiceNumber': invoiceNumber,
      'studentId': studentId,
      'studentName': studentName,
      'grossAmount': grossAmount,
      'paymentType': paymentType,
      'status': status.name,
      'transactionTime': transactionTime?.toIso8601String(),
      'settlementTime': settlementTime?.toIso8601String(),
      'referenceNumber': referenceNumber,
      'receiptUrl': receiptUrl,
    };
  }

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id']?.toString() ?? '',
      orderId: json['orderId']?.toString() ?? '',
      invoiceId: json['invoiceId']?.toString() ?? '',
      invoiceNumber: json['invoiceNumber']?.toString() ?? '-',
      studentId: json['studentId']?.toString() ?? '',
      studentName: json['studentName']?.toString() ?? '-',
      grossAmount: (json['grossAmount'] as num?)?.toDouble() ?? 0.0,
      paymentType: json['paymentType']?.toString() ?? 'unknown',
      status: TransactionStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => TransactionStatus.pending,
      ),
      transactionTime: json['transactionTime'] != null ? DateTime.parse(json['transactionTime']) : null,
      settlementTime: json['settlementTime'] != null ? DateTime.parse(json['settlementTime']) : null,
      referenceNumber: json['referenceNumber'],
      receiptUrl: json['receiptUrl'],
    );
  }
}
