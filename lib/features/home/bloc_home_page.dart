import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/app_services.dart';
import '../../core/happify_repository.dart';
import '../../core/theme/happify_colors.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/happify_emoji.dart';
import '../../core/widgets/quokka_badge.dart';
import '../mood_mindfulness_pages.dart' show showMindfulnessActivity;
import 'bloc/home_cubit.dart';
import 'bloc/home_state.dart';
import 'data/home_repository.dart';

class BlocHomePage extends StatelessWidget {
  const BlocHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AppServices.of(context).auth;
    if (!auth.canUseProtectedFeatures) {
      return const GuestGuard(
        child: Text('Your personal home dashboard is ready after sign in.'),
      );
    }
    return BlocProvider(
      create: (context) => HomeCubit(
        repository: HomeRepository(context.read<HappifyRepository>()),
      )..load(),
      child: const _BlocHomeView(),
    );
  }
}

class _BlocHomeView extends StatelessWidget {
  const _BlocHomeView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        final profile = objectMap(state.dashboard['profile']);
        final auth = AppServices.of(context).auth;
        final name =
            profile['displayName']?.toString() ??
            auth.firebaseUser?.displayName ??
            'Friend';
        return HappifyPage(
          refresh: context.read<HomeCubit>().load,
          children: [
            _HomeHeader(name: name),
            const SizedBox(height: 22),
            _QuickMoodCard(onPressed: () => context.go('/app?target=mood')),
            const SizedBox(height: 18),
            _DashboardSection(state: state),
            const SizedBox(height: 18),
            _MotivationSection(state: state),
            const SizedBox(height: 18),
            _SosCard(onPressed: () => _showSosSupport(context)),
            const SizedBox(height: 22),
            _MindfulnessSection(state: state),
          ],
        );
      },
    );
  }

  Future<void> _showSosSupport(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Support is here',
                style: Theme.of(sheetContext).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              const Text(
                'If you are in immediate danger, contact local emergency services. You can also open your saved emergency contacts or request professional care.',
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(sheetContext);
                  context.push('/contacts');
                },
                icon: const Icon(Icons.contact_phone),
                label: const Text('Emergency contacts'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(sheetContext);
                  context.push('/care');
                },
                icon: const Icon(Icons.health_and_safety),
                label: const Text('Professional care'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Welcome'),
              Text(
                'Hi, $name',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ],
          ),
        ),
        const QuokkaBadge(size: 68),
      ],
    );
  }
}

class _QuickMoodCard extends StatelessWidget {
  const _QuickMoodCard({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FeatureCard(
      color: const Color(0xFFF3E3D0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'How are you feeling?',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                const Text('A quick check-in helps reveal your mood patterns.'),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FilledButton(onPressed: onPressed, child: const Text('Check in')),
        ],
      ),
    );
  }
}

class _DashboardSection extends StatelessWidget {
  const _DashboardSection({required this.state});

  final HomeState state;

  @override
  Widget build(BuildContext context) {
    final dashboard = state.dashboard;
    return AsyncStateView(
      loading:
          state.dashboardStatus == HomeSectionStatus.loading &&
          dashboard.isEmpty,
      error: state.dashboardStatus == HomeSectionStatus.failure
          ? state.dashboardError
          : null,
      isEmpty:
          state.dashboardStatus == HomeSectionStatus.success &&
          dashboard.isEmpty,
      emptyMessage: 'Your dashboard will appear after your first check-in.',
      onRetry: context.read<HomeCubit>().loadDashboard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your wellbeing', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          _TotalsCard(dashboard: dashboard),
          const SizedBox(height: 10),
          _LatestMoodCard(dashboard: dashboard),
          if (objectList(dashboard['moodTrend']).isNotEmpty) ...[
            const SizedBox(height: 10),
            _MoodTrendCard(trend: objectList(dashboard['moodTrend'])),
          ],
        ],
      ),
    );
  }
}

class _TotalsCard extends StatelessWidget {
  const _TotalsCard({required this.dashboard});

  final Map<String, dynamic> dashboard;

