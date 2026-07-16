import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/app_services.dart';
import '../../core/happify_repository.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/happify_button.dart';
import '../../core/widgets/happify_emoji.dart';
import 'bloc/mood_cubit.dart';
import 'bloc/mood_state.dart';
import 'data/mood_repository.dart';

class BlocMoodPage extends StatelessWidget {
  const BlocMoodPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AppServices.of(context).auth;
    if (!auth.canUseProtectedFeatures) {
      return const GuestGuard(
        child: Text('Mood tracking is ready after sign in.'),
      );
    }
    return BlocProvider(
      create: (context) => MoodCubit(
        repository: MoodRepository(context.read<HappifyRepository>()),
      )..load(),
      child: const _BlocMoodView(),
    );
  }
}

class _BlocMoodView extends StatefulWidget {
  const _BlocMoodView();

  @override
  State<_BlocMoodView> createState() => _BlocMoodViewState();
}

class _BlocMoodViewState extends State<_BlocMoodView> {
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<MoodCubit, MoodState>(
      listenWhen: (previous, current) =>
          previous.saveStatus != current.saveStatus,
      listener: (context, state) {
        if (state.saveStatus == MoodSaveStatus.success) {
          _note.clear();
          showMessage(context, 'Today’s mood was saved.');
        }
        if (state.saveStatus == MoodSaveStatus.failure) {
          showMessage(
            context,
            state.saveError ?? 'The mood could not be saved.',
          );
        }
      },
      child: BlocBuilder<MoodCubit, MoodState>(
        builder: (context, state) {
          return HappifyPage(
            title: 'Mood tracker',
            refresh: context.read<MoodCubit>().load,
            children: [
              _MoodForm(note: _note, state: state),
              const SizedBox(height: 24),
              _DashboardInsight(state: state),
              const SizedBox(height: 20),
              _VoiceMoodPattern(state: state),
              const SizedBox(height: 20),
              _MoodTrend(state: state),
              const SizedBox(height: 20),
              _MoodHistory(state: state),
            ],
          );
        },
      ),
    );
  }
}

class _MoodForm extends StatelessWidget {
  const _MoodForm({required this.note, required this.state});

  static const triggers = [
    'College',
    'Family',
    'Social media',
    'Sleep',
    'Loneliness',
    'Work',
    'Health',
  ];

  final TextEditingController note;
  final MoodState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<MoodCubit>();
    final saving = state.saveStatus == MoodSaveStatus.saving;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
                  selected: state.selectedMood == option.$1,
                  avatar: happifyMoodEmoji(option.$1, size: 24),
                  label: Text(option.$2),

