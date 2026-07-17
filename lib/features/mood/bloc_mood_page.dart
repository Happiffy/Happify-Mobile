import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/app_services.dart';
import '../../core/happify_repository.dart';
import '../../core/theme/happify_colors.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/happify_button.dart';
import '../../core/widgets/happify_emoji.dart';
import '../../core/widgets/history_widgets.dart';
import 'bloc/mood_cubit.dart';
import 'bloc/mood_state.dart';
import 'data/mood_repository.dart';

class BlocMoodPage extends StatelessWidget {
  const BlocMoodPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AppServices.of(context).auth;
    if (!auth.canUseProtectedFeatures) {
      return const SignInGuard(
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
  @override
  Widget build(BuildContext context) {
    return BlocListener<MoodCubit, MoodState>(
      listenWhen: (previous, current) =>
          previous.saveStatus != current.saveStatus,
      listener: (context, state) {
        if (state.saveStatus == MoodSaveStatus.success) {
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
          return LoadMoreSentinel(
            enabled: state.hasMoreHistory,
            loading: state.loadingMoreHistory,
            onLoadMore: context.read<MoodCubit>().loadMoreHistory,
            child: HappifyPage(
              title: 'Mood tracker',
              refresh: context.read<MoodCubit>().refresh,
              bottomPadding: 110,
              children: [
                _MoodForm(state: state),
                const SizedBox(height: 24),
                _DashboardInsight(state: state),
                const SizedBox(height: 20),
                _MoodHistory(state: state),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MoodForm extends StatelessWidget {
  const _MoodForm({required this.state});

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
                  showCheckmark: false,
                  avatar: ExcludeSemantics(
                    child: happifyMoodEmoji(option.$1, size: 30),
                  ),
                  label: Text(
                    option.$2,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  onSelected: saving
                      ? null
                      : (_) => cubit.selectMood(option.$1),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 20),
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

class _MoodInsightSkeleton extends StatelessWidget {
  const _MoodInsightSkeleton();
  @override
  Widget build(BuildContext context) => FeatureCard(
    color: HappifyColors.purpleSurface,
    child: Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: const BoxDecoration(
            color: Color(0x33000000),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                height: 14,
                color: const Color(0x22000000),
              ),
              const SizedBox(height: 8),
              Container(width: 180, height: 14, color: const Color(0x22000000)),
            ],
          ),
        ),
      ],
    ),
  );
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
        if (state.loadStatus == MoodLoadStatus.loading &&
            state.dashboard.isEmpty)
          const _MoodInsightSkeleton()
        else
          AsyncStateView(
            loading: false,
            error: state.dashboardError,
            isEmpty:
                state.loadStatus != MoodLoadStatus.loading && insight == null,
            emptyMessage:
                'Insights will appear as your wellbeing history grows.',
            onRetry: context.read<MoodCubit>().load,
            child: FeatureCard(
              color: HappifyColors.purpleSurface,
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

class _MoodHistory extends StatelessWidget {
  const _MoodHistory({required this.state});

  final MoodState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FeatureCard(
          color: Colors.white,
          divider: true,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'History',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              HistoryDateRangeFilter(
                startDate: state.historyStartDate,
                endDate: state.historyEndDate,
                onApply: (startDate, endDate) =>
                    context.read<MoodCubit>().applyHistoryDateFilter(
                      startDate: startDate,
                      endDate: endDate,
                    ),
              ),
            ],
          ),
        ),
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
            children: [
              ...state.history.map((item) => _MoodHistoryCard(item: item)),
              if (state.loadingMoreHistory)
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: CircularProgressIndicator(),
                ),
            ],
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
    return FeatureCard(
      divider: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              happifyMoodEmoji(mood, size: 30),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  prettyEnum(mood),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Text(shortDate(item['createdAt'])),
            ],
          ),
        ],
      ),
    );
  }
}
