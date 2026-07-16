import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/app_services.dart';
import '../data/journal_repository.dart';
import 'journal_state.dart';

class JournalCubit extends Cubit<JournalState> {
  JournalCubit({required this.repository, this.pageSize = 10})
    : super(const JournalState());

  final JournalRepository repository;
  final int pageSize;
  bool _loading = false;
  bool _creating = false;
  bool _loadingMore = false;

  Future<void> load() => _loadFirstPage();

  Future<void> refresh() => _loadFirstPage();

  Future<void> _loadFirstPage() async {
    if (_loading) return;
    _loading = true;
    emit(
      state.copyWith(
        status: JournalStatus.loading,
        clearError: true,
        clearActionError: true,
        clearLastCreatedRisk: true,
      ),
    );
    try {
      final result = await repository.loadEntries(page: 1, limit: pageSize);
      emit(
        state.copyWith(
          status: result.items.isEmpty
              ? JournalStatus.empty
              : JournalStatus.success,
          entries: List.unmodifiable(result.items),
          page: 1,
          hasMore: result.hasMore,
          clearError: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: JournalStatus.failure,
          errorMessage: failureMessage(error),
        ),
      );
    } finally {
      _loading = false;
    }
  }

  Future<bool> createEntry({
    required String title,
    required String content,
    String? detectedMood,
  }) async {
    final cleanTitle = title.trim();
    final cleanContent = content.trim();
    if (cleanTitle.isEmpty || cleanContent.isEmpty || _creating || _loading) {
      return false;
    }
    _creating = true;
    emit(
      state.copyWith(
        creating: true,
        clearActionError: true,
        clearLastCreatedRisk: true,
      ),
    );
    try {
      final created = await repository.createEntry(
        title: cleanTitle,
        content: cleanContent,
        detectedMood: detectedMood,
      );
      final result = await repository.loadEntries(page: 1, limit: pageSize);
      emit(
        state.copyWith(
          status: result.items.isEmpty
              ? JournalStatus.empty
              : JournalStatus.success,
          entries: List.unmodifiable(result.items),
          page: 1,
          hasMore: result.hasMore,
          creating: false,
          clearError: true,
          clearActionError: true,
          lastCreatedRisk: created['riskLevel']?.toString() ?? 'LOW',
        ),
      );
      return true;
    } catch (error) {
      emit(state.copyWith(creating: false, actionError: failureMessage(error)));
      return false;
    } finally {
      _creating = false;
    }
  }

  Future<void> loadMore() async {
    if (_loadingMore || !state.hasMore || state.entries.isEmpty) return;
    _loadingMore = true;
    emit(state.copyWith(loadingMore: true, clearActionError: true));
    try {
      final nextPage = state.page + 1;
      final result = await repository.loadEntries(
        page: nextPage,
        limit: pageSize,
      );
      emit(
        state.copyWith(
          status: JournalStatus.success,
          entries: List.unmodifiable(
            _appendUnique(state.entries, result.items),
          ),
          page: nextPage,
          hasMore: result.hasMore,
          loadingMore: false,
          clearActionError: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(loadingMore: false, actionError: failureMessage(error)),
      );
    } finally {
      _loadingMore = false;
    }
  }

  List<Map<String, dynamic>> _appendUnique(
    List<Map<String, dynamic>> current,
    List<Map<String, dynamic>> next,
  ) {
    final result = [...current];
    final ids = current
        .map((item) => item['id']?.toString())
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toSet();
    for (final item in next) {
      final id = item['id']?.toString();
      if (id == null || id.isEmpty || ids.add(id)) result.add(item);
    }
    return result;
  }
}
