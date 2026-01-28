import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// API Service for communicating with Laravel backend
class ApiService {
  // Change this to your backend URL
  static const String baseUrl = 'http://localhost:8000/api';
  
  static String? _token;
  static Map<String, dynamic>? _cachedUserData;
  
  // Simple obfuscation key for token encryption
  static const String _obfuscationKey = 'sch00l_p4ym3nt_s3cur3_k3y';
  
  // Encrypt token with simple XOR obfuscation + base64
  static String _encryptToken(String token) {
    final bytes = utf8.encode(token);
    final keyBytes = utf8.encode(_obfuscationKey);
    final encrypted = List<int>.generate(
      bytes.length,
      (i) => bytes[i] ^ keyBytes[i % keyBytes.length],
    );
    return base64Encode(encrypted);
  }
  
  // Decrypt token
  static String _decryptToken(String encryptedToken) {
    try {
      final encrypted = base64Decode(encryptedToken);
      final keyBytes = utf8.encode(_obfuscationKey);
      final decrypted = List<int>.generate(
        encrypted.length,
        (i) => encrypted[i] ^ keyBytes[i % keyBytes.length],
      );
      return utf8.decode(decrypted);
    } catch (e) {
      return '';
    }
  }
  
  // Token management with encryption
  static Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    final encryptedToken = prefs.getString('auth_token_encrypted');
    if (encryptedToken != null && encryptedToken.isNotEmpty) {
      _token = _decryptToken(encryptedToken);
    }
    
