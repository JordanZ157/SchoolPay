import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../routes/app_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/sidebar_menu.dart';
import '../../services/api_service.dart';
import '../../constants/school_constants.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen>
    with SingleTickerProviderStateMixin {
  String _currentRoute = '/admin/users';
  String _searchQuery = '';
  bool _isLoading = false;
  List<Map<String, dynamic>> _users = [];
  late TabController _tabController;
  
  final List<String> _roles = ['siswa', 'wali_kelas', 'bendahara', 'admin'];
  final List<String> _roleLabels = ['Siswa', 'Wali Kelas', 'Bendahara', 'Admin'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _roles.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _loadUsers();
      }
    });
    _loadUsers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _navigate(String route) {
    setState(() => _currentRoute = route);
    Navigator.pushNamed(context, route);
  }

  void _logout() {
    context.read<AppState>().logout();
    Navigator.pushReplacementNamed(context, AppRouter.login);
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    final role = _roles[_tabController.index];
    final response = await ApiService.getUsers(role: role, search: _searchQuery.isNotEmpty ? _searchQuery : null);
    setState(() {
      _isLoading = false;
      if (response.success && response.data != null) {
        _users = List<Map<String, dynamic>>.from(response.data!);
      }
    });
  }

  void _showAddUserDialog() {
    final role = _roles[_tabController.index];
    if (role == 'siswa') {
      _showAddStudentDialog();
    } else {
      _showAddStaffDialog(role);
    }
  }

  void _showAddStudentDialog() {
    final formKey = GlobalKey<FormState>();
    final nisController = TextEditingController();
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final parentNameController = TextEditingController();
    final parentPhoneController = TextEditingController();
    final parentEmailController = TextEditingController();
    
    String selectedClass = SchoolConstants.defaultClass;
    String selectedMajor = SchoolConstants.defaultMajor;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.cardBackground,
          title: const Text('Tambah Siswa Baru'),
          content: SizedBox(
            width: 450,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Data Siswa', style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
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
                      controller: emailController,
                      decoration: const InputDecoration(labelText: 'Email Login *'),
                      validator: (v) => v?.isEmpty == true ? 'Email wajib diisi' : null,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedClass,
                            decoration: const InputDecoration(labelText: 'Kelas *'),
                            items: SchoolConstants.classes.map((c) => DropdownMenuItem(
                              value: c,
                              child: Text('Kelas $c'),
                            )).toList(),
                            onChanged: (v) => setDialogState(() => selectedClass = v!),
                            validator: (v) => v == null ? 'Kelas wajib dipilih' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedMajor,
                            decoration: const InputDecoration(labelText: 'Jurusan *'),
                            items: SchoolConstants.majors.map((m) => DropdownMenuItem(
                              value: m,
                              child: Text(m),
                            )).toList(),
                            onChanged: (v) => setDialogState(() => selectedMajor = v!),
                            validator: (v) => v == null ? 'Jurusan wajib dipilih' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text('Data Orang Tua/Wali', style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: parentNameController,
                      decoration: const InputDecoration(labelText: 'Nama Orang Tua'),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: parentPhoneController,
                            decoration: const InputDecoration(labelText: 'No. HP'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: parentEmailController,
                            decoration: const InputDecoration(labelText: 'Email'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.infoColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: AppTheme.infoColor, size: 20),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text('Password default: 123456', style: TextStyle(fontSize: 13)),
                          ),
                        ],
                      ),
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
                  
                  final result = await ApiService.createUser({
                    'name': nameController.text,
                    'email': emailController.text,
                    'role': 'siswa',
                    'nis': nisController.text,
                    'class_name': selectedClass,
                    'major': selectedMajor,
                    'parent_name': parentNameController.text.isNotEmpty ? parentNameController.text : null,
                    'parent_phone': parentPhoneController.text.isNotEmpty ? parentPhoneController.text : null,
                    'parent_email': parentEmailController.text.isNotEmpty ? parentEmailController.text : null,
                  });
                  
                  if (result.success) {
                    await _loadUsers();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Siswa berhasil ditambahkan'),
                          backgroundColor: AppTheme.successColor,
                        ),
                      );
                    }
                  } else {
                    setState(() => _isLoading = false);
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
      ),
    );
  }

  void _showAddStaffDialog(String role) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    
    String roleLabel = _roleLabels[_roles.indexOf(role)];
    String? selectedClassId;
    
    // Class options for wali_kelas (grade levels only)
    final classOptions = ['X', 'XI', 'XII'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.cardBackground,
          title: Text('Tambah $roleLabel Baru'),
          content: SizedBox(
            width: 400,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Nama Lengkap *'),
                    validator: (v) => v?.isEmpty == true ? 'Nama wajib diisi' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: emailController,
                    decoration: const InputDecoration(labelText: 'Email Login *'),
                    validator: (v) => v?.isEmpty == true ? 'Email wajib diisi' : null,
                  ),
                  // Show class selection only for wali_kelas
                  if (role == 'wali_kelas') ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedClassId,
                      decoration: const InputDecoration(labelText: 'Kelas yang Diampu *'),
                      items: classOptions.map((c) => DropdownMenuItem(
                        value: c,
                        child: Text('Kelas $c'),
                      )).toList(),
                      onChanged: (v) => setDialogState(() => selectedClassId = v),
                      validator: (v) => v == null ? 'Kelas wajib dipilih' : null,
                    ),
                  ],
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.infoColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: AppTheme.infoColor, size: 20),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text('Password default: 123456', style: TextStyle(fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                ],
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
                  
                  final userData = {
                    'name': nameController.text,
                    'email': emailController.text,
                    'role': role,
                  };
                  
                  // Add class_id for wali_kelas
                  if (role == 'wali_kelas' && selectedClassId != null) {
                    userData['class_id'] = selectedClassId!;
                  }
                  
                  final result = await ApiService.createUser(userData);
                  
                  if (result.success) {
                    await _loadUsers();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('$roleLabel berhasil ditambahkan'),
                          backgroundColor: AppTheme.successColor,
                        ),
                      );
                    }
                  } else {
                    setState(() => _isLoading = false);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(result.error ?? 'Gagal menambahkan $roleLabel'),
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
      ),
    );
  }

  void _showEditUserDialog(Map<String, dynamic> user) {
    final role = user['role'] ?? _roles[_tabController.index];
    if (role == 'siswa') {
      _showEditStudentDialog(user);
    } else {
      _showEditStaffDialog(user);
    }
  }

  void _showEditStudentDialog(Map<String, dynamic> user) {
    final formKey = GlobalKey<FormState>();
    final student = user['student'] as Map<String, dynamic>?;
    
    final nameController = TextEditingController(text: user['name'] ?? '');
    final emailController = TextEditingController(text: user['email'] ?? '');
    final parentNameController = TextEditingController(text: student?['parentName'] ?? '');
    final parentPhoneController = TextEditingController(text: student?['parentPhone'] ?? '');
    final parentEmailController = TextEditingController(text: student?['parentEmail'] ?? '');
    
    // Get current class and major, default to first option if not found
    String currentClass = student?['className'] ?? SchoolConstants.defaultClass;
    String currentMajor = student?['major'] ?? SchoolConstants.defaultMajor;
    
    // Ensure values are valid options
    if (!SchoolConstants.classes.contains(currentClass)) {
      currentClass = SchoolConstants.defaultClass;
    }
    if (!SchoolConstants.majors.contains(currentMajor)) {
      currentMajor = SchoolConstants.defaultMajor;
    }
    
    String selectedClass = currentClass;
    String selectedMajor = currentMajor;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.cardBackground,
          title: const Text('Edit Data Siswa'),
          content: SizedBox(
            width: 450,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Data Siswa', style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Text('NIS: ', style: TextStyle(color: AppTheme.textMuted)),
                          Text(student?['nis'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Nama Lengkap *'),
                      validator: (v) => v?.isEmpty == true ? 'Nama wajib diisi' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: emailController,
                      decoration: const InputDecoration(labelText: 'Email Login *'),
                      validator: (v) => v?.isEmpty == true ? 'Email wajib diisi' : null,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedClass,
                            decoration: const InputDecoration(labelText: 'Kelas *'),
                            items: SchoolConstants.classes.map((c) => DropdownMenuItem(
                              value: c,
                              child: Text('Kelas $c'),
                            )).toList(),
                            onChanged: (v) => setDialogState(() => selectedClass = v!),
                            validator: (v) => v == null ? 'Kelas wajib dipilih' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedMajor,
                            decoration: const InputDecoration(labelText: 'Jurusan *'),
                            items: SchoolConstants.majors.map((m) => DropdownMenuItem(
                              value: m,
                              child: Text(m),
                            )).toList(),
                            onChanged: (v) => setDialogState(() => selectedMajor = v!),
                            validator: (v) => v == null ? 'Jurusan wajib dipilih' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text('Data Orang Tua/Wali', style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: parentNameController,
                      decoration: const InputDecoration(labelText: 'Nama Orang Tua'),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: parentPhoneController,
                            decoration: const InputDecoration(labelText: 'No. HP'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: parentEmailController,
                            decoration: const InputDecoration(labelText: 'Email'),
                          ),
                        ),
                      ],
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
                  
                  final result = await ApiService.updateUser(user['id'].toString(), {
                    'name': nameController.text,
                    'email': emailController.text,
                    'class_name': selectedClass,
                    'major': selectedMajor,
                    'parent_name': parentNameController.text.isNotEmpty ? parentNameController.text : null,
                    'parent_phone': parentPhoneController.text.isNotEmpty ? parentPhoneController.text : null,
                    'parent_email': parentEmailController.text.isNotEmpty ? parentEmailController.text : null,
                  });
                  
                  if (result.success) {
                    await _loadUsers();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Data siswa berhasil diperbarui'),
                          backgroundColor: AppTheme.successColor,
                        ),
                      );
                    }
                  } else {
                    setState(() => _isLoading = false);
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
      ),
    );
  }

  void _showEditStaffDialog(Map<String, dynamic> user) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: user['name'] ?? '');
    final emailController = TextEditingController(text: user['email'] ?? '');
    
    String roleLabel = user['roleDisplayName'] ?? _roleLabels[_tabController.index];
    String role = user['role'] ?? _roles[_tabController.index];
    
    // Class options for wali_kelas
    final classOptions = ['X', 'XI', 'XII'];
    String? selectedClassId = user['classId'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.cardBackground,
          title: Text('Edit $roleLabel'),
          content: SizedBox(
            width: 400,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Nama Lengkap *'),
                    validator: (v) => v?.isEmpty == true ? 'Nama wajib diisi' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: emailController,
                    decoration: const InputDecoration(labelText: 'Email Login *'),
                    validator: (v) => v?.isEmpty == true ? 'Email wajib diisi' : null,
                  ),
                  // Show class selection only for wali_kelas
                  if (role == 'wali_kelas') ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: classOptions.contains(selectedClassId) ? selectedClassId : null,
                      decoration: const InputDecoration(labelText: 'Kelas yang Diampu *'),
                      items: classOptions.map((c) => DropdownMenuItem(
                        value: c,
                        child: Text('Kelas $c'),
                      )).toList(),
                      onChanged: (v) => setDialogState(() => selectedClassId = v),
                      validator: (v) => v == null ? 'Kelas wajib dipilih' : null,
                    ),
                  ],
                ],
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
                  
                  final updateData = {
                    'name': nameController.text,
                    'email': emailController.text,
                  };
                  
                  // Add class_id for wali_kelas
                  if (role == 'wali_kelas') {
                    updateData['class_id'] = selectedClassId ?? '';
                  }
                  
                  final result = await ApiService.updateUser(user['id'].toString(), updateData);
                  
                  if (result.success) {
                    await _loadUsers();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('$roleLabel berhasil diperbarui'),
                          backgroundColor: AppTheme.successColor,
                        ),
                      );
                    }
                  } else {
                    setState(() => _isLoading = false);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(result.error ?? 'Gagal memperbarui $roleLabel'),
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
      ),
    );
  }

  Future<void> _deleteUser(Map<String, dynamic> user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: const Text('Hapus User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Apakah Anda yakin ingin menghapus user:'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppTheme.errorColor.withValues(alpha: 0.2),
                    child: Text(
                      (user['name'] ?? 'U').substring(0, 1).toUpperCase(),
                      style: TextStyle(color: AppTheme.errorColor, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text(user['email'] ?? '', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.warningColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: AppTheme.warningColor, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Tindakan ini tidak dapat dibatalkan!',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      final result = await ApiService.deleteUser(user['id'].toString());
      
      if (result.success) {
        await _loadUsers();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User berhasil dihapus'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
      } else {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.error ?? 'Gagal menghapus user'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    }
  }

  Future<void> _toggleUserActive(Map<String, dynamic> user) async {
    setState(() => _isLoading = true);
    final result = await ApiService.toggleUserActive(user['id'].toString());
    if (result.success) {
      await _loadUsers();
      if (mounted) {
        final isActive = result.data?['isActive'] ?? false;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isActive ? 'Akun berhasil diaktifkan' : 'Akun berhasil dinonaktifkan'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } else {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.error ?? 'Gagal mengubah status akun'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _resetPassword(Map<String, dynamic> user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: const Text('Reset Password'),
        content: Text('Reset password ${user['name']} ke 123456?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Reset')),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      final result = await ApiService.resetUserPassword(user['id'].toString());
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.success ? 'Password berhasil direset ke 123456' : (result.error ?? 'Gagal reset password')),
            backgroundColor: result.success ? AppTheme.successColor : AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    if (!appState.isLoggedIn) {
      return const SizedBox.shrink();
    }

    final filteredUsers = _users.where((u) {
      if (_searchQuery.isEmpty) return true;
      final name = (u['name'] ?? '').toString().toLowerCase();
      final email = (u['email'] ?? '').toString().toLowerCase();
      return name.contains(_searchQuery.toLowerCase()) || email.contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      body: Row(
        children: [
          SidebarMenu(
            userRole: appState.currentUser!.role,
            currentRoute: _currentRoute,
            onNavigate: _navigate,
            onLogout: _logout,
            userName: appState.currentUser!.name,
          ),
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
                        bottom: BorderSide(color: AppTheme.dividerColor.withValues(alpha: 0.3), width: 1),
                      ),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back),
                        ),
                        const SizedBox(width: 16),
                        Text('Manajemen User', style: Theme.of(context).textTheme.headlineMedium),
                        const Spacer(),
                        if (_isLoading)
                          const Padding(
                            padding: EdgeInsets.only(right: 16),
                            child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
                          ),
                        IconButton(onPressed: _loadUsers, icon: const Icon(Icons.refresh), tooltip: 'Refresh'),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: _showAddUserDialog,
                          icon: const Icon(Icons.add),
                          label: Text('Tambah ${_roleLabels[_tabController.index]}'),
                        ),
                      ],
                    ),
                  ),

                  // Tabs
                  Container(
                    color: AppTheme.cardBackground,
                    child: TabBar(
                      controller: _tabController,
                      tabs: _roleLabels.map((label) => Tab(text: label)).toList(),
                      indicatorColor: AppTheme.accentPrimary,
                      labelColor: AppTheme.accentPrimary,
                      unselectedLabelColor: AppTheme.textMuted,
                    ),
                  ),

                  // Search bar
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: TextField(
                      onChanged: (value) {
                        setState(() => _searchQuery = value);
                        _loadUsers();
                      },
                      decoration: InputDecoration(
                        hintText: 'Cari user (nama, email)...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(icon: const Icon(Icons.clear), onPressed: () { setState(() => _searchQuery = ''); _loadUsers(); })
                            : null,
                      ),
                    ),
                  ),

                  // User list
                  Expanded(
                    child: _isLoading && filteredUsers.isEmpty
                        ? const Center(child: CircularProgressIndicator())
                        : filteredUsers.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.person_off_outlined, size: 64, color: AppTheme.textMuted),
                                    const SizedBox(height: 16),
                                    Text('Tidak ada user ditemukan', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppTheme.textMuted)),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 24),
                                itemCount: filteredUsers.length,
                                itemBuilder: (context, index) {
                                  final user = filteredUsers[index];
                                  final isActive = user['isActive'] ?? true;
                                  final student = user['student'];

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    decoration: BoxDecoration(
                                      color: AppTheme.cardBackground,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isActive ? AppTheme.dividerColor.withValues(alpha: 0.3) : AppTheme.errorColor.withValues(alpha: 0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.all(16),
                                      leading: Stack(
                                        children: [
                                          CircleAvatar(
                                            radius: 24,
                                            backgroundColor: isActive 
                                                ? AppTheme.accentPrimary.withValues(alpha: 0.2) 
                                                : AppTheme.textMuted.withValues(alpha: 0.2),
                                            child: Text(
                                              (user['name'] ?? 'U').substring(0, 1).toUpperCase(),
                                              style: TextStyle(
                                                color: isActive ? AppTheme.accentPrimary : AppTheme.textMuted,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          if (!isActive)
                                            Positioned(
                                              right: 0,
                                              bottom: 0,
                                              child: Container(
                                                padding: const EdgeInsets.all(2),
                                                decoration: BoxDecoration(
                                                  color: AppTheme.errorColor,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(Icons.block, size: 12, color: Colors.white),
                                              ),
                                            ),
                                        ],
                                      ),
                                      title: Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              user['name'] ?? '',
                                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                color: isActive ? null : AppTheme.textMuted,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (!isActive) ...[
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppTheme.errorColor.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text('Nonaktif', style: TextStyle(fontSize: 11, color: AppTheme.errorColor)),
                                            ),
                                          ],
                                        ],
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 4),
                                          Text(user['email'] ?? '', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                                          if (student != null) ...[
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                  decoration: BoxDecoration(color: AppTheme.surfaceColor, borderRadius: BorderRadius.circular(8)),
                                                  child: Text(student['nis'] ?? '', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                                                ),
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                  decoration: BoxDecoration(color: AppTheme.accentPrimary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                                                  child: Text('${student['className']}${student['major'] != null ? ' - ${student['major']}' : ''}', style: TextStyle(color: AppTheme.accentPrimary, fontSize: 12)),
                                                ),
                                              ],
                                            ),
                                            if (student['parentName'] != null) ...[
                                              const SizedBox(height: 4),
                                              Text('Wali: ${student['parentName']}', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                                            ],
                                          ],
                                        ],
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit_outlined),
                                            color: AppTheme.accentPrimary,
                                            onPressed: () => _showEditUserDialog(user),
                                            tooltip: 'Edit',
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline),
                                            color: AppTheme.errorColor,
                                            onPressed: () => _deleteUser(user),
                                            tooltip: 'Hapus',
                                          ),
                                          const SizedBox(width: 8),
                                          Switch(
                                            value: isActive,
                                            onChanged: (_) => _toggleUserActive(user),
                                            activeColor: AppTheme.successColor,
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.lock_reset),
                                            color: AppTheme.warningColor,
                                            onPressed: () => _resetPassword(user),
                                            tooltip: 'Reset Password',
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
