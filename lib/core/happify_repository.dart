import 'dart:io';

import 'package:dio/dio.dart';

import 'app_services.dart';

class HappifyRepository {
  const HappifyRepository(this.api);
  final ApiClient api;

  Future<Map<String, dynamic>> profile() async {
    final data = await api.request('GET', '/profile');
    return objectMap(data['profile']);
  }

  Future<Map<String, dynamic>> updateProfile({
    required String displayName,
    required String bio,
    String? avatarUrl,
  }) async {
    final data = await api.request(
      'PATCH',
      '/profile',
      data: {'displayName': displayName, 'bio': bio, 'avatarUrl': ?avatarUrl},
    );
    return objectMap(data['profile']);
  }

  Future<Map<String, dynamic>> uploadImage({
    required String imageBase64,
    required String contentType,
  }) async {
    final data = await api.request(
      'POST',
      '/media/images',
      data: {'imageBase64': imageBase64, 'contentType': contentType},
    );
    return objectMap(data['image']);
  }

  Future<Map<String, dynamic>> applyPsychologist({
    required String fullName,
    required String licenseNumber,
    required String certificateUrl,
    String? institution,
    String? reason,
  }) async {
    final data = await api.request(
      'POST',
      '/profile/psychologist-applications',
      data: {
        'fullName': fullName,
        'licenseNumber': licenseNumber,
        'certificateUrl': certificateUrl,
        if (institution?.isNotEmpty == true) 'institution': institution,
        if (reason?.isNotEmpty == true) 'reason': reason,
      },
    );
    return objectMap(data['application']);
  }

  Future<Map<String, dynamic>?> preference() async {
    final data = await api.request('GET', '/preferences');
    final value = data['preference'];
    return value == null ? null : objectMap(value);
  }

  Future<Map<String, dynamic>> savePreference(
    Map<String, dynamic> preference,
  ) async {
    final data = await api.request('PUT', '/preferences', data: preference);
    return objectMap(data['preference']);
  }

  Future<Map<String, dynamic>> updateNotificationPreferences(
    Map<String, bool> notifications,
  ) async {
    final data = await api.request(
      'PATCH',
      '/preferences/notifications',
      data: notifications,
    );
    return objectMap(data['preference']);
  }

  Future<List<Map<String, dynamic>>> consents() async {
    final data = await api.request('GET', '/consents');
    return objectList(data['items']);
  }

  Future<void> updateConsent(String scope, int version, bool accepted) async {
    await api.request(
      'PUT',
      '/consents',
      data: {
        'scope': scope,
        'version': version,
        'accepted': accepted,
        'source': 'MOBILE',
      },
    );
  }

  Future<List<Map<String, dynamic>>> moods({
    int limit = 30,
    String? startDate,
    String? endDate,
  }) async {
    final data = await api.request(
      'GET',
      '/mood',
      query: {
        'limit': limit,
        if (startDate case final value?) 'startDate': value,
        if (endDate case final value?) 'endDate': value,
      },
    );
    return objectList(data['items']);
  }

  Future<Map<String, dynamic>> saveMood({
    required String state,
    required int intensity,
    required List<String> triggers,
    String? note,
  }) async {
    final data = await api.request(
      'POST',
      '/mood',
      data: {
        'state': state,
        'intensity': intensity,
        'triggers': triggers,
        if (note?.trim().isNotEmpty == true) 'note': note!.trim(),
      },
    );
    return objectMap(data['mood']);
  }

  Future<Map<String, dynamic>> dashboard() async {
    final data = await api.request('GET', '/analytics/dashboard');
    return objectMap(data['dashboard']);
  }

  Future<List<Map<String, dynamic>>> journals({
    int page = 1,
    int limit = 30,
    String? startDate,
    String? endDate,
  }) async {
    final data = await api.request(
      'GET',
      '/journal',
      query: {
        'page': page,
        'limit': limit,
        if (startDate case final value?) 'startDate': value,
        if (endDate case final value?) 'endDate': value,
      },
    );
    return objectList(data['items']);
  }

  Future<Map<String, dynamic>> createJournal({
    required String title,
    required String content,
    String? detectedMood,
  }) async {
    final data = await api.request(
      'POST',
      '/journal',
      data: {'title': title, 'content': content, 'detectedMood': ?detectedMood},
    );
    return objectMap(data['journal']);
  }

  Future<Map<String, dynamic>?> motivation() async {
    final data = await api.request(
      'GET',
      '/motivation/today',
      query: {'locale': 'en'},
    );
    final value = data['motivation'];
    return value == null ? null : objectMap(value);
  }

