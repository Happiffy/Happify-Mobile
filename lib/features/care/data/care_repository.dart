import '../../../core/happify_repository.dart';

class CareOverview {
  const CareOverview({
    required this.providers,
    required this.referrals,
    required this.chats,
  });

  final List<Map<String, dynamic>> providers;
  final List<Map<String, dynamic>> referrals;
  final List<Map<String, dynamic>> chats;
}

class CareRepository {
  const CareRepository(this._repository);

  final HappifyRepository _repository;

  Future<CareOverview> loadOverview() async {
    final results = await Future.wait<Object?>([
      _repository.providers(),
      _repository.referrals(),
      _repository.chats(),
    ]);
    return CareOverview(
      providers: results[0]! as List<Map<String, dynamic>>,
      referrals: results[1]! as List<Map<String, dynamic>>,
      chats: results[2]! as List<Map<String, dynamic>>,
    );
  }

  Future<void> createReferral({
    required String reason,
    Map<String, dynamic>? provider,
  }) => _repository.createReferral(
    riskLevel: 'MEDIUM',
    reason: reason,
    requestComment: reason,
    provider: provider,
  );

  Future<Map<String, dynamic>> chat(String id) => _repository.chat(id);

  Future<void> sendChat(String id, String content) =>
      _repository.sendChat(id, content);

  Future<void> updateChatStatus(String id, String status) =>
      _repository.updateChatStatus(id, status);
}
