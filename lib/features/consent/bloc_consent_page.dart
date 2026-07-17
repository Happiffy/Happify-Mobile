import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/app_services.dart';
import '../../core/happify_repository.dart';
import '../../core/theme/happify_colors.dart';
import '../../core/theme/happify_theme.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/happify_button.dart';
import '../../core/widgets/happify_emoji.dart';
import '../../core/widgets/happify_rich_text.dart';
import 'bloc/consent_cubit.dart';
import 'bloc/consent_state.dart';
import 'data/consent_repository.dart';

typedef ConsentRouteCallback = FutureOr<void> Function();

class _ConsentVisual {
  const _ConsentVisual({
    required this.emoji,
    required this.surface,
    required this.color,
    required this.summary,
  });

  final Widget Function({double size}) emoji;
  final Color surface;
  final Color color;
  final String summary;
}

_ConsentVisual _consentVisual(String scope) => switch (scope) {
  'AI_PROCESSING' => _ConsentVisual(
    emoji: HappifyEmoji.brain,
    surface: HappifyColors.purpleSurface,
    color: HappifyColors.purpleDark,
    summary: 'AI-assisted reflections, not diagnosis.',
  ),
  'VOICE_PROCESSING' => _ConsentVisual(
    emoji: HappifyEmoji.microphone,
    surface: HappifyColors.blueSurface,
    color: HappifyColors.blueDark,
    summary: 'Transcription and protected voice responses.',
  ),
  'DEVICE_EMOTION_OBSERVATION' => _ConsentVisual(
    emoji: HappifyEmoji.companion,
    surface: HappifyColors.goldSurface,
    color: HappifyColors.goldDark,
    summary: 'Emotion signals from a paired Companion device.',
  ),
  'HEATMAP_CONTRIBUTION' => _ConsentVisual(
    emoji: HappifyEmoji.heatmap,
    surface: HappifyColors.orangeSurface,
    color: HappifyColors.orangeDark,
    summary: 'One anonymous coarse-region mood contribution per day.',
  ),
  _ => _ConsentVisual(
    emoji: HappifyEmoji.shield,
    surface: HappifyColors.greenSurface,
    color: HappifyColors.greenDark,
    summary: 'An optional Happify privacy control.',
  ),
};

class BlocConsentPage extends StatelessWidget {
  const BlocConsentPage({
    required this.onContinue,
    required this.onSignOut,
    this.repository,
    super.key,
  });

  final ConsentRouteCallback onContinue;
  final ConsentRouteCallback onSignOut;
  final ConsentRepository? repository;

  @override
  Widget build(BuildContext context) {
    final consentRepository =
        repository ??
        HappifyConsentRepository(context.read<HappifyRepository>());
    return BlocProvider(
      create: (_) => ConsentCubit(repository: consentRepository)..load(),
      child: BlocConsentView(onContinue: onContinue, onSignOut: onSignOut),
    );
  }
}

class BlocConsentView extends StatefulWidget {
  const BlocConsentView({
    required this.onContinue,
    required this.onSignOut,
    super.key,
  });

  final ConsentRouteCallback onContinue;
  final ConsentRouteCallback onSignOut;

  @override
  State<BlocConsentView> createState() => _BlocConsentViewState();
}

class _BlocConsentViewState extends State<BlocConsentView> {
  bool _routing = false;

  Future<void> _runRoute(ConsentRouteCallback callback) async {
    if (_routing) return;
    setState(() => _routing = true);
    try {
      await Future<void>.sync(callback);
    } catch (error) {
      if (mounted) showMessage(context, failureMessage(error));
    } finally {
      if (mounted) setState(() => _routing = false);
    }
  }

  Future<void> _save({required bool limited}) async {
    final cubit = context.read<ConsentCubit>();
    final saved = limited
        ? await cubit.saveLimited()
        : await cubit.saveSelected();
    if (saved && mounted) await _runRoute(widget.onContinue);
  }

