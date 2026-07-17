import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:convert';

import 'package:flutter_map/flutter_map.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/app_services.dart';
import '../../core/happify_repository.dart';
import '../../core/theme/happify_colors.dart';
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

  Future<void> _comment(
    String postId,
    String content, {
    String? imageUrl,
  }) async {
    await context.read<CommunityCubit>().comment(
      postId,
      content,
      imageUrl: imageUrl,
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
  });

  final TextEditingController alias;
  final TextEditingController content;
  final String? postMood;
  final ValueChanged<String?> onMoodChanged;
  final Future<void> Function() onCompose;
  final Future<void> Function(String postId, String content, {String? imageUrl})
  onComment;

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

class _CommunityPostCard extends StatefulWidget {
  const _CommunityPostCard({
    required this.post,
    required this.busy,
    required this.onComment,
  });

  final Map<String, dynamic> post;
  final bool busy;
  final Future<void> Function(String postId, String content, {String? imageUrl})
  onComment;

  @override
  State<_CommunityPostCard> createState() => _CommunityPostCardState();
}

class _CommunityPostCardState extends State<_CommunityPostCard> {
  final _reply = TextEditingController();
  bool _replyOpen = false;
  bool _uploadingImage = false;
  String? _imageUrl;

  Future<void> _pickReplyImage() async {
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

  @override
  void dispose() {
    _reply.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final postId = post['id']?.toString() ?? '';
    final mood = post['mood']?.toString();
    return FeatureCard(
      divider: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: HappifyColors.purple,
                child: Text(
                  (post['alias']?.toString() ?? 'Anonymous')
                      .substring(0, 1)
                      .toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 10),
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
                onPressed: widget.busy || postId.isEmpty
                    ? null
                    : () => context.read<CommunityCubit>().support(postId),
                icon: post['likedByMe'] == true
                    ? HappifyEmoji.purpleHeart(size: 22)
                    : HappifyEmoji.whiteHeart(size: 22),
                label: Text('${post['supportCount'] ?? 0} support'),
              ),
              TextButton.icon(
                onPressed: widget.busy || postId.isEmpty
                    ? null
                    : () => setState(() => _replyOpen = !_replyOpen),
                icon: HappifyEmoji.comment(size: 22),
                label: const Text('Comment'),
              ),
            ],
          ),
          if (_replyOpen) ...[
            if (_imageUrl != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    const Icon(Icons.image_outlined, size: 20),
                    const SizedBox(width: 8),
                    const Expanded(child: Text('Photo ready to send')),
                    IconButton(
                      onPressed: () => setState(() => _imageUrl = null),
                      icon: Icon(PhosphorIcons.x(PhosphorIconsStyle.bold)),
                      tooltip: 'Remove photo',
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Material(
                    color: HappifyColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(14),
                    child: IconButton(
                      onPressed: _uploadingImage ? null : _pickReplyImage,
                      icon: Icon(PhosphorIcons.image(PhosphorIconsStyle.bold)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _reply,
                      maxLength: 400,
                      decoration: const InputDecoration(
                        hintText: 'Write a supportive reply',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: HappifyColors.purple,
                    borderRadius: BorderRadius.circular(14),
                    child: IconButton(
                      color: Colors.white,
                      onPressed: () async {
                        if (_reply.text.trim().isEmpty && _imageUrl == null) {
                          return;
                        }
                        await widget.onComment(
                          postId,
                          _reply.text.trim(),
                          imageUrl: _imageUrl,
                        );
                        if (mounted) {
                          setState(() {
                            _reply.clear();
                            _imageUrl = null;
                            _replyOpen = false;
                          });
                        }
                      },
                      icon: Icon(
                        PhosphorIcons.paperPlaneTilt(PhosphorIconsStyle.fill),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          ...objectList(post['comments']).map(
            (comment) => Container(
              margin: const EdgeInsets.only(top: 10, left: 12),
              padding: const EdgeInsets.only(left: 12),
              decoration: const BoxDecoration(
                border: Border(
                  left: BorderSide(color: HappifyColors.line, width: 2),
                ),
              ),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(comment['alias']?.toString() ?? 'Anonymous'),
                subtitle: Text(comment['content']?.toString() ?? ''),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CommunityHeatmapTab extends StatefulWidget {
  const _CommunityHeatmapTab();

  @override
  State<_CommunityHeatmapTab> createState() => _CommunityHeatmapTabState();
}

class _CommunityHeatmapTabState extends State<_CommunityHeatmapTab> {
  late DateTime _startDate;
  late DateTime _endDate;

  @override
  void initState() {
    super.initState();
    _endDate = _dateOnly(DateTime.now());
    _startDate = _endDate.subtract(const Duration(days: 6));
  }

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  Future<void> _selectDate({required bool isStart}) async {
    final today = _dateOnly(DateTime.now());
    final selected = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: today.subtract(const Duration(days: 89)),
      lastDate: today,
    );
    if (selected == null || !mounted) return;
    setState(() {
      if (isStart) {
        _startDate = selected;
      } else {
        _endDate = selected;
      }
      if (_startDate.isAfter(_endDate)) {
        if (isStart) {
          _endDate = _startDate;
        } else {
          _startDate = _endDate;
        }
      }
    });
  }

  Future<void> _apply() => context.read<CommunityCubit>().loadHeatmap(
    startDate: _startDate,
    endDate: _endDate,
  );

  String _formatDate(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<CommunityCubit, CommunityState>(
    builder: (context, state) {
      if (state.heatmapStatus != CommunityHeatmapStatus.success) {
        return RefreshIndicator(
          onRefresh: _apply,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            children: [
              AsyncStateView(
                loading: state.heatmapStatus == CommunityHeatmapStatus.loading,
                error: state.heatmapStatus == CommunityHeatmapStatus.failure
                    ? state.heatmapError
                    : null,
                isEmpty: state.heatmapStatus == CommunityHeatmapStatus.empty,
                emptyMessage:
                    'No anonymous regional insights are available yet.',
                onRetry: _apply,
                child: const SizedBox.shrink(),
              ),
            ],
          ),
        );
      }
      return Stack(
        fit: StackFit.expand,
        children: [
          _PrivacyHeatmap(items: state.heatmapItems),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Align(
                alignment: Alignment.topCenter,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  color: Colors.white,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Coarse regional blocks from anonymous contributions.',
                        style: TextStyle(
                          color: HappifyColors.inkMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _HeatmapDateButton(
                              value: _formatDate(_startDate),
                              onPressed: () => _selectDate(isStart: true),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _HeatmapDateButton(
                              value: _formatDate(_endDate),
                              onPressed: () => _selectDate(isStart: false),
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed:
                                state.heatmapStatus ==
                                    CommunityHeatmapStatus.loading
                                ? null
                                : _apply,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: HappifyColors.greenDark,
                              side: const BorderSide(
                                color: HappifyColors.line,
                                width: 2,
                              ),
                              shape: const RoundedRectangleBorder(),
                            ),
                            child: const Text('Apply'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}

class _HeatmapDateButton extends StatelessWidget {
  const _HeatmapDateButton({required this.value, required this.onPressed});

  final String value;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: onPressed,
    style: OutlinedButton.styleFrom(
      foregroundColor: HappifyColors.ink,
      side: const BorderSide(color: HappifyColors.line, width: 2),
      shape: const RoundedRectangleBorder(),
    ),
    child: Text(value),
  );
}

class _PrivacyHeatmap extends StatelessWidget {
  const _PrivacyHeatmap({required this.items});
  final List<Map<String, dynamic>> items;

  @override
  Widget build(BuildContext context) {
    final polygons = <Polygon>[];
    for (final item in items) {
      final latitude = (item['latitude'] as num?)?.toDouble();
      final longitude = (item['longitude'] as num?)?.toDouble();
      final bounds = objectMap(item['bounds']);
      if (latitude == null || longitude == null || bounds.isEmpty) {
        continue;
      }
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
            LatLng(
              (bounds['south'] as num).toDouble(),
              (bounds['west'] as num).toDouble(),
            ),
            LatLng(
              (bounds['south'] as num).toDouble(),
              (bounds['east'] as num).toDouble(),
            ),
            LatLng(
              (bounds['north'] as num).toDouble(),
              (bounds['east'] as num).toDouble(),
            ),
            LatLng(
              (bounds['north'] as num).toDouble(),
              (bounds['west'] as num).toDouble(),
            ),
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
    return FlutterMap(
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
    );
  }
}