  @override
  Widget build(BuildContext context) {
    final totals = objectMap(dashboard['totals']);
    final streak = _streakValue(dashboard);
    final values = <(String, Object?, Widget)>[
      ('Moods', totals['moods'] ?? 0, HappifyEmoji.greenHeart(size: 30)),
      ('Journals', totals['journals'] ?? 0, HappifyEmoji.journal(size: 30)),
      (
        'Posts',
        totals['communityPosts'] ?? 0,
        HappifyEmoji.community(size: 30),
      ),
      if (streak != null)
        ('Streak', '$streak days', HappifyEmoji.sparkle(size: 30)),
    ];

    return FeatureCard(
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: values
            .map(
              (value) => SizedBox(
                width: 132,
                child: Semantics(
                  label: '${value.$1}: ${value.$2}',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      value.$3,

                      const SizedBox(height: 6),
                      Text(
                        '${value.$2}',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(value.$1),
                    ],
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  int? _streakValue(Map<String, dynamic> dashboard) {
    final direct = dashboard['currentStreak'] ?? dashboard['moodStreak'];
    if (direct is num) return direct.toInt();
    final streak = dashboard['streak'];
    if (streak is num) return streak.toInt();
    final values = objectMap(streak);
    final nested = values['current'] ?? values['days'] ?? values['count'];
    return nested is num ? nested.toInt() : null;
  }
}

class _LatestMoodCard extends StatelessWidget {
  const _LatestMoodCard({required this.dashboard});

  final Map<String, dynamic> dashboard;

  @override
  Widget build(BuildContext context) {
    final latest = objectMap(dashboard['latestMood']);
    if (latest.isEmpty) {
      return const FeatureCard(child: Text('No mood check-ins yet.'));
    }
    final mood = latest['state']?.toString() ?? 'NEUTRAL';
    return FeatureCard(
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: moodColor(mood),
              shape: BoxShape.circle,
            ),
            child: happifyMoodEmoji(mood, size: 32),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Latest mood',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  '${prettyEnum(mood)} · intensity ${latest['intensity'] ?? '—'}',
                ),
                Text(shortDate(latest['createdAt'])),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MoodTrendCard extends StatelessWidget {
  const _MoodTrendCard({required this.trend});

  final List<Map<String, dynamic>> trend;

  @override
  Widget build(BuildContext context) {
    return FeatureCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Mood trend', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: trend.take(14).map((entry) {
                final intensity = (entry['intensity'] as num? ?? 1).toDouble();
                final mood = entry['state']?.toString() ?? 'NEUTRAL';
                return Expanded(
                  child: Semantics(
                    label:
                        '${prettyEnum(mood)}, intensity ${intensity.toInt()}, ${shortDate(entry['createdAt'])}',
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          height: 16 + intensity * 18,
                          decoration: BoxDecoration(
                            color: moodColor(mood),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _MotivationSection extends StatelessWidget {
  const _MotivationSection({required this.state});

  final HomeState state;

  @override
  Widget build(BuildContext context) {
    final message = state.motivation?['message']?.toString();
    return AsyncStateView(
      loading:
          state.motivationStatus == HomeSectionStatus.loading &&
          state.motivation == null,
      error: state.motivationStatus == HomeSectionStatus.failure
          ? state.motivationError
          : null,
      isEmpty:
          state.motivationStatus == HomeSectionStatus.success &&
          message == null,
      emptyMessage: 'No English motivation has been published for today.',
      onRetry: context.read<HomeCubit>().loadMotivation,
      child: FeatureCard(
        color: const Color(0xFFF3E3D0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Today’s motivation',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            Text(message ?? '', style: Theme.of(context).textTheme.titleLarge),
            if (state.motivation?['author'] != null)
              Text('— ${state.motivation!['author']}'),
          ],
        ),
      ),
    );
  }
}

class _SosCard extends StatelessWidget {
  const _SosCard({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FeatureCard(
      color: const Color(0xFFFFE8E1),
      child: Row(
        children: [
          Icon(
            PhosphorIcons.lifebuoy(PhosphorIconsStyle.fill),
            size: 36,
            color: HappifyColors.coral,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Feeling anxious or unsafe?'),
                Text('Open support options whenever you need them.'),
              ],
            ),
          ),
          TextButton(onPressed: onPressed, child: const Text('SOS support')),
        ],
      ),
    );
  }
}

class _MindfulnessSection extends StatelessWidget {
  const _MindfulnessSection({required this.state});

  final HomeState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Mindfulness', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        AsyncStateView(
          loading:
              state.mindfulnessStatus == HomeSectionStatus.loading &&
              state.activities.isEmpty,
          error: state.mindfulnessStatus == HomeSectionStatus.failure
              ? state.mindfulnessError
              : null,
          isEmpty:
              state.mindfulnessStatus == HomeSectionStatus.success &&
              state.activities.isEmpty,
          emptyMessage: 'No English mindfulness activities are published.',
          onRetry: context.read<HomeCubit>().loadMindfulness,
          child: Column(
            children: state.activities
                .take(3)
                .map(
                  (activity) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: FeatureCard(
                      onTap: () => showMindfulnessActivity(context, activity),
                      child: Row(
                        children: [
                          Icon(
                            PhosphorIcons.playCircle(PhosphorIconsStyle.fill),
                            color: HappifyColors.sageDeep,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  activity['title']?.toString() ??
                                      'Mindfulness activity',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                Text(
                                  '${prettyEnum(activity['type'])} · ${(activity['durationSeconds'] as num? ?? 0).toInt()} seconds',
                                ),
                              ],
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
    );
  }
}
