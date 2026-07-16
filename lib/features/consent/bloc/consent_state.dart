import 'package:equatable/equatable.dart';

import '../data/consent_repository.dart';

enum ConsentLoadStatus { initial, loading, success, failure }

enum ConsentSaveStatus { initial, saving, success, partialFailure }

const _unset = Object();

class ConsentState extends Equatable {
  ConsentState({
    this.loadStatus = ConsentLoadStatus.initial,
    this.saveStatus = ConsentSaveStatus.initial,
    List<ConsentDocument> documents = const [],
    Map<String, bool> selections = const {},
    this.processedCount = 0,
    this.completedCount = 0,
    this.totalCount = 0,
    Map<String, String> saveErrors = const {},
    this.loadError,
    this.limitedMode = false,
  }) : documents = List.unmodifiable(documents),
       selections = Map.unmodifiable(selections),
       saveErrors = Map.unmodifiable(saveErrors);

  final ConsentLoadStatus loadStatus;
  final ConsentSaveStatus saveStatus;
  final List<ConsentDocument> documents;
  final Map<String, bool> selections;
  final int processedCount;
  final int completedCount;
  final int totalCount;
  final Map<String, String> saveErrors;
  final String? loadError;
  final bool limitedMode;

  List<String> get failedScopes => List.unmodifiable(saveErrors.keys);

  bool get isSaving => saveStatus == ConsentSaveStatus.saving;

  ConsentState copyWith({
    ConsentLoadStatus? loadStatus,
    ConsentSaveStatus? saveStatus,
    List<ConsentDocument>? documents,
    Map<String, bool>? selections,
    int? processedCount,
    int? completedCount,
    int? totalCount,
    Map<String, String>? saveErrors,
    Object? loadError = _unset,
    bool? limitedMode,
  }) {
    return ConsentState(
      loadStatus: loadStatus ?? this.loadStatus,
      saveStatus: saveStatus ?? this.saveStatus,
      documents: documents ?? this.documents,
      selections: selections ?? this.selections,
      processedCount: processedCount ?? this.processedCount,
      completedCount: completedCount ?? this.completedCount,
      totalCount: totalCount ?? this.totalCount,
      saveErrors: saveErrors ?? this.saveErrors,
      loadError: identical(loadError, _unset)
          ? this.loadError
          : loadError as String?,
      limitedMode: limitedMode ?? this.limitedMode,
    );
  }

  @override
  List<Object?> get props => [
    loadStatus,
    saveStatus,
    documents,
    selections,
    processedCount,
    completedCount,
    totalCount,
    saveErrors,
    loadError,
    limitedMode,
  ];
}
