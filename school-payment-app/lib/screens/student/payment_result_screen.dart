import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../routes/app_router.dart';
import '../../services/api_service.dart';

class PaymentResultScreen extends StatefulWidget {
  final String? orderId;
  final String? status;

  const PaymentResultScreen({super.key, this.orderId, this.status});

  @override
  State<PaymentResultScreen> createState() => _PaymentResultScreenState();
}

class _PaymentResultScreenState extends State<PaymentResultScreen> {
  bool _isLoading = true;
  String? _paymentStatus;
  String? _statusDisplayName;
  int _countdown = 5;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    // First, check if status is already provided from Midtrans redirect params
    if (widget.status != null && widget.status!.isNotEmpty) {
      setState(() {
        _isLoading = false;
        _paymentStatus = widget.status;
        _statusDisplayName = _getStatusDisplayName(widget.status!);
      });
      _startAutoRedirect();
      return;
    }

    // If no status from URL, check via API
    if (widget.orderId == null) {
      setState(() {
        _isLoading = false;
        _paymentStatus = 'error';
        _statusDisplayName = 'Order ID tidak ditemukan';
      });
      _startAutoRedirect();
      return;
    }

    // Call API directly
    final result = await ApiService.getPaymentStatus(widget.orderId!);

    if (result.success && result.data != null) {
      setState(() {
        _isLoading = false;
        _paymentStatus = result.data!['status'];
        _statusDisplayName = result.data!['statusDisplayName'] ?? result.data!['status'];
      });
    } else {
      setState(() {
        _isLoading = false;
        _paymentStatus = 'error';
        _statusDisplayName = result.error ?? 'Gagal mengecek status pembayaran';
      });
    }
    _startAutoRedirect();
  }

  void _startAutoRedirect() {
    // Auto redirect to dashboard after countdown
    Future.delayed(const Duration(seconds: 1), _countdownTick);
  }

  void _countdownTick() {
    if (!mounted) return;
    if (_countdown <= 1) {
      _goToDashboard();
    } else {
      setState(() => _countdown--);
      Future.delayed(const Duration(seconds: 1), _countdownTick);
    }
  }

  String _getStatusDisplayName(String status) {
    switch (status) {
      case 'settlement':
      case 'capture':
        return 'Pembayaran Sukses';
      case 'pending':
        return 'Menunggu Pembayaran';
      case 'deny':
        return 'Pembayaran Ditolak';
      case 'cancel':
        return 'Pembayaran Dibatalkan';
      case 'expire':
        return 'Pembayaran Kedaluwarsa';
      default:
        return status;
    }
  }

  bool get _isSuccess => _paymentStatus == 'settlement' || _paymentStatus == 'capture';
  bool get _isPending => _paymentStatus == 'pending';

  void _goToDashboard() {
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRouter.studentDashboard,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: _isLoading
              ? const CircularProgressIndicator()
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: _isSuccess
                            ? AppTheme.successColor.withValues(alpha: 0.15)
                            : _isPending
                                ? AppTheme.warningColor.withValues(alpha: 0.15)
                                : AppTheme.errorColor.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isSuccess
                            ? Icons.check_circle
                            : _isPending
                                ? Icons.schedule
                                : Icons.error,
                        size: 80,
                        color: _isSuccess
                            ? AppTheme.successColor
                            : _isPending
                                ? AppTheme.warningColor
                                : AppTheme.errorColor,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      _isSuccess
                          ? 'Pembayaran Berhasil!'
                          : _isPending
                              ? 'Pembayaran Pending'
                              : 'Pembayaran Gagal',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: _isSuccess
                                ? AppTheme.successColor
                                : _isPending
                                    ? AppTheme.warningColor
                                    : AppTheme.errorColor,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _statusDisplayName ?? '',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                    if (widget.orderId != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Order ID: ${widget.orderId}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textMuted,
                            ),
                      ),
                    ],
                    const SizedBox(height: 32),
                    Text(
                      'Kembali ke beranda dalam $_countdown detik...',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textMuted,
                          ),
                    ),
                    const SizedBox(height: 16),
                    if (_isPending)
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _isLoading = true;
                            _countdown = 5;
                          });
                          _checkStatus();
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Cek Ulang Status'),
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}

