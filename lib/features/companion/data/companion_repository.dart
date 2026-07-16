import '../../../core/happify_repository.dart';
import 'compatible_firmware_release.dart';

class CompanionRepository {
  const CompanionRepository(this._repository);

  final HappifyRepository _repository;

  Future<List<Map<String, dynamic>>> devices() => _repository.devices();

  Future<Map<String, dynamic>> startPairing(String serial, String secret) =>
      _repository.startPairing(serial, secret);

  Future<Map<String, dynamic>> pairing(String id) => _repository.pairing(id);

  Future<void> completePairing(String id) => _repository.completePairing(id);

  Future<void> cancelPairing(String id) => _repository.cancelPairing(id);

  Future<List<Map<String, dynamic>>> telemetry(String id) =>
      _repository.telemetry(id);

  Future<Map<String, dynamic>> calmingHaptic(String id) =>
      _repository.calmingHaptic(id);

  Future<Map<String, dynamic>> command(
    String id,
    String type,
    Map<String, dynamic> payload,
  ) => _repository.command(id, type, payload);

  Future<List<CompatibleFirmwareRelease>> firmwareReleases(String id) async {
    final values = await _repository.firmwareReleases(id);
    return values
        .map(CompatibleFirmwareRelease.fromMap)
        .toList(growable: false);
  }

  Future<Map<String, dynamic>> startOta(
    String id,
    CompatibleFirmwareRelease release,
  ) => _repository.ota(id, release.id);

  Future<void> unpair(String id) => _repository.unpair(id);
}
