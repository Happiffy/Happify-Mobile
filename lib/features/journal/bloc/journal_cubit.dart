import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/app_services.dart';
import '../data/journal_repository.dart';
import 'journal_state.dart';

class JournalCubit extends Cubit<JournalState> {
  JournalCubit({required this.repository, this.pageSize = 5})
    : super(const JournalState());

  final JournalRepository repository;
  final int pageSize;
  bool _loading = false;
  bool _creating = false;
  bool _loadingMore = false;

  Future<void> load() => _loadFirstPage();

  Future<void> refresh() => _loadFirstPage();

  Future<void> applyDateFilter({
    required DateTime? startDate,
    required DateTime? endDate,
  }) => _loadFirstPage(
    startDate: startDate,
    endDate: endDate,
    clearDates: startDate == null && endDate == null,
  );

  Future<void> _loadFirstPage({
    DateTime? startDate,
    DateTime? endDate,
    bool clearDates = false,
  }) async {
    if (_loading) return;
    _loading = true;
    final filterStartDate = clearDates ? null : startDate ?? state.startDate;
    final filterEndDate = clearDates ? null : endDate ?? state.endDate;
    emit(
      state.copyWith(
        status: JournalStatus.loading,
        entries: const [],
        page: 1,
        hasMore: false,
        loadingMore: false,
        startDate: filterStartDate,
        endDate: filterEndDate,
        clearDates: clearDates,
        clearError: true,
        clearActionError: true,
        clearLastCreatedRisk: true,
      ),
    );
    try {
      final result = await repository.loadEntries(
        page: 1,
        limit: pageSize,
        startDate: _apiDate(filterStartDate),
        endDate: _apiDate(filterEndDate),
      );
      emit(
        state.copyWith(
          status: result.items.isEmpty
              ? JournalStatus.empty
              : JournalStatus.success,
          entries: List.unmodifiable(result.items),
          page: 1,
          hasMore: result.hasMore,
          startDate: filterStartDate,
          endDate: filterEndDate,
          clearDates: clearDates,
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
      final result = await repository.loadEntries(
        page: 1,
        limit: pageSize,
        startDate: _apiDate(state.startDate),
        endDate: _apiDate(state.endDate),
      );
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
        startDate: _apiDate(state.startDate),
        endDate: _apiDate(state.endDate),
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

  String? _apiDate(DateTime? value) {
    if (value == null) return null;
    final date = value.toLocal();
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