                  onSelected: saving
                      ? null
                      : (_) => cubit.selectMood(option.$1),
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
                'Intensity: ${state.intensity} of 5',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Slider(
                value: state.intensity.toDouble(),
                min: 1,
                max: 5,
                divisions: 4,
                label: '${state.intensity}',
                onChanged: saving
                    ? null
                    : (value) => cubit.setIntensity(value.round()),
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
          runSpacing: 8,
          children: triggers
              .map(
                (trigger) => FilterChip(
                  label: Text(trigger),
                  selected: state.triggers.contains(trigger),
                  onSelected: saving
                      ? null
                      : (_) => cubit.toggleTrigger(trigger),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: note,
          enabled: !saving,
          maxLines: 3,
          maxLength: 1200,
          onChanged: cubit.setNote,
          decoration: const InputDecoration(labelText: 'Optional note'),
        ),
        const SizedBox(height: 14),
        HappifyButton(
          label: saving ? 'Saving...' : 'Save mood',
          onPressed: saving ? null : cubit.save,
        ),
        if (state.saveStatus == MoodSaveStatus.failure) ...[
          const SizedBox(height: 10),
          Semantics(
            liveRegion: true,
            child: Text(
              state.saveError ?? 'The mood could not be saved.',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ],
    );
  }
}

class _DashboardInsight extends StatelessWidget {
  const _DashboardInsight({required this.state});

  final MoodState state;

  @override
  Widget build(BuildContext context) {
    final insight = MoodRepository.dashboardInsight(state.dashboard);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Your insight', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        AsyncStateView(
          loading:
              state.loadStatus == MoodLoadStatus.loading &&
              state.dashboard.isEmpty,
          error: state.dashboardError,
          isEmpty:
              state.loadStatus != MoodLoadStatus.loading && insight == null,
          emptyMessage: 'Insights will appear as your wellbeing history grows.',
          onRetry: context.read<MoodCubit>().load,
          child: FeatureCard(
            color: const Color(0xFFE6DCF0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HappifyEmoji.brain(size: 34),

                const SizedBox(width: 12),
                Expanded(child: Text(insight ?? '')),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _VoiceMoodPattern extends StatelessWidget {
  const _VoiceMoodPattern({required this.state});

  final MoodState state;

  @override
  Widget build(BuildContext context) {
    final pattern = objectMap(state.dashboard['voiceMoodPattern']);
    final counts = objectList(pattern['counts']);
    final total = (pattern['totalAnalyzedTurns'] as num?)?.toInt() ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Companion mood pattern',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 10),
        AsyncStateView(
          loading:
              state.loadStatus == MoodLoadStatus.loading && pattern.isEmpty,
          error: state.dashboardError,
          isEmpty: state.loadStatus != MoodLoadStatus.loading && total == 0,
          emptyMessage:
              'Analyzed Companion conversations will build your mood pattern here.',
          onRetry: context.read<MoodCubit>().load,
          child: FeatureCard(
            color: const Color(0xFFEAF8FF),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Most frequent: ${prettyEnum(pattern['dominantMood'])}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text('$total analyzed conversation turns'),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: counts.map((item) {
                    final mood = item['state']?.toString() ?? 'NEUTRAL';
                    return Chip(
                      avatar: CircleAvatar(backgroundColor: moodColor(mood)),
                      label: Text('${prettyEnum(mood)} ${item['count'] ?? 0}'),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MoodTrend extends StatelessWidget {
  const _MoodTrend({required this.state});

  final MoodState state;

  @override
  Widget build(BuildContext context) {
    final trend = objectList(state.dashboard['moodTrend']);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recent trend', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        AsyncStateView(
          loading: state.loadStatus == MoodLoadStatus.loading && trend.isEmpty,
          error: state.dashboardError,
          isEmpty: state.loadStatus != MoodLoadStatus.loading && trend.isEmpty,
          emptyMessage: 'Save your first mood to build a trend.',
          onRetry: context.read<MoodCubit>().load,
          child: FeatureCard(
            child: SizedBox(
              height: 150,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: trend.map((entry) {
                  final intensity = (entry['intensity'] as num? ?? 1)
                      .toDouble();
                  final mood = entry['state']?.toString() ?? 'NEUTRAL';
                  return Expanded(
                    child: Semantics(
                      label:
                          '${prettyEnum(mood)}, intensity ${intensity.toInt()}, ${shortDate(entry['createdAt'])}',
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
                                    color: moodColor(mood),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              mood.substring(0, 1),
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
      ],
    );
  }
}

class _MoodHistory extends StatelessWidget {
  const _MoodHistory({required this.state});

  final MoodState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('History', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        AsyncStateView(
          loading:
              state.loadStatus == MoodLoadStatus.loading &&
              state.history.isEmpty,
          error: state.historyError,
          isEmpty:
              state.loadStatus != MoodLoadStatus.loading &&
              state.history.isEmpty,
          emptyMessage: 'No mood check-ins yet.',
          onRetry: context.read<MoodCubit>().load,
          child: Column(
            children: state.history
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _MoodHistoryCard(item: item),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _MoodHistoryCard extends StatelessWidget {
  const _MoodHistoryCard({required this.item});

  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final mood = item['state']?.toString() ?? 'NEUTRAL';
    final triggers = (item['triggers'] as List? ?? const [])
        .map((trigger) => trigger.toString())
        .toList();
    final note = item['note']?.toString().trim();
    return FeatureCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: moodColor(mood),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${prettyEnum(mood)} · intensity ${item['intensity'] ?? '—'}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Text(shortDate(item['createdAt'])),
            ],
          ),
          if (triggers.isNotEmpty) Text('Triggers: ${triggers.join(', ')}'),
          if (note != null && note.isNotEmpty) Text(note),
        ],
      ),
    );
  }
}
