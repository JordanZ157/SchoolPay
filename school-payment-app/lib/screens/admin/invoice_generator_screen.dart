import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../routes/app_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/sidebar_menu.dart';
import '../../services/api_service.dart';

class InvoiceGeneratorScreen extends StatefulWidget {
  const InvoiceGeneratorScreen({super.key});

  @override
  State<InvoiceGeneratorScreen> createState() => _InvoiceGeneratorScreenState();
}

class _InvoiceGeneratorScreenState extends State<InvoiceGeneratorScreen> {
  String _currentRoute = '/admin/invoices';
  String? _selectedCategory;
  String _selectedClass = 'Semua';
  String _selectedMonth = 'Januari';
  String _selectedYear = DateTime.now().year.toString();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 30));
  bool _isGenerating = false;

  final List<String> _months = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];

  // Only allow current year and future years
  late final List<String> _years = [
    DateTime.now().year.toString(),
    (DateTime.now().year + 1).toString(),
  ];
  final List<String> _classes = ['Semua', 'X', 'XI', 'XII'];

  void _navigate(String route) {
    setState(() => _currentRoute = route);
    Navigator.pushNamed(context, route);
  }

  void _logout() {
    context.read<AppState>().logout();
    Navigator.pushReplacementNamed(context, AppRouter.login);
  }

  Future<void> _selectDueDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() => _dueDate = date);
    }
  }

  @override
  void initState() {
    super.initState();
    // Auto-load data when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = context.read<AppState>();
      appState.loadStudentsFromApi();
      appState.loadFeeCategoriesFromApi();
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    if (!appState.isLoggedIn) {
      return const SizedBox.shrink();
    }

    // Filter students by class if selected
    final filteredStudents = appState.allStudents.where((s) {
      if (_selectedClass == 'Semua') return true;
      return s.className.startsWith(_selectedClass);
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
                        Text(
                          'Generate Invoice',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ],
                    ),
                  ),

                  // Content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(32),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Form
                          Expanded(
                            flex: 2,
                            child: Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: AppTheme.cardBackground,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppTheme.dividerColor.withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Generate Invoice Rutin',
                                    style: Theme.of(context).textTheme.titleLarge,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Buat tagihan otomatis untuk siswa berdasarkan kategori dan periode',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: AppTheme.textMuted,
                                        ),
                                  ),
                                  const SizedBox(height: 24),

                                  // Category dropdown
                                  Text(
                                    'Kategori Pembayaran',
                                    style: Theme.of(context).textTheme.titleSmall,
                                  ),
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<String>(
                                    value: _selectedCategory,
                                    decoration: const InputDecoration(
                                      hintText: 'Pilih kategori',
                                    ),
                                    items: appState.feeCategories
                                        .map((cat) => DropdownMenuItem(
                                              value: cat.id,
                                              child: Text(cat.name),
                                            ))
                                        .toList(),
                                    onChanged: (value) => setState(() => _selectedCategory = value),
                                  ),

                                  const SizedBox(height: 16),

                                  // Period selection
                                  Text(
                                    'Periode',
                                    style: Theme.of(context).textTheme.titleSmall,
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: DropdownButtonFormField<String>(
                                          value: _selectedMonth,
                                          decoration: const InputDecoration(
                                            hintText: 'Bulan',
                                          ),
                                          items: _months
                                              .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                                              .toList(),
                                          onChanged: (value) => setState(() => _selectedMonth = value!),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: DropdownButtonFormField<String>(
                                          value: _selectedYear,
                                          decoration: const InputDecoration(
                                            hintText: 'Tahun',
                                          ),
                                          items: _years
                                              .map((y) => DropdownMenuItem(value: y, child: Text(y)))
                                              .toList(),
                                          onChanged: (value) => setState(() => _selectedYear = value!),
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 16),

                                  // Class filter
                                  Text(
                                    'Kelas',
                                    style: Theme.of(context).textTheme.titleSmall,
                                  ),
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<String>(
                                    value: _selectedClass,
                                    decoration: const InputDecoration(
                                      labelText: 'Kelas',
                                    ),
                                    items: _classes
                                        .map((c) => DropdownMenuItem(value: c, child: Text(c == 'Semua' ? 'Semua Kelas' : 'Kelas $c')))
                                        .toList(),
                                    onChanged: (value) => setState(() => _selectedClass = value ?? 'Semua'),
                                  ),

                                  const SizedBox(height: 16),

                                  // Due date selection
                                  Text(
                                    'Tanggal Jatuh Tempo',
                                    style: Theme.of(context).textTheme.titleSmall,
                                  ),
                                  const SizedBox(height: 8),
                                  InkWell(
                                    onTap: _selectDueDate,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                      decoration: BoxDecoration(
                                        color: AppTheme.surfaceColor,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: AppTheme.dividerColor.withValues(alpha: 0.3),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.calendar_today, size: 20),
                                          const SizedBox(width: 12),
                                          Text(
                                            '${_dueDate.day}/${_dueDate.month}/${_dueDate.year}',
                                            style: Theme.of(context).textTheme.bodyLarge,
                                          ),
                                          const Spacer(),
                                          const Icon(Icons.arrow_drop_down),
                                        ],
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 24),

                                  // Generate button
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: _selectedCategory == null || _isGenerating
                                          ? null
                                          : _generateInvoices,
                                      icon: _isGenerating
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Icon(Icons.auto_awesome),
                                      label: Text(_isGenerating ? 'Generating...' : 'Generate Invoice'),
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(width: 24),

                          // Preview
                          Expanded(
                            flex: 1,
                            child: Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: AppTheme.cardBackground,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppTheme.dividerColor.withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Preview',
                                    style: Theme.of(context).textTheme.titleLarge,
                                  ),
                                  const SizedBox(height: 24),
                                  
                                  _buildPreviewItem(
                                    'Kategori',
                                    _selectedCategory != null
                                        ? appState.feeCategories
                                            .firstWhere((c) => c.id == _selectedCategory)
                                            .name
                                        : '-',
                                  ),
                                  _buildPreviewItem('Periode', '$_selectedMonth $_selectedYear'),
                                  _buildPreviewItem('Kelas', _selectedClass == 'Semua' ? 'Semua Kelas' : 'Kelas $_selectedClass'),
                                  _buildPreviewItem(
                                    'Jumlah Siswa',
                                    filteredStudents.length.toString(),
                                  ),
                                  _buildPreviewItem(
                                    'Jatuh Tempo',
                                    '${_dueDate.day}/${_dueDate.month}/${_dueDate.year}',
                                  ),
                                  
                                  const SizedBox(height: 16),
                                  const Divider(color: AppTheme.dividerColor),
                                  const SizedBox(height: 16),
                                  
                                  Text(
                                    'Invoice yang akan dibuat:',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: AppTheme.textMuted,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${filteredStudents.length} invoice',
                                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                          color: AppTheme.accentPrimary,
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Future<void> _generateInvoices() async {
    if (_selectedCategory == null) return;
    
    setState(() => _isGenerating = true);
    
    final period = '$_selectedMonth $_selectedYear';
    final result = await ApiService.generateInvoices({
      'category_id': int.parse(_selectedCategory!),
      'period': period,
      'due_date': _dueDate.toIso8601String().split('T')[0],
      if (_selectedClass != null && _selectedClass != 'Semua')
        'class_name': _selectedClass,
    });
    
    setState(() => _isGenerating = false);
    
    if (mounted) {
      if (result.success) {
        final count = result.data?['count'] ?? 0;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '$count invoice untuk $period berhasil digenerate!',
            ),
            backgroundColor: AppTheme.successColor,
          ),
        );
        // Refresh invoices data
        context.read<AppState>().loadInvoicesFromApi();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.error ?? 'Gagal generate invoice'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }
}

