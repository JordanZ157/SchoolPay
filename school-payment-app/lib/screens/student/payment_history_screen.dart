import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/app_state.dart';
import '../../routes/app_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/sidebar_menu.dart';

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  String _currentRoute = '/student/history';

  @override
  void initState() {
    super.initState();
    // Load transactions and invoices when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = context.read<AppState>();
      appState.loadTransactionsFromApi();
      appState.loadInvoicesFromApi();
    });
  }

  void _navigate(String route) {
    setState(() => _currentRoute = route);
    Navigator.pushNamed(context, route);
  }

  void _logout() {
    context.read<AppState>().logout();
    Navigator.pushReplacementNamed(context, AppRouter.login);
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm', 'id_ID');

    if (!appState.isLoggedIn) {
      return const SizedBox.shrink();
    }

    final transactions = appState.getMyTransactions();

    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          SidebarMenu(
            userRole: appState.currentUser!.role,
            currentRoute: _currentRoute,
            onNavigate: _navigate,
            onLogout: _logout,
            userName: appState.currentUser!.name,
          ),

          // Main content
          Expanded(
            child: Container(
              color: AppTheme.primaryDark,
              child: Column(
                children: [
                  // Top bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                    decoration: BoxDecoration(
                      color: AppTheme.cardBackground,
                      border: Border(
                        bottom: BorderSide(
                          color: AppTheme.dividerColor.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Riwayat Pembayaran',
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            Text(
                              '${transactions.length} transaksi',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Transaction list
                  Expanded(
                    child: transactions.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.receipt_long_outlined,
                                  size: 64,
                                  color: AppTheme.textMuted,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Belum ada transaksi',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        color: AppTheme.textMuted,
                                      ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(24),
                            itemCount: transactions.length,
                            itemBuilder: (context, index) {
                              final transaction = transactions[index];
                              return Container(
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
                                    onTap: () => Navigator.pushNamed(
                                      context,
                                      AppRouter.receipt,
                                      arguments: transaction.id,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: transaction.isSuccessful
                                                  ? AppTheme.successColor.withValues(alpha: 0.15)
                                                  : AppTheme.warningColor.withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Icon(
                                              transaction.isSuccessful
                                                  ? Icons.check_circle
                                                  : Icons.hourglass_empty,
                                              color: transaction.isSuccessful
                                                  ? AppTheme.successColor
                                                  : AppTheme.warningColor,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  transaction.invoiceNumber,
                                                  style: Theme.of(context).textTheme.titleSmall,
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  transaction.paymentTypeDisplayName,
                                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                        color: AppTheme.textMuted,
                                                      ),
                                                ),
                                                if (transaction.settlementTime != null)
                                                  Text(
                                                    dateFormat.format(transaction.settlementTime!),
                                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                          color: AppTheme.textMuted,
                                                        ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                currencyFormat.format(transaction.grossAmount),
                                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                                      fontWeight: FontWeight.bold,
                                                      color: AppTheme.successColor,
                                                    ),
                                              ),
                                              const SizedBox(height: 4),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: transaction.isSuccessful
                                                      ? AppTheme.successColor.withValues(alpha: 0.15)
                                                      : AppTheme.warningColor.withValues(alpha: 0.15),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  transaction.statusDisplayName,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: transaction.isSuccessful
                                                        ? AppTheme.successColor
                                                        : AppTheme.warningColor,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
