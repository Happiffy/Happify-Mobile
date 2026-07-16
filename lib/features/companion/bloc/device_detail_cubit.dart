import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/app_services.dart';
import '../data/companion_repository.dart';
import '../data/compatible_firmware_release.dart';
import 'device_detail_state.dart';

class DeviceDetailCubit extends Cubit<DeviceDetailState> {
  DeviceDetailCubit({required this.repository, required this.deviceId})
    : super(const DeviceDetailState());

  final CompanionRepository repository;
  final String deviceId;

  Future<void> load() async {
    if (state.loading) return;
    emit(state.copyWith(loading: true, clearError: true));
    try {
      final results = await Future.wait<Object>([
        repository.telemetry(deviceId),
        repository.firmwareReleases(deviceId),
      ]);
      emit(
        state.copyWith(
          loading: false,
          telemetry: results[0] as List<Map<String, dynamic>>,
          firmwareReleases: results[1] as List<CompatibleFirmwareRelease>,
        ),
      );
    } catch (error) {
      emit(state.copyWith(loading: false, errorMessage: failureMessage(error)));
    }
  }

  Future<void> sendCalmingHaptic() async {
    if (state.submitting) return;
    emit(state.copyWith(submitting: true, clearError: true));
    try {
      final command = await repository.calmingHaptic(deviceId);
      emit(state.copyWith(submitting: false, lastCommand: command));
    } catch (error) {
      emit(
        state.copyWith(submitting: false, errorMessage: failureMessage(error)),
      );
    }
  }

  Future<void> sendCommand(String type, Map<String, dynamic> payload) async {
    if (state.submitting) return;
    emit(state.copyWith(submitting: true, clearError: true));
    try {
      final command = await repository.command(deviceId, type, payload);
      emit(state.copyWith(submitting: false, lastCommand: command));
    } catch (error) {
      emit(
        state.copyWith(submitting: false, errorMessage: failureMessage(error)),
      );
    }
  }

  Future<void> startOta(CompatibleFirmwareRelease release) async {
    if (state.submitting) return;
    emit(state.copyWith(submitting: true, clearError: true));
    try {
      final ota = await repository.startOta(deviceId, release);
      emit(state.copyWith(submitting: false, lastOta: ota));
    } catch (error) {
      emit(
        state.copyWith(submitting: false, errorMessage: failureMessage(error)),
      );
    }
  }

  Future<void> unpair() async {
    if (state.submitting) return;
    emit(state.copyWith(submitting: true, clearError: true));
    try {
      await repository.unpair(deviceId);
      emit(state.copyWith(submitting: false, unpaired: true));
    } catch (error) {
      emit(
        state.copyWith(submitting: false, errorMessage: failureMessage(error)),
      );
    }
  }
}
