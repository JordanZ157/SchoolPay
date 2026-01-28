import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/app_state.dart';
import '../../routes/app_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/sidebar_menu.dart';
import '../../services/api_service.dart';
import '../../models/fee_category.dart';

class FeeManagementScreen extends StatefulWidget {
  const FeeManagementScreen({super.key});

  @override
  State<FeeManagementScreen> createState() => _FeeManagementScreenState();
}

class _FeeManagementScreenState extends State<FeeManagementScreen> {
  String _currentRoute = '/admin/fees';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Auto-load fee categories when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshCategories();
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

  Future<void> _refreshCategories() async {
    setState(() => _isLoading = true);
    await context.read<AppState>().loadFeeCategoriesFromApi();
    setState(() => _isLoading = false);
  }

  String _typeToString(FeeType type) {
    switch (type) {
      case FeeType.akademik:
        return 'akademik';
      case FeeType.nonAkademik:
        return 'non_akademik';
      case FeeType.insidental:
        return 'insidental';
      case FeeType.administratif:
        return 'administratif';
    }
  }

  FeeType _stringToType(String type) {
    switch (type) {
      case 'akademik':
        return FeeType.akademik;
      case 'non_akademik':
        return FeeType.nonAkademik;
      case 'insidental':
        return FeeType.insidental;
      case 'administratif':
        return FeeType.administratif;
      default:
        return FeeType.akademik;
    }
  }

  String _frequencyToString(FeeFrequency freq) {
    switch (freq) {
      case FeeFrequency.once:
        return 'once';
      case FeeFrequency.monthly:
        return 'monthly';
      case FeeFrequency.semester:
        return 'semester';
      case FeeFrequency.yearly:
        return 'yearly';
    }
  }

  FeeFrequency _stringToFrequency(String freq) {
    switch (freq) {
      case 'once':
        return FeeFrequency.once;
      case 'monthly':
        return FeeFrequency.monthly;
      case 'semester':
        return FeeFrequency.semester;
      case 'yearly':
        return FeeFrequency.yearly;
      default:
        return FeeFrequency.monthly;
    }
  }

