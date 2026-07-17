import 'dart:async';
import 'dart:convert';

import 'package:image_picker/image_picker.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:mobile_happify/core/app_services.dart';
import 'package:mobile_happify/core/happify_repository.dart';
import 'package:mobile_happify/core/theme/happify_colors.dart';
import 'package:mobile_happify/features/care/bloc/care_chat_cubit.dart';
import 'package:mobile_happify/features/care/bloc/care_chat_state.dart';
import 'package:mobile_happify/core/widgets/common_widgets.dart';
import 'package:mobile_happify/core/widgets/happify_emoji.dart';
import 'package:mobile_happify/core/widgets/happify_button.dart';
import 'package:mobile_happify/features/care/bloc/care_cubit.dart';
import 'package:mobile_happify/features/care/bloc/care_state.dart';
import 'package:mobile_happify/features/care/data/care_chat_realtime.dart';
import 'package:mobile_happify/features/care/data/care_repository.dart';

class BlocCarePage extends StatelessWidget {
  const BlocCarePage({this.sessionId, super.key});

  final String? sessionId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CareCubit(
        repository: context.read<CareRepository>(),
        initialSessionId: sessionId,
      )..load(),
      child: const _BlocCareView(),
    );
  }
}

class _BlocCareView extends StatelessWidget {
  const _BlocCareView();

