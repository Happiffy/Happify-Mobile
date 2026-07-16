import 'dart:async';

import 'package:flutter/material.dart';

import '../core/app_services.dart';
import '../core/happify_repository.dart';
import '../core/widgets/common_widgets.dart';
import '../core/widgets/happify_button.dart';

class MoodPage extends StatefulWidget {
  const MoodPage({super.key});

  @override
  State<MoodPage> createState() => _MoodPageState();
}

class _MoodPageState extends State<MoodPage> {
  bool _loading = true;
  bool _saving = false;
  String? _error;
  String _mood = 'NEUTRAL';
  int _intensity = 3;
  final Set<String> _triggers = {};
  final TextEditingController _note = TextEditingController();
  List<Map<String, dynamic>> _history = [];
  Map<String, dynamic> _dashboard = {};
  static const triggers = [
    'College',
    'Family',
    'Social media',
    'Sleep',
    'Loneliness',
    'Work',
    'Health',
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loading) unawaited(_load());
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
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
        repo.moods(),
        repo.dashboard(),
      ]);
      if (!mounted) return;
      setState(() {
        _history = results[0]! as List<Map<String, dynamic>>;
        _dashboard = results[1]! as Map<String, dynamic>;
        _loading = false;
        _error = null;
      });
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
    setState(() => _saving = true);
    try {
      await HappifyRepository(AppServices.of(context).auth.api).saveMood(
        state: _mood,
        intensity: _intensity,
        triggers: _triggers.toList(),
        note: _note.text,
      );
      _note.clear();
      if (mounted) showMessage(context, 'Today’s mood was saved.');
      await _load();
    } catch (error) {
      if (mounted) showMessage(context, failureMessage(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = AppServices.of(context).auth;
    if (!auth.canUseProtectedFeatures) {
      return const SignInGuard(
        child: Text('Mood tracking is ready after sign in.'),
      );
    }
    final trend = objectList(_dashboard['moodTrend']);
    return HappifyPage(
      title: 'Mood tracker',
      refresh: _load,
      children: [
        Text(
          'What are you feeling most strongly?',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: moodOptions
              .map(
                (option) => ChoiceChip(
                  selected: _mood == option.$1,
                  avatar: Text(option.$3),
                  label: Text(option.$2),
                  onSelected: (_) => setState(() => _mood = option.$1),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 18),
        FeatureCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Intensity: $_intensity of 5',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Slider(
                value: _intensity.toDouble(),
                min: 1,
                max: 5,
                divisions: 4,
                label: '$_intensity',
                onChanged: (value) =>
                    setState(() => _intensity = value.round()),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Optional triggers',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: triggers
              .map(
                (trigger) => FilterChip(
                  label: Text(trigger),
                  selected: _triggers.contains(trigger),
                  onSelected: (selected) => setState(
                    () => selected
                        ? _triggers.add(trigger)
                        : _triggers.remove(trigger),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _note,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Optional note'),
        ),
        const SizedBox(height: 14),
        HappifyButton(
          label: _saving ? 'Saving...' : 'Save mood',
          onPressed: _saving ? null : _save,
        ),
        const SizedBox(height: 24),
        Text('Recent trend', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        AsyncStateView(
          loading: _loading,
          error: _error,
          isEmpty: trend.isEmpty,
          emptyMessage: 'Save your first mood to build a trend.',
          onRetry: () {
            setState(() => _loading = true);
            unawaited(_load());
          },
          child: FeatureCard(
            child: SizedBox(
              height: 150,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: trend.map((entry) {
                  final intensity = (entry['intensity'] as num? ?? 1)
                      .toDouble();
                  final state = entry['state']?.toString() ?? 'NEUTRAL';
                  return Expanded(
                    child: Semantics(
                      label:
                          '${prettyEnum(state)}, intensity ${intensity.toInt()}, ${shortDate(entry['createdAt'])}',
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: Container(
                                  height: 20 + intensity * 20,
                                  decoration: BoxDecoration(
                                    color: moodColor(state),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              state.substring(0, 1),
                              style: const TextStyle(fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text('History', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        ..._history.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: FeatureCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: moodColor(item['state'].toString()),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${prettyEnum(item['state'])} · intensity ${item['intensity']}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      Text(shortDate(item['createdAt'])),
                    ],
                  ),
                  if ((item['triggers'] as List? ?? const []).isNotEmpty)
                    Text('Triggers: ${(item['triggers'] as List).join(', ')}'),
                  if (item['note'] != null) Text(item['note'].toString()),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

Future<void> showMindfulnessActivity(
  BuildContext context,
  Map<String, dynamic> activity,
) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => MindfulnessActivitySheet(activity: activity),
  );
}

class MindfulnessActivitySheet extends StatefulWidget {
  const MindfulnessActivitySheet({required this.activity, super.key});
  final Map<String, dynamic> activity;

  @override
  State<MindfulnessActivitySheet> createState() =>
      _MindfulnessActivitySheetState();
}

class _MindfulnessActivitySheetState extends State<MindfulnessActivitySheet> {
  Timer? _timer;
  int _seconds = 0;
  bool _running = false;
  bool _saving = false;

  int get _duration =>
      (widget.activity['durationSeconds'] as num? ?? 0).toInt();
  List<String> get _steps => (widget.activity['steps'] as List? ?? const [])
      .map((item) => '$item')
      .toList();

  void _toggle() {
    if (_running) {
      _timer?.cancel();
      setState(() => _running = false);
      return;
    }
    setState(() => _running = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return timer.cancel();
      if (_seconds >= _duration) {
        timer.cancel();
        setState(() => _running = false);
        unawaited(_save(true));
      } else {
        setState(() => _seconds++);
      }
    });
  }

  Future<void> _save(bool completed) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await HappifyRepository(
        AppServices.of(context).auth.api,
      ).updateMindfulnessProgress(
        activityId: widget.activity['id'].toString(),
        progressSeconds: _seconds,
        completed: completed,
      );
      if (mounted) {
        showMessage(
          context,
          completed ? 'Activity completed.' : 'Progress saved.',
        );
      }
    } catch (error) {
      if (mounted) showMessage(context, failureMessage(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final speech = AppServices.of(context).speech;
    final remaining = (_duration - _seconds).clamp(0, _duration);
    final guidance =
        '${widget.activity['title']}. ${widget.activity['description']}. ${_steps.join('. ')}';
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.activity['title'].toString(),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(widget.activity['description'].toString()),
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: _duration == 0 ? 0 : _seconds / _duration,
              ),
              const SizedBox(height: 8),
              Text('$remaining seconds remaining'),
              const SizedBox(height: 16),
              ..._steps.asMap().entries.map(
                (entry) => ListTile(
                  leading: CircleAvatar(child: Text('${entry.key + 1}')),
                  title: Text(entry.value),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  FilledButton.icon(
                    onPressed: _toggle,
                    icon: Icon(_running ? Icons.pause : Icons.play_arrow),
                    label: Text(_running ? 'Pause' : 'Start'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => speech.speak(guidance),
                    icon: Icon(speech.speaking ? Icons.stop : Icons.volume_up),
                    label: Text(
                      speech.speaking ? 'Stop audio' : 'Audio guidance',
                    ),
                  ),
                  TextButton(
                    onPressed: _saving
                        ? null
                        : () => _save(_seconds >= _duration),
                    child: const Text('Save progress'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
