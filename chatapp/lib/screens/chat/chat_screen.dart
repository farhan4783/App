import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import '../../models/message_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../services/socket_service.dart';
import '../../services/chat_service.dart';
import '../../core/theme/app_colors.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String chatId;
  final String chatName;

  const ChatScreen({super.key, required this.chatId, required this.chatName});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _textCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  Timer? _typingTimer;
  bool _isTyping = false;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _textCtrl.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    _typingTimer?.cancel();
    super.dispose();
  }

  void _onTextChanged() {
    final socket = ref.read(socketServiceProvider);
    if (_textCtrl.text.isNotEmpty && !_isTyping) {
      _isTyping = true;
      socket.sendTyping(widget.chatId, true);
    }
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      _isTyping = false;
      socket.sendTyping(widget.chatId, false);
    });
  }

  void _sendText() {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;
    _textCtrl.clear();
    _isTyping = false;
    ref.read(socketServiceProvider).sendMessage(chatId: widget.chatId, text: text, type: 'TEXT');
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 60);
    if (file == null) return;

    setState(() => _uploading = true);
    try {
      final url = await ref.read(chatServiceProvider).uploadMedia(file.path, 'image/jpeg');
      if (url != null) {
        ref.read(socketServiceProvider).sendMessage(
          chatId: widget.chatId,
          type: 'IMAGE',
          mediaUrl: url,
          fileName: file.name,
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Upload failed')));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(messagesProvider(widget.chatId));
    final currentUserId = ref.watch(currentUserProvider)?.id ?? '';
    final typingUsers = ref.watch(typingUsersProvider(widget.chatId));
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Auto-scroll when new messages arrive
    ref.listen(messagesProvider(widget.chatId), (_, __) => _scrollToBottom());

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: cs.primary.withOpacity(0.15),
              child: Text(
                widget.chatName.isNotEmpty ? widget.chatName[0].toUpperCase() : '?',
                style: TextStyle(color: cs.primary, fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.chatName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                typingUsers.when(
                  data: (users) {
                    final typing = users.keys.where((id) => id != currentUserId).isNotEmpty;
                    return Text(
                      typing ? 'typing...' : 'online',
                      style: TextStyle(fontSize: 11, color: typing ? cs.primary : cs.onBackground.withOpacity(0.4)),
                    );
                  },
                  loading: () => const SizedBox(),
                  error: (_, __) => const SizedBox(),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: messages.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (msgs) {
                if (msgs.isEmpty) {
                  return Center(
                    child: Text('Say hello! 👋', style: TextStyle(color: cs.onSurface.withOpacity(0.3))),
                  );
                }
                return ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: msgs.length,
                  itemBuilder: (ctx, i) => _MessageBubble(
                    message: msgs[i],
                    isMine: msgs[i].senderId == currentUserId,
                    isDark: isDark,
                    showDate: i == 0 || !_sameDay(msgs[i - 1].sentAt, msgs[i].sentAt),
                  ),
                );
              },
            ),
          ),

          // Input bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? AppColors.bgDarkCard : AppColors.bgLightCard,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.add_photo_alternate_outlined, color: cs.primary),
                    onPressed: _uploading ? null : _pickImage,
                  ),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.bgDarkSurface : AppColors.bgLightSurface,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _textCtrl,
                        maxLines: 4,
                        minLines: 1,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          hintText: 'Message...',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                        onSubmitted: (_) => _sendText(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: _sendText,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(color: cs.primary, shape: BoxShape.circle),
                      child: _uploading
                          ? const Padding(
                              padding: EdgeInsets.all(10),
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
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

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMine;
  final bool isDark;
  final bool showDate;

  const _MessageBubble({
    required this.message,
    required this.isMine,
    required this.isDark,
    required this.showDate,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bubbleColor = isMine
        ? (isDark ? AppColors.bubbleSentDark : AppColors.bubbleSentLight)
        : (isDark ? AppColors.bubbleReceivedDark : AppColors.bubbleReceivedLight);

    final textColor = isMine
        ? (isDark ? Colors.white : const Color(0xFF1A2232))
        : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight);

    return Column(
      children: [
        if (showDate)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: cs.onSurface.withOpacity(0.07),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _formatDate(message.sentAt),
                style: TextStyle(fontSize: 11, color: cs.onSurface.withOpacity(0.4)),
              ),
            ),
          ),
        Align(
          alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: EdgeInsets.only(
              bottom: 6,
              left: isMine ? 64 : 0,
              right: isMine ? 0 : 64,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: bubbleColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                )
              ],
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: isMine ? const Radius.circular(20) : const Radius.circular(6),
                bottomRight: isMine ? const Radius.circular(6) : const Radius.circular(20),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (message.type == MessageType.image && message.mediaUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(message.mediaUrl!, width: 220, fit: BoxFit.cover),
                  )
                else if (message.type == MessageType.file)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.insert_drive_file_rounded, color: textColor, size: 20),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          message.fileName ?? 'File',
                          style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  )
                else
                  Text(message.text ?? '', style: TextStyle(color: textColor, fontSize: 15, height: 1.3)),

                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTime(message.sentAt),
                      style: TextStyle(fontSize: 10, color: textColor.withOpacity(0.6)),
                    ),
                    if (isMine) ...[
                      const SizedBox(width: 4),
                      Icon(
                        message.status == MsgStatus.read
                            ? Icons.done_all
                            : message.status == MsgStatus.delivered
                                ? Icons.done_all
                                : Icons.done,
                        size: 14,
                        color: message.status == MsgStatus.read
                            ? AppColors.read
                            : textColor.withOpacity(0.5),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) return 'Today';
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day - 1) return 'Yesterday';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
