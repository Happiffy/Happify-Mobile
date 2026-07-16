import 'package:equatable/equatable.dart';

import '../data/compatible_firmware_release.dart';

class DeviceDetailState extends Equatable {
  const DeviceDetailState({
    this.loading = false,
    this.submitting = false,
    this.telemetry = const [],
    this.firmwareReleases = const [],
    this.lastCommand,
    this.lastOta,
    this.unpaired = false,
    this.errorMessage,
  });

  final bool loading;
  final bool submitting;
  final List<Map<String, dynamic>> telemetry;
  final List<CompatibleFirmwareRelease> firmwareReleases;
  final Map<String, dynamic>? lastCommand;
  final Map<String, dynamic>? lastOta;
  final bool unpaired;
  final String? errorMessage;

  DeviceDetailState copyWith({
    bool? loading,
    bool? submitting,
    List<Map<String, dynamic>>? telemetry,
    List<CompatibleFirmwareRelease>? firmwareReleases,
    Map<String, dynamic>? lastCommand,
    Map<String, dynamic>? lastOta,
    bool? unpaired,
    String? errorMessage,
    bool clearError = false,
  }) {
    return DeviceDetailState(
      loading: loading ?? this.loading,
      submitting: submitting ?? this.submitting,
      telemetry: telemetry ?? this.telemetry,
      firmwareReleases: firmwareReleases ?? this.firmwareReleases,
      lastCommand: lastCommand ?? this.lastCommand,
      lastOta: lastOta ?? this.lastOta,
      unpaired: unpaired ?? this.unpaired,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    loading,
    submitting,
    telemetry,
    firmwareReleases,
    lastCommand,
    lastOta,
    unpaired,
    errorMessage,
  ];
}
