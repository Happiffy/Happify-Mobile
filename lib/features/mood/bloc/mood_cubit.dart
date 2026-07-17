import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/app_services.dart';
import '../data/mood_repository.dart';
import 'mood_state.dart';

class MoodCubit extends Cubit<MoodState> {
  MoodCubit({required this.repository, this.pageSize = 5})
    : super(const MoodState());

  final MoodRepository repository;
  final int pageSize;
  bool _loading = false;
  bool _loadingMore = false;

  Future<void> load() => _loadFirstPage(loadDashboard: true);

  Future<void> refresh() => _loadFirstPage(loadDashboard: true);

  Future<void> applyHistoryDateFilter({
    required DateTime? startDate,
    required DateTime? endDate,
  }) => _loadFirstPage(
    startDate: startDate,
    endDate: endDate,
    clearHistoryDates: startDate == null && endDate == null,
    loadDashboard: false,
  );

  Future<void> _loadFirstPage({
    DateTime? startDate,
    DateTime? endDate,
    bool clearHistoryDates = false,
    required bool loadDashboard,
  }) async {
    if (_loading) return;
    _loading = true;
    final filterStartDate = clearHistoryDates
        ? null
        : startDate ?? state.historyStartDate;
    final filterEndDate = clearHistoryDates
        ? null
        : endDate ?? state.historyEndDate;
    emit(
      state.copyWith(
        loadStatus: MoodLoadStatus.loading,
        history: const [],
        historyPage: 1,
        hasMoreHistory: false,
        loadingMoreHistory: false,
        historyStartDate: filterStartDate,
        historyEndDate: filterEndDate,
        clearHistoryDates: clearHistoryDates,
        clearHistoryError: true,
        clearDashboardError: loadDashboard,
      ),
    );
    List<Map<String, dynamic>>? history;
    Map<String, dynamic>? dashboard;
    String? historyError;
    String? dashboardError;

    Future<void> loadHistory() async {
      try {
        history = await repository.moods(
          limit: pageSize + 1,
          startDate: _apiDate(filterStartDate),
          endDate: _apiDate(filterEndDate),
        );
      } catch (error) {
        historyError = failureMessage(error);
      }
    }

    Future<void> loadDashboardData() async {
      if (!loadDashboard) return;
      try {
        dashboard = await repository.dashboard();
      } catch (error) {
        dashboardError = failureMessage(error);
      }
    }

    await Future.wait<void>([loadHistory(), loadDashboardData()]);
    final loadedHistory = history ?? const <Map<String, dynamic>>[];
    final shownHistory = loadedHistory.take(pageSize).toList(growable: false);
    final failed =
        historyError != null && (!loadDashboard || dashboardError != null);
    emit(
      state.copyWith(
        loadStatus: failed ? MoodLoadStatus.failure : MoodLoadStatus.success,
        history: List.unmodifiable(shownHistory),
        dashboard: dashboard ?? state.dashboard,
        historyPage: 1,
        hasMoreHistory: loadedHistory.length > shownHistory.length,
        loadingMoreHistory: false,
        historyStartDate: filterStartDate,
        historyEndDate: filterEndDate,
        clearHistoryDates: clearHistoryDates,
        historyError: historyError,
        dashboardError: dashboardError,
        clearHistoryError: historyError == null,
        clearDashboardError: loadDashboard && dashboardError == null,
      ),
    );
    _loading = false;
  }

  Future<void> loadMoreHistory() async {
    if (_loadingMore || !state.hasMoreHistory || state.history.isEmpty) return;
    _loadingMore = true;
    emit(state.copyWith(loadingMoreHistory: true, clearHistoryError: true));
    try {
      final nextPage = state.historyPage + 1;
      final nextCount = nextPage * pageSize;
      final requestedCount = (nextCount + 1).clamp(1, 100).toInt();
      final history = await repository.moods(
        limit: requestedCount,
        startDate: _apiDate(state.historyStartDate),
        endDate: _apiDate(state.historyEndDate),
      );
      final shownHistory = history.take(nextCount).toList(growable: false);
      emit(
        state.copyWith(
          history: List.unmodifiable(shownHistory),
          historyPage: nextPage,
          hasMoreHistory: history.length > shownHistory.length,
          loadingMoreHistory: false,
          clearHistoryError: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          loadingMoreHistory: false,
          historyError: failureMessage(error),
        ),
      );
    } finally {
      _loadingMore = false;
    }
  }

  void selectMood(String mood) {
    if (mood == state.selectedMood) return;
    emit(
      state.copyWith(
        selectedMood: mood,
        saveStatus: MoodSaveStatus.idle,
        clearSaveError: true,
      ),
    );
  }

  void setIntensity(int intensity) {
    final value = intensity.clamp(1, 5);
    if (value == state.intensity) return;
    emit(
      state.copyWith(
        intensity: value,
        saveStatus: MoodSaveStatus.idle,
        clearSaveError: true,
      ),
    );
  }

  void toggleTrigger(String trigger) {
    final triggers = Set<String>.of(state.triggers);
    triggers.contains(trigger)
        ? triggers.remove(trigger)
        : triggers.add(trigger);
    emit(
      state.copyWith(
        triggers: Set<String>.unmodifiable(triggers),
        saveStatus: MoodSaveStatus.idle,
        clearSaveError: true,
      ),
    );
  }

  void setNote(String note) {
    if (note == state.note) return;
    emit(
      state.copyWith(
        note: note,
        saveStatus: MoodSaveStatus.idle,
        clearSaveError: true,
      ),
    );
  }

  Future<bool> save() async {
    if (state.saveStatus == MoodSaveStatus.saving) return false;
    emit(
      state.copyWith(saveStatus: MoodSaveStatus.saving, clearSaveError: true),
    );
    try {
      await repository.saveMood(
        state: state.selectedMood,
        intensity: state.intensity,
        triggers: state.triggers.toList(growable: false),
        note: state.note,
      );
      emit(
        state.copyWith(
          saveStatus: MoodSaveStatus.success,
          note: '',
          triggers: const {},
          clearSaveError: true,
        ),
      );
      await load();
      return true;
    } catch (error) {
      emit(
        state.copyWith(
          saveStatus: MoodSaveStatus.failure,
          saveError: failureMessage(error),
        ),
      );
      return false;
    }
  }

  String? _apiDate(DateTime? value) {
    if (value == null) return null;
    final date = value.toLocal();
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
