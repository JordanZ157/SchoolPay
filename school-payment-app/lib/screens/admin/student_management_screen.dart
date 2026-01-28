import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../routes/app_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/sidebar_menu.dart';
import '../../services/api_service.dart';
import '../../models/student.dart';

class StudentManagementScreen extends StatefulWidget {
  const StudentManagementScreen({super.key});

  @override
  State<StudentManagementScreen> createState() => _StudentManagementScreenState();
}

class _StudentManagementScreenState extends State<StudentManagementScreen> {
  String _currentRoute = '/admin/students';
  String _searchQuery = '';
  bool _isLoading = false;

  void _navigate(String route) {
    setState(() => _currentRoute = route);
    Navigator.pushNamed(context, route);
  }

  void _logout() {
    context.read<AppState>().logout();
    Navigator.pushReplacementNamed(context, AppRouter.login);
  }

  Future<void> _refreshStudents() async {
    setState(() => _isLoading = true);
    await context.read<AppState>().loadStudentsFromApi();
    setState(() => _isLoading = false);
  }

  void _showAddStudentDialog() {
    final formKey = GlobalKey<FormState>();
    final nisController = TextEditingController();
    final nameController = TextEditingController();
    final classController = TextEditingController();
    final majorController = TextEditingController();
    final parentNameController = TextEditingController();
    final parentPhoneController = TextEditingController();
    final parentEmailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: const Text('Tambah Siswa Baru'),
        content: SizedBox(
          width: 400,
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nisController,
                    decoration: const InputDecoration(labelText: 'NIS *'),
                    validator: (v) => v?.isEmpty == true ? 'NIS wajib diisi' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Nama Lengkap *'),
                    validator: (v) => v?.isEmpty == true ? 'Nama wajib diisi' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: classController,
                    decoration: const InputDecoration(labelText: 'Kelas * (contoh: X-A)'),
                    validator: (v) => v?.isEmpty == true ? 'Kelas wajib diisi' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: majorController,
                    decoration: const InputDecoration(labelText: 'Jurusan (opsional)'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: parentNameController,
                    decoration: const InputDecoration(labelText: 'Nama Orang Tua'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: parentPhoneController,
                    decoration: const InputDecoration(labelText: 'No. HP Orang Tua'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: parentEmailController,
                    decoration: const InputDecoration(labelText: 'Email Orang Tua'),
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState?.validate() == true) {
                Navigator.pop(context);
                setState(() => _isLoading = true);
                
                final result = await ApiService.createStudent({
                  'nis': nisController.text,
                  'name': nameController.text,
                  'class_name': classController.text,
                  'major': majorController.text.isNotEmpty ? majorController.text : null,
                  'parent_name': parentNameController.text.isNotEmpty ? parentNameController.text : null,
                  'parent_phone': parentPhoneController.text.isNotEmpty ? parentPhoneController.text : null,
                  'parent_email': parentEmailController.text.isNotEmpty ? parentEmailController.text : null,
                });
                
                setState(() => _isLoading = false);
                
                if (result.success) {
                  await _refreshStudents();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Siswa berhasil ditambahkan'),
                        backgroundColor: AppTheme.successColor,
                      ),
                    );
                  }
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(result.error ?? 'Gagal menambahkan siswa'),
                        backgroundColor: AppTheme.errorColor,
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showEditStudentDialog(Student student) {
    final formKey = GlobalKey<FormState>();
    final nisController = TextEditingController(text: student.nis);
    final nameController = TextEditingController(text: student.name);
    final classController = TextEditingController(text: student.className);
    final majorController = TextEditingController(text: student.major ?? '');
    final parentNameController = TextEditingController(text: student.parentName ?? '');
    final parentPhoneController = TextEditingController(text: student.parentPhone ?? '');
    final parentEmailController = TextEditingController(text: student.parentEmail ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: Text('Edit ${student.name}'),
        content: SizedBox(
          width: 400,
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nisController,
                    decoration: const InputDecoration(labelText: 'NIS *'),
                    validator: (v) => v?.isEmpty == true ? 'NIS wajib diisi' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Nama Lengkap *'),
                    validator: (v) => v?.isEmpty == true ? 'Nama wajib diisi' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: classController,
                    decoration: const InputDecoration(labelText: 'Kelas *'),
                    validator: (v) => v?.isEmpty == true ? 'Kelas wajib diisi' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: majorController,
                    decoration: const InputDecoration(labelText: 'Jurusan'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: parentNameController,
                    decoration: const InputDecoration(labelText: 'Nama Orang Tua'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: parentPhoneController,
                    decoration: const InputDecoration(labelText: 'No. HP Orang Tua'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: parentEmailController,
                    decoration: const InputDecoration(labelText: 'Email Orang Tua'),
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState?.validate() == true) {
                Navigator.pop(context);
                setState(() => _isLoading = true);
                
                final result = await ApiService.updateStudent(student.id, {
                  'nis': nisController.text,
                  'name': nameController.text,
                  'class_name': classController.text,
                  'major': majorController.text.isNotEmpty ? majorController.text : null,
                  'parent_name': parentNameController.text.isNotEmpty ? parentNameController.text : null,
                  'parent_phone': parentPhoneController.text.isNotEmpty ? parentPhoneController.text : null,
                  'parent_email': parentEmailController.text.isNotEmpty ? parentEmailController.text : null,
                });
                
                setState(() => _isLoading = false);
                
                if (result.success) {
                  await _refreshStudents();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Data siswa berhasil diperbarui'),
                        backgroundColor: AppTheme.successColor,
                      ),
                    );
                  }
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(result.error ?? 'Gagal memperbarui data siswa'),
                        backgroundColor: AppTheme.errorColor,
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(Student student) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: const Text('Hapus Siswa'),
        content: Text('Apakah Anda yakin ingin menghapus ${student.name}?\n\nPerhatian: Siswa yang memiliki tagihan tidak dapat dihapus.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isLoading = true);
              
              final result = await ApiService.deleteStudent(student.id);
              
              setState(() => _isLoading = false);
              
              if (result.success) {
                await _refreshStudents();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Siswa berhasil dihapus'),
                      backgroundColor: AppTheme.successColor,
                    ),
                  );
                }
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(result.error ?? 'Gagal menghapus siswa'),
                      backgroundColor: AppTheme.errorColor,
                    ),
                  );
                }
              }
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    if (!appState.isLoggedIn) {
      return const SizedBox.shrink();
    }

    final students = appState.allStudents.where((s) {
      if (_searchQuery.isEmpty) return true;
      return s.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          s.nis.contains(_searchQuery) ||
          s.className.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

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
                              'Kelola Siswa',
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            Text(
                              '${appState.allStudents.length} siswa terdaftar',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        if (_isLoading)
                          const Padding(
                            padding: EdgeInsets.only(right: 16),
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        IconButton(
                          onPressed: _refreshStudents,
                          icon: const Icon(Icons.refresh),
                          tooltip: 'Refresh',
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: _showAddStudentDialog,
                          icon: const Icon(Icons.add),
                          label: const Text('Tambah Siswa'),
                        ),
                      ],
                    ),
                  ),

                  // Search bar
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: TextField(
                      onChanged: (value) => setState(() => _searchQuery = value),
                      decoration: InputDecoration(
                        hintText: 'Cari siswa (nama, NIS, kelas)...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () => setState(() => _searchQuery = ''),
                              )
                            : null,
                      ),
                    ),
                  ),

                  // Student list
                  Expanded(
                    child: _isLoading && students.isEmpty
                        ? const Center(child: CircularProgressIndicator())
                        : students.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.person_off_outlined,
                                      size: 64,
                                      color: AppTheme.textMuted,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Tidak ada siswa ditemukan',
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            color: AppTheme.textMuted,
                                          ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 24),
                                itemCount: students.length,
                                itemBuilder: (context, index) {
                                  final student = students[index];
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
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.all(16),
                                      leading: CircleAvatar(
                                        radius: 24,
                                        backgroundColor: AppTheme.accentPrimary.withValues(alpha: 0.2),
                                        child: Text(
                                          student.name.substring(0, 1).toUpperCase(),
                                          style: TextStyle(
                                            color: AppTheme.accentPrimary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      title: Text(
                                        student.name,
                                        style: Theme.of(context).textTheme.titleMedium,
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: AppTheme.surfaceColor,
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  student.nis,
                                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                        color: AppTheme.textMuted,
                                                      ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: AppTheme.accentPrimary.withValues(alpha: 0.1),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  student.displayClass,
                                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                        color: AppTheme.accentPrimary,
                                                      ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (student.parentName != null) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              'Wali: ${student.parentName}',
                                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                    color: AppTheme.textMuted,
                                                  ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit_outlined),
                                            color: AppTheme.infoColor,
                                            onPressed: () => _showEditStudentDialog(student),
                                            tooltip: 'Edit',
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outlined),
                                            color: AppTheme.errorColor,
                                            onPressed: () => _showDeleteConfirmation(student),
                                            tooltip: 'Hapus',
                                          ),
                                        ],
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
