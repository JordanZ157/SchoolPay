import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/user.dart';
import 'confirmation_dialog.dart';

class SidebarMenu extends StatelessWidget {
  final UserRole userRole;
  final String currentRoute;
  final Function(String) onNavigate;
  final VoidCallback onLogout;
  final String userName;

  const SidebarMenu({
    super.key,
    required this.userRole,
    required this.currentRoute,
    required this.onNavigate,
    required this.onLogout,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    // Separate role checks for proper menu access
    final isAdmin = userRole == UserRole.admin;
    final isBendahara = userRole == UserRole.bendahara;
    final isWaliKelas = userRole == UserRole.waliKelas;
    final isStudentOrParent = userRole == UserRole.siswa || userRole == UserRole.orangTua;

    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        border: Border(
          right: BorderSide(
            color: AppTheme.dividerColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Logo/Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.school,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'SchoolPay',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Payment System',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // User info
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppTheme.accentPrimary.withValues(alpha: 0.2),
                  child: Icon(
                    Icons.person,
                    color: AppTheme.accentPrimary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _getRoleLabel(userRole),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textMuted,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Menu items - role specific
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                // Admin: Full access
                if (isAdmin) ...[
                  _buildMenuItem(
                    context,
                    icon: Icons.dashboard_outlined,
                    label: 'Dashboard',
                    route: '/admin',
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.people_outline,
                    label: 'Manajemen User',
                    route: '/admin/users',
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.attach_money,
                    label: 'Tarif Pembayaran',
                    route: '/admin/fees',
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.receipt_long_outlined,
                    label: 'Generate Invoice',
                    route: '/admin/invoices',
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.bar_chart,
                    label: 'Laporan',
                    route: '/admin/reports',
                  ),
                ]
                // Bendahara: Same as admin WITHOUT User Management
                else if (isBendahara) ...[
                  _buildMenuItem(
                    context,
                    icon: Icons.dashboard_outlined,
                    label: 'Dashboard',
                    route: '/admin',
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.attach_money,
                    label: 'Tarif Pembayaran',
                    route: '/admin/fees',
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.receipt_long_outlined,
                    label: 'Generate Invoice',
                    route: '/admin/invoices',
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.bar_chart,
                    label: 'Laporan',
                    route: '/admin/reports',
                  ),
                ]
                // Wali Kelas: Class-specific menus
                else if (isWaliKelas) ...[
                  _buildMenuItem(
                    context,
                    icon: Icons.dashboard_outlined,
                    label: 'Dashboard',
                    route: '/wali-kelas',
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.receipt_outlined,
                    label: 'Tagihan Siswa',
                    route: '/wali-kelas/invoices',
                  ),
                ]
                // Siswa & Orang Tua: Student menus
                else if (isStudentOrParent) ...[
                  _buildMenuItem(
                    context,
                    icon: Icons.dashboard_outlined,
                    label: 'Dashboard',
                    route: '/student',
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.receipt_outlined,
                    label: 'Tagihan Saya',
                    route: '/student/invoices',
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.history,
                    label: 'Riwayat Pembayaran',
                    route: '/student/history',
                  ),
                ],
                const SizedBox(height: 8),
                const Divider(color: AppTheme.dividerColor),
                const SizedBox(height: 8),
                _buildMenuItem(
                  context,
                  icon: Icons.chat_outlined,
                  label: 'Chatbot',
                  route: '/chatbot',
                ),
              ],
            ),
          ),
          
          // Logout button
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final confirmed = await ConfirmationDialog.showLogoutConfirmation(context);
                  if (confirmed) {
                    onLogout();
                  }
                },
                icon: const Icon(Icons.logout, size: 18),
                label: const Text('Keluar'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.errorColor,
                  side: BorderSide(color: AppTheme.errorColor.withValues(alpha: 0.5)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String route,
  }) {
    final isActive = currentRoute == route;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isActive ? AppTheme.accentPrimary.withValues(alpha: 0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onNavigate(route),
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isActive ? AppTheme.accentPrimary : AppTheme.textSecondary,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isActive ? AppTheme.accentPrimary : AppTheme.textSecondary,
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                      ),
                ),
                if (isActive) ...[
                  const Spacer(),
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      color: AppTheme.accentPrimary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getRoleLabel(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'Administrator';
      case UserRole.bendahara:
        return 'Bendahara';
      case UserRole.waliKelas:
        return 'Wali Kelas';
      case UserRole.siswa:
        return 'Siswa';
      case UserRole.orangTua:
        return 'Orang Tua';
    }
  }
}
