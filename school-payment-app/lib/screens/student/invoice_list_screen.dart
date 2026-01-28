import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/invoice.dart';
import '../../providers/app_state.dart';
import '../../routes/app_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/sidebar_menu.dart';
import '../../widgets/invoice_card.dart';

class InvoiceListScreen extends StatefulWidget {
  const InvoiceListScreen({super.key});

  @override
  State<InvoiceListScreen> createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends State<InvoiceListScreen> {
  String _currentRoute = '/student/invoices';
  String _selectedFilter = 'all';

  void _navigate(String route) {
    setState(() => _currentRoute = route);
    Navigator.pushNamed(context, route);
  }

  void _logout() {
    context.read<AppState>().logout();
    Navigator.pushReplacementNamed(context, AppRouter.login);
  }

  List<Invoice> _filterInvoices(List<Invoice> invoices) {
    switch (_selectedFilter) {
      case 'unpaid':
        return invoices.where((i) => i.status == InvoiceStatus.unpaid).toList();
      case 'partial':
        return invoices.where((i) => i.status == InvoiceStatus.partial).toList();
      case 'paid':
        return invoices.where((i) => i.status == InvoiceStatus.paid).toList();
      default:
        return invoices;
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    if (!appState.isLoggedIn) {
      return const SizedBox.shrink();
    }

    final allInvoices = appState.getMyInvoices();
    final filteredInvoices = _filterInvoices(allInvoices);

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
                              'Tagihan Saya',
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            Text(
                              '${allInvoices.length} tagihan total',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Filter tabs
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    child: Row(
                      children: [
                        _buildFilterChip('all', 'Semua', allInvoices.length),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          'unpaid',
                          'Belum Bayar',
                          allInvoices.where((i) => i.status == InvoiceStatus.unpaid).length,
                          color: AppTheme.errorColor,
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          'partial',
                          'Sebagian',
                          allInvoices.where((i) => i.status == InvoiceStatus.partial).length,
                          color: AppTheme.warningColor,
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          'paid',
                          'Lunas',
                          allInvoices.where((i) => i.status == InvoiceStatus.paid).length,
                          color: AppTheme.successColor,
                        ),
                      ],
                    ),
                  ),

                  // Invoice list
                  Expanded(
                    child: filteredInvoices.isEmpty
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
                                  'Tidak ada tagihan',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        color: AppTheme.textMuted,
                                      ),
                                ),
                                Text(
                                  'Coba ubah filter di atas',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: AppTheme.textMuted,
                                      ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            itemCount: filteredInvoices.length,
                            itemBuilder: (context, index) {
                              final invoice = filteredInvoices[index];
                              return InvoiceCard(
                                invoice: invoice,
                                onTap: () => Navigator.pushNamed(
                                  context,
                                  AppRouter.invoiceDetail,
                                  arguments: invoice.id,
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

  Widget _buildFilterChip(String filter, String label, int count, {Color? color}) {
    final isSelected = _selectedFilter == filter;

    return InkWell(
      onTap: () => setState(() => _selectedFilter = filter),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (color ?? AppTheme.accentPrimary).withValues(alpha: 0.15)
              : AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? (color ?? AppTheme.accentPrimary).withValues(alpha: 0.3)
                : AppTheme.dividerColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? (color ?? AppTheme.accentPrimary) : AppTheme.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (color ?? AppTheme.accentPrimary).withValues(alpha: 0.2)
                      : AppTheme.dividerColor.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 12,
                    color: isSelected ? (color ?? AppTheme.accentPrimary) : AppTheme.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
