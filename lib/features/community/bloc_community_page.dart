import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/app_services.dart';
import '../../core/happify_repository.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/happify_button.dart';
import '../../core/widgets/happify_emoji.dart';
import '../../core/widgets/happify_rich_text.dart';
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
      return const SignInGuard(
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
  final _alias = TextEditingController(text: 'Anonymous');
  final _content = TextEditingController();
  String? _postMood;

  @override
  void dispose() {
    _alias.dispose();
    _content.dispose();
    super.dispose();
  }

  Future<void> _compose() async {
    if (_content.text.trim().isEmpty) {
      showMessage(context, 'Write a story before sharing.');
      return;
    }
    final created = await context.read<CommunityCubit>().createPost(
      alias: _alias.text.trim().isEmpty ? 'Anonymous' : _alias.text.trim(),
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
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
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
                    const _CommunityHeatmapTab(),
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
                      decoration: const InputDecoration(labelText: 'Pseudonym'),
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
                            : HappifyEmoji.next(size: 22),

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
  });

  final Map<String, dynamic> post;
  final bool busy;
  final Future<void> Function(String postId) onComment;

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
              if (mood != null) happifyMoodEmoji(mood, size: 32),
            ],
          ),
          const SizedBox(height: 8),
          HappifyRichText(post['content']?.toString() ?? ''),
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
                icon: HappifyEmoji.comment(size: 22),
                label: const Text('Comment'),
              ),
            ],
          ),
          ...objectList(post['comments']).map(
            (comment) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(comment['alias']?.toString() ?? 'Anonymous'),
              subtitle: Text(comment['content']?.toString() ?? ''),
            ),
          ),
        ],
      ),
    );
  }
}

class _CommunityHeatmapTab extends StatelessWidget {
  const _CommunityHeatmapTab();

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<CommunityCubit, CommunityState>(
        builder: (context, state) => RefreshIndicator(
          onRefresh: context.read<CommunityCubit>().loadHeatmap,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
            children: [
              AsyncStateView(
                loading: state.heatmapStatus == CommunityHeatmapStatus.loading,
                error: state.heatmapStatus == CommunityHeatmapStatus.failure
                    ? state.heatmapError
                    : null,
                isEmpty: state.heatmapStatus == CommunityHeatmapStatus.empty,
                emptyMessage:
                    'No anonymous regional insights are available yet.',
                onRetry: context.read<CommunityCubit>().loadHeatmap,
                child: _PrivacyHeatmap(items: state.heatmapItems),
              ),
            ],
          ),
        ),
      );
}

class _PrivacyHeatmap extends StatelessWidget {
  const _PrivacyHeatmap({required this.items});
  final List<Map<String, dynamic>> items;

  ({double latitude, double longitude})? _parseRegion(String key) {
    final match = RegExp(r'^G([NS])(\d+)_([EW])(\d+)$').firstMatch(key);
    if (match == null) return null;
    return (
      latitude:
          double.parse(match.group(2)!) / 10 * (match.group(1) == 'S' ? -1 : 1),
      longitude:
          double.parse(match.group(4)!) / 10 * (match.group(3) == 'W' ? -1 : 1),
    );
  }

  @override
  Widget build(BuildContext context) {
    final polygons = <Polygon>[];
    for (final item in items) {
      final region = _parseRegion(item['regionKey']?.toString() ?? '');
      if (region == null) continue;
      final moods = objectMap(item['moods']);
      var dominant = 'NEUTRAL';
      var highest = -1;
      for (final entry in moods.entries) {
        final value = (entry.value as num? ?? 0).toInt();
        if (value > highest) {
          dominant = entry.key;
          highest = value;
        }
      }
      final color = moodColor(dominant);
      polygons.add(
        Polygon(
          points: [
            LatLng(region.latitude, region.longitude),
            LatLng(region.latitude, region.longitude + .1),
            LatLng(region.latitude + .1, region.longitude + .1),
            LatLng(region.latitude + .1, region.longitude),
          ],
          color: color.withValues(alpha: .58),
          borderColor: color,
          borderStrokeWidth: 2,
          label: '${item['count']} · ${prettyEnum(dominant)}',
          labelStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
    }
    return SizedBox(
      height: 340,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: FlutterMap(
          options: const MapOptions(
            initialCenter: LatLng(-6.2, 106.8),
            initialZoom: 9,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.happify.app.mobile_happify',
            ),
            PolygonLayer(polygons: polygons),
          ],
        ),
      ),
    );
  }
}
