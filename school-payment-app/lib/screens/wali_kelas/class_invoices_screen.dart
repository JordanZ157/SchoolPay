import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/app_state.dart';
import '../../routes/app_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/sidebar_menu.dart';
import '../../models/invoice.dart';

class ClassInvoicesScreen extends StatefulWidget {
  const ClassInvoicesScreen({super.key});

  @override
  State<ClassInvoicesScreen> createState() => _ClassInvoicesScreenState();
}

class _ClassInvoicesScreenState extends State<ClassInvoicesScreen> {
  String _currentRoute = '/wali-kelas/invoices';
  String _statusFilter = 'all';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final appState = context.read<AppState>();
      // Reload user data to get fresh classId
      await appState.initialize();
      // Then load invoices and students
      appState.loadInvoicesFromApi();
      appState.loadStudentsFromApi();
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

    // Get class-specific data - filter by grade prefix (X, XI, XII)
    final userClassId = appState.currentUser?.classId;
    final classStudents = appState.allStudents
        .where((s) => userClassId == null || s.className.startsWith(userClassId!))
        .toList();
    
    // Filter invoices for class students
    List<Invoice> classInvoices = appState.allInvoices.where((i) {
      return classStudents.any((s) => s.id == i.studentId);
    }).toList();

    // Apply status filter
    if (_statusFilter != 'all') {
      classInvoices = classInvoices.where((i) {
        if (_statusFilter == 'unpaid') {
          return i.status.name == 'unpaid' || i.status.name == 'partial';
        } else if (_statusFilter == 'paid') {
          return i.status.name == 'paid';
        }
        return true;
      }).toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      classInvoices = classInvoices.where((i) {
        final student = classStudents.firstWhere(
          (s) => s.id == i.studentId,
          orElse: () => classStudents.first,
        );
        return student.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            student.nis.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            i.invoiceNumber.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

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
                              'Tagihan Siswa',
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            Text(
                              userClassId != null 
                                  ? 'Kelas $userClassId • ${classInvoices.length} tagihan'
                                  : '${classInvoices.length} tagihan',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Filters
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: AppTheme.cardBackground,
                    child: Row(
                      children: [
                        // Search
                        Expanded(
                          flex: 2,
                          child: TextField(
                            onChanged: (value) => setState(() => _searchQuery = value),
                            decoration: InputDecoration(
                              hintText: 'Cari siswa atau nomor invoice...',
                              prefixIcon: const Icon(Icons.search),
                              filled: true,
                              fillColor: AppTheme.surfaceColor,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Status filter
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _statusFilter,
                              items: const [
                                DropdownMenuItem(value: 'all', child: Text('Semua Status')),
                                DropdownMenuItem(value: 'unpaid', child: Text('Belum Lunas')),
                                DropdownMenuItem(value: 'paid', child: Text('Lunas')),
                              ],
                              onChanged: (value) => setState(() => _statusFilter = value ?? 'all'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Invoice list
                  Expanded(
                    child: classInvoices.isEmpty
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
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(24),
                            itemCount: classInvoices.length,
                            itemBuilder: (context, index) {
                              final invoice = classInvoices[index];
                              final student = classStudents.firstWhere(
                                (s) => s.id == invoice.studentId,
                                orElse: () => classStudents.first,
                              );
                              
                              final isUnpaid = invoice.status.name == 'unpaid' || 
                                  invoice.status.name == 'partial';
                              
                              return InkWell(
                                onTap: () {
                                  if (isUnpaid) {
                                    // Navigate to payment screen for unpaid invoices
                                    Navigator.pushNamed(
                                      context, 
                                      '/student/invoice',
                                      arguments: invoice.id,
                                    );
                                  } else {
                                    // For paid invoices, show invoice detail (which has transaction info)
                                    Navigator.pushNamed(
                                      context, 
                                      '/student/invoice',
                                      arguments: invoice.id,
                                    );
                                  }
                                },
                                borderRadius: BorderRadius.circular(16),
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
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        // Student avatar
                                        CircleAvatar(
                                          radius: 24,
                                          backgroundColor: AppTheme.accentPrimary.withValues(alpha: 0.15),
                                          child: Text(
                                            student.name.isNotEmpty ? student.name[0].toUpperCase() : '?',
                                            style: TextStyle(
                                              color: AppTheme.accentPrimary,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        // Student info & invoice details
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                student.name,
                                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                '${student.nis} • ${student.displayClass}',
                                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                      color: AppTheme.textMuted,
                                                    ),
                                              ),
                                              const SizedBox(height: 8),
                                              Row(
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: AppTheme.surfaceColor,
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: Text(
                                                      invoice.invoiceNumber,
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: AppTheme.textSecondary,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Flexible(
                                                    child: Text(
                                                      '${invoice.categoryName} - ${invoice.period}',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: AppTheme.textMuted,
                                                      ),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Amount and status with action icon
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              currencyFormat.format(isUnpaid ? invoice.remainingAmount : invoice.totalAmount),
                                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                    color: isUnpaid ? AppTheme.errorColor : AppTheme.successColor,
                                                  ),
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: isUnpaid
                                                        ? AppTheme.errorColor.withValues(alpha: 0.15)
                                                        : AppTheme.successColor.withValues(alpha: 0.15),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Text(
                                                    isUnpaid ? 'Belum Lunas' : 'Lunas',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: isUnpaid ? AppTheme.errorColor : AppTheme.successColor,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                Icon(
                                                  isUnpaid ? Icons.payment : Icons.receipt,
                                                  size: 16,
                                                  color: isUnpaid ? AppTheme.errorColor : AppTheme.successColor,
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
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
