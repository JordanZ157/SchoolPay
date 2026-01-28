import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import '../../services/api_service.dart';
import '../../providers/app_state.dart';
import '../../routes/app_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/sidebar_menu.dart';
import '../../constants/school_constants.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _currentRoute = '/admin/reports';
  
  // Ringkasan (Summary) data
  bool _isLoadingSummary = true;
  double _totalIncome = 0;
  double _totalArrears = 0;
  int _transactionCount = 0;
  List<Map<String, dynamic>> _categoryData = [];
  String? _summaryError;
  
  // Transaksi data
  bool _isLoadingTransactions = true;
  List<Map<String, dynamic>> _transactions = [];
  String? _transactionsError;
  
  // Tunggakan (Arrears) data
  bool _isLoadingArrears = true;
  List<Map<String, dynamic>> _arrearsStudents = [];
  String? _arrearsError;
  
  // Filter state
  String _sortOrder = 'newest'; // 'newest' or 'oldest'
  String _filterClass = 'Semua';
  
  final _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadSummaryData();
  }
  
  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }
  
  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    
    switch (_tabController.index) {
      case 0:
        if (_categoryData.isEmpty && !_isLoadingSummary) {
          _loadSummaryData();
        }
        break;
      case 1:
        if (_transactions.isEmpty && !_isLoadingTransactions) {
          _loadTransactionsData();
        } else if (_transactions.isEmpty) {
          _loadTransactionsData();
        }
        break;
      case 2:
        if (_arrearsStudents.isEmpty && !_isLoadingArrears) {
          _loadArrearsData();
        } else if (_arrearsStudents.isEmpty) {
          _loadArrearsData();
        }
        break;
    }
  }
  
  Future<void> _loadSummaryData() async {
    setState(() {
      _isLoadingSummary = true;
      _summaryError = null;
    });
    
    try {
      // Load daily report with 'all' to get all-time income
      final dailyResponse = await ApiService.getDailyReport(date: 'all');
      
      // Load arrears report for total arrears
      final arrearsResponse = await ApiService.getArrearsReport();
      
      if (dailyResponse.success && arrearsResponse.success) {
        final dailyData = dailyResponse.data!;
        final arrearsData = arrearsResponse.data!;
        
        setState(() {
          // Use allTimeIncome for total, or sum of transactions
          _totalIncome = (dailyData['allTimeIncome'] ?? dailyData['totalIncome'] ?? 0).toDouble();
          _transactionCount = dailyData['transactionCount'] ?? 0;
          _totalArrears = (arrearsData['summary']?['totalArrears'] ?? 0).toDouble();
          
          // Parse category data from byCategory
          final byCategory = dailyData['byCategory'];
          _categoryData = [];
          if (byCategory is Map<String, dynamic>) {
            _categoryData = byCategory.entries.map((e) {
              final value = e.value as Map<String, dynamic>;
              return {
                'name': e.key,
                'count': value['count'] ?? 0,
                'total': (value['total'] ?? 0).toDouble(),
              };
            }).toList();
          }
          
          _isLoadingSummary = false;
        });
      } else {
        setState(() {
          _summaryError = dailyResponse.error ?? arrearsResponse.error;
          _isLoadingSummary = false;
        });
      }
    } catch (e) {
      setState(() {
        _summaryError = 'Gagal memuat data: $e';
        _isLoadingSummary = false;
      });
    }
  }
  
  Future<void> _loadTransactionsData() async {
    setState(() {
      _isLoadingTransactions = true;
      _transactionsError = null;
    });
    
    try {
      // Load ALL transactions using date=all parameter
      final response = await ApiService.getDailyReport(date: 'all');
      
      if (response.success) {
        final data = response.data!;
        final transactions = data['transactions'] as List<dynamic>? ?? [];
        
        setState(() {
          _transactions = transactions.map((t) => Map<String, dynamic>.from(t)).toList();
          _isLoadingTransactions = false;
        });
      } else {
        setState(() {
          _transactionsError = response.error;
          _isLoadingTransactions = false;
        });
      }
    } catch (e) {
      setState(() {
        _transactionsError = 'Gagal memuat transaksi: $e';
        _isLoadingTransactions = false;
      });
    }
  }
  
  Future<void> _loadArrearsData() async {
    setState(() {
      _isLoadingArrears = true;
      _arrearsError = null;
    });
    
    try {
      final response = await ApiService.getArrearsReport();
      
      if (response.success) {
        final data = response.data!;
        final byStudent = data['byStudent'] as List<dynamic>? ?? [];
        
        setState(() {
          _arrearsStudents = byStudent.map((s) => Map<String, dynamic>.from(s)).toList();
          _isLoadingArrears = false;
        });
      } else {
        setState(() {
          _arrearsError = response.error;
          _isLoadingArrears = false;
        });
      }
    } catch (e) {
      setState(() {
        _arrearsError = 'Gagal memuat data tunggakan: $e';
        _isLoadingArrears = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredTransactions {
    var list = List<Map<String, dynamic>>.from(_transactions);
    
    // Filter by class
    if (_filterClass != 'Semua') {
      list = list.where((tx) {
        final className = tx['className'] ?? '';
        return className.toString().startsWith(_filterClass);
      }).toList();
    }
    
    // Sort by date
    list.sort((a, b) {
      final dateA = DateTime.tryParse(a['settlementTime'] ?? '') ?? DateTime(2000);
      final dateB = DateTime.tryParse(b['settlementTime'] ?? '') ?? DateTime(2000);
      return _sortOrder == 'newest' ? dateB.compareTo(dateA) : dateA.compareTo(dateB);
    });
    
    return list;
  }

  List<Map<String, dynamic>> get _filteredArrears {
    var list = List<Map<String, dynamic>>.from(_arrearsStudents);
    
    // Filter by class
    if (_filterClass != 'Semua') {
      list = list.where((student) {
        final className = student['className'] ?? '';
        return className.toString().startsWith(_filterClass);
      }).toList();
    }
    
    // Sort by due date
    list.sort((a, b) {
      final dateA = DateTime.tryParse(a['oldestDueDate'] ?? '') ?? DateTime(2000);
      final dateB = DateTime.tryParse(b['oldestDueDate'] ?? '') ?? DateTime(2000);
      return _sortOrder == 'newest' ? dateB.compareTo(dateA) : dateA.compareTo(dateB);
    });
    
    return list;
  }
  
  Future<void> _exportReport() async {
    String type = 'daily';
    if (_tabController.index == 2) {
      type = 'arrears';
    }
    
    final response = await ApiService.exportReport(type: type);
    
    if (response.success && mounted) {
      final data = response.data!;
      final headers = List<String>.from(data['headers'] ?? []);
      final rows = List<List<dynamic>>.from(data['rows'] ?? []);
      final filename = data['filename'] ?? 'export_${DateTime.now().toIso8601String()}.csv';
      
      // Generate CSV content
      final csvContent = StringBuffer();
      csvContent.writeln(headers.join(','));
      for (final row in rows) {
        csvContent.writeln(row.map((cell) => '"$cell"').join(','));
      }
      
      // Download file directly
      final bytes = utf8.encode(csvContent.toString());
      final blob = html.Blob([bytes], 'text/csv');
      final url = html.Url.createObjectUrlFromBlob(blob);
      
      html.AnchorElement(href: url)
        ..setAttribute('download', filename)
        ..click();
      
      html.Url.revokeObjectUrl(url);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('File $filename berhasil didownload'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.error ?? 'Gagal export'),
          backgroundColor: Colors.red,
        ),
      );
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
    
    if (!appState.isLoggedIn) {
      return const SizedBox.shrink();
    }
    
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
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
            child: Column(
              children: [
                _buildHeader(),
                _buildTabBar(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildSummaryTab(),
                      _buildTransactionsTab(),
                      _buildArrearsTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          const SizedBox(width: 16),
          const Text(
            'Laporan',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: _exportReport,
            icon: const Icon(Icons.download, size: 18),
            label: const Text('Export'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C5CE7),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: TabBar(
        controller: _tabController,
        labelColor: const Color(0xFF6C5CE7),
        unselectedLabelColor: Colors.white54,
        indicatorColor: const Color(0xFF6C5CE7),
        tabs: const [
          Tab(text: 'Ringkasan'),
          Tab(text: 'Transaksi'),
          Tab(text: 'Tunggakan'),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          // Sort dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E2E),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _sortOrder,
                dropdownColor: const Color(0xFF1E1E2E),
                icon: const Icon(Icons.arrow_drop_down, color: Colors.white54),
                items: const [
                  DropdownMenuItem(value: 'newest', child: Text('Terbaru', style: TextStyle(color: Colors.white))),
                  DropdownMenuItem(value: 'oldest', child: Text('Terlama', style: TextStyle(color: Colors.white))),
                ],
                onChanged: (value) => setState(() => _sortOrder = value ?? 'newest'),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Class filter dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E2E),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _filterClass,
                dropdownColor: const Color(0xFF1E1E2E),
                icon: const Icon(Icons.arrow_drop_down, color: Colors.white54),
                items: ['Semua', ...SchoolConstants.classes].map((c) => DropdownMenuItem(
                  value: c,
                  child: Text(c == 'Semua' ? 'Semua Kelas' : 'Kelas $c', style: const TextStyle(color: Colors.white)),
                )).toList(),
                onChanged: (value) => setState(() => _filterClass = value ?? 'Semua'),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSummaryTab() {
    if (_isLoadingSummary) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF6C5CE7)),
      );
    }
    
    if (_summaryError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade300, size: 48),
            const SizedBox(height: 16),
            Text(_summaryError!, style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadSummaryData,
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Cards
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  icon: Icons.trending_up,
                  iconColor: Colors.green,
                  title: 'Total Pemasukan',
                  value: _currencyFormat.format(_totalIncome),
                  subtitle: 'Semua waktu',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  icon: Icons.warning_amber,
                  iconColor: Colors.orange,
                  title: 'Total Tunggakan',
                  value: _currencyFormat.format(_totalArrears),
                  subtitle: 'Belum dibayar',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  icon: Icons.check_circle,
                  iconColor: const Color(0xFF6C5CE7),
                  title: 'Transaksi Sukses',
                  value: _transactionCount.toString(),
                  subtitle: 'Total transaksi',
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          
          // Category breakdown
          const Text(
            'Pemasukan per Kategori',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          if (_categoryData.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E2E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text(
                  'Belum ada transaksi hari ini',
                  style: TextStyle(color: Colors.white54),
                ),
              ),
            )
          else
            ..._categoryData.map((category) => _buildCategoryRow(
              name: category['name'] ?? 'Unknown',
              count: category['count'] ?? 0,
              total: (category['total'] ?? 0).toDouble(),
            )),
        ],
      ),
    );
  }
  
  Widget _buildSummaryCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCategoryRow({
    required String name,
    required int count,
    required double total,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
              ),
              Text(
                '$count transaksi',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
          Text(
            _currencyFormat.format(total),
            style: const TextStyle(
              color: Color(0xFF6C5CE7),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTransactionsTab() {
    if (_isLoadingTransactions) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF6C5CE7)),
      );
    }
    
    if (_transactionsError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade300, size: 48),
            const SizedBox(height: 16),
            Text(_transactionsError!, style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadTransactionsData,
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }
    
    final filtered = _filteredTransactions;
    
    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, color: Colors.white.withOpacity(0.3), size: 64),
            const SizedBox(height: 16),
            const Text(
              'Belum ada transaksi pembayaran',
              style: TextStyle(color: Colors.white54, fontSize: 16),
            ),
          ],
        ),
      );
    }
    
    return Column(
      children: [
        _buildFilterBar(),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final tx = filtered[index];
              return _buildTransactionItem(tx);
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildTransactionItem(Map<String, dynamic> tx) {
    final amount = (tx['amount'] ?? 0).toDouble();
    final settlementTime = tx['settlementTime'] != null 
        ? DateTime.tryParse(tx['settlementTime']) 
        : null;
    final invoiceId = tx['invoiceId']?.toString();
    final className = tx['className'] ?? '';
    
    return InkWell(
      onTap: () => _showTransactionDetailDialog(tx),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E2E),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.check_circle, color: Colors.green, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tx['studentName'] ?? 'Unknown',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${className.isNotEmpty ? '$className • ' : ''}${tx['categoryName'] ?? ''} • ${tx['invoiceNumber'] ?? ''}',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  if (settlementTime != null)
                    Text(
                      DateFormat('dd MMM yyyy, HH:mm').format(settlementTime),
                      style: const TextStyle(color: Colors.white38, fontSize: 11),
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _currencyFormat.format(amount),
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                const Icon(Icons.chevron_right, color: Colors.white38, size: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showTransactionDetailDialog(Map<String, dynamic> tx) {
    final amount = (tx['amount'] ?? 0).toDouble();
    final settlementTime = tx['settlementTime'] != null 
        ? DateTime.tryParse(tx['settlementTime']) 
        : null;
    final invoiceId = tx['invoiceId']?.toString();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.check_circle, color: Colors.green, size: 24),
            ),
            const SizedBox(width: 12),
            const Text('Detail Transaksi', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Status', 'Berhasil', valueColor: Colors.green),
              _buildDetailRow('Nama Siswa', tx['studentName'] ?? '-'),
              _buildDetailRow('Kelas', tx['className'] ?? '-'),
              _buildDetailRow('Kategori', tx['categoryName'] ?? '-'),
              _buildDetailRow('No. Invoice', tx['invoiceNumber'] ?? '-'),
              _buildDetailRow('Metode Pembayaran', tx['paymentType'] ?? '-'),
              _buildDetailRow('Jumlah', _currencyFormat.format(amount), valueColor: Colors.green),
              if (settlementTime != null)
                _buildDetailRow('Waktu Pembayaran', DateFormat('dd MMMM yyyy, HH:mm').format(settlementTime)),
              _buildDetailRow('Order ID', tx['orderId'] ?? '-'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
          if (invoiceId != null && invoiceId.isNotEmpty)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRouter.invoiceDetail, arguments: invoiceId);
              },
              child: const Text('Lihat Tagihan'),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor ?? Colors.white,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildArrearsTab() {
    if (_isLoadingArrears) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF6C5CE7)),
      );
    }
    
    if (_arrearsError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade300, size: 48),
            const SizedBox(height: 16),
            Text(_arrearsError!, style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadArrearsData,
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }
    
    final filtered = _filteredArrears;
    
    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.celebration, color: Colors.green.withOpacity(0.5), size: 64),
            const SizedBox(height: 16),
            const Text(
              'Tidak ada tunggakan! 🎉',
              style: TextStyle(color: Colors.white54, fontSize: 16),
            ),
          ],
        ),
      );
    }
    
    return Column(
      children: [
        _buildFilterBar(),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final student = filtered[index];
              return _buildArrearsItem(student);
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildArrearsItem(Map<String, dynamic> student) {
    final totalArrears = (student['totalArrears'] ?? 0).toDouble();
    final invoiceCount = student['invoiceCount'] ?? 0;
    final oldestDueDate = student['oldestDueDate'] != null 
        ? DateTime.tryParse(student['oldestDueDate']) 
        : null;
    final isOverdue = oldestDueDate != null && oldestDueDate.isBefore(DateTime.now());
    final invoices = student['invoices'] as List<dynamic>? ?? [];
    final firstInvoiceId = invoices.isNotEmpty ? invoices.first['id']?.toString() : null;
    
    return InkWell(
      onTap: firstInvoiceId != null ? () {
        Navigator.pushNamed(context, AppRouter.invoiceDetail, arguments: firstInvoiceId);
      } : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E2E),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (isOverdue ? Colors.red : Colors.orange).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isOverdue ? Icons.error : Icons.schedule,
                color: isOverdue ? Colors.red : Colors.orange,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student['name'] ?? 'Unknown',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${student['className'] ?? ''} • $invoiceCount tagihan',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  if (oldestDueDate != null)
                    Text(
                      'Jatuh tempo: ${DateFormat('dd MMM yyyy').format(oldestDueDate)}',
                      style: TextStyle(
                        color: isOverdue ? Colors.red.shade300 : Colors.white38,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _currencyFormat.format(totalArrears),
                  style: TextStyle(
                    color: isOverdue ? Colors.red : Colors.orange,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                if (firstInvoiceId != null)
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, AppRouter.invoiceDetail, arguments: firstInvoiceId);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentPrimary,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      minimumSize: const Size(0, 0),
                    ),
                    child: const Text('Bayar', style: TextStyle(fontSize: 12)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
