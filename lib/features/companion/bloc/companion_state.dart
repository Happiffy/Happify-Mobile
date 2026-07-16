import 'package:equatable/equatable.dart';

enum CompanionStatus { initial, loading, refreshing, success, failure }

class CompanionState extends Equatable {
  const CompanionState({
    this.status = CompanionStatus.initial,
    this.devices = const [],
    this.pairing,
    this.pairingRemaining = Duration.zero,
    this.pairingBusy = false,
    this.serialError,
    this.claimSecretError,
    this.errorMessage,
    this.pairingErrorMessage,
  });

  final CompanionStatus status;
  final List<Map<String, dynamic>> devices;
  final Map<String, dynamic>? pairing;
  final Duration pairingRemaining;
  final bool pairingBusy;
  final String? serialError;
  final String? claimSecretError;
  final String? errorMessage;
  final String? pairingErrorMessage;

  String? get pairingStatus => pairing?['status']?.toString();

  bool get pairingExpired =>
      pairingStatus == 'EXPIRED' ||
      (pairingStatus == 'PENDING' && pairingRemaining == Duration.zero);

  bool get canComplete => pairingStatus == 'PENDING' && !pairingExpired;

  CompanionState copyWith({
    CompanionStatus? status,
    List<Map<String, dynamic>>? devices,
    Map<String, dynamic>? pairing,
    bool clearPairing = false,
    Duration? pairingRemaining,
    bool? pairingBusy,
    String? serialError,
    bool clearSerialError = false,
    String? claimSecretError,
    bool clearClaimSecretError = false,
    String? errorMessage,
    bool clearError = false,
    String? pairingErrorMessage,
    bool clearPairingError = false,
  }) {
    return CompanionState(
      status: status ?? this.status,
      devices: devices ?? this.devices,
      pairing: clearPairing ? null : pairing ?? this.pairing,
      pairingRemaining: clearPairing
          ? Duration.zero
          : pairingRemaining ?? this.pairingRemaining,
      pairingBusy: pairingBusy ?? this.pairingBusy,
      serialError: clearSerialError ? null : serialError ?? this.serialError,
      claimSecretError: clearClaimSecretError
          ? null
          : claimSecretError ?? this.claimSecretError,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      pairingErrorMessage: clearPairingError
          ? null
          : pairingErrorMessage ?? this.pairingErrorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    devices,
    pairing,
    pairingRemaining,
    pairingBusy,
    serialError,
    claimSecretError,
    errorMessage,
    pairingErrorMessage,
  ];
}
