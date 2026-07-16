import 'package:equatable/equatable.dart';

class CompatibleFirmwareRelease extends Equatable {
  const CompatibleFirmwareRelease({
    required this.id,
    required this.model,
    required this.version,
    required this.hardwareRevision,
    required this.minimumBootloaderVersion,
    required this.protocolVersion,
    required this.releaseNotes,
    required this.createdAt,
  });

  factory CompatibleFirmwareRelease.fromMap(Map<String, dynamic> value) {
    return CompatibleFirmwareRelease(
      id: value['id']?.toString() ?? '',
      model: value['model']?.toString() ?? '',
      version: value['version']?.toString() ?? '',
      hardwareRevision: value['hardwareRevision']?.toString(),
      minimumBootloaderVersion: value['minimumBootloaderVersion']?.toString(),
      protocolVersion: value['protocolVersion']?.toString() ?? '',
      releaseNotes: value['releaseNotes']?.toString(),
      createdAt:
          DateTime.tryParse(value['createdAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }

  final String id;
  final String model;
  final String version;
  final String? hardwareRevision;
  final String? minimumBootloaderVersion;
  final String protocolVersion;
  final String? releaseNotes;
  final DateTime createdAt;

  @override
  List<Object?> get props => [
    id,
    model,
    version,
    hardwareRevision,
    minimumBootloaderVersion,
    protocolVersion,
    releaseNotes,
    createdAt,
  ];
}
