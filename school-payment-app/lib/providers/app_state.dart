import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/student.dart';
import '../models/invoice.dart';
import '../models/transaction.dart';
import '../models/fee_category.dart';
import '../services/api_service.dart';
import '../services/mock_data.dart';

/// App state management using ChangeNotifier
/// This handles authentication state and data access
class AppState extends ChangeNotifier {
  User? _currentUser;
  Student? _currentStudent;
  bool _isLoading = false;
  String? _error;
  bool _useApi = true; // Toggle to switch between API and mock data

  // Cached data from API
  List<Invoice> _invoices = [];
  List<Transaction> _transactions = [];
  List<Student> _students = [];
  List<FeeCategory> _feeCategories = [];

  // Getters
  User? get currentUser => _currentUser;
  Student? get currentStudent => _currentStudent;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin => _currentUser?.isAdmin ?? false;

  // Initialize - check for existing token and restore session
  Future<void> initialize() async {
    await ApiService.loadToken();
    if (ApiService.hasToken) {
      // First, try to restore from cached user data (instant)
      final cachedUser = ApiService.cachedUserData;
      if (cachedUser != null) {
        try {
          _currentUser = User.fromJson(cachedUser);
          if (_currentUser?.studentId != null && cachedUser['student'] != null) {
            _currentStudent = Student.fromJson(cachedUser['student']);
          }
          notifyListeners();
        } catch (e) {
          // Cached data is invalid, will verify with API
        }
      }
      
      // Then verify with API (in background if cached data exists)
      await _loadCurrentUser();
    }
  }

  // Load current user from API
  Future<void> _loadCurrentUser() async {
    final response = await ApiService.getMe();
    if (response.success && response.data != null) {
      _currentUser = User.fromJson(response.data!);
      if (_currentUser?.studentId != null) {
        _currentStudent = _currentUser?.student != null 
            ? Student.fromJson(response.data!['student'])
            : null;
      }
      // Update cached data with fresh data
      await ApiService.saveUserData(response.data!);
      notifyListeners();
    } else {
      // Token invalid, but keep cached user if exists for offline support
      if (_currentUser == null) {
        await ApiService.clearToken();
      }
    }
  }

