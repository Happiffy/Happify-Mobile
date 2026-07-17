import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/app_services.dart';
import '../../core/happify_repository.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/happify_button.dart';
import '../../core/widgets/happify_emoji.dart';
import '../../core/widgets/happify_rich_text.dart';
import '../../core/widgets/history_widgets.dart';
import 'bloc/journal_cubit.dart';
import 'bloc/journal_state.dart';
import 'data/journal_repository.dart';

class BlocJournalPage extends StatelessWidget {
  const BlocJournalPage({this.repository, super.key});

  final JournalRepository? repository;

  @override
  Widget build(BuildContext context) {
    if (!AppServices.of(context).auth.canUseProtectedFeatures) {
      return const SignInGuard(
        child: Text('Private journaling is ready after sign in.'),
      );
    }
    final journalRepository =
        repository ?? JournalRepository(context.read<HappifyRepository>());
    return BlocProvider(
      create: (_) => JournalCubit(repository: journalRepository)..load(),
      child: const _BlocJournalView(),
    );
  }
}

class _BlocJournalView extends StatefulWidget {
  const _BlocJournalView();

  @override
  State<_BlocJournalView> createState() => _BlocJournalViewState();
}

class _BlocJournalViewState extends State<_BlocJournalView> {
  final _title = TextEditingController();
  final _content = TextEditingController();
  String? _detectedMood;

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty || _content.text.trim().isEmpty) {
      showMessage(context, 'Add a title and journal text.');
      return;
    }
    final saved = await context.read<JournalCubit>().createEntry(
      title: _title.text,
      content: _content.text,
      detectedMood: _detectedMood,
    );
    if (!mounted) return;
    final state = context.read<JournalCubit>().state;
    if (!saved) {
      showMessage(
        context,
        state.actionError ?? 'The journal entry could not be saved.',
      );
      return;
    }
    _title.clear();
    _content.clear();
    setState(() => _detectedMood = null);
    final risk = state.lastCreatedRisk ?? 'LOW';
    showMessage(
      context,
      risk == 'HIGH' || risk == 'CRISIS'
          ? 'Entry saved. Happify also created a professional care request.'
          : 'Journal entry saved.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<JournalCubit, JournalState>(
      builder: (context, state) {
        return LoadMoreSentinel(
          enabled: state.hasMore,
          loading: state.loadingMore,
          onLoadMore: context.read<JournalCubit>().loadMore,
          child: HappifyPage(
            title: 'Journal',
            refresh: context.read<JournalCubit>().refresh,
            bottomPadding: 110,
            children: [
              FeatureCard(
                child: Column(
                  children: [
                    TextField(
                      controller: _title,
                      enabled: !state.creating,
                      maxLength: 120,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Entry title',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _content,
                      enabled: !state.creating,
                      minLines: 5,
                      maxLines: 10,
                      maxLength: 20000,
                      decoration: const InputDecoration(
                        labelText: 'Write what you are feeling',
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String?>(
                      initialValue: _detectedMood,
                      decoration: const InputDecoration(
                        labelText: 'Mood hint (optional)',
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          child: Text('Let Happify reflect'),
                        ),
                        ...moodOptions.map(
                          (option) => DropdownMenuItem<String?>(
                            value: option.$1,
                            child: Row(
                              children: [
                                happifyMoodEmoji(option.$1, size: 24),
                                const SizedBox(width: 8),
                                Text(option.$2),
                              ],
                            ),
                          ),
                        ),
                      ],
                      onChanged: state.creating
                          ? null
                          : (value) => setState(() => _detectedMood = value),
                    ),
                    const SizedBox(height: 14),
                    HappifyButton(
                      label: state.creating
                          ? 'Saving and reflecting...'
                          : 'Save entry',
                      onPressed: state.isBusy ? null : _save,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              FeatureCard(
                color: Colors.white,
                divider: true,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'History',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    HistoryDateRangeFilter(
                      startDate: state.startDate,
                      endDate: state.endDate,
                      onApply: (startDate, endDate) =>
                          context.read<JournalCubit>().applyDateFilter(
                            startDate: startDate,
                            endDate: endDate,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              AsyncStateView(
                loading: state.status == JournalStatus.loading,
                error: state.status == JournalStatus.failure
                    ? state.errorMessage
                    : null,
                isEmpty: state.status == JournalStatus.empty,
                emptyMessage: 'Your saved journal entries will appear here.',
                onRetry: context.read<JournalCubit>().load,
                child: Column(
                  children: [
                    ...state.entries.map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _JournalEntryCard(entry: entry),
                      ),
                    ),
                    if (state.actionError != null && !state.creating)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 10),
                        child: FeatureCard(
                          child: Text(
                            'We could not save this entry. Please try again.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    if (state.loadingMore)
                      const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: CircularProgressIndicator(),
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

class _JournalEntryCard extends StatefulWidget {
  const _JournalEntryCard({required this.entry});

  final Map<String, dynamic> entry;

  @override
  State<_JournalEntryCard> createState() => _JournalEntryCardState();
}

class _JournalEntryCardState extends State<_JournalEntryCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final content = entry['content']?.toString() ?? '';
    final reflection = entry['aiReflection']?.toString();
    final mood = entry['detectedMood']?.toString();
    return FeatureCard(
      padding: EdgeInsets.zero,
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
        childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
        leading: ExcludeSemantics(
          child: mood == null
              ? HappifyEmoji.journal(size: 36)
              : happifyMoodEmoji(mood, size: 36),
        ),
        title: Text(
          entry['title']?.toString() ?? 'Untitled entry',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Text(shortDate(entry['createdAt'])),
        onExpansionChanged: (expanded) => setState(() => _expanded = expanded),
        trailing: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Chip(label: Text(prettyEnum(entry['riskLevel']))),
            Icon(
              _expanded
                  ? PhosphorIcons.caretDown(PhosphorIconsStyle.bold)
                  : PhosphorIcons.caretRight(PhosphorIconsStyle.bold),
              color: Colors.black,
              size: 20,
            ),
          ],
        ),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: HappifyRichText(content),
          ),
          if (mood != null) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Detected mood: ${prettyEnum(mood)}'),
            ),
          ],
          if (reflection != null && reflection.isNotEmpty) ...[
            const Divider(height: 28),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Reflection',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 6),
            Align(alignment: Alignment.centerLeft, child: Text(reflection)),
          ],
        ],
      ),
    );
  }
}
