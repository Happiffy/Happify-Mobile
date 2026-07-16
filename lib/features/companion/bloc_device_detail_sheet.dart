import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/happify_emoji.dart';
import 'bloc/device_detail_cubit.dart';
import 'bloc/device_detail_state.dart';
import 'data/companion_repository.dart';
import 'data/compatible_firmware_release.dart';

class BlocDeviceDetailSheet extends StatelessWidget {
  const BlocDeviceDetailSheet({required this.device, super.key});

  final Map<String, dynamic> device;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DeviceDetailCubit(
        repository: context.read<CompanionRepository>(),
        deviceId: device['id'].toString(),
      )..load(),
      child: _BlocDeviceDetailView(device: device),
    );
  }
}

class _BlocDeviceDetailView extends StatelessWidget {
  const _BlocDeviceDetailView({required this.device});

  final Map<String, dynamic> device;

  Future<void> _customCommand(BuildContext context) async {
    final type = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                PhosphorIcons.arrowsClockwise(PhosphorIconsStyle.bold),
              ),

              title: const Text('Restart Companion'),
              onTap: () => Navigator.pop(context, 'RESTART'),
            ),
          ],
        ),
      ),
    );
    if (type == null || !context.mounted) return;
    await context.read<DeviceDetailCubit>().sendCommand(type, {
      'delaySeconds': 0,
    });
  }

  Future<void> _startOta(
    BuildContext context,
    List<CompatibleFirmwareRelease> releases,
  ) async {
    final release = await showModalBottomSheet<CompatibleFirmwareRelease>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        if (releases.isEmpty) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  HappifyEmoji.update(size: 54),

                  const SizedBox(height: 12),
                  Text(
                    'No compatible firmware',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Your Companion is up to date or no release matches its hardware and protocol.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 18),
                  FilledButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ),
          );
        }
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.sizeOf(context).height * .6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 4, 24, 12),
                  child: Text(
                    'Choose firmware',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                    itemCount: releases.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final release = releases[index];
                      final notes = release.releaseNotes?.trim();
                      return ListTile(
                        leading: HappifyEmoji.update(size: 32),

                        title: Text('Version ${release.version}'),
                        subtitle: Text(
                          notes?.isNotEmpty == true
                              ? notes!
                              : 'Compatible with protocol ${release.protocolVersion}',
                        ),
                        trailing: Icon(
                          PhosphorIcons.caretRight(PhosphorIconsStyle.bold),
                        ),

                        onTap: () => Navigator.pop(context, release),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (release == null || !context.mounted) return;
    await context.read<DeviceDetailCubit>().startOta(release);
  }

  Future<void> _confirmUnpair(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unpair Companion?'),
        content: const Text(
          'This Companion will stop syncing with your account until it is paired again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep paired'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Unpair'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<DeviceDetailCubit>().unpair();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DeviceDetailCubit, DeviceDetailState>(
      listenWhen: (previous, current) =>
          previous.unpaired != current.unpaired ||
          previous.errorMessage != current.errorMessage,
      listener: (context, state) {
        if (state.unpaired) {
          Navigator.pop(context, true);
        } else if (state.errorMessage != null) {
          showMessage(context, state.errorMessage!);
        }
      },
      child: SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .9,
          child: BlocBuilder<DeviceDetailCubit, DeviceDetailState>(
            builder: (context, state) {
              return HappifyPage(
                title:
                    device['displayName']?.toString() ??
                    device['model'].toString(),
                refresh: context.read<DeviceDetailCubit>().load,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      HappifyEmoji.companion(size: 52),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Serial: ${device['serialNumber']}'),
                            Text('Status: ${prettyEnum(device['status'])}'),
                          ],
                        ),
                      ),
                    ],
                  ),

                  Text('Paired: ${shortDate(device['pairedAt'])}'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton.icon(
                        onPressed: state.submitting
                            ? null
                            : context
                                  .read<DeviceDetailCubit>()
                                  .sendCalmingHaptic,
                        icon: Icon(
                          PhosphorIcons.vibrate(PhosphorIconsStyle.bold),
                        ),

                        label: const Text('Calming haptic'),
                      ),
                      OutlinedButton(
                        onPressed: state.submitting
                            ? null
                            : () => _customCommand(context),
                        child: const Text('Device actions'),
                      ),
                      OutlinedButton(
                        onPressed: state.submitting
                            ? null
                            : () => _startOta(context, state.firmwareReleases),
                        child: const Text('Start OTA'),
                      ),
                    ],
                  ),
                  if (state.lastCommand != null)
                    FeatureCard(
                      child: Text(
                        'Latest command: ${state.lastCommand!['type']} · ${prettyEnum(state.lastCommand!['status'])}',
                      ),
                    ),
                  if (state.lastOta != null)
                    FeatureCard(
                      child: Text(
                        'Latest OTA: ${prettyEnum(state.lastOta!['status'])} · ${state.lastOta!['progress'] ?? 0}%',
                      ),
                    ),
                  const SizedBox(height: 16),
                  Text(
                    'Telemetry',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  AsyncStateView(
                    loading: state.loading,
                    error: state.errorMessage,
                    isEmpty: state.telemetry.isEmpty,
                    emptyMessage:
                        'No telemetry has been received from this Companion.',
                    onRetry: context.read<DeviceDetailCubit>().load,
                    child: Column(
                      children: state.telemetry
                          .map(
                            (item) => ListTile(
                              title: Text(item['metric'].toString()),
                              subtitle: Text(shortDate(item['recordedAt'])),
                              trailing: Text(
                                '${item['value']} ${item['unit'] ?? ''}',
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextButton.icon(
                    onPressed: state.submitting
                        ? null
                        : () => _confirmUnpair(context),
                    icon: Icon(
                      PhosphorIcons.linkBreak(PhosphorIconsStyle.bold),
                    ),

                    label: const Text('Unpair device'),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
