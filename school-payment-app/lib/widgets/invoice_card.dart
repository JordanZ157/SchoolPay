import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/invoice.dart';
import '../theme/app_theme.dart';
import 'status_badge.dart';

class InvoiceCard extends StatelessWidget {
  final Invoice invoice;
  final VoidCallback? onTap;
  final bool showStudentName;

  const InvoiceCard({
    super.key,
    required this.invoice,
    this.onTap,
    this.showStudentName = false,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final dateFormat = DateFormat('dd MMM yyyy', 'id_ID');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.dividerColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              invoice.categoryName,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              invoice.invoiceNumber,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.textMuted,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      StatusBadge(status: invoice.status.name.toUpperCase()),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Period
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      invoice.period,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                  ),
                  
                  if (showStudentName) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.person_outline,
                          size: 16,
                          color: AppTheme.textMuted,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          invoice.studentName,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                        ),
                      ],
                    ),
                  ],
                  
                  const SizedBox(height: 12),
                  const Divider(color: AppTheme.dividerColor, height: 1),
                  const SizedBox(height: 12),
                  
                  // Footer
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Tagihan',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.textMuted,
                                ),
                          ),
                          Text(
                            currencyFormat.format(invoice.totalAmount),
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Jatuh Tempo',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.textMuted,
                                ),
                          ),
                          Text(
                            dateFormat.format(invoice.dueDate),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: invoice.isOverdue
                                      ? AppTheme.errorColor
                                      : AppTheme.textSecondary,
                                  fontWeight: invoice.isOverdue ? FontWeight.w600 : null,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  
                  // Remaining amount for partial payments
                  if (invoice.status == InvoiceStatus.partial) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.warningColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: AppTheme.warningColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Sisa: ${currencyFormat.format(invoice.remainingAmount)}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.warningColor,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
