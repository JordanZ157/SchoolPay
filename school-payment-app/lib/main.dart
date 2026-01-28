import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'providers/app_state.dart';
import 'routes/app_router.dart';
import 'theme/app_theme.dart';
import 'services/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  
  // Load existing token (for session persistence)
  await ApiService.loadToken();
  
  // Check for Midtrans callback params in browser URL (before hash)
  String? initialRoute;
  final browserUrl = html.window.location.href;
  final uri = Uri.parse(browserUrl);
  
  // If we have order_id and transaction_status, this is a Midtrans callback
  if (uri.queryParameters.containsKey('order_id') && 
      uri.queryParameters.containsKey('transaction_status')) {
    final orderId = uri.queryParameters['order_id'];
    final status = uri.queryParameters['transaction_status'];
    initialRoute = '/payment-result?order_id=$orderId&transaction_status=$status';
  } else if (ApiService.hasToken) {
    // Has existing session, go to appropriate dashboard
    final userData = ApiService.cachedUserData;
    if (userData != null) {
      final role = userData['role'] ?? 'siswa';
      if (role == 'admin' || role == 'bendahara' || role == 'wali_kelas') {
        initialRoute = AppRouter.adminDashboard;
      } else {
        initialRoute = AppRouter.studentDashboard;
      }
    }
  }
  
  runApp(SchoolPaymentApp(initialRoute: initialRoute));
}

class SchoolPaymentApp extends StatelessWidget {
  final String? initialRoute;
  
  const SchoolPaymentApp({super.key, this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()..initialize()),
      ],
      child: MaterialApp(
        title: 'School Payment System',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        initialRoute: initialRoute ?? AppRouter.login,
        onGenerateRoute: AppRouter.generateRoute,
      ),
    );
  }
}
