import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/invoice.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';

class PaymentScreen extends StatefulWidget {
  final String invoiceId;

  const PaymentScreen({super.key, required this.invoiceId});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _isProcessing = false;
  bool _isSuccess = false;
  bool _isLoadingInvoice = true;
  String? _errorMessage;
  String? _currentOrderId;
  Invoice? _invoice;
  
  final List<Map<String, dynamic>> _paymentMethods = [
    {'id': 'qris', 'name': 'QRIS', 'icon': Icons.qr_code_2},
    {'id': 'gopay', 'name': 'GoPay', 'icon': Icons.account_balance_wallet},
    {'id': 'bank_transfer', 'name': 'Transfer Bank', 'icon': Icons.account_balance},
    {'id': 'credit_card', 'name': 'Kartu Kredit', 'icon': Icons.credit_card},
  ];

  @override
  void initState() {
    super.initState();
    _loadInvoice();
  }

  Future<void> _loadInvoice() async {
    setState(() {
      _isLoadingInvoice = true;
      _errorMessage = null;
    });

    final response = await ApiService.getInvoice(widget.invoiceId);
    
    if (response.success && response.data != null) {
      setState(() {
        _invoice = Invoice.fromJson(response.data!);
        _isLoadingInvoice = false;
      });
    } else {
      setState(() {
        _errorMessage = response.error ?? 'Gagal memuat tagihan';
        _isLoadingInvoice = false;
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

    if (_isLoadingInvoice) {
      return Scaffold(
        backgroundColor: AppTheme.primaryDark,
        appBar: AppBar(title: const Text('Pembayaran')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_invoice == null) {
      return Scaffold(
        backgroundColor: AppTheme.primaryDark,
        appBar: AppBar(title: const Text('Pembayaran')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: AppTheme.errorColor),
              const SizedBox(height: 16),
              Text(_errorMessage ?? 'Tagihan tidak ditemukan'),
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
                    child: Text(
                      'Pembayaran',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content
          Expanded(
            child: _isSuccess
                ? _buildSuccessView(context, _invoice!, currencyFormat)
                : _buildPaymentForm(context, _invoice!, currencyFormat),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentForm(BuildContext context, Invoice invoice, NumberFormat currencyFormat) {
    final amount = invoice.remainingAmount;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            children: [
              // Amount card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: AppTheme.gradientCardDecoration,
                child: Column(
                  children: [
                    Text(
                      'Total Pembayaran',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      currencyFormat.format(amount),
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${invoice.categoryName} - ${invoice.period}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Error message
              if (_errorMessage != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.errorColor.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: AppTheme.errorColor,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.errorColor,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Midtrans info box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.infoColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.infoColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.payment,
                      color: AppTheme.infoColor,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pembayaran via Midtrans',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  color: AppTheme.infoColor,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Anda akan diarahkan ke halaman pembayaran Midtrans yang aman untuk melanjutkan transaksi.',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.infoColor.withValues(alpha: 0.8),
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Payment methods supported
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
                      'Metode Pembayaran Tersedia',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: _paymentMethods.map((method) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceColor,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppTheme.dividerColor.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                method['icon'] as IconData,
                                size: 18,
                                color: AppTheme.textSecondary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                method['name'] as String,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppTheme.textSecondary,
                                    ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Pay button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _processPayment,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppTheme.accentPrimary,
                  ),
                  child: _isProcessing
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Memproses...',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          'Bayar Sekarang ${currencyFormat.format(amount)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 16),

              // Check status button (if payment was initiated)
              if (_currentOrderId != null)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _checkPaymentStatus,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Cek Status Pembayaran'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessView(BuildContext context, Invoice invoice, NumberFormat currencyFormat) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.successColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                size: 80,
                color: AppTheme.successColor,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Pembayaran Berhasil!',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppTheme.successColor,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              currencyFormat.format(invoice.remainingAmount),
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '${invoice.categoryName} - ${invoice.period}',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _buildReceiptRow(context, 'No. Transaksi', _currentOrderId ?? '-'),
                  _buildReceiptRow(context, 'Status', 'Lunas'),
                  _buildReceiptRow(context, 'Waktu', DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(DateTime.now())),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Kembali'),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    // Navigate to receipt
                    Navigator.pushReplacementNamed(
                      context, 
                      '/receipt',
                      arguments: {'invoiceId': widget.invoiceId},
                    );
                  },
                  icon: const Icon(Icons.receipt),
                  label: const Text('Lihat Bukti'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textMuted,
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  Future<void> _processPayment() async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    final appState = context.read<AppState>();
    final paymentData = await appState.createPayment(widget.invoiceId);

    if (paymentData != null) {
      _currentOrderId = paymentData['orderId'];
      final redirectUrl = paymentData['redirectUrl'];
      
      if (redirectUrl != null) {
        // Open Midtrans payment page in browser
        final uri = Uri.parse(redirectUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          
          // Show message to check status after payment
          if (mounted) {
            setState(() => _isProcessing = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Selesaikan pembayaran di halaman Midtrans, lalu klik "Cek Status Pembayaran"'),
                backgroundColor: AppTheme.infoColor,
                duration: const Duration(seconds: 5),
                action: SnackBarAction(
                  label: 'Cek Status',
                  textColor: Colors.white,
                  onPressed: _checkPaymentStatus,
                ),
              ),
            );
          }
        } else {
          setState(() {
            _isProcessing = false;
            _errorMessage = 'Tidak dapat membuka halaman pembayaran';
          });
        }
      } else {
        setState(() {
          _isProcessing = false;
          _errorMessage = 'URL pembayaran tidak tersedia';
        });
      }
    } else {
      setState(() {
        _isProcessing = false;
        _errorMessage = appState.error ?? 'Gagal membuat pembayaran';
      });
    }
  }

  Future<void> _checkPaymentStatus() async {
    if (_currentOrderId == null) return;

    setState(() => _isProcessing = true);

    final appState = context.read<AppState>();
    final status = await appState.checkPaymentStatus(_currentOrderId!);

    if (status != null) {
      final paymentStatus = status['status'];
      
      if (paymentStatus == 'settlement' || paymentStatus == 'capture') {
        setState(() {
          _isProcessing = false;
          _isSuccess = true;
        });
      } else if (paymentStatus == 'pending') {
        if (mounted) {
          setState(() => _isProcessing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Pembayaran masih pending. Silakan selesaikan pembayaran.'),
              backgroundColor: AppTheme.warningColor,
            ),
          );
        }
      } else {
        setState(() {
          _isProcessing = false;
          _errorMessage = 'Status pembayaran: ${status['statusDisplayName'] ?? paymentStatus}';
        });
      }
    } else {
      setState(() {
        _isProcessing = false;
        _errorMessage = 'Gagal mengecek status pembayaran';
      });
    }
  }
}
