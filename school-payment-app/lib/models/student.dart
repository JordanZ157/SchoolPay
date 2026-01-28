class Student {
  final String id;
  final String nis;
  final String name;
  final String className;
  final String? major; // Jurusan (for SMK/SMA)
  final String? parentId;
  final String? parentName;
  final String? parentPhone;
  final String? parentEmail;
  final String status; // active, inactive, graduated
  final String? avatarUrl;
  final DateTime enrolledAt;

  Student({
    required this.id,
    required this.nis,
    required this.name,
    required this.className,
    this.major,
    this.parentId,
    this.parentName,
    this.parentPhone,
    this.parentEmail,
    this.status = 'active',
    this.avatarUrl,
    DateTime? enrolledAt,
  }) : enrolledAt = enrolledAt ?? DateTime.now();

  String get displayClass => major != null ? '$className - $major' : className;

  Student copyWith({
    String? id,
    String? nis,
    String? name,
    String? className,
    String? major,
    String? parentId,
    String? parentName,
    String? parentPhone,
    String? parentEmail,
    String? status,
    String? avatarUrl,
    DateTime? enrolledAt,
  }) {
    return Student(
      id: id ?? this.id,
      nis: nis ?? this.nis,
      name: name ?? this.name,
      className: className ?? this.className,
      major: major ?? this.major,
      parentId: parentId ?? this.parentId,
      parentName: parentName ?? this.parentName,
      parentPhone: parentPhone ?? this.parentPhone,
      parentEmail: parentEmail ?? this.parentEmail,
      status: status ?? this.status,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      enrolledAt: enrolledAt ?? this.enrolledAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nis': nis,
      'name': name,
      'className': className,
      'major': major,
      'parentId': parentId,
      'parentName': parentName,
      'parentPhone': parentPhone,
      'parentEmail': parentEmail,
      'status': status,
      'avatarUrl': avatarUrl,
      'enrolledAt': enrolledAt.toIso8601String(),
    };
  }

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id']?.toString() ?? '',
      nis: json['nis'] ?? '',
      name: json['name'] ?? '',
      className: json['className'] ?? json['class_name'] ?? '',
      major: json['major'],
      parentId: json['parentId']?.toString() ?? json['parent_id']?.toString(),
      parentName: json['parentName'] ?? json['parent_name'],
      parentPhone: json['parentPhone'] ?? json['parent_phone'],
      parentEmail: json['parentEmail'] ?? json['parent_email'],
      status: json['status'] ?? 'active',
      avatarUrl: json['avatarUrl'] ?? json['avatar_url'],
      enrolledAt: json['enrolledAt'] != null 
          ? DateTime.parse(json['enrolledAt']) 
          : json['enrolled_at'] != null 
              ? DateTime.parse(json['enrolled_at'])
              : DateTime.now(),
    );
  }
}
