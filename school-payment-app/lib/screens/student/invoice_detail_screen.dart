import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/invoice.dart';
import '../../providers/app_state.dart';
import '../../routes/app_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/status_badge.dart';
import '../../services/api_service.dart';

class InvoiceDetailScreen extends StatefulWidget {
  final String invoiceId;

  const InvoiceDetailScreen({super.key, required this.invoiceId});

  @override
  State<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends State<InvoiceDetailScreen> {
  Invoice? _invoice;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadInvoice();
  }

  Future<void> _loadInvoice() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final response = await ApiService.getInvoice(widget.invoiceId);
    
    if (response.success && response.data != null) {
      setState(() {
        _invoice = Invoice.fromJson(response.data!);
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = response.error ?? 'Gagal memuat tagihan';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final dateFormat = DateFormat('dd MMMM yyyy', 'id_ID');

    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.primaryDark,
        appBar: AppBar(title: const Text('Detail Tagihan')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _invoice == null) {
      return Scaffold(
        backgroundColor: AppTheme.primaryDark,
        appBar: AppBar(title: const Text('Detail Tagihan')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: AppTheme.errorColor),
              const SizedBox(height: 16),
              Text(_error ?? 'Tagihan tidak ditemukan'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadInvoice,
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    final invoice = _invoice!;

    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      body: Column(
        children: [
          // App bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: AppTheme.cardBackground,
              border: Border(
                bottom: BorderSide(
                  color: AppTheme.dividerColor.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Detail Tagihan',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
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
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Column(
                    children: [
                      // Invoice header card
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: AppTheme.gradientCardDecoration,
                        child: Column(
                          children: [
                            Icon(
                              Icons.receipt_long,
                              size: 48,
                              color: AppTheme.accentPrimary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              invoice.categoryName,
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              invoice.period,
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              currencyFormat.format(invoice.totalAmount),
                              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                            ),
                            if (invoice.status == InvoiceStatus.partial) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppTheme.warningColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'Sisa: ${currencyFormat.format(invoice.remainingAmount)}',
                                  style: TextStyle(
                                    color: AppTheme.warningColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Invoice details
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
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
                            Text(
                              'Detail Tagihan',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 16),
                            _buildDetailRow(context, 'Nama Siswa', invoice.studentName),
                            _buildDetailRow(context, 'Jatuh Tempo', dateFormat.format(invoice.dueDate)),
                            _buildDetailRow(context, 'Dibuat', dateFormat.format(invoice.createdAt)),
                            if (invoice.notes != null)
                              _buildDetailRow(context, 'Catatan', invoice.notes!),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Invoice items
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
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
                            Text(
                              'Rincian',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 16),
                            ...invoice.items.map((item) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.description,
                                              style: Theme.of(context).textTheme.bodyMedium,
                                            ),
                                            if (item.quantity > 1)
                                              Text(
                                                '${item.quantity}x ${currencyFormat.format(item.amount)}',
                                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                      color: AppTheme.textMuted,
                                                    ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        currencyFormat.format(item.total),
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ],
                                  ),
                                )),
                            const Divider(color: AppTheme.dividerColor),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                Text(
                                  currencyFormat.format(invoice.totalAmount),
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.accentPrimary,
                                      ),
                                ),
                              ],
                            ),
                            if (invoice.paidAmount > 0) ...[
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Sudah Dibayar',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: AppTheme.successColor,
                                        ),
                                  ),
                                  Text(
                                    '- ${currencyFormat.format(invoice.paidAmount)}',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: AppTheme.successColor,
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Sisa Tagihan',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          color: AppTheme.warningColor,
                                        ),
                                  ),
                                  Text(
                                    currencyFormat.format(invoice.remainingAmount),
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.warningColor,
                                        ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Pay button
                      if (invoice.status != InvoiceStatus.paid)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => Navigator.pushNamed(
                              context,
                              AppRouter.payment,
                              arguments: invoice!.id,
                            ),
                            icon: const Icon(Icons.payment),
                            label: Text(
                              invoice.status == InvoiceStatus.partial
                                  ? 'Bayar Sisa ${currencyFormat.format(invoice.remainingAmount)}'
                                  : 'Bayar Sekarang',
                            ),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: AppTheme.accentPrimary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textMuted,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
