import '../../../core/app_services.dart';
import '../../../core/happify_repository.dart';

class MoodRepository {
  const MoodRepository(this._repository);

  final HappifyRepository _repository;

  Future<List<Map<String, dynamic>>> moods({int limit = 30}) async {
    final moods = await _repository.moods(limit: limit);
    return _immutableList(moods);
  }

  Future<Map<String, dynamic>> dashboard() async {
    return _immutableMap(await _repository.dashboard());
  }

  Future<Map<String, dynamic>> saveMood({
    required String state,
    required int intensity,
    required List<String> triggers,
    String? note,
  }) async {
    final mood = await _repository.saveMood(
      state: state,
      intensity: intensity,
      triggers: List.unmodifiable(triggers),
      note: note,
    );
    return _immutableMap(mood);
  }

  static String? dashboardInsight(Map<String, dynamic> dashboard) {
    final direct = _nonEmptyString(
      dashboard['moodInsight'] ?? dashboard['insight'] ?? dashboard['summary'],
    );
    if (direct != null) return direct;
    final insights = objectMap(dashboard['insights']);
    final nested = _nonEmptyString(
      insights['mood'] ?? insights['summary'] ?? insights['message'],
    );
    if (nested != null) return nested;
    for (final journal in objectList(dashboard['recentJournals'])) {
      final reflection = _nonEmptyString(journal['aiReflection']);
      if (reflection != null) return reflection;
    }
    return null;
  }

  static Map<String, dynamic> _immutableMap(Map<String, dynamic> value) {
    return Map<String, dynamic>.unmodifiable(
      value.map((key, item) {
        if (item is Map) return MapEntry(key, _immutableMap(objectMap(item)));
        if (item is List) {
          return MapEntry(
            key,
            List<Object?>.unmodifiable(item.map(_immutableValue)),
          );
        }
        return MapEntry(key, item);
      }),
    );
  }

  static Object? _immutableValue(Object? value) {
    if (value is Map) return _immutableMap(objectMap(value));
    if (value is List) {
      return List<Object?>.unmodifiable(value.map(_immutableValue));
    }
    return value;
  }

  static List<Map<String, dynamic>> _immutableList(
    List<Map<String, dynamic>> values,
  ) {
    return List<Map<String, dynamic>>.unmodifiable(values.map(_immutableMap));
  }

  static String? _nonEmptyString(Object? value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }
}
