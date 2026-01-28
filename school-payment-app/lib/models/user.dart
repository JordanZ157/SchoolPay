import 'student.dart';

enum UserRole {
  admin,
  bendahara,
  waliKelas,
  siswa,
  orangTua,
}

class User {
  final String id;
  final String email;
  final String name;
  final UserRole role;
  final String? studentId; // For siswa, linked student ID
  final String? classId; // For wali_kelas, assigned class
  final String? avatarUrl;
  final bool mustChangePassword; // Force password change on first login
  final DateTime createdAt;
  final Student? student; // Loaded student data

  User({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.studentId,
    this.classId,
    this.avatarUrl,
    this.mustChangePassword = false,
    DateTime? createdAt,
    this.student,
  }) : createdAt = createdAt ?? DateTime.now();

  String get roleDisplayName {
    switch (role) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.bendahara:
        return 'Bendahara';
      case UserRole.waliKelas:
        return 'Wali Kelas';
      case UserRole.siswa:
        return 'Siswa';
      case UserRole.orangTua:
        return 'Orang Tua';
    }
  }

  bool get isAdmin => role == UserRole.admin || role == UserRole.bendahara;

  User copyWith({
    String? id,
    String? email,
    String? name,
    UserRole? role,
    String? studentId,
    String? classId,
    String? avatarUrl,
    bool? mustChangePassword,
    DateTime? createdAt,
    Student? student,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      studentId: studentId ?? this.studentId,
      classId: classId ?? this.classId,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      mustChangePassword: mustChangePassword ?? this.mustChangePassword,
      createdAt: createdAt ?? this.createdAt,
      student: student ?? this.student,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role.name,
      'studentId': studentId,
      'classId': classId,
      'avatarUrl': avatarUrl,
      'mustChangePassword': mustChangePassword,
      'createdAt': createdAt.toIso8601String(),
      'student': student?.toJson(),
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    // Map role string from API to enum
    UserRole parseRole(String? roleStr) {
      if (roleStr == null) return UserRole.siswa;
      switch (roleStr.toLowerCase()) {
        case 'admin':
          return UserRole.admin;
        case 'bendahara':
          return UserRole.bendahara;
        case 'wali_kelas':
        case 'walikelas':
          return UserRole.waliKelas;
        case 'orang_tua':
        case 'orangtua':
          return UserRole.orangTua;
        case 'siswa':
        default:
          return UserRole.siswa;
      }
    }

    return User(
      id: json['id']?.toString() ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      role: parseRole(json['role']),
      studentId: json['studentId']?.toString(),
      classId: json['classId']?.toString() ?? json['class_id']?.toString(),
      avatarUrl: json['avatarUrl'],
      mustChangePassword: json['mustChangePassword'] ?? false,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      student: json['student'] != null 
          ? Student.fromJson(json['student']) 
          : null,
    );
  }
}
