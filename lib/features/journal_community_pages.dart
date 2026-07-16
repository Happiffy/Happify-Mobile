import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../core/app_services.dart';
import '../core/happify_repository.dart';
import '../core/theme/happify_colors.dart';
import '../core/widgets/common_widgets.dart';
import '../core/widgets/happify_button.dart';
import '../core/widgets/happify_rich_text.dart';

class JournalPage extends StatefulWidget {
  const JournalPage({super.key});

  @override
  State<JournalPage> createState() => _JournalPageState();
}

class _JournalPageState extends State<JournalPage> {
  final _title = TextEditingController();
  final _content = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  String? _error;
  List<Map<String, dynamic>> _items = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loading) unawaited(_load());
  }

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final auth = AppServices.of(context).auth;
    if (!auth.canUseProtectedFeatures) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final items = await HappifyRepository(auth.api).journals();
      if (mounted) {
        setState(() {
          _items = items;
          _loading = false;
          _error = null;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = failureMessage(error);
          _loading = false;
        });
      }
    }
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty || _content.text.trim().isEmpty) {
      showMessage(context, 'Add a title and journal text.');
      return;
    }
    setState(() => _saving = true);
    try {
      final journal = await HappifyRepository(
        AppServices.of(context).auth.api,
      ).createJournal(title: _title.text.trim(), content: _content.text.trim());
      _title.clear();
      _content.clear();
      if (!mounted) return;
      final risk = journal['riskLevel']?.toString() ?? 'LOW';
      showMessage(
        context,
        risk == 'HIGH' || risk == 'CRISIS'
            ? 'Entry saved. Happify also created a professional care request.'
            : 'Journal entry saved.',
      );
      await _load();
    } catch (error) {
      if (mounted) showMessage(context, failureMessage(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!AppServices.of(context).auth.canUseProtectedFeatures) {
      return const SignInGuard(
        child: Text('Private journaling is ready after sign in.'),
      );
    }
    return HappifyPage(
      title: 'Journal',
      refresh: _load,
      children: [
        FeatureCard(
          child: Column(
            children: [
              TextField(
                controller: _title,
                maxLength: 120,
                decoration: const InputDecoration(labelText: 'Entry title'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _content,
                minLines: 5,
                maxLines: 10,
                maxLength: 20000,
                decoration: const InputDecoration(
                  labelText: 'Write what you are feeling',
                ),
              ),
              const SizedBox(height: 10),
              HappifyButton(
                label: _saving ? 'Saving and reflecting...' : 'Save entry',
                onPressed: _saving ? null : _save,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const FeatureCard(
          color: Color(0xFFE6DCF0),
          child: Text(
            'If AI processing consent is active, Happify generates a gentle reflection. Otherwise the backend uses privacy-preserving local rules. High-risk entries create a care request.',
          ),
        ),
        const SizedBox(height: 20),
        Text('History', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        AsyncStateView(
          loading: _loading,
          error: _error,
          isEmpty: _items.isEmpty,
          emptyMessage: 'Your saved journal entries will appear here.',
          onRetry: () {
            setState(() => _loading = true);
            unawaited(_load());
          },
          child: Column(
            children: _items
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: FeatureCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item['title'].toString(),
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                              ),
                              Chip(label: Text(prettyEnum(item['riskLevel']))),
                            ],
                          ),
                          Text(shortDate(item['createdAt'])),
                          const SizedBox(height: 6),
                          HappifyRichText(item['content']?.toString() ?? ''),
                          if (item['detectedMood'] != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Detected mood: ${prettyEnum(item['detectedMood'])}',
                            ),
                          ],
                          if (item['aiReflection'] != null) ...[
                            const Divider(),
                            Text(
                              'Reflection',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(item['aiReflection'].toString()),
                          ],
                        ],
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _posts = [];
  List<Map<String, dynamic>> _heatmap = [];
  String _heatmapMood = 'NEUTRAL';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loading) unawaited(_load());
  }

  Future<void> _load() async {
    final auth = AppServices.of(context).auth;
    if (!auth.canUseProtectedFeatures) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final repo = HappifyRepository(auth.api);
      final results = await Future.wait<Object?>([
        repo.community(),
        repo.heatmap(),
      ]);
      if (mounted) {
        setState(() {
          _posts = results[0]! as List<Map<String, dynamic>>;
          _heatmap = results[1]! as List<Map<String, dynamic>>;
          _loading = false;
          _error = null;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = failureMessage(error);
          _loading = false;
        });
      }
    }
  }

  Future<void> _compose() async {
    final content = await showTextPrompt(
      context,
      title: 'Share anonymously',
      label: 'Your story',
      maxLines: 5,
    );
    if (content == null || content.isEmpty || !mounted) return;
    try {
      await HappifyRepository(
        AppServices.of(context).auth.api,
      ).createPost(alias: 'Anonymous Quokka', content: content);
      await _load();
    } catch (error) {
      if (mounted) showMessage(context, failureMessage(error));
    }
  }

  Future<void> _comment(String postId) async {
    final content = await showTextPrompt(
      context,
      title: 'Add supportive comment',
      label: 'Comment',
      maxLines: 3,
    );
    if (content == null || content.isEmpty || !mounted) return;
    try {
      await HappifyRepository(
        AppServices.of(context).auth.api,
      ).comment(postId, content);
      await _load();
    } catch (error) {
      if (mounted) showMessage(context, failureMessage(error));
    }
  }

  Future<void> _support(String postId) async {
    final api = AppServices.of(context).auth.api;
    try {
      await HappifyRepository(api).support(postId);
      await _load();
    } catch (error) {
      if (mounted) showMessage(context, failureMessage(error));
    }
  }

  Future<void> _report(String targetType, String targetId) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Report content'),
        children:
            [
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
                    child: Text(prettyEnum(value)),
                  ),
                )
                .toList(),
      ),
    );
    if (reason == null || !mounted) return;
    try {
      await HappifyRepository(
        AppServices.of(context).auth.api,
      ).report(targetType: targetType, targetId: targetId, reason: reason);
      if (mounted) showMessage(context, 'Report submitted for review.');
    } catch (error) {
      if (mounted) showMessage(context, failureMessage(error));
    }
  }

  Future<void> _contribute() async {
    final api = AppServices.of(context).auth.api;
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw const AppFailure('Location services are disabled.');
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw const AppFailure(
          'Location permission is required for an opt-in heatmap contribution.',
        );
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
        ),
      );
      final latBucket = (position.latitude * 10).floor();
      final lonBucket = (position.longitude * 10).floor();
      final regionKey =
          'G${latBucket < 0 ? 'S' : 'N'}${latBucket.abs()}_${lonBucket < 0 ? 'W' : 'E'}${lonBucket.abs()}';
      await HappifyRepository(api).contributeHeatmap(regionKey, _heatmapMood);
      if (mounted) {
        showMessage(
          context,
          'Coarse regional mood contribution saved. Exact coordinates were not sent.',
        );
      }
      await _load();
    } catch (error) {
      if (mounted) showMessage(context, failureMessage(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!AppServices.of(context).auth.canUseProtectedFeatures) {
      return const SignInGuard(
        child: Text('Community support is available after sign in.'),
      );
    }
    return DefaultTabController(
      length: 2,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Community',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                  IconButton(
                    onPressed: _compose,
                    icon: const Icon(Icons.edit),
                    tooltip: 'Compose anonymous post',
                  ),
                ],
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
                  RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
                      children: [
                        AsyncStateView(
                          loading: _loading,
                          error: _error,
                          isEmpty: _posts.isEmpty,
                          emptyMessage:
                              'No community stories yet. You can share the first one.',
                          onRetry: () {
                            setState(() => _loading = true);
                            unawaited(_load());
                          },
                          child: Column(
                            children: _posts
                                .map(
                                  (post) => Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: FeatureCard(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  post['alias']?.toString() ??
                                                      'Anonymous',
                                                  style: Theme.of(
                                                    context,
                                                  ).textTheme.titleMedium,
                                                ),
                                              ),
                                              PopupMenuButton<String>(
                                                onSelected: (_) => _report(
                                                  'POST',
                                                  post['id'].toString(),
                                                ),
                                                itemBuilder: (_) => const [
                                                  PopupMenuItem(
                                                    value: 'report',
                                                    child: Text('Report'),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          HappifyRichText(
                                            post['content']?.toString() ?? '',
                                          ),
                                          const SizedBox(height: 8),
                                          Wrap(
                                            spacing: 8,
                                            children: [
                                              TextButton.icon(
                                                onPressed: () => _support(
                                                  post['id'].toString(),
                                                ),
                                                icon: Icon(
                                                  post['likedByMe'] == true
                                                      ? Icons.favorite
                                                      : Icons.favorite_border,
                                                ),
                                                label: Text(
                                                  '${post['supportCount'] ?? 0} support',
                                                ),
                                              ),
                                              TextButton.icon(
                                                onPressed: () => _comment(
                                                  post['id'].toString(),
                                                ),
                                                icon: const Icon(Icons.comment),
                                                label: const Text('Comment'),
                                              ),
                                            ],
                                          ),
                                          ...objectList(post['comments']).map(
                                            (comment) => ListTile(
                                              contentPadding: EdgeInsets.zero,
                                              title: Text(
                                                comment['alias']?.toString() ??
                                                    'Anonymous',
                                              ),
                                              subtitle: Text(
                                                comment['content']
                                                        ?.toString() ??
                                                    '',
                                              ),
                                              trailing: IconButton(
                                                onPressed: () => _report(
                                                  'COMMENT',
                                                  comment['id'].toString(),
                                                ),
                                                icon: const Icon(
                                                  Icons.flag_outlined,
                                                ),
                                                tooltip: 'Report comment',
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
                    children: [
                      const FeatureCard(
                        color: Color(0xFFE6DCF0),
                        child: Text(
                          'The backend only releases regions meeting its minimum anonymity cohort. The app sends a coarse grid key, never exact coordinates.',
                        ),
                      ),
                      const SizedBox(height: 12),
                      PrivacyHeatmap(items: _heatmap),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: _heatmapMood,
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
                        onChanged: (value) =>
                            setState(() => _heatmapMood = value ?? 'NEUTRAL'),
                      ),
                      const SizedBox(height: 12),
                      HappifyButton(
                        label: 'Contribute coarse location',
                        onPressed: _contribute,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PrivacyHeatmap extends StatelessWidget {
  const PrivacyHeatmap({required this.items, super.key});
  final List<Map<String, dynamic>> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const FeatureCard(
        child: Text(
          'No region currently meets the anonymous cohort threshold.',
        ),
      );
    }
    return FeatureCard(
      color: HappifyColors.ink,
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: items.map((item) {
          final moods = objectMap(item['moods']);
          String dominant = 'NEUTRAL';
          int max = -1;
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
                    item['regionKey'].toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('${item['count']} people'),
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
