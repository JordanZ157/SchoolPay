import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? iconColor;
  final Color? valueColor;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool useGradient;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.iconColor,
    this.valueColor,
    this.subtitle,
    this.onTap,
    this.useGradient = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: useGradient
            ? AppTheme.gradientCardDecoration
            : BoxDecoration(
                color: AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.dividerColor.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (iconColor ?? AppTheme.accentPrimary).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor ?? AppTheme.accentPrimary,
                    size: 24,
                  ),
                ),
                const Spacer(),
                if (onTap != null)
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: AppTheme.textMuted,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: valueColor ?? AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textMuted,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class MiniStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const MiniStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