  Future<void> _retrySave() async {
    final saved = await context.read<ConsentCubit>().retrySave();
    if (saved && mounted) await _runRoute(widget.onContinue);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<ConsentCubit, ConsentState>(
        builder: (context, state) {
          final busy = state.isSaving || _routing;
          return HappifyPage(
            title: 'Your data stays yours.',
            refresh: context.read<ConsentCubit>().load,
            children: [
              _PrivacyHero(documentCount: state.documents.length),
              const SizedBox(height: 20),
              if (state.loadStatus == ConsentLoadStatus.loading &&
                  state.documents.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator()),
                ),
              if (state.loadError != null)
                _ConsentMessageCard(
                  icon: HappifyEmoji.warning(size: 34),
                  message: state.loadError!,
                  actionLabel: 'Retry loading',
                  onAction: busy ? null : context.read<ConsentCubit>().load,
                ),
              if (state.loadStatus == ConsentLoadStatus.success &&
                  state.documents.isEmpty)
                _ConsentMessageCard(
                  icon: HappifyEmoji.shield(size: 34),
                  message:
                      'No active consent documents are available. You can still continue and review this page later.',
                ),
              if (state.documents.isNotEmpty)
                ...state.documents.map(
                  (document) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ConsentCard(
                      document: document,
                      value:
                          state.selections[document.scope] ?? document.accepted,
                      enabled: !busy,
                      onChanged: (value) => context
                          .read<ConsentCubit>()
                          .setChoice(document.scope, value),
                    ),
                  ),
                ),
              if (state.isSaving) ...[
                const SizedBox(height: 8),
                _ConsentProgress(state: state),
              ],
              if (state.saveStatus == ConsentSaveStatus.partialFailure) ...[
                const SizedBox(height: 8),
                _ConsentSaveFailure(
                  state: state,
                  onRetry: busy ? null : _retrySave,
                  onContinue: busy ? null : () => _runRoute(widget.onContinue),
                ),
              ],
              if (state.saveStatus == ConsentSaveStatus.success) ...[
                const SizedBox(height: 8),
                _ConsentMessageCard(
                  icon: HappifyEmoji.check(size: 34),
                  message:
                      'All ${state.completedCount} consent choices were saved.',
                ),
              ],
              const SizedBox(height: 20),
              HappifyButton(
                label: _routing
                    ? 'Continuing...'
                    : state.isSaving
                    ? 'Saving ${state.processedCount} of ${state.totalCount}...'
                    : state.documents.isEmpty
                    ? 'Continue to Happify'
                    : 'Save and continue',
                onPressed: busy
                    ? null
                    : state.documents.isEmpty
                    ? () => _runRoute(widget.onContinue)
                    : () => _save(limited: false),
              ),
              TextButton(
                onPressed: busy
                    ? null
                    : state.documents.isEmpty
                    ? () => _runRoute(widget.onContinue)
                    : () => _save(limited: true),
                child: const Text('Continue with limited features'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PrivacyHero extends StatelessWidget {
  const _PrivacyHero({required this.documentCount});

  final int documentCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: HappifyColors.greenSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: HappifyColors.green, width: 2),
        boxShadow: HappifyShadows.card,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: HappifyEmoji.shield(size: 38),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Privacy controls',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: HappifyColors.greenDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Choose what you want to share.',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 6),
                Text(
                  '$documentCount optional controls. You can change these choices later.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConsentCard extends StatelessWidget {
  const _ConsentCard({
    required this.document,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final ConsentDocument document;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final visual = _consentVisual(document.scope);
    return FeatureCard(
      color: visual.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: HappifyColors.line, width: 2),
                ),
                child: visual.emoji(size: 30),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      document.title.isEmpty
                          ? prettyEnum(document.scope)
                          : document.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      visual.summary,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Switch(value: value, onChanged: enabled ? onChanged : null),
            ],
          ),
          const SizedBox(height: 12),
          HappifyRichText(document.content),
          const SizedBox(height: 8),
          Row(
            children: [
              value
                  ? HappifyEmoji.check(size: 18)
                  : HappifyEmoji.whiteHeart(size: 18),
              const SizedBox(width: 6),
              Text(
                value ? 'On' : 'Off',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: value ? visual.color : HappifyColors.inkMuted,
                ),
              ),
              const Spacer(),
              Text(
                'Version ${document.version}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ConsentProgress extends StatelessWidget {
  const _ConsentProgress({required this.state});

  final ConsentState state;

  @override
  Widget build(BuildContext context) {
    final value = state.totalCount == 0
        ? null
        : state.processedCount / state.totalCount;
    return Semantics(
      liveRegion: true,
      label:
          '${state.processedCount} of ${state.totalCount} choices processed, ${state.completedCount} saved',
      child: FeatureCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LinearProgressIndicator(value: value),
            const SizedBox(height: 12),
            Text(
              '${state.processedCount} of ${state.totalCount} processed · ${state.completedCount} saved',
            ),
          ],
        ),
      ),
    );
  }
}

class _ConsentSaveFailure extends StatelessWidget {
  const _ConsentSaveFailure({
    required this.state,
    required this.onRetry,
    required this.onContinue,
  });

  final ConsentState state;
  final VoidCallback? onRetry;
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
    final scopes = state.failedScopes.map(prettyEnum).join(', ');
    return Semantics(
      liveRegion: true,
      child: FeatureCard(
        color: Theme.of(context).colorScheme.errorContainer,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Some choices were not saved',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              '${state.completedCount} of ${state.totalCount} choices were saved. Not saved: $scopes.',
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonal(
                  onPressed: onRetry,
                  child: const Text('Retry save'),
                ),
                TextButton(
                  onPressed: onContinue,
                  child: const Text('Continue with saved choices'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ConsentMessageCard extends StatelessWidget {
  const _ConsentMessageCard({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final Widget icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: FeatureCard(
        child: Column(
          children: [
            icon,
            const SizedBox(height: 10),
            Text(message, textAlign: TextAlign.center),
            if (actionLabel != null) ...[
              const SizedBox(height: 12),
              FilledButton.tonal(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
