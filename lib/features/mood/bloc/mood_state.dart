import 'package:equatable/equatable.dart';

enum MoodLoadStatus { initial, loading, success, failure }

enum MoodSaveStatus { idle, saving, success, failure }

class MoodState extends Equatable {
  const MoodState({
    this.loadStatus = MoodLoadStatus.initial,
    this.saveStatus = MoodSaveStatus.idle,
    this.selectedMood = 'NEUTRAL',
    this.intensity = 3,
    this.triggers = const {},
    this.note = '',
    this.history = const [],
    this.dashboard = const {},
    this.historyPage = 1,
    this.hasMoreHistory = false,
    this.loadingMoreHistory = false,
    this.historyStartDate,
    this.historyEndDate,
    this.historyError,
    this.dashboardError,
    this.saveError,
  });

  final MoodLoadStatus loadStatus;
  final MoodSaveStatus saveStatus;
  final String selectedMood;
  final int intensity;
  final Set<String> triggers;
  final String note;
  final List<Map<String, dynamic>> history;
  final Map<String, dynamic> dashboard;
  final int historyPage;
  final bool hasMoreHistory;
  final bool loadingMoreHistory;
  final DateTime? historyStartDate;
  final DateTime? historyEndDate;
  final String? historyError;
  final String? dashboardError;
  final String? saveError;

  bool get isEmpty => history.isEmpty && dashboard.isEmpty;

  MoodState copyWith({
    MoodLoadStatus? loadStatus,
    MoodSaveStatus? saveStatus,
    String? selectedMood,
    int? intensity,
    Set<String>? triggers,
    String? note,
    List<Map<String, dynamic>>? history,
    Map<String, dynamic>? dashboard,
    int? historyPage,
    bool? hasMoreHistory,
    bool? loadingMoreHistory,
    DateTime? historyStartDate,
    DateTime? historyEndDate,
    bool clearHistoryDates = false,
    String? historyError,
    String? dashboardError,
    String? saveError,
    bool clearHistoryError = false,
    bool clearDashboardError = false,
    bool clearSaveError = false,
  }) {
    return MoodState(
      loadStatus: loadStatus ?? this.loadStatus,
      saveStatus: saveStatus ?? this.saveStatus,
      selectedMood: selectedMood ?? this.selectedMood,
      intensity: intensity ?? this.intensity,
      triggers: triggers ?? this.triggers,
      note: note ?? this.note,
      history: history ?? this.history,
      dashboard: dashboard ?? this.dashboard,
      historyPage: historyPage ?? this.historyPage,
      hasMoreHistory: hasMoreHistory ?? this.hasMoreHistory,
      loadingMoreHistory: loadingMoreHistory ?? this.loadingMoreHistory,
      historyStartDate: clearHistoryDates
          ? null
          : historyStartDate ?? this.historyStartDate,
      historyEndDate: clearHistoryDates
          ? null
          : historyEndDate ?? this.historyEndDate,
      historyError: clearHistoryError
          ? null
          : historyError ?? this.historyError,
      dashboardError: clearDashboardError
          ? null
          : dashboardError ?? this.dashboardError,
      saveError: clearSaveError ? null : saveError ?? this.saveError,
    );
  }

  @override
  List<Object?> get props => [
    loadStatus,
    saveStatus,
    selectedMood,
    intensity,
    triggers,
    note,
    history,
    dashboard,
    historyPage,
    hasMoreHistory,
    loadingMoreHistory,
    historyStartDate,
    historyEndDate,
    historyError,
    dashboardError,
    saveError,
  ];
}