  Future<List<Map<String, dynamic>>> mindfulness({String? type}) async {
    final data = await api.request(
      'GET',
      '/mindfulness',
      query: {'locale': 'en', 'type': ?type},
    );
    return objectList(data['items']);
  }

  Future<Map<String, dynamic>> updateMindfulnessProgress({
    required String activityId,
    required int progressSeconds,
    required bool completed,
  }) async {
    final data = await api.request(
      'PUT',
      '/mindfulness/progress',
      data: {
        'activityId': activityId,
        'progressSeconds': progressSeconds,
        'completed': completed,
      },
    );
    return objectMap(data['progress']);
  }

  Future<List<Map<String, dynamic>>> community() async {
    final page = await communityPage(limit: 30);
    return objectList(page['items']);
  }

  Future<Map<String, dynamic>> communityPage({
    String? cursor,
    int limit = 30,
  }) async {
    final data = await api.request(
      'GET',
      '/community',
      query: {'limit': limit, 'cursor': ?cursor},
    );
    return {
      'items': objectList(data['items']),
      'nextCursor': data['nextCursor']?.toString(),
    };
  }

  Future<void> createPost({
    required String alias,
    required String content,
    String? mood,
  }) async {
    await api.request(
      'POST',
      '/community',
      data: {'alias': alias, 'content': content, 'mood': ?mood},
    );
  }

  Future<void> support(String postId) async {
    await api.request('POST', '/community/$postId/support');
  }

  Future<void> comment(String postId, String content) async {
    await api.request(
      'POST',
      '/community/$postId/comments',
      data: {'content': content},
    );
  }

  Future<void> report({
    required String targetType,
    required String targetId,
    required String reason,
    String? details,
  }) async {
    await api.request(
      'POST',
      '/community/reports',
      data: {
        'targetType': targetType,
        'targetId': targetId,
        'reason': reason,
        if (details?.trim().isNotEmpty == true) 'details': details!.trim(),
      },
    );
  }

  Future<List<Map<String, dynamic>>> heatmap() async {
    final data = await api.request('GET', '/heatmap', query: {'days': 7});
    return objectList(data['items']);
  }

  Future<void> contributeHeatmap(String regionKey, String mood) async {
    await api.request(
      'PUT',
      '/heatmap/contribution',
      data: {'regionKey': regionKey, 'mood': mood},
    );
  }

  Future<List<Map<String, dynamic>>> emergencyContacts() async {
    final data = await api.request('GET', '/emergency-contacts');
    return objectList(data['items']);
  }

  Future<void> saveEmergencyContact({
    String? id,
    required String name,
    required String relationship,
    required String phone,
    required bool isPrimary,
  }) async {
    await api.request(
      id == null ? 'POST' : 'PATCH',
      id == null ? '/emergency-contacts' : '/emergency-contacts/$id',
      data: {
        'name': name,
        'relationship': relationship,
        'phone': phone,
        'isPrimary': isPrimary,
      },
    );
  }

  Future<void> deleteEmergencyContact(String id) async {
    await api.request('DELETE', '/emergency-contacts/$id');
  }

  Future<List<Map<String, dynamic>>> providers({bool? emergency}) async {
    final data = await api.request(
      'GET',
      '/providers',
      query: {'emergency': ?emergency},
    );
    return objectList(data['items']);
  }

  Future<List<Map<String, dynamic>>> referrals() async {
    final data = await api.request(
      'GET',
      '/referral',
      query: {'page': 1, 'limit': 30},
    );
    return objectList(data['items']);
  }

  Future<void> createReferral({
    required String riskLevel,
    required String reason,
    String? requestComment,
    Map<String, dynamic>? provider,
  }) async {
    await api.request(
      'POST',
      '/referral',
      data: {
        'riskLevel': riskLevel,
        'reason': reason,
        if (requestComment?.trim().isNotEmpty == true)
          'requestComment': requestComment!.trim(),
        if (provider?['name'] != null) 'providerName': provider!['name'],
        if (provider?['type'] != null) 'providerType': provider!['type'],
        if (provider?['websiteUrl'] != null)
          'contactUrl': provider!['websiteUrl'],
      },
    );
  }

  Future<List<Map<String, dynamic>>> chats() async {
    final data = await api.request(
      'GET',
      '/referral/chats',
      query: {'page': 1, 'limit': 30},
    );
    return objectList(data['items']);
  }

  Future<Map<String, dynamic>> chat(String id) async {
    final data = await api.request('GET', '/referral/chats/$id');
    return objectMap(data['session']);
  }