  // Login
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    if (_useApi) {
      final response = await ApiService.login(email, password);
      
      if (response.success && response.data != null) {
        _currentUser = User.fromJson(response.data!['user']);
        if (response.data!['user']['student'] != null) {
          _currentStudent = Student.fromJson(response.data!['user']['student']);
        }
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response.error ?? 'Login gagal';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } else {
      // Fallback to mock data
      await Future.delayed(const Duration(milliseconds: 500));
      final user = MockData.getUserByEmail(email);
      if (user != null) {
        _currentUser = user;
        if (user.studentId != null) {
          _currentStudent = MockData.getStudentById(user.studentId!);
        }
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _error = 'Email tidak ditemukan';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Demo login shortcuts (credentials match seeded users in Laravel database)
  Future<bool> loginAsStudent() async {
    return login('siswa1@school.com', 'password');
  }

  Future<bool> loginAsAdmin() async {
    return login('admin@school.com', 'password');
  }

  Future<bool> loginAsBendahara() async {
    return login('bendahara@school.com', 'password');
  }

  // Logout
  Future<void> logout() async {
    if (_useApi) {
      await ApiService.logout();
    }
    _currentUser = null;
    _currentStudent = null;
    _error = null;
    _invoices = [];
    _transactions = [];
    notifyListeners();
  }

  // ==================== INVOICES ====================

  // Fetch invoices from API
  Future<void> fetchInvoices() async {
    if (_useApi) {
      _isLoading = true;
      notifyListeners();

      final response = await ApiService.getInvoices();
      if (response.success && response.data != null) {
        _invoices = (response.data as List)
            .map((json) => Invoice.fromJson(json))
            .toList();
      }
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get invoices for current user
  List<Invoice> getMyInvoices() {
    if (_useApi && _invoices.isNotEmpty) {
      return _invoices;
    }
    if (_currentStudent == null) return [];
    return MockData.getInvoicesByStudentId(_currentStudent!.id);
  }

  // Get transactions for current user
  List<Transaction> getMyTransactions() {
    if (_useApi && _transactions.isNotEmpty) {
      return _transactions;
    }
    if (_currentStudent == null) return [];
    return MockData.getTransactionsByStudentId(_currentStudent!.id);
  }

  // Get unpaid invoices
  List<Invoice> getUnpaidInvoices() {
    return getMyInvoices()
        .where((i) => i.status == InvoiceStatus.unpaid || i.status == InvoiceStatus.partial)
        .toList();
  }

  // Get paid invoices
  List<Invoice> getPaidInvoices() {
    return getMyInvoices().where((i) => i.status == InvoiceStatus.paid).toList();
  }

  // Get total amounts for dashboard
  double get totalUnpaid {
    if (_useApi && _invoices.isNotEmpty) {
      return _invoices
          .where((i) => i.status != InvoiceStatus.paid)
          .fold(0, (sum, i) => sum + i.remainingAmount);
    }
    if (_currentStudent == null) return 0;
    return MockData.getTotalUnpaid(_currentStudent!.id);
  }

  double get totalPaid {
    if (_useApi && _invoices.isNotEmpty) {
      return _invoices.fold(0, (sum, i) => sum + i.paidAmount);
    }
    if (_currentStudent == null) return 0;
    return MockData.getTotalPaid(_currentStudent!.id);
  }

  // ==================== PAYMENT ====================

  // Create payment (get Midtrans Snap token)
  Future<Map<String, dynamic>?> createPayment(String invoiceId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final response = await ApiService.createSnapToken(invoiceId);
    
    _isLoading = false;
    notifyListeners();

    if (response.success && response.data != null) {
      return response.data;
    } else {
      _error = response.error ?? 'Gagal membuat pembayaran';
      return null;
    }
  }

  // Check payment status
  Future<Map<String, dynamic>?> checkPaymentStatus(String orderId) async {
    final response = await ApiService.getPaymentStatus(orderId);
    if (response.success && response.data != null) {
      return response.data;
    }
    return null;
  }

  // ==================== ADMIN DATA ====================

  // Fetch students (admin)
  Future<void> fetchStudents() async {
    if (_useApi) {
      final response = await ApiService.getStudents();
      if (response.success && response.data != null) {
        _students = (response.data as List)
            .map((json) => Student.fromJson(json))
            .toList();
        notifyListeners();
      }
    }
  }

  // Fetch fee categories (admin)
  Future<void> fetchFeeCategories() async {
    if (_useApi) {
      final response = await ApiService.getFeeCategories();
      if (response.success && response.data != null) {
        _feeCategories = (response.data as List)
            .map((json) => FeeCategory.fromJson(json))
            .toList();
        notifyListeners();
      }
    }
  }

  // Fetch transactions from API
  Future<void> fetchTransactions() async {
    if (_useApi) {
      _isLoading = true;
      notifyListeners();

      final response = await ApiService.getTransactions();
      if (response.success && response.data != null) {
        _transactions = (response.data as List)
            .map((json) => Transaction.fromJson(json))
            .toList();
      }
      _isLoading = false;
      notifyListeners();
    }
  }

  List<Student> get allStudents => _useApi ? _students : MockData.students;
  List<Invoice> get allInvoices => _useApi ? _invoices : MockData.invoices;
  List<Transaction> get allTransactions => _useApi ? _transactions : MockData.transactions;
  List<FeeCategory> get allFeeCategories => _useApi ? _feeCategories : MockData.feeCategories;
  
  // Alias for feeCategories used by screens
  List<FeeCategory> get feeCategories => allFeeCategories;

  // Get transaction by ID for e-receipt
  Transaction? getTransactionById(String id) {
    try {
      if (_useApi && _transactions.isNotEmpty) {
        return _transactions.firstWhere((t) => t.id == id);
      }
      return MockData.transactions.firstWhere((t) => t.id == id);
    } catch (e) {
      return null;
    }
  }

  // Calculate statistics from real data
  double get todayIncome {
    if (_useApi && _transactions.isNotEmpty) {
      final today = DateTime.now();
      return _transactions
          .where((t) => t.isSuccessful && t.settlementTime != null &&
              t.settlementTime!.year == today.year &&
              t.settlementTime!.month == today.month &&
              t.settlementTime!.day == today.day)
          .fold(0.0, (sum, t) => sum + t.grossAmount);
    }
    return MockData.getTodayIncome();
  }

  double get monthIncome {
    if (_useApi && _transactions.isNotEmpty) {
      final now = DateTime.now();
      return _transactions
          .where((t) => t.isSuccessful && t.settlementTime != null &&
              t.settlementTime!.year == now.year &&
              t.settlementTime!.month == now.month)
          .fold(0.0, (sum, t) => sum + t.grossAmount);
    }
    return MockData.getMonthIncome();
  }

  double get totalArrears {
    if (_useApi && _invoices.isNotEmpty) {
      return _invoices
          .where((i) => i.status.name == 'unpaid' || i.status.name == 'partial')
          .fold(0.0, (sum, i) => sum + i.remainingAmount);
    }
    return MockData.getTotalArrears();
  }

  int get arrearsCount {
    if (_useApi && _invoices.isNotEmpty) {
      return _invoices
          .where((i) => i.status.name == 'unpaid' || i.status.name == 'partial')
          .length;
    }
    return MockData.getArrearsCount();
  }
  
  // Method aliases for screen compatibility
  Future<void> loadStudentsFromApi() async => fetchStudents();
  Future<void> loadFeeCategoriesFromApi() async => fetchFeeCategories();
  Future<void> loadInvoicesFromApi() async => fetchInvoices();
  Future<void> loadTransactionsFromApi() async => fetchTransactions();


  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Toggle API mode (for testing)
  void setUseApi(bool value) {
    _useApi = value;
    notifyListeners();
  }
}
