import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/app_state.dart';
import '../../routes/app_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/sidebar_menu.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/invoice_card.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  String _currentRoute = '/admin';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    final appState = context.read<AppState>();
    
    // Force refresh invoices first to ensure accurate totalArrears
    await appState.loadInvoicesFromApi();
    
    // Fetch all data needed for dashboard
    await Future.wait([
      appState.fetchTransactions(),
      appState.fetchStudents(),
    ]);
    
    if (mounted) {
      setState(() => _isLoading = false);
    }
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

    if (!appState.isLoggedIn) {
      return const SizedBox.shrink();
    }

    final unpaidInvoices = appState.allInvoices
        .where((i) =>
            i.status.name == 'unpaid' || i.status.name == 'partial')
        .take(5)
        .toList();

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
                              'Dashboard Admin',
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            Text(
                              'Ringkasan keuangan sekolah',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 16,
                                color: AppTheme.textSecondary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                DateFormat('dd MMMM yyyy', 'id_ID').format(DateTime.now()),
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
                          // Stats grid
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final isWide = constraints.maxWidth > 1000;
                              final cardWidth = isWide
                                  ? (constraints.maxWidth - 48) / 4
                                  : (constraints.maxWidth - 16) / 2;
                              
                              return Wrap(
                                spacing: 16,
                                runSpacing: 16,
                                children: [
                                  SizedBox(
                                    width: cardWidth,
                                    child: StatCard(
                                      title: 'Pemasukan Hari Ini',
                                      value: currencyFormat.format(appState.todayIncome),
                                      icon: Icons.today,
                                      iconColor: AppTheme.accentSecondary,
                                      useGradient: true,
                                    ),
                                  ),
                                  SizedBox(
                                    width: cardWidth,
                                    child: StatCard(
                                      title: 'Pemasukan Bulan Ini',
                                      value: currencyFormat.format(appState.monthIncome),
                                      icon: Icons.calendar_month,
                                      iconColor: AppTheme.successColor,
                                    ),
                                  ),
                                  SizedBox(
                                    width: cardWidth,
                                    child: StatCard(
                                      title: 'Total Tunggakan',
                                      value: currencyFormat.format(appState.totalArrears),
                                      icon: Icons.warning_amber,
                                      iconColor: AppTheme.errorColor,
                                      valueColor: AppTheme.errorColor,
                                      subtitle: '${appState.arrearsCount} invoice',
                                    ),
                                  ),
                                  SizedBox(
                                    width: cardWidth,
                                    child: StatCard(
                                      title: 'Total Siswa',
                                      value: appState.allStudents.length.toString(),
                                      icon: Icons.people,
                                      iconColor: AppTheme.accentPrimary,
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
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              _buildQuickAction(
                                icon: Icons.receipt_long,
                                label: 'Generate Invoice',
                                color: AppTheme.accentPrimary,
                                onTap: () => _navigate(AppRouter.invoiceGenerator),
                              ),
                              _buildQuickAction(
                                icon: Icons.people,
                                label: 'Kelola Siswa',
                                color: AppTheme.successColor,
                                onTap: () => _navigate(AppRouter.studentManagement),
                              ),
                              _buildQuickAction(
                                icon: Icons.attach_money,
                                label: 'Tarif Pembayaran',
                                color: AppTheme.warningColor,
                                onTap: () => _navigate(AppRouter.feeManagement),
                              ),
                              _buildQuickAction(
                                icon: Icons.bar_chart,
                                label: 'Laporan',
                                color: AppTheme.infoColor,
                                onTap: () => _navigate(AppRouter.reports),
                              ),
                            ],
                          ),

                          const SizedBox(height: 32),

                          // Recent unpaid invoices
                          Row(
                            children: [
                              Text(
                                'Tunggakan Terbaru',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const Spacer(),
                              TextButton(
                                onPressed: () => _navigate(AppRouter.reports),
                                child: const Text('Lihat Semua'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          if (unpaidInvoices.isEmpty)
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
                                      Icons.check_circle_outline,
                                      size: 48,
                                      color: AppTheme.successColor,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Tidak ada tunggakan',
                                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                            color: AppTheme.successColor,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            ...unpaidInvoices.map((invoice) => InvoiceCard(
                                  invoice: invoice,
                                  showStudentName: true,
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
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
    );
  }
}
