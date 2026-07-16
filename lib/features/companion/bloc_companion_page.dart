import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/theme/happify_colors.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/happify_button.dart';
import '../../core/widgets/happify_emoji.dart';
import 'bloc/companion_cubit.dart';
import 'bloc/companion_state.dart';
import 'bloc_device_detail_sheet.dart';
import 'data/companion_repository.dart';

class BlocCompanionPage extends StatelessWidget {
  const BlocCompanionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          CompanionCubit(repository: context.read<CompanionRepository>())
            ..load(),
      child: const _BlocCompanionView(),
    );
  }
}

class _BlocCompanionView extends StatelessWidget {
  const _BlocCompanionView();

  Future<void> _openDevice(
    BuildContext context,
    Map<String, dynamic> device,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => BlocDeviceDetailSheet(device: device),
    );
    if (context.mounted) await context.read<CompanionCubit>().refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Happify Companion')),
      body: BlocBuilder<CompanionCubit, CompanionState>(
        builder: (context, state) {
          final device = state.devices.firstOrNull;
          final loadError = state.status == CompanionStatus.failure
              ? state.errorMessage
              : null;
          return HappifyPage(
            refresh: context.read<CompanionCubit>().refresh,
            children: [
              if (state.status == CompanionStatus.refreshing)
                const LinearProgressIndicator(),
              if (state.status == CompanionStatus.refreshing)
                const SizedBox(height: 14),
              AsyncStateView(
                loading:
                    state.status == CompanionStatus.initial ||
                    state.status == CompanionStatus.loading,
                error: loadError,
                isEmpty: device == null,
                emptyMessage:
                    'Your hackathon Companion is not available yet. Check the IoT service and pull to refresh.',
                onRetry: context.read<CompanionCubit>().load,
                child: device == null
                    ? const SizedBox.shrink()
                    : _SingleCompanionCard(
                        device: device,
                        onOpen: () => _openDevice(context, device),
                      ),
              ),
              const SizedBox(height: 16),
              FeatureCard(
                color: HappifyColors.blueSurface,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    HappifyEmoji.iot(size: 30),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'This app is prepared for one dedicated IoT Companion. Connection, mood sync, telemetry, and calming feedback happen automatically.',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SingleCompanionCard extends StatelessWidget {
  const _SingleCompanionCard({required this.device, required this.onOpen});

  final Map<String, dynamic> device;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final lastSeen = DateTime.tryParse(device['lastSeenAt']?.toString() ?? '');
    final online =
        lastSeen != null &&
        DateTime.now().toUtc().difference(lastSeen.toUtc()).inMinutes < 3;
    final name =
        device['displayName']?.toString() ??
        device['model']?.toString() ??
        'Happify Companion';

    return FeatureCard(
      color: HappifyColors.greenSurface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ExcludeSemantics(child: HappifyEmoji.companion(size: 58)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: online
                                ? HappifyColors.green
                                : HappifyColors.inkMuted,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 7),
                        Text(online ? 'Connected' : 'Waiting for connection'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            lastSeen == null
                ? 'No heartbeat received yet.'
                : 'Last sync: ${shortDate(lastSeen)}',
          ),
          const SizedBox(height: 16),
          HappifyButton(
            label: 'Open Companion',
            leading: HappifyEmoji.next(size: 22),
            onPressed: onOpen,
          ),
        ],
      ),
    );
  }
}
