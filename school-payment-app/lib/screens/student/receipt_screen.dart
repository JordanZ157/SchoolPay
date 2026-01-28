import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/transaction.dart';
import '../../theme/app_theme.dart';
import '../../providers/app_state.dart';

class ReceiptScreen extends StatefulWidget {
  final String transactionId;

  const ReceiptScreen({super.key, required this.transactionId});

  @override
  State<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptScreen> {
  @override
  void initState() {
    super.initState();
    // Load transactions if not already loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().loadTransactionsFromApi();
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final dateFormat = DateFormat('dd MMMM yyyy, HH:mm', 'id_ID');

    // Find transaction from AppState
    final transaction = appState.getTransactionById(widget.transactionId);

    if (transaction == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('E-Receipt')),
        body: Center(
          child: appState.isLoading 
            ? const CircularProgressIndicator()
            : const Text('Transaksi tidak ditemukan'),
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
                      'E-Receipt',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      // Download logic
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Fitur unduh akan tersedia saat terhubung ke backend'),
                          backgroundColor: AppTheme.infoColor,
                        ),
                      );
                    },
                    icon: const Icon(Icons.download),
                    tooltip: 'Unduh',
                  ),
                  IconButton(
                    onPressed: () {
                      // Share logic
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Fitur bagikan akan tersedia saat terhubung ke backend'),
                          backgroundColor: AppTheme.infoColor,
                        ),
                      );
                    },
                    icon: const Icon(Icons.share),
                    tooltip: 'Bagikan',
                  ),
                ],
              ),
            ),
          ),

          // Receipt content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 450),
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Header
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.school, color: Colors.white, size: 32),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'SchoolPay',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Bukti Pembayaran',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.8),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Success icon
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.successColor.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check_circle,
                            size: 48,
                            color: AppTheme.successColor,
                          ),
                        ),

                        const SizedBox(height: 16),

                        Text(
                          'Pembayaran Berhasil',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.successColor,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Amount
                        Text(
                          currencyFormat.format(transaction.grossAmount),
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryDark,
                          ),
                        ),

                        const SizedBox(height: 24),

                        const Divider(color: AppTheme.dividerColor),

                        const SizedBox(height: 16),

                        // Details
                        _buildReceiptRow('No. Transaksi', transaction.orderId),
                        _buildReceiptRow('No. Invoice', transaction.invoiceNumber),
                        _buildReceiptRow('Nama Siswa', transaction.studentName),
                        _buildReceiptRow('Metode Pembayaran', transaction.paymentTypeDisplayName),
                        if (transaction.settlementTime != null)
                          _buildReceiptRow('Waktu', dateFormat.format(transaction.settlementTime!)),
                        if (transaction.referenceNumber != null)
                          _buildReceiptRow('No. Referensi', transaction.referenceNumber!),
                        _buildReceiptRow('Status', transaction.statusDisplayName),

                        const SizedBox(height: 16),

                        const Divider(color: AppTheme.dividerColor),

                        const SizedBox(height: 16),

                        // Footer
                        Text(
                          'Terima kasih atas pembayaran Anda',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Simpan bukti ini sebagai referensi',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppTheme.primaryDark,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
