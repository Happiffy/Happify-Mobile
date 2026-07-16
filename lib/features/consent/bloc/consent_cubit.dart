import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/app_services.dart';
import '../data/consent_repository.dart';
import 'consent_state.dart';

class ConsentCubit extends Cubit<ConsentState> {
  ConsentCubit({required this.repository}) : super(ConsentState());

  final ConsentRepository repository;
  bool _loading = false;

  Future<void> load() async {
    if (_loading || state.isSaving) return;
    _loading = true;
    emit(
      state.copyWith(
        loadStatus: ConsentLoadStatus.loading,
        saveStatus: ConsentSaveStatus.initial,
        processedCount: 0,
        completedCount: 0,
        totalCount: 0,
        saveErrors: const {},
        loadError: null,
      ),
    );
    try {
      final documents = _latestByScope(await repository.loadDocuments());
      final previousVersions = {
        for (final document in state.documents)
          document.scope: document.version,
      };
      final selections = <String, bool>{};
      for (final document in documents) {
        final unchanged = previousVersions[document.scope] == document.version;
        selections[document.scope] = unchanged
            ? state.selections[document.scope] ?? document.accepted
            : document.accepted;
      }
      if (!isClosed) {
        emit(
          state.copyWith(
            loadStatus: ConsentLoadStatus.success,
            documents: documents,
            selections: selections,
            loadError: null,
          ),
        );
      }
    } catch (error) {
      if (!isClosed) {
        emit(
          state.copyWith(
            loadStatus: ConsentLoadStatus.failure,
            loadError: failureMessage(error),
          ),
        );
      }
    } finally {
      _loading = false;
    }
  }

  void setChoice(String scope, bool accepted) {
    if (state.isSaving || !state.selections.containsKey(scope)) return;
    emit(
      state.copyWith(
        selections: {...state.selections, scope: accepted},
        saveStatus: ConsentSaveStatus.initial,
        processedCount: 0,
        completedCount: 0,
        totalCount: 0,
        saveErrors: const {},
      ),
    );
  }

  Future<bool> saveSelected() => _save(limited: false);

  Future<bool> saveLimited() => _save(limited: true);

  Future<bool> retrySave() => _save(limited: state.limitedMode);

  Future<bool> _save({required bool limited}) async {
    if (state.isSaving || state.documents.isEmpty) return false;
    final total = state.documents.length;
    final selections = Map<String, bool>.of(state.selections);
    final errors = <String, String>{};
    var processed = 0;
    var completed = 0;
    emit(
      state.copyWith(
        saveStatus: ConsentSaveStatus.saving,
        processedCount: 0,
        completedCount: 0,
        totalCount: total,
        saveErrors: const {},
        limitedMode: limited,
      ),
    );
    for (final document in state.documents) {
      final accepted = limited
          ? false
          : state.selections[document.scope] ?? document.accepted;
      try {
        await repository.saveChoice(document, accepted);
        selections[document.scope] = accepted;
        completed += 1;
      } catch (error) {
        errors[document.scope] = failureMessage(error);
      }
      processed += 1;
      if (!isClosed) {
        emit(
          state.copyWith(
            saveStatus: ConsentSaveStatus.saving,
            selections: selections,
            processedCount: processed,
            completedCount: completed,
            totalCount: total,
            saveErrors: errors,
            limitedMode: limited,
          ),
        );
      }
    }
    if (isClosed) return false;
    final succeeded = errors.isEmpty;
    emit(
      state.copyWith(
        saveStatus: succeeded
            ? ConsentSaveStatus.success
            : ConsentSaveStatus.partialFailure,
        selections: selections,
        processedCount: processed,
        completedCount: completed,
        totalCount: total,
        saveErrors: errors,
        limitedMode: limited,
      ),
    );
    return succeeded;
  }

  List<ConsentDocument> _latestByScope(List<ConsentDocument> documents) {
    final latest = <String, ConsentDocument>{};
    for (final document in documents) {
      if (document.scope.isEmpty || document.version < 1) continue;
      final current = latest[document.scope];
      if (current == null || document.version > current.version) {
        latest[document.scope] = document;
      }
    }
    final values = latest.values.toList(growable: false);
    values.sort((left, right) => left.scope.compareTo(right.scope));
    return values;
  }
}