    // Also load cached user data
    final userData = prefs.getString('user_data');
    if (userData != null && userData.isNotEmpty) {
      try {
        _cachedUserData = jsonDecode(userData);
      } catch (e) {
        _cachedUserData = null;
      }
    }
  }
  
  static Future<void> saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token_encrypted', _encryptToken(token));
  }
  
  static Future<void> saveUserData(Map<String, dynamic> userData) async {
    _cachedUserData = userData;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_data', jsonEncode(userData));
  }
  
  static Future<void> clearToken() async {
    _token = null;
    _cachedUserData = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token_encrypted');
    await prefs.remove('user_data');
    // Also remove old unencrypted token if exists
    await prefs.remove('auth_token');
  }
  
  static String? get token => _token;
  static bool get hasToken => _token != null && _token!.isNotEmpty;
  static Map<String, dynamic>? get cachedUserData => _cachedUserData;
  
  // Headers
  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };
  
  // ==================== AUTH ====================
  
  /// Login with email and password
  static Future<ApiResponse<Map<String, dynamic>>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'device_name': 'flutter-web',
        }),
      );
      
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 && data['success'] == true) {
        // Save token and user data for session persistence
        await saveToken(data['data']['token']);
        await saveUserData(data['data']['user']);
        return ApiResponse.success(data['data']);
      } else {
        final message = data['message'] ?? data['errors']?['email']?[0] ?? 'Login gagal';
        return ApiResponse.error(message);
      }
    } catch (e) {
      return ApiResponse.error('Tidak dapat terhubung ke server: $e');
    }
  }
  
  /// Logout
  static Future<ApiResponse<void>> logout() async {
    try {
      await http.post(
        Uri.parse('$baseUrl/logout'),
        headers: _headers,
      );
      await clearToken();
      return ApiResponse.success(null);
    } catch (e) {
      await clearToken();
      return ApiResponse.success(null);
    }
  }
  
  /// Get current user
  static Future<ApiResponse<Map<String, dynamic>>> getMe() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/me'),
        headers: _headers,
      );
      
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 && data['success'] == true) {
        return ApiResponse.success(data['data']);
      } else {
        return ApiResponse.error(data['message'] ?? 'Gagal mengambil data user');
      }
    } catch (e) {
      return ApiResponse.error('Tidak dapat terhubung ke server: $e');
    }
  }
  
  /// Change password (required on first login)
  static Future<ApiResponse<void>> changePassword(String currentPassword, String newPassword) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/change-password'),
        headers: _headers,
        body: jsonEncode({
          'current_password': currentPassword,
          'new_password': newPassword,
          'new_password_confirmation': newPassword,
        }),
      );
      
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 && data['success'] == true) {
        return ApiResponse.success(null);
      } else {
        final message = data['message'] ?? data['errors']?['current_password']?[0] ?? 'Gagal mengubah password';
        return ApiResponse.error(message);
      }
    } catch (e) {
      return ApiResponse.error('Tidak dapat terhubung ke server: $e');
    }
  }
  
  // ==================== INVOICES ====================
  
  /// Get all invoices
  static Future<ApiResponse<List<dynamic>>> getInvoices({String? status}) async {
    try {
      var url = '$baseUrl/invoices';
      if (status != null) {
        url += '?status=$status';
      }
      
      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      );
      
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 && data['success'] == true) {
        return ApiResponse.success(data['data'] as List<dynamic>);
      } else {
        return ApiResponse.error(data['message'] ?? 'Gagal mengambil data tagihan');
      }
    } catch (e) {
      return ApiResponse.error('Tidak dapat terhubung ke server: $e');
    }
  }
  
  /// Get single invoice
  static Future<ApiResponse<Map<String, dynamic>>> getInvoice(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/invoices/$id'),
        headers: _headers,
      );
      
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 && data['success'] == true) {
        return ApiResponse.success(data['data']);
      } else {
        return ApiResponse.error(data['message'] ?? 'Tagihan tidak ditemukan');
      }
    } catch (e) {
      return ApiResponse.error('Tidak dapat terhubung ke server: $e');
    }
  }
  
  // ==================== PAYMENT ====================
  
  /// Create Midtrans Snap token for payment
  static Future<ApiResponse<Map<String, dynamic>>> createSnapToken(String invoiceId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/pay/$invoiceId'),
        headers: _headers,
      );
      
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 && data['success'] == true) {
        return ApiResponse.success(data['data']);
      } else {
        return ApiResponse.error(data['message'] ?? 'Gagal membuat pembayaran');
      }
    } catch (e) {
      return ApiResponse.error('Tidak dapat terhubung ke server: $e');
    }
  }
  
  /// Get payment status
  static Future<ApiResponse<Map<String, dynamic>>> getPaymentStatus(String orderId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/payment/status/$orderId'),
        headers: _headers,
      );
      
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 && data['success'] == true) {
        return ApiResponse.success(data['data']);
      } else {
        return ApiResponse.error(data['message'] ?? 'Status tidak ditemukan');
      }
    } catch (e) {
      return ApiResponse.error('Tidak dapat terhubung ke server: $e');
    }
  }
  
  /// Get all transactions for current user
  static Future<ApiResponse<List<dynamic>>> getTransactions() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/transactions'),
        headers: _headers,
      );
      
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 && data['success'] == true) {
        return ApiResponse.success(data['data'] as List<dynamic>);
      } else {
        return ApiResponse.error(data['message'] ?? 'Gagal mengambil data transaksi');
      }
    } catch (e) {
      return ApiResponse.error('Tidak dapat terhubung ke server: $e');
    }
  }
  
  // ==================== CHATBOT ====================
  
  /// Send message to chatbot
  static Future<ApiResponse<Map<String, dynamic>>> sendChatMessage(String message) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/chatbot/message'),
        headers: _headers,
        body: jsonEncode({'message': message}),
      );
      
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 && data['success'] == true) {
        return ApiResponse.success(data['data']);
      } else {
        return ApiResponse.error(data['message'] ?? 'Gagal mengirim pesan');
      }
    } catch (e) {
      return ApiResponse.error('Tidak dapat terhubung ke server: $e');
    }
  }
  
  /// Get chat history
  static Future<ApiResponse<List<dynamic>>> getChatHistory() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/chatbot/history'),
        headers: _headers,
      );
      
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 && data['success'] == true) {
        return ApiResponse.success(data['data'] as List<dynamic>);
      } else {
        return ApiResponse.error(data['message'] ?? 'Gagal mengambil riwayat chat');
      }
    } catch (e) {
      return ApiResponse.error('Tidak dapat terhubung ke server: $e');
    }
  }
  
  // ==================== ADMIN: USERS ====================
  
  /// Get all users (admin only)
  static Future<ApiResponse<List<dynamic>>> getUsers({String? role, String? search}) async {
    try {
      var url = '$baseUrl/users';
      final params = <String>[];
      if (role != null) params.add('role=$role');
      if (search != null && search.isNotEmpty) params.add('search=$search');
      if (params.isNotEmpty) url += '?${params.join('&')}';
      
      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      );
      
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 && data['success'] == true) {
        return ApiResponse.success(data['data'] as List<dynamic>);
      } else {
        return ApiResponse.error(data['message'] ?? 'Gagal mengambil data user');
      }
    } catch (e) {
      return ApiResponse.error('Tidak dapat terhubung ke server: $e');
    }
  }
  
  /// Create a new user
  static Future<ApiResponse<Map<String, dynamic>>> createUser(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users'),
        headers: _headers,
        body: jsonEncode(data),
      );
      
      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 201 && responseData['success'] == true) {
        return ApiResponse.success(responseData['data']);
      } else {
        return ApiResponse.error(responseData['message'] ?? 'Gagal membuat user');
      }
    } catch (e) {
      return ApiResponse.error('Tidak dapat terhubung ke server: $e');
    }
  }
  
  /// Toggle user active status
  static Future<ApiResponse<Map<String, dynamic>>> toggleUserActive(String userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/$userId/toggle-active'),
        headers: _headers,
      );
      
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 && data['success'] == true) {
        return ApiResponse.success(data['data']);
      } else {
        return ApiResponse.error(data['message'] ?? 'Gagal mengubah status user');
      }
    } catch (e) {
      return ApiResponse.error('Tidak dapat terhubung ke server: $e');
    }
  }
  
  /// Reset user password to default (123456)
  static Future<ApiResponse<void>> resetUserPassword(String userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/$userId/reset-password'),
        headers: _headers,
      );
      
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 && data['success'] == true) {
        return ApiResponse.success(null);
      } else {
        return ApiResponse.error(data['message'] ?? 'Gagal reset password');
      }
    } catch (e) {
      return ApiResponse.error('Tidak dapat terhubung ke server: $e');
    }
  }
  
  /// Update user
  static Future<ApiResponse<Map<String, dynamic>>> updateUser(String userId, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/users/$userId'),
        headers: _headers,
        body: jsonEncode(data),
      );
      
      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 200 && responseData['success'] == true) {
        return ApiResponse.success(responseData['data']);
      } else {
        return ApiResponse.error(responseData['message'] ?? 'Gagal memperbarui user');
      }
    } catch (e) {
      return ApiResponse.error('Tidak dapat terhubung ke server: $e');
    }
  }
  
  /// Delete user
  static Future<ApiResponse<void>> deleteUser(String userId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/users/$userId'),
        headers: _headers,
      );
      
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 && data['success'] == true) {
        return ApiResponse.success(null);
      } else {
        return ApiResponse.error(data['message'] ?? 'Gagal menghapus user');
      }
    } catch (e) {
      return ApiResponse.error('Tidak dapat terhubung ke server: $e');
    }
  }
  
  // ==================== ADMIN: STUDENTS ====================
  
  /// Get all students (admin only)
  static Future<ApiResponse<List<dynamic>>> getStudents() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/students'),
        headers: _headers,
      );
      
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 && data['success'] == true) {
        return ApiResponse.success(data['data'] as List<dynamic>);
      } else {
        return ApiResponse.error(data['message'] ?? 'Gagal mengambil data siswa');
      }
    } catch (e) {
      return ApiResponse.error('Tidak dapat terhubung ke server: $e');
    }
  }
  
  // ==================== ADMIN: FEE CATEGORIES ====================
  
  /// Get all fee categories (admin only)
  static Future<ApiResponse<List<dynamic>>> getFeeCategories() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/fee-categories'),
        headers: _headers,
      );
      
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 && data['success'] == true) {
        return ApiResponse.success(data['data'] as List<dynamic>);
      } else {
        return ApiResponse.error(data['message'] ?? 'Gagal mengambil data kategori');
      }
    } catch (e) {
      return ApiResponse.error('Tidak dapat terhubung ke server: $e');
    }
  }
  
  // ==================== ADMIN: REPORTS ====================
  
  /// Get daily report
  static Future<ApiResponse<Map<String, dynamic>>> getDailyReport({String? date}) async {
    try {
      var url = '$baseUrl/reports/daily';
      if (date != null) {
        url += '?date=$date';
      }
      
      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      );
      
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 && data['success'] == true) {
        return ApiResponse.success(data['data']);
      } else {
        return ApiResponse.error(data['message'] ?? 'Gagal mengambil laporan');
      }
    } catch (e) {
      return ApiResponse.error('Tidak dapat terhubung ke server: $e');
    }
  }
  
  /// Get arrears report
  static Future<ApiResponse<Map<String, dynamic>>> getArrearsReport() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/reports/arrears'),
        headers: _headers,
      );
      
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 && data['success'] == true) {
        return ApiResponse.success(data['data']);
      } else {
        return ApiResponse.error(data['message'] ?? 'Gagal mengambil laporan tunggakan');
      }
    } catch (e) {
      return ApiResponse.error('Tidak dapat terhubung ke server: $e');
    }
  }
  
  /// Get export URL for reports (opens in browser)
  static String getExportUrl({String type = 'daily', String? date}) {
    var url = '$baseUrl/reports/export?type=$type';
    if (date != null) {
      url += '&date=$date';
    }
    return url;
  }
  
  /// Export report with authentication (returns data for CSV generation)
  static Future<ApiResponse<Map<String, dynamic>>> exportReport({String type = 'daily', String? date}) async {
    try {
      var url = '$baseUrl/reports/export?type=$type';
      if (date != null) {
        url += '&date=$date';
      }
      
      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      );
      
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 && data['success'] == true) {
        return ApiResponse.success(data['data']);
      } else {
        return ApiResponse.error(data['message'] ?? 'Gagal mengambil laporan');
      }
    } catch (e) {
      return ApiResponse.error('Tidak dapat terhubung ke server: $e');
    }
  }
  
  // ==================== ADMIN: STUDENT CRUD ====================
  
  /// Create a new student
  static Future<ApiResponse<Map<String, dynamic>>> createStudent(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/students'),
        headers: _headers,
        body: jsonEncode(data),
      );
      
      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 201 && responseData['success'] == true) {
        return ApiResponse.success(responseData['data']);
      } else {
        return ApiResponse.error(responseData['message'] ?? 'Gagal menambahkan siswa');
      }
    } catch (e) {
      return ApiResponse.error('Tidak dapat terhubung ke server: $e');
    }
  }
  
  /// Update student
  static Future<ApiResponse<Map<String, dynamic>>> updateStudent(String id, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/students/$id'),
        headers: _headers,
        body: jsonEncode(data),
      );
      
      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 200 && responseData['success'] == true) {
        return ApiResponse.success(responseData['data']);
      } else {
        return ApiResponse.error(responseData['message'] ?? 'Gagal memperbarui data siswa');
      }
    } catch (e) {
      return ApiResponse.error('Tidak dapat terhubung ke server: $e');
    }
  }
  
  /// Delete student
  static Future<ApiResponse<void>> deleteStudent(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/students/$id'),
        headers: _headers,
      );
      
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 && data['success'] == true) {
        return ApiResponse.success(null);
      } else {
        return ApiResponse.error(data['message'] ?? 'Gagal menghapus siswa');
      }
    } catch (e) {
      return ApiResponse.error('Tidak dapat terhubung ke server: $e');
    }
  }
  
  // ==================== ADMIN: FEE CATEGORY CRUD ====================
  
  /// Create a new fee category
  static Future<ApiResponse<Map<String, dynamic>>> createFeeCategory(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/fee-categories'),
        headers: _headers,
        body: jsonEncode(data),
      );
      
      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 201 && responseData['success'] == true) {
        return ApiResponse.success(responseData['data']);
      } else {
        return ApiResponse.error(responseData['message'] ?? 'Gagal menambahkan kategori');
      }
    } catch (e) {
      return ApiResponse.error('Tidak dapat terhubung ke server: $e');
    }
  }
  
  /// Update fee category
  static Future<ApiResponse<Map<String, dynamic>>> updateFeeCategory(String id, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/fee-categories/$id'),
        headers: _headers,
        body: jsonEncode(data),
      );
      
      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 200 && responseData['success'] == true) {
        return ApiResponse.success(responseData['data']);
      } else {
        return ApiResponse.error(responseData['message'] ?? 'Gagal memperbarui kategori');
      }
    } catch (e) {
      return ApiResponse.error('Tidak dapat terhubung ke server: $e');
    }
  }
  
  /// Delete fee category
  static Future<ApiResponse<void>> deleteFeeCategory(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/fee-categories/$id'),
        headers: _headers,
      );
      
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 && data['success'] == true) {
        return ApiResponse.success(null);
      } else {
        return ApiResponse.error(data['message'] ?? 'Gagal menghapus kategori');
      }
    } catch (e) {
      return ApiResponse.error('Tidak dapat terhubung ke server: $e');
    }
  }
  
  // ==================== ADMIN: INVOICE MANAGEMENT ====================
  
  /// Create a new invoice
  static Future<ApiResponse<Map<String, dynamic>>> createInvoice(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/invoices'),
        headers: _headers,
        body: jsonEncode(data),
      );
      
      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 201 && responseData['success'] == true) {
        return ApiResponse.success(responseData['data']);
      } else {
        return ApiResponse.error(responseData['message'] ?? 'Gagal membuat invoice');
      }
    } catch (e) {
      return ApiResponse.error('Tidak dapat terhubung ke server: $e');
    }
  }
  
  /// Generate invoices for multiple students
  static Future<ApiResponse<Map<String, dynamic>>> generateInvoices(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/invoices/generate'),
        headers: _headers,
        body: jsonEncode(data),
      );
      
      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 201 && responseData['success'] == true) {
        return ApiResponse.success(responseData['data']);
      } else {
        return ApiResponse.error(responseData['message'] ?? 'Gagal generate invoice');
      }
    } catch (e) {
      return ApiResponse.error('Tidak dapat terhubung ke server: $e');
    }
  }
}

/// Generic API response wrapper
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? error;
  
  ApiResponse._({required this.success, this.data, this.error});
  
  factory ApiResponse.success(T data) => ApiResponse._(success: true, data: data);
  factory ApiResponse.error(String message) => ApiResponse._(success: false, error: message);
}
