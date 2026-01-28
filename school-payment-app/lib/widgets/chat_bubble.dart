import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ChatBubble extends StatelessWidget {
  final String message;
  final bool isUser;
  final DateTime? timestamp;
  final List<String>? quickReplies;
  final Function(String)? onQuickReply;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isUser,
    this.timestamp,
    this.quickReplies,
    this.onQuickReply,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isUser) ...[
                Container(
                  width: 32,
                  height: 32,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.smart_toy,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ],
              Flexible(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.6,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isUser ? AppTheme.accentPrimary : AppTheme.cardBackground,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isUser ? 16 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 16),
                    ),
                    border: isUser
                        ? null
                        : Border.all(
                            color: AppTheme.dividerColor.withValues(alpha: 0.3),
                            width: 1,
                          ),
                  ),
                  child: Text(
                    message,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isUser ? Colors.white : AppTheme.textPrimary,
                          height: 1.4,
                        ),
                  ),
                ),
              ),
              if (isUser) ...[
                Container(
                  width: 32,
                  height: 32,
                  margin: const EdgeInsets.only(left: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: AppTheme.textSecondary,
                    size: 18,
                  ),
                ),
              ],
            ],
          ),
          
          // Quick replies
          if (quickReplies != null && quickReplies!.isNotEmpty && !isUser) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 40),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: quickReplies!.map((reply) {
                  return InkWell(
                    onTap: () => onQuickReply?.call(reply),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.accentPrimary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppTheme.accentPrimary.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        reply,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.accentPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.smart_toy,
              color: Colors.white,
              size: 18,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.cardBackground,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(16),
              ),
              border: Border.all(
                color: AppTheme.dividerColor.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (index) {
                    final delay = index * 0.2;
                    final animValue = (_controller.value + delay) % 1.0;
                    final opacity = (1.0 - (animValue - 0.5).abs() * 2).clamp(0.3, 1.0);
                    
                    return Container(
                      margin: EdgeInsets.only(right: index < 2 ? 4 : 0),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppTheme.textMuted.withValues(alpha: opacity),
                        shape: BoxShape.circle,
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
