import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/app_state.dart';
import '../../routes/app_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/chat_bubble.dart';
import '../../models/user.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    // Role-specific welcome message
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = context.read<AppState>();
      final role = appState.currentUser?.role;
      
      if (role == UserRole.admin) {
        _addBotMessage(
          'Halo Admin! 👋 Saya adalah asisten pembayaran sekolah. Apa yang ingin Anda cek?',
          quickReplies: ['Cek tunggakan', 'Pemasukan hari ini', 'Laporan', 'Bantuan'],
        );
      } else if (role == UserRole.bendahara) {
        _addBotMessage(
          'Halo Bendahara! 👋 Saya siap membantu urusan pembayaran sekolah.',
          quickReplies: ['Cek tunggakan', 'Pemasukan', 'Laporan', 'Bantuan'],
        );
      } else if (role == UserRole.waliKelas) {
        _addBotMessage(
          'Halo Wali Kelas! 👋 Saya bisa membantu melihat status pembayaran siswa kelas Anda.',
          quickReplies: ['Tagihan kelas', 'Tunggakan kelas', 'Bantuan'],
        );
      } else {
        _addBotMessage(
          'Halo! 👋 Saya adalah asisten pembayaran sekolah. Ada yang bisa saya bantu?',
          quickReplies: ['Cek tagihan', 'Cek tunggakan', 'Cara bayar', 'Bantuan'],
        );
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _addBotMessage(String message, {List<String>? quickReplies}) {
    setState(() {
      _messages.add(ChatMessage(
        message: message,
        isUser: false,
        quickReplies: quickReplies,
      ));
    });
    _scrollToBottom();
  }

  void _addUserMessage(String message) {
    setState(() {
      _messages.add(ChatMessage(
        message: message,
        isUser: true,
      ));
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleMessage(String message) async {
    if (message.trim().isEmpty) return;

    _addUserMessage(message);
    _messageController.clear();

    setState(() => _isTyping = true);
    await Future.delayed(const Duration(milliseconds: 800));
    setState(() => _isTyping = false);

    _processIntent(message.toLowerCase());
  }

  void _processIntent(String message) {
    final appState = context.read<AppState>();
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    if (message.contains('tagihan') || message.contains('invoice') || message.contains('kelas')) {
      if (appState.currentUser?.role == UserRole.waliKelas) {
        // Wali kelas - show class invoices summary
        final classStudents = appState.allStudents
            .where((s) => appState.currentUser?.classId == null || s.className == appState.currentUser?.classId)
            .toList();
        final classInvoices = appState.allInvoices.where((i) => 
            classStudents.any((s) => s.id == i.studentId)).toList();
        final unpaidInvoices = classInvoices.where((i) => 
            i.status.name == 'unpaid' || i.status.name == 'partial').toList();
        final totalArrears = unpaidInvoices.fold(0.0, (sum, i) => sum + i.remainingAmount);
        
        if (unpaidInvoices.isEmpty) {
          _addBotMessage(
            '✅ Semua siswa di kelas Anda sudah lunas!',
            quickReplies: ['Lihat daftar siswa', 'Bantuan'],
          );
        } else {
          _addBotMessage(
            '📋 Kelas Anda memiliki ${unpaidInvoices.length} tagihan belum lunas dari ${classStudents.length} siswa.\n\nTotal tunggakan: ${currencyFormat.format(totalArrears)}',
            quickReplies: ['Lihat tagihan siswa', 'Bantuan'],
          );
        }
      } else if (appState.currentStudent != null) {
        final invoices = appState.getUnpaidInvoices();
        if (invoices.isEmpty) {
          _addBotMessage(
            '✅ Tidak ada tagihan yang belum dibayar. Semua lunas!',
            quickReplies: ['Riwayat pembayaran', 'Bantuan'],
          );
        } else {
          final total = invoices.fold(0.0, (sum, i) => sum + i.remainingAmount);
          String response = '📋 Kamu memiliki ${invoices.length} tagihan belum lunas:\n\n';
          for (var inv in invoices.take(3)) {
            response += '• ${inv.categoryName} (${inv.period}): ${currencyFormat.format(inv.remainingAmount)}\n';
          }
          response += '\nTotal: ${currencyFormat.format(total)}';
          _addBotMessage(
            response,
            quickReplies: ['Bayar sekarang', 'Detail tagihan', 'Bantuan'],
          );
        }
      } else if (appState.isAdmin) {
        _addBotMessage(
          '📊 Total tagihan belum lunas: ${currencyFormat.format(appState.totalArrears)} (${appState.arrearsCount} invoice)',
          quickReplies: ['Lihat laporan', 'Pemasukan bulan ini'],
        );
      }
    } else if (message.contains('tunggakan') || message.contains('belum bayar')) {
      if (appState.currentUser?.role == UserRole.waliKelas) {
        // Wali kelas - show class arrears
        final classStudents = appState.allStudents
            .where((s) => appState.currentUser?.classId == null || s.className == appState.currentUser?.classId)
            .toList();
        final classInvoices = appState.allInvoices.where((i) => 
            classStudents.any((s) => s.id == i.studentId)).toList();
        final unpaidInvoices = classInvoices.where((i) => 
            i.status.name == 'unpaid' || i.status.name == 'partial').toList();
        final totalArrears = unpaidInvoices.fold(0.0, (sum, i) => sum + i.remainingAmount);
        
        _addBotMessage(
          '⚠️ Total tunggakan kelas Anda: ${currencyFormat.format(totalArrears)}\n\nTerdapat ${unpaidInvoices.length} tagihan dari ${classStudents.length} siswa yang belum lunas.',
          quickReplies: ['Lihat tagihan siswa', 'Bantuan'],
        );
      } else if (appState.isAdmin) {
        _addBotMessage(
          '⚠️ Total tunggakan saat ini: ${currencyFormat.format(appState.totalArrears)}\n\nTerdapat ${appState.arrearsCount} invoice yang belum lunas.',
          quickReplies: ['Detail per siswa', 'Kirim pengingat'],
        );
      } else {
        final total = appState.totalUnpaid;
        if (total == 0) {
          _addBotMessage('✅ Tidak ada tunggakan. Semua pembayaran lunas!');
        } else {
          _addBotMessage(
            '⚠️ Total tunggakan kamu: ${currencyFormat.format(total)}',
            quickReplies: ['Bayar sekarang', 'Detail tagihan'],
          );
        }
      }
    } else if (message.contains('bayar')) {
      if (appState.currentStudent != null) {
        final invoices = appState.getUnpaidInvoices();
        if (invoices.isEmpty) {
          _addBotMessage('✅ Tidak ada tagihan yang perlu dibayar!');
        } else {
          _addBotMessage(
            '💳 Untuk membayar tagihan:\n\n1. Buka menu "Tagihan Saya"\n2. Pilih tagihan yang ingin dibayar\n3. Klik tombol "Bayar Sekarang"\n4. Pilih metode pembayaran\n5. Selesaikan pembayaran\n\nMau langsung ke halaman tagihan?',
            quickReplies: ['Ya, buka tagihan', 'Nanti saja'],
          );
        }
      } else {
        _addBotMessage(
          'Sebagai admin, Anda tidak bisa melakukan pembayaran. Gunakan menu Laporan untuk melihat status pembayaran.',
        );
      }
    } else if (message.contains('pemasukan') || message.contains('income')) {
      if (appState.isAdmin) {
        _addBotMessage(
          '💰 Ringkasan Pemasukan:\n\n• Hari ini: ${currencyFormat.format(appState.todayIncome)}\n• Bulan ini: ${currencyFormat.format(appState.monthIncome)}',
          quickReplies: ['Laporan detail', 'Tunggakan'],
        );
      }
    } else if (message.contains('riwayat') || message.contains('history')) {
      if (appState.currentStudent != null) {
        final transactions = appState.getMyTransactions();
        if (transactions.isEmpty) {
          _addBotMessage('Belum ada riwayat pembayaran.');
        } else {
          String response = '📜 Riwayat pembayaran terakhir:\n\n';
          for (var t in transactions.take(3)) {
            response += '• ${t.invoiceNumber}: ${currencyFormat.format(t.grossAmount)} ✓\n';
          }
          _addBotMessage(
            response,
            quickReplies: ['Lihat semua', 'Download bukti'],
          );
        }
      }
    } else if (message.contains('bantuan') || message.contains('help')) {
      _addBotMessage(
        '🤖 Saya bisa membantu Anda dengan:\n\n• Cek tagihan & tunggakan\n• Cara melakukan pembayaran\n• Riwayat pembayaran\n• Status transaksi\n\nSilakan ketik pertanyaan Anda!',
        quickReplies: ['Cek tagihan', 'Cek tunggakan', 'Cara bayar'],
      );
    } else if (message.contains('buka tagihan') || message.contains('ya')) {
      // Simulated navigation prompt
      _addBotMessage(
        '🔗 Silakan klik menu "Tagihan Saya" di sidebar untuk melihat dan membayar tagihan.',
      );
    } else if (message.contains('laporan') || message.contains('report')) {
      if (appState.isAdmin) {
        _addBotMessage(
          '📊 Silakan klik menu "Laporan" di sidebar untuk melihat laporan lengkap termasuk:\n\n• Ringkasan pemasukan\n• Daftar transaksi\n• Data tunggakan',
        );
      }
    } else {
      _addBotMessage(
        '🤔 Maaf, saya belum mengerti pertanyaan Anda. Coba gunakan kata kunci seperti:\n\n• "cek tagihan"\n• "tunggakan"\n• "cara bayar"\n• "riwayat"\n• "bantuan"',
        quickReplies: ['Cek tagihan', 'Tunggakan', 'Bantuan'],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      body: Column(
        children: [
          // App bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
            ),
            child: SafeArea(
              bottom: false,
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.smart_toy,
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
                          'SchoolPay Bot',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppTheme.successColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Online',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (_isTyping && index == _messages.length) {
                  return const TypingIndicator();
                }
                final message = _messages[index];
                return ChatBubble(
                  message: message.message,
                  isUser: message.isUser,
                  quickReplies: message.quickReplies,
                  onQuickReply: _handleMessage,
                );
              },
            ),
          ),

          // Input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cardBackground,
              border: Border(
                top: BorderSide(
                  color: AppTheme.dividerColor.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Ketik pesan...',
                        filled: true,
                        fillColor: AppTheme.surfaceColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      onSubmitted: _handleMessage,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    decoration: const BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: () => _handleMessage(_messageController.text),
                      icon: const Icon(Icons.send, color: Colors.white),
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

class ChatMessage {
  final String message;
  final bool isUser;
  final List<String>? quickReplies;

  ChatMessage({
    required this.message,
    required this.isUser,
    this.quickReplies,
  });
}
