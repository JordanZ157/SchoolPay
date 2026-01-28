import 'package:flutter/material.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/change_password_screen.dart';
import '../screens/student/student_dashboard.dart';
import '../screens/student/invoice_list_screen.dart';
import '../screens/student/invoice_detail_screen.dart';
import '../screens/student/payment_screen.dart';
import '../screens/student/payment_history_screen.dart';
import '../screens/student/receipt_screen.dart';
import '../screens/student/payment_result_screen.dart';
import '../screens/admin/admin_dashboard.dart';
import '../screens/admin/student_management_screen.dart';
import '../screens/admin/user_management_screen.dart';
import '../screens/admin/fee_management_screen.dart';
import '../screens/admin/invoice_generator_screen.dart';
import '../screens/admin/reports_screen.dart';
import '../screens/wali_kelas/wali_kelas_dashboard.dart';
import '../screens/wali_kelas/class_invoices_screen.dart';
import '../screens/chatbot/chatbot_screen.dart';

class AppRouter {
  // Route names
  static const String login = '/login';
  static const String changePassword = '/change-password';
  static const String studentDashboard = '/student';
  static const String invoiceList = '/student/invoices';
  static const String invoiceDetail = '/student/invoice';
  static const String payment = '/student/payment';
  static const String paymentHistory = '/student/history';
  static const String receipt = '/student/receipt';
  static const String paymentResult = '/payment-result';
  static const String adminDashboard = '/admin';
  static const String studentManagement = '/admin/students';
  static const String userManagement = '/admin/users';
  static const String feeManagement = '/admin/fees';
  static const String invoiceGenerator = '/admin/invoices';
  static const String reports = '/admin/reports';
  static const String waliKelasDashboard = '/wali-kelas';
  static const String classInvoices = '/wali-kelas/invoices';
  static const String classReports = '/wali-kelas/reports';
  static const String chatbot = '/chatbot';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    // Parse query parameters for payment-result route
    String? routeName = settings.name;
    Map<String, String> queryParams = {};
    
    if (routeName != null && routeName.contains('?')) {
      final uri = Uri.parse(routeName);
      routeName = uri.path;
      queryParams = uri.queryParameters;
    }

    switch (routeName) {
      case login:
        return _fadeRoute(const LoginScreen(), settings);
      case changePassword:
        return _fadeRoute(const ChangePasswordScreen(), settings);
      
      // Student routes
      case studentDashboard:
        return _fadeRoute(const StudentDashboard(), settings);
      case invoiceList:
        return _fadeRoute(const InvoiceListScreen(), settings);
      case invoiceDetail:
        final invoiceId = settings.arguments as String?;
        return _fadeRoute(InvoiceDetailScreen(invoiceId: invoiceId ?? ''), settings);
      case payment:
        final invoiceId = settings.arguments as String?;
        return _fadeRoute(PaymentScreen(invoiceId: invoiceId ?? ''), settings);
      case paymentHistory:
        return _fadeRoute(const PaymentHistoryScreen(), settings);
      case receipt:
        final transactionId = settings.arguments as String?;
        return _fadeRoute(ReceiptScreen(transactionId: transactionId ?? ''), settings);
      case paymentResult:
        final orderId = queryParams['order_id'] ?? (settings.arguments as Map<String, dynamic>?)?['order_id'];
        final status = queryParams['transaction_status'] ?? (settings.arguments as Map<String, dynamic>?)?['status'];
        return _fadeRoute(PaymentResultScreen(orderId: orderId, status: status), settings);
      
      // Admin routes
      case adminDashboard:
        return _fadeRoute(const AdminDashboard(), settings);
      case studentManagement:
        return _fadeRoute(const StudentManagementScreen(), settings);
      case userManagement:
        return _fadeRoute(const UserManagementScreen(), settings);
      case feeManagement:
        return _fadeRoute(const FeeManagementScreen(), settings);
      case invoiceGenerator:
        return _fadeRoute(const InvoiceGeneratorScreen(), settings);
      case reports:
        return _fadeRoute(const ReportsScreen(), settings);
      
      // Wali Kelas routes
      case waliKelasDashboard:
        return _fadeRoute(const WaliKelasDashboard(), settings);
      case classInvoices:
        return _fadeRoute(const ClassInvoicesScreen(), settings);
      case classReports:
        return _fadeRoute(const ReportsScreen(), settings); // Reuse reports screen for now
      
      // Chatbot
      case chatbot:
        return _fadeRoute(const ChatbotScreen(), settings);
      
      default:
        return _fadeRoute(const LoginScreen(), settings);
    }
  }

  static PageRouteBuilder _fadeRoute(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 200),
    );
  }
}

