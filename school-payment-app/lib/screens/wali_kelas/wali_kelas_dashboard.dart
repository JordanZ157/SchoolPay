import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/app_state.dart';
import '../../routes/app_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/sidebar_menu.dart';
import '../../widgets/stat_card.dart';

class WaliKelasDashboard extends StatefulWidget {
  const WaliKelasDashboard({super.key});

  @override
  State<WaliKelasDashboard> createState() => _WaliKelasDashboardState();
}

class _WaliKelasDashboardState extends State<WaliKelasDashboard> {
  String _currentRoute = '/wali-kelas';

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
    
    final classInvoices = appState.allInvoices.where((i) {
      return classStudents.any((s) => s.id == i.studentId);
    }).toList();

    final totalArrears = classInvoices
        .where((i) => i.status.name == 'unpaid' || i.status.name == 'partial')
        .fold(0.0, (sum, i) => sum + i.remainingAmount);
    
    final totalPaid = classInvoices.fold(0.0, (sum, i) => sum + i.paidAmount);
    
    final arrearsCount = classInvoices
        .where((i) => i.status.name == 'unpaid' || i.status.name == 'partial')
        .length;

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
                              'Dashboard Wali Kelas 📚',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                            ),
                            Text(
                              appState.currentUser!.name,
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                          ],
                        ),
                        const Spacer(),
                        if (userClassId != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppTheme.accentPrimary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.class_outlined,
                                  size: 16,
                                  color: AppTheme.accentPrimary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Kelas $userClassId',
                                  style: TextStyle(
                                    color: AppTheme.accentPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
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
                                    width: isWide ? (constraints.maxWidth - 48) / 4 : constraints.maxWidth,
                                    child: StatCard(
                                      title: 'Total Siswa',
                                      value: '${classStudents.length}',
                                      icon: Icons.people,
                                      iconColor: AppTheme.accentPrimary,
                                      subtitle: 'Siswa di kelas',
                                    ),
                                  ),
                                  SizedBox(
                                    width: isWide ? (constraints.maxWidth - 48) / 4 : constraints.maxWidth,
                                    child: StatCard(
                                      title: 'Total Tunggakan',
                                      value: currencyFormat.format(totalArrears),
                                      icon: Icons.warning_amber,
                                      iconColor: AppTheme.errorColor,
                                      valueColor: AppTheme.errorColor,
                                      subtitle: '$arrearsCount tagihan belum lunas',
                                      onTap: () => _navigate('/wali-kelas/invoices'),
                                    ),
                                  ),
                                  SizedBox(
                                    width: isWide ? (constraints.maxWidth - 48) / 4 : constraints.maxWidth,
                                    child: StatCard(
                                      title: 'Total Dibayar',
                                      value: currencyFormat.format(totalPaid),
                                      icon: Icons.check_circle_outline,
                                      iconColor: AppTheme.successColor,
                                      valueColor: AppTheme.successColor,
                                      subtitle: 'Tahun ajaran ini',
                                    ),
                                  ),
                                  SizedBox(
                                    width: isWide ? (constraints.maxWidth - 48) / 4 : constraints.maxWidth,
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

                          // Student List
                          Row(
                            children: [
                              Text(
                                'Daftar Siswa',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const Spacer(),
                              TextButton.icon(
                                onPressed: () => _navigate('/wali-kelas/invoices'),
                                icon: const Icon(Icons.receipt_long, size: 18),
                                label: const Text('Lihat Tagihan'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          if (classStudents.isEmpty)
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
                                      Icons.people_outline,
                                      size: 48,
                                      color: AppTheme.textMuted,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Belum ada siswa di kelas ini',
                                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                            color: AppTheme.textMuted,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            Container(
                              decoration: BoxDecoration(
                                color: AppTheme.cardBackground,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: classStudents.length,
                                separatorBuilder: (_, __) => Divider(
                                  color: AppTheme.dividerColor.withValues(alpha: 0.3),
                                  height: 1,
                                ),
                                itemBuilder: (context, index) {
                                  final student = classStudents[index];
                                  final studentInvoices = classInvoices
                                      .where((i) => i.studentId == student.id)
                                      .toList();
                                  final studentArrears = studentInvoices
                                      .where((i) => i.status.name == 'unpaid' || i.status.name == 'partial')
                                      .fold(0.0, (sum, i) => sum + i.remainingAmount);
                                  
                                  return ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                    leading: CircleAvatar(
                                      backgroundColor: AppTheme.accentPrimary.withValues(alpha: 0.15),
                                      child: Text(
                                        student.name.isNotEmpty ? student.name[0].toUpperCase() : '?',
                                        style: TextStyle(
                                          color: AppTheme.accentPrimary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      student.name,
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                    subtitle: Text(
                                      '${student.nis} • ${student.displayClass}',
                                      style: TextStyle(color: AppTheme.textMuted),
                                    ),
                                    trailing: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          studentArrears > 0 
                                              ? currencyFormat.format(studentArrears)
                                              : 'Lunas',
                                          style: TextStyle(
                                            color: studentArrears > 0 
                                                ? AppTheme.errorColor 
                                                : AppTheme.successColor,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          '${studentInvoices.length} tagihan',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppTheme.textMuted,
                                          ),
                                        ),
                                      ],
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
            ),
          ),
        ],
      ),
    );
  }
}