  void _showAddCategoryDialog() {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final amountController = TextEditingController();
    final maxInstallmentController = TextEditingController();
    String selectedType = 'akademik';
    String selectedFrequency = 'monthly';
    bool allowInstallment = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.cardBackground,
          title: const Text('Tambah Kategori Biaya'),
          content: SizedBox(
            width: 450,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Nama Kategori *'),
                      validator: (v) => v?.isEmpty == true ? 'Nama wajib diisi' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: descController,
                      decoration: const InputDecoration(labelText: 'Deskripsi'),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedType,
                      decoration: const InputDecoration(labelText: 'Tipe *'),
                      items: const [
                        DropdownMenuItem(value: 'akademik', child: Text('Akademik')),
                        DropdownMenuItem(value: 'non_akademik', child: Text('Non-Akademik')),
                        DropdownMenuItem(value: 'insidental', child: Text('Insidental')),
                        DropdownMenuItem(value: 'administratif', child: Text('Administratif')),
                      ],
                      onChanged: (v) => setDialogState(() => selectedType = v!),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedFrequency,
                      decoration: const InputDecoration(labelText: 'Frekuensi *'),
                      items: const [
                        DropdownMenuItem(value: 'once', child: Text('Sekali')),
                        DropdownMenuItem(value: 'monthly', child: Text('Bulanan')),
                        DropdownMenuItem(value: 'semester', child: Text('Semester')),
                        DropdownMenuItem(value: 'yearly', child: Text('Tahunan')),
                      ],
                      onChanged: (v) => setDialogState(() => selectedFrequency = v!),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: amountController,
                      decoration: const InputDecoration(
                        labelText: 'Nominal Dasar (Rp) *',
                        prefixText: 'Rp ',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) => v?.isEmpty == true ? 'Nominal wajib diisi' : null,
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Izinkan Cicilan'),
                      value: allowInstallment,
                      onChanged: (v) => setDialogState(() => allowInstallment = v),
                      contentPadding: EdgeInsets.zero,
                    ),
                    if (allowInstallment) ...[
                      TextFormField(
                        controller: maxInstallmentController,
                        decoration: const InputDecoration(labelText: 'Maksimal Cicilan'),
                        keyboardType: TextInputType.number,
                      ),
                    ],
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
                  
                  final result = await ApiService.createFeeCategory({
                    'name': nameController.text,
                    'description': descController.text.isNotEmpty ? descController.text : null,
                    'type': selectedType,
                    'frequency': selectedFrequency,
                    'base_amount': double.tryParse(amountController.text.replaceAll('.', '').replaceAll(',', '')) ?? 0,
                    'is_active': true,
                    'allow_installment': allowInstallment,
                    'max_installments': allowInstallment && maxInstallmentController.text.isNotEmpty
                        ? int.tryParse(maxInstallmentController.text)
                        : null,
                  });
                  
                  setState(() => _isLoading = false);
                  
                  if (result.success) {
                    await _refreshCategories();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Kategori berhasil ditambahkan'),
                          backgroundColor: AppTheme.successColor,
                        ),
                      );
                    }
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(result.error ?? 'Gagal menambahkan kategori'),
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

  void _showEditCategoryDialog(FeeCategory category) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: category.name);
    final descController = TextEditingController(text: category.description);
    final amountController = TextEditingController(text: category.baseAmount.toStringAsFixed(0));
    final maxInstallmentController = TextEditingController(
      text: category.maxInstallments?.toString() ?? '',
    );
    String selectedType = _typeToString(category.type);
    String selectedFrequency = _frequencyToString(category.frequency);
    bool allowInstallment = category.allowInstallment;
    bool isActive = category.isActive;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.cardBackground,
          title: Text('Edit ${category.name}'),
          content: SizedBox(
            width: 450,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Nama Kategori *'),
                      validator: (v) => v?.isEmpty == true ? 'Nama wajib diisi' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: descController,
                      decoration: const InputDecoration(labelText: 'Deskripsi'),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedType,
                      decoration: const InputDecoration(labelText: 'Tipe *'),
                      items: const [
                        DropdownMenuItem(value: 'akademik', child: Text('Akademik')),
                        DropdownMenuItem(value: 'non_akademik', child: Text('Non-Akademik')),
                        DropdownMenuItem(value: 'insidental', child: Text('Insidental')),
                        DropdownMenuItem(value: 'administratif', child: Text('Administratif')),
                      ],
                      onChanged: (v) => setDialogState(() => selectedType = v!),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedFrequency,
                      decoration: const InputDecoration(labelText: 'Frekuensi *'),
                      items: const [
                        DropdownMenuItem(value: 'once', child: Text('Sekali')),
                        DropdownMenuItem(value: 'monthly', child: Text('Bulanan')),
                        DropdownMenuItem(value: 'semester', child: Text('Semester')),
                        DropdownMenuItem(value: 'yearly', child: Text('Tahunan')),
                      ],
                      onChanged: (v) => setDialogState(() => selectedFrequency = v!),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: amountController,
                      decoration: const InputDecoration(
                        labelText: 'Nominal Dasar (Rp) *',
                        prefixText: 'Rp ',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) => v?.isEmpty == true ? 'Nominal wajib diisi' : null,
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Kategori Aktif'),
                      value: isActive,
                      onChanged: (v) => setDialogState(() => isActive = v),
                      contentPadding: EdgeInsets.zero,
                    ),
                    SwitchListTile(
                      title: const Text('Izinkan Cicilan'),
                      value: allowInstallment,
                      onChanged: (v) => setDialogState(() => allowInstallment = v),
                      contentPadding: EdgeInsets.zero,
                    ),
                    if (allowInstallment) ...[
                      TextFormField(
                        controller: maxInstallmentController,
                        decoration: const InputDecoration(labelText: 'Maksimal Cicilan'),
                        keyboardType: TextInputType.number,
                      ),
                    ],
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
                  
                  final result = await ApiService.updateFeeCategory(category.id, {
                    'name': nameController.text,
                    'description': descController.text.isNotEmpty ? descController.text : null,
                    'type': selectedType,
                    'frequency': selectedFrequency,
                    'base_amount': double.tryParse(amountController.text.replaceAll('.', '').replaceAll(',', '')) ?? 0,
                    'is_active': isActive,
                    'allow_installment': allowInstallment,
                    'max_installments': allowInstallment && maxInstallmentController.text.isNotEmpty
                        ? int.tryParse(maxInstallmentController.text)
                        : null,
                  });
                  
                  setState(() => _isLoading = false);
                  
                  if (result.success) {
                    await _refreshCategories();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Kategori berhasil diperbarui'),
                          backgroundColor: AppTheme.successColor,
                        ),
                      );
                    }
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(result.error ?? 'Gagal memperbarui kategori'),
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

  void _showDeleteConfirmation(FeeCategory category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: const Text('Hapus Kategori'),
        content: Text(
          'Apakah Anda yakin ingin menghapus kategori "${category.name}"?\n\n'
          'Perhatian: Kategori yang memiliki tagihan tidak dapat dihapus.',
        ),
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
              
              final result = await ApiService.deleteFeeCategory(category.id);
              
              setState(() => _isLoading = false);
              
              if (result.success) {
                await _refreshCategories();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Kategori berhasil dihapus'),
                      backgroundColor: AppTheme.successColor,
                    ),
                  );
                }
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(result.error ?? 'Gagal menghapus kategori'),
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
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    if (!appState.isLoggedIn) {
      return const SizedBox.shrink();
    }

    final categories = appState.feeCategories;

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
                              'Kelola Tarif Pembayaran',
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            Text(
                              '${categories.length} kategori biaya',
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
                          onPressed: _refreshCategories,
                          icon: const Icon(Icons.refresh),
                          tooltip: 'Refresh',
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: _showAddCategoryDialog,
                          icon: const Icon(Icons.add),
                          label: const Text('Tambah Kategori'),
                        ),
                      ],
                    ),
                  ),

                  // Category grid
                  Expanded(
                    child: _isLoading && categories.isEmpty
                        ? const Center(child: CircularProgressIndicator())
                        : categories.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.category_outlined,
                                      size: 64,
                                      color: AppTheme.textMuted,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Belum ada kategori biaya',
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            color: AppTheme.textMuted,
                                          ),
                                    ),
                                  ],
                                ),
                              )
                            : GridView.builder(
                                padding: const EdgeInsets.all(24),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  childAspectRatio: 1.4,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                ),
                                itemCount: categories.length,
                                itemBuilder: (context, index) {
                                  final category = categories[index];
                                  return Container(
                                    decoration: BoxDecoration(
                                      color: AppTheme.cardBackground,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: category.isActive
                                            ? _getTypeColor(category.type).withValues(alpha: 0.3)
                                            : AppTheme.dividerColor.withValues(alpha: 0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(20),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(10),
                                                decoration: BoxDecoration(
                                                  color: _getTypeColor(category.type).withValues(alpha: 0.2),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Icon(
                                                  _getTypeIcon(category.type),
                                                  color: _getTypeColor(category.type),
                                                  size: 24,
                                                ),
                                              ),
                                              const Spacer(),
                                              if (!category.isActive)
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: AppTheme.textMuted.withValues(alpha: 0.2),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Text(
                                                    'Nonaktif',
                                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                          color: AppTheme.textMuted,
                                                        ),
                                                  ),
                                                ),
                                              PopupMenuButton<String>(
                                                icon: const Icon(Icons.more_vert),
                                                onSelected: (value) {
                                                  if (value == 'edit') {
                                                    _showEditCategoryDialog(category);
                                                  } else if (value == 'delete') {
                                                    _showDeleteConfirmation(category);
                                                  }
                                                },
                                                itemBuilder: (context) => [
                                                  const PopupMenuItem(
                                                    value: 'edit',
                                                    child: Row(
                                                      children: [
                                                        Icon(Icons.edit_outlined, size: 20),
                                                        SizedBox(width: 8),
                                                        Text('Edit'),
                                                      ],
                                                    ),
                                                  ),
                                                  const PopupMenuItem(
                                                    value: 'delete',
                                                    child: Row(
                                                      children: [
                                                        Icon(Icons.delete_outlined, size: 20, color: Colors.red),
                                                        SizedBox(width: 8),
                                                        Text('Hapus', style: TextStyle(color: Colors.red)),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            category.name,
                                            style: Theme.of(context).textTheme.titleMedium,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          if (category.description.isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              category.description,
                                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                    color: AppTheme.textMuted,
                                                  ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                          const Spacer(),
                                          Text(
                                            currencyFormatter.format(category.baseAmount),
                                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                                  color: AppTheme.accentPrimary,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: _getTypeColor(category.type).withValues(alpha: 0.1),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  category.typeDisplayName,
                                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                        color: _getTypeColor(category.type),
                                                      ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                '• ${category.frequencyDisplayName}',
                                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                      color: AppTheme.textMuted,
                                                    ),
                                              ),
                                            ],
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

  Color _getTypeColor(FeeType type) {
    switch (type) {
      case FeeType.akademik:
        return AppTheme.accentPrimary;
      case FeeType.nonAkademik:
        return AppTheme.successColor;
      case FeeType.insidental:
        return AppTheme.warningColor;
      case FeeType.administratif:
        return AppTheme.infoColor;
    }
  }

  IconData _getTypeIcon(FeeType type) {
    switch (type) {
      case FeeType.akademik:
        return Icons.school;
      case FeeType.nonAkademik:
        return Icons.sports_soccer;
      case FeeType.insidental:
        return Icons.event;
      case FeeType.administratif:
        return Icons.description;
    }
  }
}
