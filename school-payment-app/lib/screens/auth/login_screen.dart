import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../routes/app_router.dart';
import '../../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final appState = context.read<AppState>();
    final success = await appState.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (success && mounted) {
      // Check if user must change password on first login
      if (appState.currentUser?.mustChangePassword == true) {
        Navigator.pushReplacementNamed(context, AppRouter.changePassword);
      } else if (appState.isAdmin) {
        Navigator.pushReplacementNamed(context, AppRouter.adminDashboard);
      } else {
        Navigator.pushReplacementNamed(context, AppRouter.studentDashboard);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final appState = context.watch<AppState>();

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryDark,
              AppTheme.primaryMid,
              AppTheme.primaryLight,
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo and Title
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.accentPrimary.withValues(alpha: 0.3),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.school,
                    size: 48,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'SchoolPay',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: -1,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sistem Pembayaran Sekolah',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
                const SizedBox(height: 48),

                // Login Card
                Container(
                  width: size.width > 500 ? 420 : double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: AppTheme.glassDecoration,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Masuk',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Masukkan kredensial Anda untuk melanjutkan',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                      ),
                      const SizedBox(height: 32),

                      // Email field
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          hintText: 'contoh@sekolah.id',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Password field
                      TextField(
                        controller: _passwordController,
                        obscureText: !_isPasswordVisible,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          hintText: '••••••••',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                          ),
                        ),
                      ),

                      // Error message
                      if (appState.error != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.errorColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppTheme.errorColor.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: AppTheme.errorColor,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  appState.error!,
                                  style: TextStyle(color: AppTheme.errorColor),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // Login button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: appState.isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: AppTheme.accentPrimary,
                          ),
                          child: appState.isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Masuk',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
