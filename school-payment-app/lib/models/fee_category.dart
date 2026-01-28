enum FeeType {
  akademik,
  nonAkademik,
  insidental,
  administratif,
}

enum FeeFrequency {
  once,
  monthly,
  semester,
  yearly,
}

class FeeCategory {
  final String id;
  final String name;
  final String description;
  final FeeType type;
  final FeeFrequency frequency;
  final double baseAmount;
  final bool isActive;
  final bool allowInstallment;
  final int? maxInstallments;

  FeeCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.frequency,
    required this.baseAmount,
    this.isActive = true,
    this.allowInstallment = false,
    this.maxInstallments,
  });

  String get typeDisplayName {
    switch (type) {
      case FeeType.akademik:
        return 'Akademik';
      case FeeType.nonAkademik:
        return 'Non-Akademik';
      case FeeType.insidental:
        return 'Insidental';
      case FeeType.administratif:
        return 'Administratif';
    }
  }

  String get frequencyDisplayName {
    switch (frequency) {
      case FeeFrequency.once:
        return 'Sekali Bayar';
      case FeeFrequency.monthly:
        return 'Bulanan';
      case FeeFrequency.semester:
        return 'Per Semester';
      case FeeFrequency.yearly:
        return 'Tahunan';
    }
  }

  FeeCategory copyWith({
    String? id,
    String? name,
    String? description,
    FeeType? type,
    FeeFrequency? frequency,
    double? baseAmount,
    bool? isActive,
    bool? allowInstallment,
    int? maxInstallments,
  }) {
    return FeeCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      frequency: frequency ?? this.frequency,
      baseAmount: baseAmount ?? this.baseAmount,
      isActive: isActive ?? this.isActive,
      allowInstallment: allowInstallment ?? this.allowInstallment,
      maxInstallments: maxInstallments ?? this.maxInstallments,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type.name,
      'frequency': frequency.name,
      'baseAmount': baseAmount,
      'isActive': isActive,
      'allowInstallment': allowInstallment,
      'maxInstallments': maxInstallments,
    };
  }

  factory FeeCategory.fromJson(Map<String, dynamic> json) {
    return FeeCategory(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      type: FeeType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => FeeType.akademik,
      ),
      frequency: FeeFrequency.values.firstWhere(
        (e) => e.name == json['frequency'],
        orElse: () => FeeFrequency.once,
      ),
      baseAmount: (json['baseAmount'] as num?)?.toDouble() ?? 0,
      isActive: json['isActive'] ?? true,
      allowInstallment: json['allowInstallment'] ?? false,
      maxInstallments: json['maxInstallments'],
    );
  }
}
