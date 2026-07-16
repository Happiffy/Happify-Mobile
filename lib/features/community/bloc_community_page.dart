import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/app_services.dart';
import '../../core/happify_repository.dart';
import '../../core/theme/happify_colors.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/happify_button.dart';
import '../../core/widgets/happify_emoji.dart';
import 'bloc/community_cubit.dart';
import 'bloc/community_state.dart';
import 'data/community_repository.dart';

typedef CoarseRegionKeyCallback = Future<String?> Function();

class BlocCommunityPage extends StatelessWidget {
  const BlocCommunityPage({
    this.repository,
    this.requestCoarseRegionKey,
    super.key,
  });

  final CommunityRepository? repository;
  final CoarseRegionKeyCallback? requestCoarseRegionKey;

  @override
  Widget build(BuildContext context) {
    if (!AppServices.of(context).auth.canUseProtectedFeatures) {
      return const GuestGuard(
        child: Text('Community support is available after sign in.'),
      );
    }
    final communityRepository =
        repository ?? CommunityRepository(context.read<HappifyRepository>());
    return BlocProvider(
      create: (_) => CommunityCubit(repository: communityRepository)..load(),
      child: _BlocCommunityView(requestCoarseRegionKey: requestCoarseRegionKey),
    );
  }
}

class _BlocCommunityView extends StatefulWidget {
  const _BlocCommunityView({required this.requestCoarseRegionKey});

  final CoarseRegionKeyCallback? requestCoarseRegionKey;

  @override
  State<_BlocCommunityView> createState() => _BlocCommunityViewState();
}

class _BlocCommunityViewState extends State<_BlocCommunityView> {
  final _alias = TextEditingController(text: 'Anonymous Quokka');
  final _content = TextEditingController();
  String? _postMood;
  String _heatmapMood = 'NEUTRAL';

  @override
  void dispose() {
    _alias.dispose();
    _content.dispose();
    super.dispose();
  }

  Future<void> _compose() async {
    if (_alias.text.trim().isEmpty || _content.text.trim().isEmpty) {
      showMessage(context, 'Add an alias and your story.');
      return;
    }
    final created = await context.read<CommunityCubit>().createPost(
      alias: _alias.text,
      content: _content.text,
      mood: _postMood,
    );
    if (!mounted || !created) return;
    _content.clear();
    setState(() => _postMood = null);
  }

  Future<void> _comment(String postId) async {
    final content = await showTextPrompt(
      context,
      title: 'Add supportive comment',
      label: 'Comment',
      maxLines: 3,
    );
    if (content == null || content.isEmpty || !mounted) return;
    await context.read<CommunityCubit>().comment(postId, content);
  }

