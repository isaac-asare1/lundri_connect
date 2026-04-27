import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/user_provider.dart';

class LiveChatScreen extends StatefulWidget {
  final String role;
  const LiveChatScreen({super.key, required this.role});

  @override
  State<LiveChatScreen> createState() => _LiveChatScreenState();
}

class _LiveChatScreenState extends State<LiveChatScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isSending = false;

  String get _uid => _auth.currentUser?.uid ?? '';

  String get _role {
    // final user = context.read<UserProvider>().currentUser;
    return widget.role;
  }

  CollectionReference<Map<String, dynamic>> get _chatRef {
    final collection = _role == 'rider' ? 'riders' : 'laundries';

    return _firestore
        .collection(collection)
        .doc(_uid)
        .collection('support chat');
  }

  bool get _canSend => !_isSending && _messageController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _messageController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();

    if (text.isEmpty || _uid.isEmpty || _isSending) return;

    setState(() => _isSending = true);

    try {
      final user = context.read<UserProvider>().currentUser;

      await _chatRef.add({
        'senderId': _uid,
        'senderRole': _role,
        'senderName': user?.fullName ?? 'User',
        'receiverRole': 'support',
        'messageType': 'text',
        'text': text,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await _firestore
          .collection(_role == 'rider' ? 'riders' : 'laundries')
          .doc(_uid)
          .set({
            'supportChatMeta': {
              'lastMessage': text,
              'lastMessageAt': FieldValue.serverTimestamp(),
              'lastMessageSenderId': _uid,
              'lastMessageSenderRole': _role,
              'hasUnreadSupportReply': false,
            },
            'timestamps': {'updatedAt': FieldValue.serverTimestamp()},
          }, SetOptions(merge: true));

      _messageController.clear();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    } catch (e) {
      _showSnackBar('Could not send message');
      debugPrint('Send support message error: $e');
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _scrollToBottom() async {
    if (!_scrollController.hasClients) return;

    await _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  Stream<List<SupportChatMessage>> _messageStream() {
    return _chatRef
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => SupportChatMessage.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  @override
  Widget build(BuildContext context) {
    if (_uid.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('No signed-in user found')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5F5),
        elevation: 0,
        foregroundColor: Colors.black87,
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                color: Color(0xFFE36C9A),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.support_agent_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Lundri Support',
                style: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Column(
              children: [
                Expanded(
                  child: StreamBuilder<List<SupportChatMessage>>(
                    stream: _messageStream(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting &&
                          !snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return const Center(
                          child: Text('Failed to load support chat'),
                        );
                      }

                      final messages = snapshot.data ?? [];

                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _scrollToBottom();
                      });

                      if (messages.isEmpty) {
                        return const _EmptySupportChatView();
                      }

                      return ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(10, 14, 10, 110),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          final previous = index > 0
                              ? messages[index - 1]
                              : null;

                          final isMine = message.senderId == _uid;

                          final showDaySeparator =
                              previous == null ||
                              !_isSameDay(
                                previous.createdAt ?? DateTime.now(),
                                message.createdAt ?? DateTime.now(),
                              );

                          final isFirstSequence =
                              previous == null ||
                              previous.senderId != message.senderId ||
                              !_isSameDay(
                                previous.createdAt ?? DateTime.now(),
                                message.createdAt ?? DateTime.now(),
                              );

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (showDaySeparator)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    top: 18,
                                    bottom: 14,
                                  ),
                                  child: Center(
                                    child: Text(
                                      _formatDaySeparator(
                                        message.createdAt ?? DateTime.now(),
                                      ),
                                      style: const TextStyle(
                                        color: Color(0xFF9E9E9E),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                              _SupportMessageBubble(
                                message: message,
                                isMine: isMine,
                                isFirstSequence: isFirstSequence,
                                showSenderLabel: !isMine && isFirstSequence,
                                timestamp: _formatTimestamp(
                                  message.createdAt ?? DateTime.now(),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _SupportMessageInputBar(
              controller: _messageController,
              onSend: _sendMessage,
              isSending: _isSending,
              canSend: _canSend,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime dt) {
    return DateFormat('HH:mm').format(dt);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isYesterday(DateTime date) {
    final now = DateTime.now();
    final yesterday = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 1));

    return DateTime(date.year, date.month, date.day) == yesterday;
  }

  bool _isToday(DateTime date) {
    return _isSameDay(DateTime.now(), date);
  }

  String _formatDaySeparator(DateTime date) {
    if (_isToday(date)) return 'Today';
    if (_isYesterday(date)) return 'Yesterday';
    return DateFormat('MMMM d, y').format(date);
  }

  void _showSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }
}

class SupportChatMessage {
  final String id;
  final String senderId;
  final String senderRole;
  final String senderName;
  final String receiverRole;
  final String messageType;
  final String text;
  final bool isRead;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const SupportChatMessage({
    required this.id,
    required this.senderId,
    required this.senderRole,
    required this.senderName,
    required this.receiverRole,
    required this.messageType,
    required this.text,
    required this.isRead,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SupportChatMessage.fromMap(String id, Map<String, dynamic> map) {
    return SupportChatMessage(
      id: id,
      senderId: (map['senderId'] ?? '').toString(),
      senderRole: (map['senderRole'] ?? '').toString(),
      senderName: (map['senderName'] ?? '').toString(),
      receiverRole: (map['receiverRole'] ?? '').toString(),
      messageType: (map['messageType'] ?? 'text').toString(),
      text: (map['text'] ?? '').toString(),
      isRead: map['isRead'] == true,
      createdAt: _parseDateTime(map['createdAt']),
      updatedAt: _parseDateTime(map['updatedAt']),
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}

class _EmptySupportChatView extends StatelessWidget {
  const _EmptySupportChatView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.support_agent_rounded,
              size: 58,
              color: AppColors.iconMuted,
            ),
            SizedBox(height: 14),
            Text(
              'No messages yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Send a message to the Lundri support team.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SupportMessageBubble extends StatelessWidget {
  final SupportChatMessage message;
  final bool isMine;
  final bool isFirstSequence;
  final bool showSenderLabel;
  final String timestamp;

  const _SupportMessageBubble({
    required this.message,
    required this.isMine,
    required this.isFirstSequence,
    required this.showSenderLabel,
    required this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    final bubbleColor = isMine
        ? const Color(0xFFDDF4FB)
        : const Color(0xFFE2E5EA);

    final timeColor = isMine
        ? const Color(0xFF2AAFC9)
        : const Color(0xFF9E9E9E);

    final margin = EdgeInsets.only(
      top: isFirstSequence ? 6 : 2,
      bottom: 2,
      left: isMine ? 72 : 12,
      right: isMine ? 12 : 72,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Container(
        margin: margin,
        child: Column(
          crossAxisAlignment: isMine
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            if (showSenderLabel)
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircleAvatar(
                      radius: 10,
                      backgroundColor: Color(0xFFE36C9A),
                      child: Icon(
                        Icons.support_agent_rounded,
                        color: Colors.white,
                        size: 11,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      message.senderName.trim().isEmpty
                          ? 'Support'
                          : message.senderName,
                      style: const TextStyle(
                        color: Color(0xFF8B8B8B),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            Align(
              alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.76,
                ),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                decoration: BoxDecoration(
                  color: bubbleColor,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(20),
                    topRight: const Radius.circular(20),
                    bottomLeft: Radius.circular(isMine ? 20 : 6),
                    bottomRight: Radius.circular(isMine ? 6 : 20),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Align(
                      alignment: isMine
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Text(
                        message.text,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF202020),
                          fontWeight: FontWeight.w500,
                          height: 1.28,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          timestamp,
                          style: TextStyle(
                            fontSize: 12,
                            color: timeColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (isMine) ...[
                          const SizedBox(width: 4),
                          Icon(
                            message.isRead
                                ? Icons.done_all_rounded
                                : Icons.done_rounded,
                            size: 17,
                            color: const Color(0xFF2AAFC9),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SupportMessageInputBar extends StatelessWidget {
  final TextEditingController controller;
  final Future<void> Function() onSend;
  final bool isSending;
  final bool canSend;

  const _SupportMessageInputBar({
    required this.controller,
    required this.onSend,
    required this.isSending,
    required this.canSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF2F2F2),
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 14),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: const Color(0xFFE5E5E5)),
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 120),
                  child: TextField(
                    controller: controller,
                    minLines: 1,
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Message support',
                      hintStyle: TextStyle(
                        color: Color(0xFF9B9B9B),
                        fontSize: 17,
                        fontWeight: FontWeight.w400,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 15,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: canSend ? onSend : null,
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: canSend
                      ? const Color(0xFFE8F7FC)
                      : const Color(0xFFE6E6E6),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: isSending
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          Icons.send_rounded,
                          size: 26,
                          color: canSend
                              ? const Color(0xFFE36C9A)
                              : const Color(0xFFB8B8B8),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
