import 'package:equatable/equatable.dart';

import '../../../core/app_services.dart';
import '../../../core/happify_repository.dart';

class ConsentDocument extends Equatable {
  const ConsentDocument({
    required this.scope,
    required this.version,
    required this.title,
    required this.content,
    required this.accepted,
  });

  factory ConsentDocument.fromMap(Map<String, dynamic> value) {
    final consents = objectList(value['consents']);
    return ConsentDocument(
      scope: value['scope']?.toString() ?? '',
      version: (value['version'] as num?)?.toInt() ?? 0,
      title: value['title']?.toString() ?? '',
      content: value['content']?.toString() ?? '',
      accepted: consents.any((item) => item['status'] == 'ACCEPTED'),
    );
  }

  final String scope;
  final int version;
  final String title;
  final String content;
  final bool accepted;

  @override
  List<Object?> get props => [scope, version, title, content, accepted];
}

abstract class ConsentRepository {
  Future<List<ConsentDocument>> loadDocuments();

  Future<void> saveChoice(ConsentDocument document, bool accepted);
}

class HappifyConsentRepository implements ConsentRepository {
  const HappifyConsentRepository(this._repository);

  final HappifyRepository _repository;

  @override
  Future<List<ConsentDocument>> loadDocuments() async {
    final values = await _repository.consents();
    return values.map(ConsentDocument.fromMap).toList(growable: false);
  }

  @override
  Future<void> saveChoice(ConsentDocument document, bool accepted) {
    return _repository.updateConsent(
      document.scope,
      document.version,
      accepted,
    );
  }
}
