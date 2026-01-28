import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/app_state.dart';
import '../../routes/app_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/sidebar_menu.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/invoice_card.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  String _currentRoute = '/student';

  @override
  void initState() {
    super.initState();
    // Fetch invoices when dashboard loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().fetchInvoices();
    });
  }

  void _navigate(String route) {
    setState(() => _currentRoute = route);
    Navigator.pushNamed(context, route);
  }

  void _logout() async {
    await context.read<AppState>().logout();
    if (mounted) {
      Navigator.pushReplacementNamed(context, AppRouter.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    if (!appState.isLoggedIn) {
      return const SizedBox.shrink();
    }

    final unpaidInvoices = appState.getUnpaidInvoices();
    final recentInvoices = appState.getMyInvoices().take(3).toList();

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
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Selamat Datang! 👋',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                            ),
                            Text(
                              appState.currentStudent?.name ?? appState.currentUser!.name,
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                          ],
                        ),
                        const Spacer(),
                        if (appState.currentStudent != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.school_outlined,
                                  size: 16,
                                  color: AppTheme.textSecondary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  appState.currentStudent!.displayClass,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Stats row
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final isWide = constraints.maxWidth > 800;
                              return Wrap(
                                spacing: 16,
                                runSpacing: 16,
                                children: [
                                  SizedBox(
                                    width: isWide ? (constraints.maxWidth - 32) / 3 : constraints.maxWidth,
                                    child: StatCard(
                                      title: 'Total Tunggakan',
                                      value: currencyFormat.format(appState.totalUnpaid),
                                      icon: Icons.warning_amber,
                                      iconColor: AppTheme.errorColor,
                                      valueColor: AppTheme.errorColor,
                                      subtitle: '${unpaidInvoices.length} tagihan belum lunas',
                                      onTap: () => _navigate(AppRouter.invoiceList),
                                    ),
                                  ),
                                  SizedBox(
                                    width: isWide ? (constraints.maxWidth - 32) / 3 : constraints.maxWidth,
                                    child: StatCard(
                                      title: 'Total Dibayar',
                                      value: currencyFormat.format(appState.totalPaid),
                                      icon: Icons.check_circle_outline,
                                      iconColor: AppTheme.successColor,
                                      valueColor: AppTheme.successColor,
                                      subtitle: 'Tahun ajaran ini',
                                    ),
                                  ),
                                  SizedBox(
                                    width: isWide ? (constraints.maxWidth - 32) / 3 : constraints.maxWidth,
                                    child: StatCard(
                                      title: 'Butuh Bantuan?',
                                      value: 'Tanya Chatbot',
                                      icon: Icons.chat_bubble_outline,
                                      iconColor: AppTheme.accentSecondary,
                                      onTap: () => _navigate(AppRouter.chatbot),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),

                          const SizedBox(height: 32),

                          // Quick actions
                          Text(
                            'Aksi Cepat',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              _buildQuickAction(
                                icon: Icons.receipt_long,
                                label: 'Lihat Tagihan',
                                color: AppTheme.accentPrimary,
                                onTap: () => _navigate(AppRouter.invoiceList),
                              ),
                              const SizedBox(width: 12),
                              _buildQuickAction(
                                icon: Icons.history,
                                label: 'Riwayat',
                                color: AppTheme.successColor,
                                onTap: () => _navigate(AppRouter.paymentHistory),
                              ),
                              const SizedBox(width: 12),
                              _buildQuickAction(
                                icon: Icons.chat,
                                label: 'Chatbot',
                                color: AppTheme.warningColor,
                                onTap: () => _navigate(AppRouter.chatbot),
                              ),
                            ],
                          ),

                          const SizedBox(height: 32),

                          // Recent invoices
                          Row(
                            children: [
                              Text(
                                'Tagihan Terbaru',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const Spacer(),
                              TextButton(
                                onPressed: () => _navigate(AppRouter.invoiceList),
                                child: const Text('Lihat Semua'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          if (recentInvoices.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(32),
                              decoration: BoxDecoration(
                                color: AppTheme.cardBackground,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Center(
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.receipt_long_outlined,
                                      size: 48,
                                      color: AppTheme.textMuted,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Belum ada tagihan',
                                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                            color: AppTheme.textMuted,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            ...recentInvoices.map((invoice) => InvoiceCard(
                                  invoice: invoice,
                                  onTap: () => Navigator.pushNamed(
                                    context,
                                    AppRouter.invoiceDetail,
                                    arguments: invoice.id,
                                  ),
                                )),
                        ],
                      ),
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

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
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
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
