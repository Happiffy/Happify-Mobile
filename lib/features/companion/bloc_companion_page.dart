import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/app_services.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/happify_emoji.dart';
import '../../core/widgets/quokka_badge.dart';
import 'bloc/companion_cubit.dart';
import 'bloc/companion_state.dart';
import 'bloc_device_detail_sheet.dart';
import 'data/companion_repository.dart';

class BlocCompanionPage extends StatelessWidget {
  const BlocCompanionPage({this.clock, super.key});

  final CompanionClock? clock;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CompanionCubit(
        repository: context.read<CompanionRepository>(),
        clock: clock,
      )..load(),
      child: const _BlocCompanionView(),
    );
  }
}

class _BlocCompanionView extends StatelessWidget {
  const _BlocCompanionView();

  Future<void> _showPairingDialog(BuildContext context) async {
    final cubit = context.read<CompanionCubit>()..clearPairingFormErrors();
    await showDialog<void>(
      context: context,
      builder: (_) =>
          BlocProvider.value(value: cubit, child: const _PairingDialog()),
    );
  }

  Future<void> _openDevice(
    BuildContext context,
    Map<String, dynamic> device,
  ) async {
    final unpaired = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => BlocDeviceDetailSheet(device: device),
    );
    if (unpaired == true && context.mounted) {
      await context.read<CompanionCubit>().refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Happify Companion')),
      floatingActionButton: BlocSelector<CompanionCubit, CompanionState, bool>(
        selector: (state) => state.pairingBusy,
        builder: (context, pairingBusy) => FloatingActionButton.extended(
          onPressed: pairingBusy ? null : () => _showPairingDialog(context),
          icon: HappifyEmoji.link(size: 28),
          label: const Text('Pair device'),
        ),
      ),
      body: BlocBuilder<CompanionCubit, CompanionState>(
        builder: (context, state) {
          final loadError = state.status == CompanionStatus.failure
              ? state.errorMessage
              : null;
          return HappifyPage(
            refresh: context.read<CompanionCubit>().refresh,
            children: [
              const Center(child: QuokkaBadge(size: 130, calm: true)),
              const SizedBox(height: 12),
              const _PairingGuide(),
              const SizedBox(height: 14),
              if (state.status == CompanionStatus.refreshing)
                const LinearProgressIndicator(),
              if (state.status == CompanionStatus.refreshing)
                const SizedBox(height: 12),
              if (state.pairing != null) ...[
                _PairingCard(state: state),
                const SizedBox(height: 14),
              ],
              AsyncStateView(
                loading:
                    state.status == CompanionStatus.initial ||
                    state.status == CompanionStatus.loading,
                error: loadError,
                isEmpty: state.devices.isEmpty,
                emptyMessage: 'No Companion is paired with this account.',
                onRetry: context.read<CompanionCubit>().load,
                child: Column(
                  children: state.devices
                      .map(
                        (device) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: FeatureCard(
                            onTap: () => _openDevice(context, device),
                            child: Row(
                              children: [
                                HappifyEmoji.companion(size: 42),

                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        device['displayName']?.toString() ??
                                            device['model']?.toString() ??
                                            'Companion',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleMedium,
                                      ),
                                      Text(
                                        '${device['serialNumber'] ?? ''} · ${prettyEnum(device['status'])}',
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  PhosphorIcons.caretRight(
                                    PhosphorIconsStyle.bold,
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
        },
      ),
    );
  }
}

class _PairingGuide extends StatelessWidget {
  const _PairingGuide();

  @override
  Widget build(BuildContext context) {
    final steps = [
      ('1', HappifyEmoji.iot(size: 34), 'Register simulator'),
      ('2', HappifyEmoji.link(size: 34), 'Pair securely'),
      ('3', HappifyEmoji.companion(size: 34), 'Haptic, data & OTA'),
    ];
    return FeatureCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Companion demo flow',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Row(
            children: steps
                .map(
                  (step) => Expanded(
                    child: Semantics(
                      label: 'Step ${step.$1}: ${step.$3}',
                      child: Column(
                        children: [
                          step.$2,
                          const SizedBox(height: 6),
                          Text(
                            step.$3,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                )
                .toList(growable: false),
          ),
        ],
      ),
    );
  }
}

class _PairingCard extends StatelessWidget {
  const _PairingCard({required this.state});

  final CompanionState state;

  @override
  Widget build(BuildContext context) {
    final device = objectMap(state.pairing?['device']);
    final pairingStatus = state.pairingExpired
        ? 'Expired'
        : prettyEnum(state.pairingStatus);
    final remaining = state.pairingRemaining;
    final countdown =
        '${remaining.inMinutes}:${(remaining.inSeconds % 60).toString().padLeft(2, '0')}';
    final cubit = context.read<CompanionCubit>();
    return FeatureCard(
      color: const Color(0xFFEAF8FF),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              HappifyEmoji.iot(size: 34),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Pairing $pairingStatus',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ],
          ),

          Semantics(
            liveRegion: true,
            label: 'Pairing time remaining $countdown',
            child: ExcludeSemantics(child: Text('Time remaining: $countdown')),
          ),
          Text('Device: ${device['serialNumber'] ?? ''}'),
          if (state.pairingErrorMessage != null) ...[
            const SizedBox(height: 8),
            Semantics(
              liveRegion: true,
              child: Text(
                state.pairingErrorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              TextButton.icon(
                onPressed: state.pairingBusy ? null : cubit.refreshPairing,
                icon: Icon(
                  PhosphorIcons.arrowClockwise(PhosphorIconsStyle.bold),
                ),

                label: const Text('Refresh status'),
              ),
              FilledButton(
                onPressed: state.pairingBusy || !state.canComplete
                    ? null
                    : cubit.completePairing,
                child: const Text('Complete'),
              ),
              TextButton(
                onPressed: state.pairingBusy ? null : cubit.cancelPairing,
                child: const Text('Cancel'),
              ),
              if (state.pairingBusy)
                const SizedBox.square(
                  dimension: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PairingDialog extends StatefulWidget {
  const _PairingDialog();

  @override
  State<_PairingDialog> createState() => _PairingDialogState();
}

class _PairingDialogState extends State<_PairingDialog> {
  final _serial = TextEditingController();
  final _claimSecret = TextEditingController();
  final _claimSecretFocus = FocusNode();

  Future<void> _submit() async {
    final paired = await context.read<CompanionCubit>().startPairing(
      _serial.text,
      _claimSecret.text,
    );
    if (paired && mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _serial.dispose();
    _claimSecret.dispose();
    _claimSecretFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CompanionCubit, CompanionState>(
      builder: (context, state) => AlertDialog(
        title: const Text('Start Companion pairing'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FeatureCard(
                color: const Color(0xFFF1FFE8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    HappifyEmoji.companion(size: 42),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Demo IoT: use serial HAPPIFY-SIM-001 after the backend simulator is registered. Enter the private claim code configured on the deployed backend; Happify never ships that secret inside the app.',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: state.pairingBusy
                      ? null
                      : () => _serial.text = 'HAPPIFY-SIM-001',
                  icon: HappifyEmoji.iot(size: 24),
                  label: const Text('Use demo serial'),
                ),
              ),
              TextField(
                controller: _serial,

                autofocus: true,
                enabled: !state.pairingBusy,
                maxLength: 80,
                textCapitalization: TextCapitalization.characters,
                textInputAction: TextInputAction.next,
                autocorrect: false,
                enableSuggestions: false,
                onSubmitted: (_) => _claimSecretFocus.requestFocus(),
                decoration: InputDecoration(
                  labelText: 'Serial number',
                  helperText: '8-80 letters, numbers, or hyphens',
                  errorText: state.serialError,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _claimSecret,
                focusNode: _claimSecretFocus,
                enabled: !state.pairingBusy,
                maxLength: 256,
                obscureText: true,
                textInputAction: TextInputAction.done,
                autocorrect: false,
                enableSuggestions: false,
                onSubmitted: state.pairingBusy ? null : (_) => _submit(),
                decoration: InputDecoration(
                  labelText: 'Claim code',
                  helperText: 'At least 16 characters',
                  errorText: state.claimSecretError,
                ),
              ),
              if (state.pairingErrorMessage != null) ...[
                const SizedBox(height: 8),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    state.pairingErrorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: state.pairingBusy ? null : () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: state.pairingBusy ? null : _submit,
            child: state.pairingBusy
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Start'),
          ),
        ],
      ),
    );
  }
}
