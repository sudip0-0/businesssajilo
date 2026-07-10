import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/ui/empty_state.dart';
import '../../core/ui/error_state.dart';
import '../../core/utils/bs_date.dart';
import '../../data/repositories/messages_repository.dart';
import '../auth/providers/auth_provider.dart';
import 'providers.dart';

class OrderChatScreen extends ConsumerStatefulWidget {
  const OrderChatScreen({
    super.key,
    required this.orderId,
    this.embedded = false,
  });

  final String orderId;
  final bool embedded;

  @override
  ConsumerState<OrderChatScreen> createState() => _OrderChatScreenState();
}

class _OrderChatScreenState extends ConsumerState<OrderChatScreen> {
  final _controller = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _sendText() async {
    final body = _controller.text.trim();
    if (body.isEmpty) return;
    final member = ref.read(authProvider).value?.member;
    if (member == null) return;

    setState(() => _sending = true);
    try {
      await ref
          .read(messagesRepositoryProvider)
          .sendText(
            orderId: widget.orderId,
            senderMemberId: member.id,
            body: body,
          );
      _controller.clear();
    } catch (_) {
      _showSendFailed();
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _showSendFailed() {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.messageSendFailed)));
  }

  Future<void> _attachImage() async {
    final member = ref.read(authProvider).value?.member;
    final businessId = member?.businessId;
    if (member == null || businessId == null) return;

    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1280,
      imageQuality: 85,
    );
    if (file == null) return;

    final bytes = await file.readAsBytes();
    // Soft client cap — storage bucket enforces 5 MB.
    if (bytes.lengthInBytes > 5 * 1024 * 1024) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).actionFailed)),
        );
      }
      return;
    }
    final safeName = file.name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    setState(() => _sending = true);
    try {
      await ref
          .read(messagesRepositoryProvider)
          .sendImage(
            orderId: widget.orderId,
            senderMemberId: member.id,
            businessId: businessId,
            bytes: bytes,
            fileName: safeName.isEmpty ? 'chat.jpg' : safeName,
          );
    } catch (_) {
      _showSendFailed();
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  /// Time-only for same-day messages; BS date + time otherwise.
  String _timestamp(BuildContext context, DateTime createdAtUtc) {
    final local = createdAtUtc.toLocal();
    final now = DateTime.now();
    final time = DateFormat.jm().format(local);
    final sameDay =
        local.year == now.year &&
        local.month == now.month &&
        local.day == now.day;
    if (sameDay) return time;
    final date = BsDate.both(
      createdAtUtc,
      locale: Localizations.localeOf(context),
    );
    return '$date · $time';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final messagesAsync = ref.watch(orderMessagesProvider(widget.orderId));
    final myMemberId = ref.watch(authProvider).value?.member?.id;

    final chatBody = Column(
      children: [
        Expanded(
          child: messagesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => ErrorState(
              message: l10n.loadingFailed,
              onRetry: () =>
                  ref.invalidate(orderMessagesProvider(widget.orderId)),
            ),
            data: (messages) {
              if (messages.isEmpty) {
                return EmptyState(
                  icon: Icons.chat_bubble_outline,
                  message: l10n.noMessages,
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages[index];
                  final isMine = msg.senderMemberId == myMemberId;
                  return Align(
                    alignment: isMine
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.sizeOf(context).width * 0.75,
                      ),
                      decoration: BoxDecoration(
                        color: isMine
                            ? Theme.of(context).colorScheme.primaryContainer
                            : Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (msg.senderName != null)
                            Text(
                              msg.senderName!,
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          if (msg.imageUrl != null)
                            FutureBuilder<String?>(
                              future: ref
                                  .read(messagesRepositoryProvider)
                                  .signedImageUrl(msg.imageUrl),
                              builder: (context, snap) {
                                final url = snap.data;
                                if (url == null) {
                                  return const SizedBox(
                                    height: 120,
                                    width: 120,
                                    child: Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                }
                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: CachedNetworkImage(
                                    imageUrl: url,
                                    height: 160,
                                    memCacheWidth: 480,
                                    fit: BoxFit.cover,
                                  ),
                                );
                              },
                            ),
                          if (msg.body.isNotEmpty) Text(msg.body),
                          if (msg.createdAt != null)
                            Text(
                              _timestamp(context, msg.createdAt!),
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                IconButton(
                  onPressed: _sending ? null : _attachImage,
                  icon: const Icon(Icons.image_outlined),
                  tooltip: l10n.attachImage,
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(hintText: l10n.typeMessage),
                    onSubmitted: (_) => _sendText(),
                  ),
                ),
                IconButton(
                  onPressed: _sending ? null : _sendText,
                  icon: const Icon(Icons.send),
                  tooltip: l10n.send,
                ),
              ],
            ),
          ),
        ),
      ],
    );

    if (widget.embedded) return chatBody;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.orderChat)),
      body: chatBody,
    );
  }
}
