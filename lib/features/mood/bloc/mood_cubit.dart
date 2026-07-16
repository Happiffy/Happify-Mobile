import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/app_services.dart';
import '../data/mood_repository.dart';
import 'mood_state.dart';

class MoodCubit extends Cubit<MoodState> {
  MoodCubit({required this.repository}) : super(const MoodState());

  final MoodRepository repository;
  bool _loading = false;

  Future<void> load() async {
    if (_loading) return;
    _loading = true;
    emit(
      state.copyWith(
        loadStatus: MoodLoadStatus.loading,
        clearHistoryError: true,
        clearDashboardError: true,
      ),
    );
    List<Map<String, dynamic>>? history;
    Map<String, dynamic>? dashboard;
    String? historyError;
    String? dashboardError;

    Future<void> loadHistory() async {
      try {
        history = await repository.moods();
      } catch (error) {
        historyError = failureMessage(error);
      }
    }

    Future<void> loadDashboard() async {
      try {
        dashboard = await repository.dashboard();
      } catch (error) {
        dashboardError = failureMessage(error);
      }
    }

    await Future.wait<void>([loadHistory(), loadDashboard()]);
    final failed = historyError != null && dashboardError != null;
    emit(
      state.copyWith(
        loadStatus: failed ? MoodLoadStatus.failure : MoodLoadStatus.success,
        history: history ?? state.history,
        dashboard: dashboard ?? state.dashboard,
        historyError: historyError,
        dashboardError: dashboardError,
        clearHistoryError: historyError == null,
        clearDashboardError: dashboardError == null,
      ),
    );
    _loading = false;
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
      final mood = await repository.saveMood(
        state: state.selectedMood,
        intensity: state.intensity,
        triggers: state.triggers.toList(growable: false),
        note: state.note,
      );
      final history = List<Map<String, dynamic>>.unmodifiable([
        mood,
        ...state.history.where((item) => item['id'] != mood['id']),
      ]);
      emit(
        state.copyWith(
          saveStatus: MoodSaveStatus.success,
          note: '',
          triggers: const {},
          history: history,
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
}
