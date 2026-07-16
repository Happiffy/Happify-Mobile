import '../../../core/happify_repository.dart';

class HomeRepository {
  const HomeRepository(this._repository);

  final HappifyRepository _repository;

  Future<Map<String, dynamic>> dashboard() async {
    return _immutableMap(await _repository.dashboard());
  }

  Future<Map<String, dynamic>?> motivation() async {
    final motivation = await _repository.motivation();
    return motivation == null ? null : _immutableMap(motivation);
  }

  Future<List<Map<String, dynamic>>> mindfulness() async {
    final activities = await _repository.mindfulness();
    return List<Map<String, dynamic>>.unmodifiable(
      activities.map(_immutableMap),
    );
  }

  static Map<String, dynamic> _immutableMap(Map<String, dynamic> value) {
    return Map<String, dynamic>.unmodifiable(
      value.map((key, item) => MapEntry(key, _immutableValue(item))),
    );
  }

  static Object? _immutableValue(Object? value) {
    if (value is Map) {
      return _immutableMap(
        value.map((key, item) => MapEntry(key.toString(), item)),
      );
    }
    if (value is List) {
      return List<Object?>.unmodifiable(value.map(_immutableValue));
    }
    return value;
  }
}
