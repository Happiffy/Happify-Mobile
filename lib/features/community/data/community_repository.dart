import '../../../core/happify_repository.dart';

class CommunityFeedPage {
  const CommunityFeedPage({required this.items, required this.nextCursor});

  final List<Map<String, dynamic>> items;
  final String? nextCursor;
}

class CommunityRepository {
  const CommunityRepository(this._repository);

  final HappifyRepository _repository;

  Future<CommunityFeedPage> loadFeed({
    String? cursor,
    required int limit,
  }) async {
    final data = await _repository.communityPage(cursor: cursor, limit: limit);
    return CommunityFeedPage(
      items: List<Map<String, dynamic>>.from(data['items'] as List),
      nextCursor: data['nextCursor']?.toString(),
    );
  }

  Future<List<Map<String, dynamic>>> loadHeatmap({
    DateTime? startDate,
    DateTime? endDate,
  }) => _repository.heatmap(startDate: startDate, endDate: endDate);

  Future<void> createPost({
    required String alias,
    required String content,
    String? mood,
  }) => _repository.createPost(alias: alias, content: content, mood: mood);

  Future<void> support(String postId) => _repository.support(postId);

  Future<void> comment(String postId, String content, {String? imageUrl}) =>
      _repository.comment(postId, content, imageUrl: imageUrl);

  Future<void> report({
    required String targetType,
    required String targetId,
    required String reason,
    String? details,
  }) => _repository.report(
    targetType: targetType,
    targetId: targetId,
    reason: reason,
    details: details,
  );

  Future<void> contributeHeatmap(String regionKey, String mood) =>
      _repository.contributeHeatmap(regionKey, mood);
}