  Future<void> _report(String targetType, String targetId) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Report content'),
        children:
            const [
                  'HARASSMENT',
                  'SELF_HARM',
                  'SPAM',
                  'MISINFORMATION',
                  'PRIVACY',
                  'OTHER',
                ]
                .map(
                  (value) => SimpleDialogOption(
                    onPressed: () => Navigator.pop(context, value),
                    child: Text(value),
                  ),
                )
                .toList(),
      ),
    );
    if (reason == null || !mounted) return;
    await context.read<CommunityCubit>().report(
      targetType: targetType,
      targetId: targetId,
      reason: reason,
    );
  }

  Future<void> _contribute() async {
    final callback = widget.requestCoarseRegionKey;
    if (callback == null) {
      showMessage(
        context,
        'Location contribution is unavailable until a location gateway is connected.',
      );
      return;
    }
    try {
      final regionKey = await callback();
      if (!mounted || regionKey == null || regionKey.isEmpty) return;
      await context.read<CommunityCubit>().contributeHeatmap(
        regionKey: regionKey,
        mood: _heatmapMood,
      );
    } catch (error) {
      if (mounted) showMessage(context, failureMessage(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CommunityCubit, CommunityState>(
      listenWhen: (previous, current) =>
          previous.actionVersion != current.actionVersion,
      listener: (context, state) {
        final message = state.actionError ?? state.actionMessage;
        if (message != null) showMessage(context, message);
      },
      child: DefaultTabController(
        length: 2,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 6),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Community',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
              ),
              const TabBar(
                tabs: [
                  Tab(text: 'Safe space'),
                  Tab(text: 'Heatmap'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _CommunityFeedTab(
                      alias: _alias,
                      content: _content,
                      postMood: _postMood,
                      onMoodChanged: (value) =>
                          setState(() => _postMood = value),
                      onCompose: _compose,
                      onComment: _comment,
                      onReport: _report,
                    ),
                    _CommunityHeatmapTab(
                      mood: _heatmapMood,
                      onMoodChanged: (value) =>
                          setState(() => _heatmapMood = value ?? 'NEUTRAL'),
                      onContribute: _contribute,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CommunityFeedTab extends StatelessWidget {
  const _CommunityFeedTab({
    required this.alias,
    required this.content,
    required this.postMood,
    required this.onMoodChanged,
    required this.onCompose,
    required this.onComment,
    required this.onReport,
  });

  final TextEditingController alias;
  final TextEditingController content;
  final String? postMood;
  final ValueChanged<String?> onMoodChanged;
  final Future<void> Function() onCompose;
  final Future<void> Function(String postId) onComment;
  final Future<void> Function(String targetType, String targetId) onReport;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CommunityCubit, CommunityState>(
      builder: (context, state) {
        return RefreshIndicator(
          onRefresh: context.read<CommunityCubit>().loadFeed,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
            children: [
              FeatureCard(
                child: Column(
                  children: [
                    TextField(
                      controller: alias,
                      enabled: !state.composing,
                      maxLength: 60,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(labelText: 'Alias'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: content,
                      enabled: !state.composing,
                      minLines: 3,
                      maxLines: 6,
                      maxLength: 600,
                      decoration: const InputDecoration(
                        labelText: 'Share your story',
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String?>(
                      initialValue: postMood,
                      decoration: const InputDecoration(
                        labelText: 'Mood (optional)',
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          child: Text('No mood selected'),
                        ),
                        ...moodOptions.map(
                          (option) => DropdownMenuItem<String?>(
                            value: option.$1,
                            child: Text('${option.$3} ${option.$2}'),
                          ),
                        ),
                      ],
                      onChanged: state.composing ? null : onMoodChanged,
                    ),
                    const SizedBox(height: 14),
                    HappifyButton(
                      label: state.composing ? 'Sharing...' : 'Share safely',
                      onPressed: state.composing ? null : onCompose,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AsyncStateView(
                loading: state.feedStatus == CommunityFeedStatus.loading,
                error: state.feedStatus == CommunityFeedStatus.failure
                    ? state.feedError
                    : null,
                isEmpty: state.feedStatus == CommunityFeedStatus.empty,
                emptyMessage:
                    'No community stories yet. You can share the first one.',
                onRetry: context.read<CommunityCubit>().loadFeed,
                child: Column(
                  children: [
                    ...state.posts.map(
                      (post) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _CommunityPostCard(
                          post: post,
                          busy: state.busyTargetIds.contains(
                            post['id']?.toString(),
                          ),
                          onComment: onComment,
                          onReport: onReport,
                        ),
                      ),
                    ),
                    if (state.feedError != null &&
                        state.feedStatus == CommunityFeedStatus.success)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: FeatureCard(
                          child: Text(
                            state.feedError!,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    if (state.hasMoreFeed || state.loadingMoreFeed)
                      OutlinedButton.icon(
                        onPressed: state.loadingMoreFeed
                            ? null
                            : context.read<CommunityCubit>().loadMoreFeed,
                        icon: state.loadingMoreFeed
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(
                                PhosphorIcons.caretDown(
                                  PhosphorIconsStyle.bold,
                                ),
                              ),

                        label: Text(
                          state.loadingMoreFeed
                              ? 'Loading stories...'
                              : 'Load more',
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CommunityPostCard extends StatelessWidget {
  const _CommunityPostCard({
    required this.post,
    required this.busy,
    required this.onComment,
    required this.onReport,
  });

  final Map<String, dynamic> post;
  final bool busy;
  final Future<void> Function(String postId) onComment;
  final Future<void> Function(String targetType, String targetId) onReport;

  @override
  Widget build(BuildContext context) {
    final postId = post['id']?.toString() ?? '';
    final mood = post['mood']?.toString();
    return FeatureCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post['alias']?.toString() ?? 'Anonymous',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(shortDate(post['createdAt'])),
                  ],
                ),
              ),
              if (mood != null) Chip(label: Text(prettyEnum(mood))),
              PopupMenuButton<String>(
                onSelected: (_) => onReport('POST', postId),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'report', child: Text('Report')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(post['content']?.toString() ?? ''),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              TextButton.icon(
                onPressed: busy || postId.isEmpty
                    ? null
                    : () => context.read<CommunityCubit>().support(postId),
                icon: post['likedByMe'] == true
                    ? HappifyEmoji.purpleHeart(size: 22)
                    : HappifyEmoji.whiteHeart(size: 22),

                label: Text('${post['supportCount'] ?? 0} support'),
              ),
              TextButton.icon(
                onPressed: busy || postId.isEmpty
                    ? null
                    : () => onComment(postId),
                icon: const Icon(Icons.comment),
                label: const Text('Comment'),
              ),
            ],
          ),
          ...objectList(post['comments']).map((comment) {
            final commentId = comment['id']?.toString() ?? '';
            return ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(comment['alias']?.toString() ?? 'Anonymous'),
              subtitle: Text(comment['content']?.toString() ?? ''),
              trailing: IconButton(
                onPressed: commentId.isEmpty
                    ? null
                    : () => onReport('COMMENT', commentId),
                icon: const Icon(Icons.flag_outlined),
                tooltip: 'Report comment',
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _CommunityHeatmapTab extends StatelessWidget {
  const _CommunityHeatmapTab({
    required this.mood,
    required this.onMoodChanged,
    required this.onContribute,
  });

  final String mood;
  final ValueChanged<String?> onMoodChanged;
  final Future<void> Function() onContribute;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CommunityCubit, CommunityState>(
      builder: (context, state) {
        return RefreshIndicator(
          onRefresh: context.read<CommunityCubit>().loadHeatmap,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
            children: [
              const FeatureCard(
                color: Color(0xFFE6DCF0),
                child: Text(
                  'The backend only releases regions meeting its minimum anonymity cohort. The app sends a coarse grid key, never exact coordinates.',
                ),
              ),
              const SizedBox(height: 12),
              AsyncStateView(
                loading: state.heatmapStatus == CommunityHeatmapStatus.loading,
                error: state.heatmapStatus == CommunityHeatmapStatus.failure
                    ? state.heatmapError
                    : null,
                isEmpty: state.heatmapStatus == CommunityHeatmapStatus.empty,
                emptyMessage:
                    'No region currently meets the anonymous cohort threshold.',
                onRetry: context.read<CommunityCubit>().loadHeatmap,
                child: _BlocPrivacyHeatmap(items: state.heatmapItems),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: mood,
                decoration: const InputDecoration(
                  labelText: 'Mood to contribute',
                ),
                items: moodOptions
                    .map(
                      (option) => DropdownMenuItem(
                        value: option.$1,
                        child: Text('${option.$3} ${option.$2}'),
                      ),
                    )
                    .toList(),
                onChanged: state.contributingHeatmap ? null : onMoodChanged,
              ),
              const SizedBox(height: 12),
              HappifyButton(
                label: state.contributingHeatmap
                    ? 'Contributing...'
                    : 'Contribute coarse location',
                onPressed: state.contributingHeatmap ? null : onContribute,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BlocPrivacyHeatmap extends StatelessWidget {
  const _BlocPrivacyHeatmap({required this.items});

  final List<Map<String, dynamic>> items;

  @override
  Widget build(BuildContext context) {
    return FeatureCard(
      color: HappifyColors.ink,
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: items.map((item) {
          final moods = objectMap(item['moods']);
          var dominant = 'NEUTRAL';
          var max = -1;
          for (final entry in moods.entries) {
            final count = (entry.value as num? ?? 0).toInt();
            if (count > max) {
              dominant = entry.key;
              max = count;
            }
          }
          return Semantics(
            label:
                '${item['regionKey']}, ${item['count']} anonymous contributions, mostly ${prettyEnum(dominant)}',
            child: Container(
              width: 102,
              height: 102,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: moodColor(dominant),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item['regionKey']?.toString() ?? '',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('${item['count'] ?? 0} people'),
                  Text(prettyEnum(dominant)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
