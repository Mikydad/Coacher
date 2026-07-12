import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/presentation/keyboard_dismiss.dart';
import '../../../../core/utils/stable_id.dart';
import '../../application/circle_providers.dart';
import '../../data/circle_proof_storage.dart';
import '../../domain/models/circle_enums.dart';
import '../../domain/models/circle_message.dart';
import '../widgets/full_screen_image_viewer.dart';

import '../../../../core/presentation/app_colors.dart';
import '../../../../core/presentation/async_value_ui.dart';

const _kPresetEmojis = ['🔥', '💪', '👏', '✅', '😅', '❤️'];

const _kProofCategories = [
  'Workout',
  'Study',
  'Meal',
  'Milestone',
  'Goal Progress',
];

class CircleChatView extends ConsumerStatefulWidget {
  const CircleChatView({super.key, required this.circleId});

  final String circleId;

  @override
  ConsumerState<CircleChatView> createState() => _CircleChatViewState();
}

class _CircleChatViewState extends ConsumerState<CircleChatView> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  bool _sending = false;

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendText() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _textController.clear();
    dismissKeyboard(context);

    final msg = CircleMessage(
      id: StableId.generate('msg'),
      circleId: widget.circleId,
      senderId: user.uid,
      senderDisplayName: user.displayName ?? 'User',
      type: MessageType.text,
      content: text,
      createdAtMs: DateTime.now().millisecondsSinceEpoch,
    );
    // Optimistic send: the message list's snapshot listener echoes the local
    // write instantly, and Firestore's own offline queue delivers it when a
    // connection exists — the composer never waits on a server ack. A genuine
    // rejection (e.g. rules) surfaces as a snackbar with the text restored.
    unawaited(
      ref.read(circleMessageRepositoryProvider).sendMessage(msg).catchError((
        Object _,
      ) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Message not delivered.')));
        if (_textController.text.trim().isEmpty) {
          _textController.text = text; // restore for retry
        }
      }),
    );
  }

  Future<void> _pickAndSendImage() async {
    final category = await _showProofCategorySheet();
    if (category == null || !mounted) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 1080,
    );
    if (picked == null || !mounted) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _sending = true);
    try {
      final file = File(picked.path);
      final url = await ref
          .read(circleProofStorageProvider)
          .uploadChatProof(
            circleId: widget.circleId,
            userId: user.uid,
            file: file,
            mimeType: picked.mimeType,
            sourcePath: picked.path,
          );

      final msg = CircleMessage(
        id: StableId.generate('msg'),
        circleId: widget.circleId,
        senderId: user.uid,
        senderDisplayName: user.displayName ?? 'User',
        type: MessageType.image,
        content: category, // store proof category as content
        imageUrl: url,
        createdAtMs: DateTime.now().millisecondsSinceEpoch,
      );
      await ref.read(circleMessageRepositoryProvider).sendMessage(msg);
    } catch (e, st) {
      debugPrint('Circle chat image upload failed: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(circleProofUploadErrorMessage(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<String?> _showProofCategorySheet() {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.fg.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Proof category',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              ..._kProofCategories.map(
                (cat) => ListTile(
                  title: Text(
                    cat,
                    style: TextStyle(color: AppColors.textPrimary),
                  ),
                  onTap: () => Navigator.pop(ctx, cat),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _toggleReaction(CircleMessage message, String emoji) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final current = Map<String, List<String>>.from(
      message.reactions.map((k, v) => MapEntry(k, List<String>.from(v))),
    );

    final users = current[emoji] ?? [];
    if (users.contains(uid)) {
      users.remove(uid);
      if (users.isEmpty) current.remove(emoji);
    } else {
      users.add(uid);
      current[emoji] = users;
    }

    await ref
        .read(circleMessageRepositoryProvider)
        .updateReactions(widget.circleId, message.id, current);
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(circleMessagesProvider(widget.circleId));

    return Column(
      children: [
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => dismissKeyboard(context),
            child: messagesAsync.when(
              loading: () => Center(
                child: CircularProgressIndicator(color: AppColors.accent),
              ),
              error: (e, _) => swallowedAsyncError(
                'circle_chat_view',
                e,
                Center(
                  child: Text(
                    'Could not load messages.',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                ),
              ),
              data: (messages) {
                if (messages.isEmpty) {
                  return Center(
                    child: Text(
                      'No messages yet.\nSay hello to your circle!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 15,
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  itemCount: messages.length,
                  itemBuilder: (_, i) {
                    final msg = messages[i];
                    if (msg.type == MessageType.systemEvent) {
                      return _SystemEventPill(msg.content ?? '');
                    }
                    if (msg.type == MessageType.image) {
                      return _ImageMessageBubble(
                        message: msg,
                        onReaction: (emoji) => _toggleReaction(msg, emoji),
                      );
                    }
                    return _TextMessageBubble(
                      message: msg,
                      onReaction: (emoji) => _toggleReaction(msg, emoji),
                    );
                  },
                );
              },
            ),
          ),
        ),
        _InputBar(
          controller: _textController,
          sending: _sending,
          onSend: _sendText,
          onPickImage: _pickAndSendImage,
        ),
      ],
    );
  }
}

// ── Message bubbles ───────────────────────────────────────────────────────────

class _TextMessageBubble extends StatelessWidget {
  const _TextMessageBubble({required this.message, required this.onReaction});

  final CircleMessage message;
  final ValueChanged<String> onReaction;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final isMe = message.senderId == uid;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: GestureDetector(
        onLongPress: () => _showEmojiBar(context),
        child: Row(
          mainAxisAlignment: isMe
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isMe) ...[
              _AvatarInitial(
                name: message.senderDisplayName,
                userId: message.senderId,
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Column(
                crossAxisAlignment: isMe
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  if (!isMe)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2, left: 4),
                      child: Text(
                        message.senderDisplayName,
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isMe
                          ? AppColors.accent.withOpacity(0.15)
                          : AppColors.surfaceCard,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isMe ? 16 : 4),
                        bottomRight: Radius.circular(isMe ? 4 : 16),
                      ),
                    ),
                    child: Text(
                      message.content ?? '',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      _formatTime(message.createdAtMs),
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  if (message.reactions.isNotEmpty)
                    _ReactionRow(
                      reactions: message.reactions,
                      onReaction: onReaction,
                    ),
                ],
              ),
            ),
            if (isMe) const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  void _showEmojiBar(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _EmojiReactionBar(onReaction: onReaction),
    );
  }
}

class _ImageMessageBubble extends StatelessWidget {
  const _ImageMessageBubble({required this.message, required this.onReaction});

  final CircleMessage message;
  final ValueChanged<String> onReaction;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final isMe = message.senderId == uid;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: GestureDetector(
        onLongPress: () => showModalBottomSheet<void>(
          context: context,
          backgroundColor: AppColors.surfaceCard,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          builder: (_) => _EmojiReactionBar(onReaction: onReaction),
        ),
        child: Row(
          mainAxisAlignment: isMe
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isMe) ...[
              _AvatarInitial(
                name: message.senderDisplayName,
                userId: message.senderId,
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Column(
                crossAxisAlignment: isMe
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  if (!isMe)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2, left: 4),
                      child: Text(
                        message.senderDisplayName,
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      children: [
                        if (message.imageUrl != null)
                          GestureDetector(
                            onTap: () => FullScreenImageViewer.open(
                              context,
                              imageUrl: message.imageUrl!,
                              heroTag: 'chat_image_${message.id}',
                            ),
                            child: Hero(
                              tag: 'chat_image_${message.id}',
                              child: CachedNetworkImage(
                                imageUrl: message.imageUrl!,
                                width: 220,
                                // Decode at display size — without this each
                                // ~1080px source is decoded full-res for a
                                // 220-logical-px bubble (several MB RAM
                                // each). Disk cache: downloads once, ever.
                                memCacheWidth:
                                    (220 *
                                            MediaQuery.devicePixelRatioOf(
                                              context,
                                            ))
                                        .round(),
                                fit: BoxFit.cover,
                                placeholder: (_, _) => Container(
                                  width: 220,
                                  height: 140,
                                  color: AppColors.surfaceCard,
                                  child: Center(
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ),
                                ),
                                errorWidget: (_, _, _) => Container(
                                  width: 220,
                                  height: 140,
                                  color: AppColors.surfaceCard,
                                  child: Icon(
                                    Icons.broken_image_rounded,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        if (message.content != null &&
                            message.content!.isNotEmpty)
                          Positioned(
                            bottom: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                message.content!,
                                style: TextStyle(
                                  color: AppColors.accent,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      _formatTime(message.createdAtMs),
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  if (message.reactions.isNotEmpty)
                    _ReactionRow(
                      reactions: message.reactions,
                      onReaction: onReaction,
                    ),
                ],
              ),
            ),
            if (isMe) const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}

class _SystemEventPill extends StatelessWidget {
  const _SystemEventPill(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            text,
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
        ),
      ),
    );
  }
}

// ── Reactions ─────────────────────────────────────────────────────────────────

class _ReactionRow extends StatelessWidget {
  const _ReactionRow({required this.reactions, required this.onReaction});

  final Map<String, List<String>> reactions;
  final ValueChanged<String> onReaction;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return Padding(
      padding: const EdgeInsets.only(top: 4, left: 4),
      child: Wrap(
        spacing: 4,
        children: reactions.entries.map((e) {
          final reacted = uid != null && e.value.contains(uid);
          return GestureDetector(
            onTap: () => onReaction(e.key),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: reacted
                    ? AppColors.accent.withOpacity(0.2)
                    : AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: reacted
                      ? AppColors.accent.withOpacity(0.4)
                      : Colors.transparent,
                ),
              ),
              child: Text(
                '${e.key} ${e.value.length}',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _EmojiReactionBar extends StatelessWidget {
  const _EmojiReactionBar({required this.onReaction});
  final ValueChanged<String> onReaction;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: _kPresetEmojis
              .map(
                (e) => GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    onReaction(e);
                  },
                  child: Text(e, style: const TextStyle(fontSize: 28)),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

// ── Input bar ─────────────────────────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.sending,
    required this.onSend,
    required this.onPickImage,
  });

  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;
  final VoidCallback onPickImage;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        border: Border(top: BorderSide(color: AppColors.fg.withOpacity(0.06))),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Image picker button
            IconButton(
              icon: const Icon(Icons.add_photo_alternate_outlined),
              color: AppColors.textMuted,
              onPressed: sending ? null : onPickImage,
            ),
            // Text field
            Expanded(
              child: TextField(
                controller: controller,
                style: TextStyle(color: AppColors.textPrimary),
                maxLines: 4,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.send,
                onTapOutside: (_) => dismissKeyboard(context),
                onSubmitted: (_) {
                  if (!sending && controller.text.trim().isNotEmpty) {
                    onSend();
                  }
                },
                decoration: InputDecoration(
                  hintText: 'Message your circle…',
                  hintStyle: TextStyle(color: AppColors.textMuted),
                  filled: true,
                  fillColor: AppColors.surfaceCard,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Send button
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (_, value, __) {
                final canSend = value.text.trim().isNotEmpty && !sending;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  child: IconButton(
                    icon: sending
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.accent,
                            ),
                          )
                        : Icon(
                            Icons.send_rounded,
                            color: canSend
                                ? AppColors.accent
                                : AppColors.textMuted,
                          ),
                    onPressed: canSend ? onSend : null,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _AvatarInitial extends StatelessWidget {
  _AvatarInitial({required this.name, required this.userId});
  final String name;
  final String userId;

  static final _colors = [
    AppColors.accent,
    AppColors.cyanDeep,
    AppColors.orange,
    AppColors.pink,
    AppColors.violet,
    AppColors.mint,
    AppColors.yellow,
    AppColors.danger,
  ];

  Color get _color => _colors[userId.hashCode.abs() % _colors.length];

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return CircleAvatar(
      radius: 16,
      backgroundColor: _color.withOpacity(0.2),
      child: Text(
        initial,
        style: TextStyle(
          color: _color,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

String _formatTime(int ms) {
  final dt = DateTime.fromMillisecondsSinceEpoch(ms);
  final now = DateTime.now();
  final diff = now.difference(dt);

  if (diff.inMinutes < 1) return 'now';
  if (diff.inHours < 1) return '${diff.inMinutes}m ago';
  if (diff.inDays < 1) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
  return '${dt.day}/${dt.month}';
}
