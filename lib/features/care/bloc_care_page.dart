import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:mobile_happify/core/app_services.dart';
import 'package:mobile_happify/features/care/bloc/care_chat_cubit.dart';
import 'package:mobile_happify/features/care/bloc/care_chat_state.dart';
import 'package:mobile_happify/core/widgets/common_widgets.dart';
import 'package:mobile_happify/core/widgets/happify_emoji.dart';
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
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => BlocCareChatSheet(sessionId: id),
    );
    if (context.mounted) {
      unawaited(context.read<CareCubit>().refresh());
    }
  }

  Future<void> _request(
    BuildContext context,
    Map<String, dynamic>? provider,
  ) async {
    final reason = await showTextPrompt(
      context,
      title: 'Request professional care',
      label: 'What support do you need?',
      maxLines: 4,
    );
    if (reason == null || reason.isEmpty || !context.mounted) return;
    final success = await context.read<CareCubit>().requestCare(
      reason: reason,
      provider: provider,
    );
    if (context.mounted && success) {
      showMessage(context, 'Care request submitted.');
    }
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
            final empty =
                overview.providers.isEmpty &&
                overview.referrals.isEmpty &&
                overview.chats.isEmpty;
            return HappifyPage(
              refresh: context.read<CareCubit>().refresh,
              children: [
                const FeatureCard(
                  color: Color(0xFFE6DCF0),
                  child: Text(
                    'Happify can connect signed-in users with configured care providers. It does not diagnose or replace emergency services.',
                  ),
                ),
                const SizedBox(height: 12),
                AsyncStateView(
                  loading: state.status == CareStatus.loading,
                  error: state.errorMessage,
                  isEmpty: empty,
                  emptyMessage:
                      'No providers, referrals, or chats are available.',
                  onRetry: context.read<CareCubit>().load,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FilledButton.icon(
                        onPressed: state.submitting
                            ? null
                            : () => _request(context, null),
                        icon: HappifyEmoji.referral(size: 28),

                        label: const Text('New care request'),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Referral status',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      if (overview.referrals.isEmpty)
                        const Text('No care requests yet.'),
                      ...overview.referrals.map(
                        (item) => ListTile(
                          leading: HappifyEmoji.referral(size: 34),

                          title: Text(item['reason'].toString()),
                          subtitle: Text(
                            '${prettyEnum(item['status'])} · ${prettyEnum(item['riskLevel'])} · ${shortDate(item['createdAt'])}',
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
                          leading: HappifyEmoji.chat(size: 34),

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
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Providers',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      if (overview.providers.isEmpty)
                        const Text('No active providers are configured.'),
                      ...overview.providers.map(
                        (provider) => FeatureCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                provider['name'].toString(),
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Text(
                                '${prettyEnum(provider['type'])} · ${provider['region']}',
                              ),
                              Text(provider['description'].toString()),
                              TextButton(
                                onPressed: state.submitting
                                    ? null
                                    : () => _request(context, provider),
                                child: const Text('Request this provider'),
                              ),
                            ],
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

class BlocCareChatSheet extends StatelessWidget {
  const BlocCareChatSheet({required this.sessionId, super.key});

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

  @override
  void dispose() {
    if (_isTyping) unawaited(_cubit.setTyping(false));
    _message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .88,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: BlocBuilder<CareChatCubit, CareChatState>(
            builder: (context, state) {
              final messages = objectList(state.session['messages']);
              final open = state.session['status'] == 'OPEN';
              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Care chat',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                      TextButton(
                        onPressed: state.updatingStatus
                            ? null
                            : context.read<CareChatCubit>().toggleStatus,
                        child: Text(open ? 'Close chat' : 'Reopen chat'),
                      ),
                    ],
                  ),
                  if (state.errorMessage != null) Text(state.errorMessage!),
                  Expanded(
                    child: state.loading
                        ? const Center(child: CircularProgressIndicator())
                        : messages.isEmpty
                        ? const Center(child: Text('No messages yet.'))
                        : ListView(
                            children: messages.map((item) {
                              final sender = objectMap(item['sender']);
                              return ListTile(
                                title: Text(
                                  sender['displayName']?.toString() ??
                                      prettyEnum(sender['role']),
                                ),
                                subtitle: Text(
                                  item['content']?.toString() ?? '',
                                ),
                                trailing: Text(shortDate(item['createdAt'])),
                              );
                            }).toList(),
                          ),
                  ),
                  if (state.session['summary'] != null)
                    FeatureCard(
                      child: Text('Summary: ${state.session['summary']}'),
                    ),
                  if (state.typingDisplayName != null)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('${state.typingDisplayName} is typing...'),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _message,
                          enabled: open && !state.sending,
                          maxLength: 1200,
                          onChanged: _setTyping,
                          decoration: const InputDecoration(
                            labelText: 'Message',
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: open && !state.sending
                            ? () async {
                                final content = _message.text.trim();
                                if (content.isEmpty) return;
                                final sent = await context
                                    .read<CareChatCubit>()
                                    .sendMessage(content);
                                if (sent) {
                                  _message.clear();
                                  _setTyping('');
                                }
                              }
                            : null,
                        icon: state.sending
                            ? const SizedBox.square(
                                dimension: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(
                                PhosphorIcons.paperPlaneTilt(
                                  PhosphorIconsStyle.bold,
                                ),
                              ),

                        tooltip: 'Send message',
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
