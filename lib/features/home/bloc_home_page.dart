import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_services.dart';
import '../../core/happify_repository.dart';
import '../../core/theme/happify_colors.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/happify_emoji.dart';
import '../../core/widgets/quokka_badge.dart';
import 'bloc/home_cubit.dart';
import 'bloc/home_state.dart';
import 'data/home_repository.dart';

class BlocHomePage extends StatelessWidget {
  const BlocHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AppServices.of(context).auth;
    if (!auth.canUseProtectedFeatures) {
      return const SignInGuard(
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
          bottomPadding: 110,
          children: [
            _HomeHeader(
              name: name,
              avatarUrl: profile['avatarUrl']?.toString(),
            ),
            const SizedBox(height: 22),
            _QuickMoodCard(onPressed: () => context.go('/app?target=mood')),
            const SizedBox(height: 18),
            _DashboardSection(state: state),
          ],
        );
      },
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.name, this.avatarUrl});

  final String name;
  final String? avatarUrl;

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
        Semantics(
          button: true,
          label: 'Open profile',
          child: InkWell(
            borderRadius: BorderRadius.circular(29),
            onTap: () => context.go('/app?target=profile'),
            child: HappifyAvatar(
              size: 58,
              imageUrl: avatarUrl,
              fallbackName: name,
            ),
          ),
        ),
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
      color: HappifyColors.greenSurface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: HappifyColors.line, width: 2),
                ),
                child: HappifyEmoji.mood(size: 30),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How are you feeling?',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'A quick check-in helps reveal your mood patterns.',
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onPressed,
            icon: HappifyEmoji.next(size: 22),
            label: const Text('Start check-in'),
          ),
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
    if (state.dashboardStatus == HomeSectionStatus.loading &&
        dashboard.isEmpty) {
      return const _DashboardSkeleton();
    }
    return AsyncStateView(
      loading: false,
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
          const SizedBox(height: 4),
          const Text('A clear view of your recent check-ins and progress.'),
          const SizedBox(height: 12),
          _LatestMoodCard(dashboard: dashboard),
          const SizedBox(height: 12),
          _TotalsCard(dashboard: dashboard),
          if (objectList(dashboard['moodTrend']).isNotEmpty) ...[
            const SizedBox(height: 12),
            _MoodTrendCard(trend: objectList(dashboard['moodTrend'])),
          ],
        ],
      ),
    );
  }
}

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const _SkeletonBox(width: 150, height: 24),
      const SizedBox(height: 8),
      const _SkeletonBox(width: 250, height: 16),
      const SizedBox(height: 12),
      const _SkeletonBox(width: double.infinity, height: 94),
      const SizedBox(height: 12),
      GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.7,
        children: const [_SkeletonBox(), _SkeletonBox(), _SkeletonBox()],
      ),
      const SizedBox(height: 12),
      const _SkeletonBox(width: double.infinity, height: 170),
    ],
  );
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({this.width, this.height});
  final double? width;
  final double? height;
  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: HappifyColors.surfaceMuted,
      borderRadius: BorderRadius.circular(18),
    ),
  );
}

class _TotalsCard extends StatelessWidget {
  const _TotalsCard({required this.dashboard});

  final Map<String, dynamic> dashboard;

  @override
  Widget build(BuildContext context) {
    final totals = objectMap(dashboard['totals']);
    final values = <(String, Object?, Widget)>[
      ('Moods', totals['moods'] ?? 0, HappifyEmoji.greenHeart(size: 30)),
      ('Journals', totals['journals'] ?? 0, HappifyEmoji.journal(size: 30)),
      (
        'Posts',
        totals['communityPosts'] ?? 0,
        HappifyEmoji.community(size: 30),
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.7,
      children: values
          .map(
            (value) => Semantics(
              label: '${value.$1}: ${value.$2}',
              child: FeatureCard(
                color: HappifyColors.surfaceMuted,
                child: Row(
                  children: [
                    ExcludeSemantics(child: value.$3),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${value.$2}',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Text(
                            value.$1,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
    );
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
    final latest = (trend.first['intensity'] as num? ?? 0).toDouble();
    final oldest = (trend.last['intensity'] as num? ?? 0).toDouble();
    final percent = oldest == 0
        ? 0
        : (((latest - oldest) / oldest) * 100).round();
    final trendLabel = percent == 0
        ? 'Steady'
        : percent > 0
        ? '+$percent% from your first check-in'
        : '$percent% from your first check-in';
    return FeatureCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Mood trend',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Text(
                trendLabel,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: percent > 0
                      ? HappifyColors.greenDark
                      : HappifyColors.inkSoft,
                ),
              ),
            ],
          ),
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
                      child: Tooltip(
                        message:
                            '${prettyEnum(mood)}\nIntensity ${intensity.toInt()}/5\n${shortDate(entry['createdAt'])}',
                        triggerMode: TooltipTriggerMode.tap,
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