  Future<void> _openChat(BuildContext context, String id) async {
    context.read<CareCubit>().consumePendingChat();
    await context.push('/care/chat/$id');
    if (context.mounted) unawaited(context.read<CareCubit>().refresh());
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CareCubit, CareState>(
      listenWhen: (previous, current) =>
          previous.pendingChatId != current.pendingChatId &&
          current.pendingChatId != null,
      listener: (context, state) {
        final id = state.pendingChatId;
        if (id != null) unawaited(_openChat(context, id));
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Professional care')),
        body: BlocBuilder<CareCubit, CareState>(
          builder: (context, state) {
            final overview = state.overview;
            return HappifyPage(
              refresh: context.read<CareCubit>().refresh,
              children: [
                const FeatureCard(
                  color: HappifyColors.purpleSurface,
                  child: Text(
                    'Happify can connect signed-in users with configured care providers. It does not diagnose or replace emergency services.',
                  ),
                ),
                const SizedBox(height: 12),
                AsyncStateView(
                  loading: state.status == CareStatus.loading,
                  error: state.errorMessage,
                  isEmpty: false,
                  onRetry: context.read<CareCubit>().load,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      HappifyButton(
                        label: 'New care request',
                        onPressed: state.submitting
                            ? null
                            : () async {
                                await context.push('/care/request');
                                if (context.mounted) {
                                  unawaited(
                                    context.read<CareCubit>().refresh(),
                                  );
                                }
                              },
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'My care requests',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 10),
                      if (overview.referrals.isEmpty)
                        const Text(
                          'Your care requests and psychologist updates will appear here.',
                        ),
                      ...overview.referrals.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: FeatureCard(
                            divider: true,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    HappifyEmoji.referral(size: 34),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        item['providerName']?.toString() ??
                                            'Happify Wellbeing Network',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleMedium,
                                      ),
                                    ),
                                    _CareStatusPill(
                                      label: prettyEnum(item['status']),
                                      accepted: item['status'] == 'ACCEPTED',
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(item['reason']?.toString() ?? ''),
                                if (item['requestComment']
                                        ?.toString()
                                        .isNotEmpty ==
                                    true) ...[
                                  const SizedBox(height: 10),
                                  Text(
                                    'Your comment: ${item['requestComment']}',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ],
                                if (item['reviewerComment']
                                        ?.toString()
                                        .isNotEmpty ==
                                    true) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'Psychologist note: ${item['reviewerComment']}',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Care chats',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      if (overview.chats.isEmpty)
                        const Text(
                          'Accepted referrals will create care chats here.',
                        ),
                      ...overview.chats.map(
                        (chat) => ListTile(
                          onTap: () =>
                              _openChat(context, chat['id'].toString()),
                          leading: ExcludeSemantics(
                            child: HappifyEmoji.chat(size: 34),
                          ),
                          title: Text(
                            objectMap(
                                  chat['psychologist'],
                                )['displayName']?.toString() ??
                                'Care professional',
                          ),
                          subtitle: Text(
                            '${prettyEnum(chat['status'])} · ${shortDate(chat['updatedAt'])}',
                          ),
                          trailing: Icon(
                            PhosphorIcons.caretRight(PhosphorIconsStyle.bold),
                            color: Colors.black,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CareStatusPill extends StatelessWidget {
  const _CareStatusPill({required this.label, required this.accepted});

  final String label;
  final bool accepted;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: accepted ? HappifyColors.greenSurface : HappifyColors.goldSurface,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: accepted ? HappifyColors.greenDark : HappifyColors.goldInk,
        fontSize: 12,
        fontWeight: FontWeight.w900,
      ),
    ),
  );
}

class BlocCareRequestPage extends StatelessWidget {
  const BlocCareRequestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          CareCubit(repository: context.read<CareRepository>()),
      child: const _BlocCareRequestView(),
    );
  }
}

class _BlocCareRequestView extends StatefulWidget {
  const _BlocCareRequestView();

  @override
  State<_BlocCareRequestView> createState() => _BlocCareRequestViewState();
}

class _BlocCareRequestViewState extends State<_BlocCareRequestView> {
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final reason = _reason.text.trim();
    if (reason.isEmpty) {
      showMessage(context, 'Describe the support you need before submitting.');
      return;
    }
    final success = await context.read<CareCubit>().requestCare(reason: reason);
    if (!mounted || !success) return;
    context.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New care request')),
      body: HappifyPage(
        children: [
          const FeatureCard(
            color: HappifyColors.purpleSurface,
            child: Text(
              'Tell us what support you need. A care professional will review your request.',
            ),
          ),
          const SizedBox(height: 16),
          BlocBuilder<CareCubit, CareState>(
            builder: (context, state) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _reason,
                  enabled: !state.submitting,
                  maxLines: 4,
                  maxLength: 1200,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: 'What support do you need?',
                  ),
                  onSubmitted: (_) => _submit(),
                ),
                if (state.errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(state.errorMessage!),
                ],
                const SizedBox(height: 16),
                HappifyButton(
                  label: state.submitting ? 'Submitting...' : 'Submit request',
                  onPressed: state.submitting ? null : _submit,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CareChatListPage extends StatelessWidget {
  const CareChatListPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (context) =>
        CareCubit(repository: context.read<CareRepository>())..load(),
    child: const _CareChatListView(),
  );
}

class _CareChatListView extends StatefulWidget {
  const _CareChatListView();

  @override
  State<_CareChatListView> createState() => _CareChatListViewState();
}

class _CareChatListViewState extends State<_CareChatListView> {
  late final Timer _refreshTimer;

  @override
  void initState() {
    super.initState();
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) unawaited(context.read<CareCubit>().refresh());
    });
  }

  @override
  void dispose() {
    _refreshTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Care chats')),
    body: BlocBuilder<CareCubit, CareState>(
      builder: (context, state) => HappifyPage(
        children: [
          if (state.status == CareStatus.loading)
            const Center(child: CircularProgressIndicator())
          else if (state.overview.chats.isEmpty)
            FeatureCard(
              borderless: true,
              child: Column(
                children: [
                  HappifyEmoji.comment(size: 64),
                  const SizedBox(height: 12),
                  Text(
                    'No chats yet',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Once a psychologist approves your request, the chat opens here.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            ...state.overview.chats.map((chat) {
              final psychologist = objectMap(chat['psychologist']);
              final name =
                  psychologist['displayName']?.toString() ??
                  'Care professional';
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: FeatureCard(
                  onTap: () => context.push('/care/chat/${chat['id']}'),
                  child: Row(
                    children: [
                      CircleAvatar(
                        child: Text(name.substring(0, 1).toUpperCase()),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              chat['peerOnline'] == true ? 'Online' : 'Offline',
                              style: TextStyle(
                                color: chat['peerOnline'] == true
                                    ? HappifyColors.greenDark
                                    : HappifyColors.inkMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        PhosphorIcons.caretRight(PhosphorIconsStyle.bold),
                        color: Colors.black,
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    ),
  );
}

class BlocCareChatPage extends StatelessWidget {
  const BlocCareChatPage({required this.sessionId, super.key});

  final String sessionId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CareChatCubit(
        repository: context.read<CareRepository>(),
        sessionId: sessionId,
        realtime: context.read<CareChatRealtimeFactory>().create(sessionId),
      )..load(),
      child: _BlocCareChatView(sessionId: sessionId),
    );
  }
}

class _BlocCareChatView extends StatefulWidget {
  const _BlocCareChatView({required this.sessionId});

  final String sessionId;

  @override
  State<_BlocCareChatView> createState() => _BlocCareChatViewState();
}

class _BlocCareChatViewState extends State<_BlocCareChatView> {
  final _message = TextEditingController();
  late CareChatCubit _cubit;
  bool _isTyping = false;
  String? _imageUrl;
  bool _uploadingImage = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _cubit = context.read<CareChatCubit>();
  }

  void _setTyping(String value) {
    final isTyping = value.trim().isNotEmpty;
    if (isTyping == _isTyping) return;
    _isTyping = isTyping;
    unawaited(_cubit.setTyping(isTyping));
  }

  Future<void> _pickImage() async {
    final api = AppServices.of(context).auth.api;
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
      maxWidth: 1600,
    );
    if (file == null || !mounted) return;
    setState(() => _uploadingImage = true);
    try {
      final bytes = await file.readAsBytes();
      final extension = file.name.toLowerCase().endsWith('.png')
          ? 'png'
          : file.name.toLowerCase().endsWith('.webp')
          ? 'webp'
          : 'jpeg';
      final image = await HappifyRepository(api).uploadImage(
        imageBase64: base64Encode(bytes),
        contentType: 'image/$extension',
      );
      if (mounted) setState(() => _imageUrl = image['url']?.toString());
    } catch (error) {
      if (mounted) showMessage(context, failureMessage(error));
    } finally {
      if (mounted) setState(() => _uploadingImage = false);
    }
  }

  Future<void> _confirmStatusChange(CareChatState state) async {
    final reopening = state.session['status'] != 'OPEN';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                reopening
                    ? PhosphorIcons.arrowCounterClockwise(
                        PhosphorIconsStyle.bold,
                      )
                    : PhosphorIcons.xCircle(PhosphorIconsStyle.bold),
                color: reopening ? HappifyColors.green : HappifyColors.red,
                size: 34,
              ),
              const SizedBox(height: 16),
              Text(
                reopening ? 'Reopen this chat?' : 'Close this chat?',
                style: Theme.of(dialogContext).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                reopening
                    ? 'You and your care professional can continue this conversation.'
                    : 'You can reopen this conversation later if you need to continue.',
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(dialogContext, false),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: reopening
                            ? HappifyColors.green
                            : HappifyColors.red,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => Navigator.pop(dialogContext, true),
                      child: Text(reopening ? 'Reopen' : 'Close chat'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (confirmed == true && mounted) await _cubit.toggleStatus();
  }

  @override
  void dispose() {
    if (_isTyping) unawaited(_cubit.setTyping(false));
    _message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Care chat')),
      body: SafeArea(
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.fromLTRB(
            18,
            18,
            18,
            18 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: BlocBuilder<CareChatCubit, CareChatState>(
            builder: (context, state) {
              final messages = objectList(state.session['messages']);
              final open = state.session['status'] == 'OPEN';
              final me = AppServices.of(
                context,
              ).auth.backendUser?['id']?.toString();
              final sessionUserId = state.session['userId']?.toString();
              final peer = objectMap(
                state.session[sessionUserId == me ? 'psychologist' : 'user'],
              );
              final peerName =
                  peer['displayName']?.toString() ?? 'Care professional';
              final connected = state.peerOnline;
              return Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: HappifyColors.blue,
                        backgroundImage:
                            peer['avatarUrl']?.toString().isNotEmpty == true
                            ? NetworkImage(peer['avatarUrl'].toString())
                            : null,
                        child: peer['avatarUrl']?.toString().isNotEmpty == true
                            ? null
                            : Text(
                                peerName.substring(0, 1).toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              peerName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              state.typingDisplayName != null
                                  ? '${state.typingDisplayName} is typing...'
                                  : connected
                                  ? 'Online'
                                  : 'Offline',
                              style: TextStyle(
                                color: connected
                                    ? HappifyColors.greenDark
                                    : HappifyColors.inkMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: open
                              ? HappifyColors.red
                              : HappifyColors.green,
                          disabledForegroundColor: Colors.white70,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: state.updatingStatus
                            ? null
                            : () => _confirmStatusChange(state),
                        child: Text(open ? 'Close' : 'Reopen'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: state.loading
                        ? const Center(child: CircularProgressIndicator())
                        : messages.isEmpty
                        ? const Center(child: Text('No messages yet.'))
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            itemCount: messages.length,
                            separatorBuilder: (_, index) {
                              return const SizedBox(height: 10);
                            },
                            itemBuilder: (_, index) {
                              final item = messages[index];
                              final senderId =
                                  item['senderId']?.toString() ??
                                  objectMap(item['sender'])['id']?.toString();
                              final mine = senderId == me;
                              return Align(
                                alignment: mine
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 290,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: mine
                                          ? HappifyColors.blue
                                          : HappifyColors.surfaceMuted,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item['content']?.toString() ?? '',
                                          style: TextStyle(
                                            color: mine
                                                ? Colors.white
                                                : HappifyColors.ink,
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          shortDate(item['createdAt']),
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: mine
                                                ? Colors.white70
                                                : HappifyColors.inkMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  if (state.session['summary'] != null)
                    FeatureCard(
                      child: Text(state.session['summary'].toString()),
                    ),
                  if (_imageUrl != null)
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Image attached',
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                        ),
                        IconButton(
                          onPressed: () => setState(() => _imageUrl = null),
                          icon: Icon(PhosphorIcons.x(PhosphorIconsStyle.bold)),
                        ),
                      ],
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Material(
                        color: HappifyColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(16),
                        child: IconButton(
                          onPressed: open && !_uploadingImage
                              ? _pickImage
                              : null,
                          icon: _uploadingImage
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : HappifyEmoji.picture(size: 24),
                          tooltip: 'Attach photo',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _message,
                          enabled: open,
                          maxLength: 1200,
                          onChanged: _setTyping,
                          decoration: const InputDecoration(
                            hintText: 'Write a message',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Material(
                        color: HappifyColors.blue,
                        borderRadius: BorderRadius.circular(16),
                        child: IconButton(
                          color: Colors.white,
                          onPressed: open
                              ? () async {
                                  final content = _message.text.trim();
                                  if (content.isEmpty && _imageUrl == null) {
                                    showMessage(
                                      context,
                                      'Write a message or attach a photo before sending.',
                                    );
                                    return;
                                  }
                                  final sent = await _cubit.sendMessage(
                                    content,
                                    imageUrl: _imageUrl,
                                  );
                                  if (sent) {
                                    _message.clear();
                                    setState(() => _imageUrl = null);
                                    _setTyping('');
                                  }
                                }
                              : null,
                          icon: Icon(
                            PhosphorIcons.paperPlaneTilt(
                              PhosphorIconsStyle.fill,
                            ),
                          ),
                          tooltip: 'Send message',
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
