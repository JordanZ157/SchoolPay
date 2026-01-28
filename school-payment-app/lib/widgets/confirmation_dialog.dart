import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Reusable confirmation dialog widget
class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final Color confirmColor;
  final IconData? icon;

  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmText = 'Konfirmasi',
    this.cancelText = 'Batal',
    this.confirmColor = AppTheme.accentPrimary,
    this.icon,
  });

  /// Show a confirmation dialog and return true if confirmed
  static Future<bool> show({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Konfirmasi',
    String cancelText = 'Batal',
    Color confirmColor = AppTheme.accentPrimary,
    IconData? icon,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ConfirmationDialog(
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
        confirmColor: confirmColor,
        icon: icon,
      ),
    );
    return result ?? false;
  }

  /// Convenience method for logout confirmation
  static Future<bool> showLogoutConfirmation(BuildContext context) {
    return show(
      context: context,
      title: 'Keluar dari Aplikasi',
      message: 'Apakah Anda yakin ingin keluar dari akun Anda?',
      confirmText: 'Keluar',
      confirmColor: AppTheme.warningColor,
      icon: Icons.logout,
    );
  }

  /// Convenience method for delete confirmation
  static Future<bool> showDeleteConfirmation(
    BuildContext context, {
    String? itemName,
  }) {
    return show(
      context: context,
      title: 'Konfirmasi Hapus',
      message: itemName != null
          ? 'Apakah Anda yakin ingin menghapus "$itemName"? Tindakan ini tidak dapat dibatalkan.'
          : 'Apakah Anda yakin ingin menghapus item ini? Tindakan ini tidak dapat dibatalkan.',
      confirmText: 'Hapus',
      confirmColor: AppTheme.errorColor,
      icon: Icons.delete_forever,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: confirmColor, size: 28),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
        ],
      ),
      content: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelText),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: confirmColor,
          ),
          child: Text(confirmText),
        ),
      ],
    );
  }
}
