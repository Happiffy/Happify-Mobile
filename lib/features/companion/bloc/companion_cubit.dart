import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/app_services.dart';
import '../data/companion_repository.dart';
import 'companion_state.dart';

typedef CompanionClock = DateTime Function();

class CompanionCubit extends Cubit<CompanionState> {
  CompanionCubit({required this.repository, CompanionClock? clock})
    : _clock = clock ?? DateTime.now,
      super(const CompanionState());

  static final RegExp _serialPattern = RegExp(r'^[A-Z0-9-]+$');

  final CompanionRepository repository;
  final CompanionClock _clock;
  Timer? _pairingTimer;
  bool _loading = false;

  Future<void> load() => _load(refreshing: false);

  Future<void> refresh() => _load(refreshing: true);

  Future<void> _load({required bool refreshing}) async {
    if (_loading) return;
    _loading = true;
    emit(
      state.copyWith(
        status: refreshing
            ? CompanionStatus.refreshing
            : CompanionStatus.loading,
        clearError: true,
      ),
    );
    try {
      final devices = await repository.devices();
      if (devices.isEmpty) await repository.ensureCompanion();
      final companionDevices = devices.isEmpty
          ? await repository.devices()
          : devices;
      emit(
        state.copyWith(
          status: CompanionStatus.success,
          devices: List.unmodifiable(companionDevices),
          clearError: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: CompanionStatus.failure,
          errorMessage: failureMessage(error),
        ),
      );
    } finally {
      _loading = false;
    }
  }

  Future<bool> startPairing(String serial, String claimSecret) async {
    if (state.pairingBusy) return false;
    final normalizedSerial = serial.trim().toUpperCase();
    final serialError = _validateSerial(normalizedSerial);
    final claimSecretError = _validateClaimSecret(claimSecret);
    if (serialError != null || claimSecretError != null) {
      emit(
        state.copyWith(
          serialError: serialError,
          clearSerialError: serialError == null,
          claimSecretError: claimSecretError,
          clearClaimSecretError: claimSecretError == null,
          clearPairingError: true,
        ),
      );
      return false;
    }
    emit(
      state.copyWith(
        pairingBusy: true,
        clearSerialError: true,
        clearClaimSecretError: true,
        clearPairingError: true,
      ),
    );
    try {
      final pairing = await repository.startPairing(
        normalizedSerial,
        claimSecret,
      );
      _adoptPairing(pairing);
      return true;
    } catch (error) {
      emit(
        state.copyWith(
          pairingBusy: false,
          pairingErrorMessage: failureMessage(error),
        ),
      );
      return false;
    }
  }

  Future<void> refreshPairing() async {
    final id = state.pairing?['id']?.toString();
    if (id == null || state.pairingBusy) return;
    emit(state.copyWith(pairingBusy: true, clearPairingError: true));
    try {
      final pairing = await repository.pairing(id);
      _adoptPairing(pairing);
    } catch (error) {
      emit(
        state.copyWith(
          pairingBusy: false,
          pairingErrorMessage: failureMessage(error),
        ),
      );
    }
  }

  Future<bool> completePairing() async {
    final id = state.pairing?['id']?.toString();
    if (id == null || state.pairingBusy || !state.canComplete) return false;
    emit(state.copyWith(pairingBusy: true, clearPairingError: true));
    try {
      await repository.completePairing(id);
      _clearPairing();
      await refresh();
      return true;
    } catch (error) {
      emit(
        state.copyWith(
          pairingBusy: false,
          pairingErrorMessage: failureMessage(error),
        ),
      );
      return false;
    }
  }

  Future<bool> cancelPairing() async {
    final id = state.pairing?['id']?.toString();
    if (id == null || state.pairingBusy) return false;
    emit(state.copyWith(pairingBusy: true, clearPairingError: true));
    try {
      await repository.cancelPairing(id);
      _clearPairing();
      return true;
    } catch (error) {
      emit(
        state.copyWith(
          pairingBusy: false,
          pairingErrorMessage: failureMessage(error),
        ),
      );
      return false;
    }
  }

  void clearPairingFormErrors() {
    if (state.serialError == null &&
        state.claimSecretError == null &&
        state.pairingErrorMessage == null) {
      return;
    }
    emit(
      state.copyWith(
        clearSerialError: true,
        clearClaimSecretError: true,
        clearPairingError: true,
      ),
    );
  }

  void updatePairingCountdown() {
    if (isClosed) return;
    final pairing = state.pairing;
    if (pairing == null) {
      _pairingTimer?.cancel();
      return;
    }
    final remaining = _remaining(pairing);
    if (remaining == Duration.zero) _pairingTimer?.cancel();
    if (remaining != state.pairingRemaining) {
      emit(state.copyWith(pairingRemaining: remaining));
    }
  }

  String? _validateSerial(String serial) {
    if (serial.length < 8 ||
        serial.length > 80 ||
        !_serialPattern.hasMatch(serial)) {
      return 'Enter 8-80 letters, numbers, or hyphens.';
    }
    return null;
  }

  String? _validateClaimSecret(String claimSecret) {
    if (claimSecret.length < 16 || claimSecret.length > 256) {
      return 'Claim code must be 16-256 characters.';
    }
    return null;
  }

  Duration _remaining(Map<String, dynamic> pairing) {
    if (pairing['status']?.toString() != 'PENDING') return Duration.zero;
    final expiresAt = DateTime.tryParse(pairing['expiresAt']?.toString() ?? '');
    if (expiresAt == null) return Duration.zero;
    final remaining = expiresAt.toUtc().difference(_clock().toUtc());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  void _adoptPairing(Map<String, dynamic> pairing) {
    final remaining = _remaining(pairing);
    emit(
      state.copyWith(
        pairing: Map.unmodifiable(pairing),
        pairingRemaining: remaining,
        pairingBusy: false,
        clearPairingError: true,
      ),
    );
    _pairingTimer?.cancel();
    if (remaining > Duration.zero) {
      _pairingTimer = Timer.periodic(
        const Duration(seconds: 1),
        (_) => updatePairingCountdown(),
      );
    }
  }

  void _clearPairing() {
    _pairingTimer?.cancel();
    emit(
      state.copyWith(
        clearPairing: true,
        pairingBusy: false,
        clearSerialError: true,
        clearClaimSecretError: true,
        clearPairingError: true,
      ),
    );
  }

  @override
  Future<void> close() {
    _pairingTimer?.cancel();
    return super.close();
  }
}
