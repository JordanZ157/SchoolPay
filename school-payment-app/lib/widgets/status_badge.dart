import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final bool showIcon;
  final double fontSize;

  const StatusBadge({
    super.key,
    required this.status,
    this.showIcon = true,
    this.fontSize = 12,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.getStatusColor(status);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(
              _getStatusIcon(status),
              size: 14,
              color: color,
            ),
            const SizedBox(width: 6),
          ],
          Text(
            _getStatusText(status),
            style: TextStyle(
              color: color,
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status.toUpperCase()) {
      case 'PAID':
        return Icons.check_circle;
      case 'UNPAID':
        return Icons.warning;
      case 'PARTIAL':
        return Icons.timelapse;
      case 'EXPIRED':
        return Icons.error_outline;
      case 'PENDING':
        return Icons.hourglass_empty;
      default:
        return Icons.info_outline;
    }
  }

  String _getStatusText(String status) {
    switch (status.toUpperCase()) {
      case 'PAID':
        return 'Lunas';
      case 'UNPAID':
        return 'Belum Bayar';
      case 'PARTIAL':
        return 'Sebagian';
      case 'EXPIRED':
        return 'Kadaluarsa';
      case 'PENDING':
        return 'Menunggu';
      default:
        return status;
    }
  }
}