  Future<void> sendChat(String id, String content, {String? imageUrl}) async {
    await api.request(
      'POST',
      '/referral/chats/$id/messages',
      data: {'content': content, if (imageUrl != null) 'imageUrl': imageUrl},
    );
  }

  Future<void> updateChatStatus(String id, String status) async {
    await api.request(
      'PATCH',
      '/referral/chats/$id/status',
      data: {'status': status},
    );
  }

  Future<List<Map<String, dynamic>>> voiceTurns({int limit = 30}) async {
    final data = await api.request(
      'GET',
      '/voice/turns',
      query: {'limit': limit},
    );
    return objectList(data['items']);
  }

  Future<Map<String, dynamic>> uploadVoice(
    File file, {
    required String idempotencyKey,
    required String sessionId,
    String language = 'id',
  }) async {
    final bytes = await file.readAsBytes();
    final extension = file.path.split('.').last.toLowerCase();
    final contentType = switch (extension) {
      'wav' => 'audio/wav',
      'm4a' || 'mp4' => 'audio/mp4',
      'mp3' => 'audio/mpeg',
      'ogg' => 'audio/ogg',
      _ => 'audio/wav',
    };
    final data = await api.request(
      'POST',
      '/voice/turns',
      data: Stream.fromIterable([bytes]),
      headers: {
        Headers.contentTypeHeader: contentType,
        Headers.contentLengthHeader: bytes.length,
        'x-voice-language': language,
        'x-session-id': sessionId,
        'idempotency-key': idempotencyKey,
      },
    );
    return objectMap(data['turn']);
  }

  Future<List<Map<String, dynamic>>> devices() async {
    final data = await api.request('GET', '/devices');
    return objectList(data['items']);
  }

  Future<Map<String, dynamic>> ensureCompanion() async {
    final data = await api.request('POST', '/devices/companion');
    return objectMap(data['device']);
  }

  Future<Map<String, dynamic>> device(String id) async {
    final data = await api.request('GET', '/devices/$id');
    return objectMap(data['device']);
  }

  Future<void> renameDevice(String id, String name) async {
    await api.request('PATCH', '/devices/$id', data: {'displayName': name});
  }

  Future<Map<String, dynamic>> startPairing(
    String serial,
    String secret,
  ) async {
    final data = await api.request(
      'POST',
      '/devices/pairing-sessions',
      data: {'serialNumber': serial, 'claimSecret': secret},
    );
    return objectMap(data['session']);
  }

  Future<Map<String, dynamic>> pairing(String id) async {
    final data = await api.request('GET', '/devices/pairing-sessions/$id');
    return objectMap(data['session']);
  }

  Future<void> completePairing(String id) async {
    await api.request('POST', '/devices/pairing-sessions/$id/complete');
  }

  Future<void> cancelPairing(String id) async {
    await api.request('DELETE', '/devices/pairing-sessions/$id');
  }

  Future<void> unpair(String id) async {
    await api.request('DELETE', '/devices/$id', data: {'revoke': false});
  }

  Future<List<Map<String, dynamic>>> telemetry(String id) async {
    final data = await api.request(
      'GET',
      '/devices/$id/telemetry',
      query: {'limit': 100},
    );
    return objectList(data['items']);
  }

  Future<Map<String, dynamic>> calmingHaptic(String id) {
    return command(id, 'HAPTIC_THERAPY', {
      'therapyId': 'calming',
      'pattern': [
        {'durationMs': 1200, 'amplitude': 0.6, 'pauseAfterMs': 400},
        {'durationMs': 1200, 'amplitude': 0.4, 'pauseAfterMs': 400},
      ],
      'repeat': 2,
    });
  }

  Future<Map<String, dynamic>> command(
    String id,
    String type,
    Map<String, dynamic> payload,
  ) async {
    final data = await api.request(
      'POST',
      '/devices/$id/commands',
      data: {
        'type': type,
        'payload': payload,
        'idempotencyKey':
            'mobile-${DateTime.now().microsecondsSinceEpoch.toString()}',
      },
    );
    return objectMap(data['command']);
  }

  Future<List<Map<String, dynamic>>> firmwareReleases(String id) async {
    final data = await api.request('GET', '/devices/$id/firmware-releases');
    return objectList(data['items']);
  }

  Future<Map<String, dynamic>> ota(String id, String firmwareId) async {
    final data = await api.request(
      'POST',
      '/devices/$id/ota',
      data: {'firmwareId': firmwareId},
    );
    return objectMap(data['ota']);
  }
}
