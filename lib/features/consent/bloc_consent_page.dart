import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/app_services.dart';
import '../../core/happify_repository.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/happify_button.dart';
import '../../core/widgets/quokka_badge.dart';
import 'bloc/consent_cubit.dart';
import 'bloc/consent_state.dart';
import 'data/consent_repository.dart';

typedef ConsentRouteCallback = FutureOr<void> Function();

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
              const Center(child: QuokkaBadge(size: 100, calm: true)),
              const SizedBox(height: 16),
              Text(
                'Choose which optional Happify features may process your data. You can change these choices later.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 20),
              if (state.loadStatus == ConsentLoadStatus.loading &&
                  state.documents.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator()),
                ),
              if (state.loadError != null)
                _ConsentMessageCard(
                  icon: Icons.warning_amber_rounded,
                  message: state.loadError!,
                  actionLabel: 'Retry loading',
                  onAction: busy ? null : context.read<ConsentCubit>().load,
                ),
              if (state.loadStatus == ConsentLoadStatus.success &&
                  state.documents.isEmpty)
                const _ConsentMessageCard(
                  icon: Icons.privacy_tip_outlined,
                  message:
                      'No active consent documents are available. You can still continue and review this page later.',
                ),
              if (state.documents.isNotEmpty)
                ...state.documents.map(
                  (document) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: FeatureCard(
                      child: SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          document.title.isEmpty
                              ? prettyEnum(document.scope)
                              : document.title,
                        ),
                        subtitle: Text(
                          '${document.content}\nVersion ${document.version}',
                        ),
                        value:
                            state.selections[document.scope] ??
                            document.accepted,
                        onChanged: busy
                            ? null
                            : (value) => context.read<ConsentCubit>().setChoice(
                                document.scope,
                                value,
                              ),
                      ),
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
                  icon: Icons.check_circle_outline,
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
                icon: Icons.check,
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
              TextButton.icon(
                onPressed: busy ? null : () => _runRoute(widget.onSignOut),
                icon: const Icon(Icons.logout),
                label: const Text('Sign out'),
              ),
            ],
          );
        },
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

  final IconData icon;
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
            Icon(icon, size: 34),
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
