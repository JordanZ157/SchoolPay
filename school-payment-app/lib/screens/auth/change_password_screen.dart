import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../routes/app_router.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleChangePassword() async {
    // Validation - no current password needed for first login
    if (_newPasswordController.text.isEmpty) {
      setState(() => _error = 'Password baru harus diisi');
      return;
    }
    if (_newPasswordController.text.length < 6) {
      setState(() => _error = 'Password baru minimal 6 karakter');
      return;
    }
    if (_newPasswordController.text != _confirmPasswordController.text) {
      setState(() => _error = 'Konfirmasi password tidak cocok');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    // Use default password 123456 for first login
    final response = await ApiService.changePassword(
      '123456',
      _newPasswordController.text,
    );

    setState(() => _isLoading = false);

    if (response.success && mounted) {
      // Reload user data to update mustChangePassword flag
      final appState = context.read<AppState>();
      await appState.initialize();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password berhasil diubah!'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate to appropriate dashboard
      if (appState.isAdmin) {
        Navigator.pushReplacementNamed(context, AppRouter.adminDashboard);
      } else {
        Navigator.pushReplacementNamed(context, AppRouter.studentDashboard);
      }
    } else {
      setState(() => _error = response.error ?? 'Gagal mengubah password');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

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
                // Icon
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
                    Icons.lock_reset,
                    size: 48,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Ubah Password',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: -1,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Anda harus mengubah password untuk melanjutkan',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),

                // Form Card
                Container(
                  width: size.width > 500 ? 420 : double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: AppTheme.glassDecoration,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Password Baru',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Buat password baru yang aman untuk akun Anda',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                      ),
                      const SizedBox(height: 32),

                      // New password field
                      TextField(
                        controller: _newPasswordController,
                        obscureText: !_isNewPasswordVisible,
                        decoration: InputDecoration(
                          labelText: 'Password Baru',
                          hintText: 'Minimal 6 karakter',
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isNewPasswordVisible
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                _isNewPasswordVisible = !_isNewPasswordVisible;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Confirm password field
                      TextField(
                        controller: _confirmPasswordController,
                        obscureText: !_isConfirmPasswordVisible,
                        decoration: InputDecoration(
                          labelText: 'Konfirmasi Password Baru',
                          hintText: 'Ulangi password baru',
                          prefixIcon: const Icon(Icons.lock_clock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isConfirmPasswordVisible
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                              });
                            },
                          ),
                        ),
                      ),

                      // Error message
                      if (_error != null) ...[
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
                                  _error!,
                                  style: TextStyle(color: AppTheme.errorColor),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // Submit button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleChangePassword,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: AppTheme.accentPrimary,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Ubah Password',
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
