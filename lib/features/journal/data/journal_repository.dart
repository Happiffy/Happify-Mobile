import '../../../core/happify_repository.dart';

class JournalPageResult {
  const JournalPageResult({required this.items, required this.hasMore});

  final List<Map<String, dynamic>> items;
  final bool hasMore;
}

class JournalRepository {
  const JournalRepository(this._repository);

  final HappifyRepository _repository;

  Future<JournalPageResult> loadEntries({
    required int page,
    required int limit,
  }) async {
    final items = await _repository.journals(page: page, limit: limit);
    return JournalPageResult(items: items, hasMore: items.length == limit);
  }

  Future<Map<String, dynamic>> createEntry({
    required String title,
    required String content,
    String? detectedMood,
  }) => _repository.createJournal(
    title: title,
    content: content,
    detectedMood: detectedMood,
  );
}
