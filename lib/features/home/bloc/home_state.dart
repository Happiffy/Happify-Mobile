import 'package:equatable/equatable.dart';

enum HomeSectionStatus { initial, loading, success, failure }

class HomeState extends Equatable {
  const HomeState({
    this.dashboardStatus = HomeSectionStatus.initial,
    this.motivationStatus = HomeSectionStatus.initial,
    this.mindfulnessStatus = HomeSectionStatus.initial,
    this.dashboard = const {},
    this.motivation,
    this.activities = const [],
    this.dashboardError,
    this.motivationError,
    this.mindfulnessError,
  });

  final HomeSectionStatus dashboardStatus;
  final HomeSectionStatus motivationStatus;
  final HomeSectionStatus mindfulnessStatus;
  final Map<String, dynamic> dashboard;
  final Map<String, dynamic>? motivation;
  final List<Map<String, dynamic>> activities;
  final String? dashboardError;
  final String? motivationError;
  final String? mindfulnessError;

  HomeState copyWith({
    HomeSectionStatus? dashboardStatus,
    HomeSectionStatus? motivationStatus,
    HomeSectionStatus? mindfulnessStatus,
    Map<String, dynamic>? dashboard,
    Map<String, dynamic>? motivation,
    bool clearMotivation = false,
    List<Map<String, dynamic>>? activities,
    String? dashboardError,
    String? motivationError,
    String? mindfulnessError,
    bool clearDashboardError = false,
    bool clearMotivationError = false,
    bool clearMindfulnessError = false,
  }) {
    return HomeState(
      dashboardStatus: dashboardStatus ?? this.dashboardStatus,
      motivationStatus: motivationStatus ?? this.motivationStatus,
      mindfulnessStatus: mindfulnessStatus ?? this.mindfulnessStatus,
      dashboard: dashboard ?? this.dashboard,
      motivation: clearMotivation ? null : motivation ?? this.motivation,
      activities: activities ?? this.activities,
      dashboardError: clearDashboardError
          ? null
          : dashboardError ?? this.dashboardError,
      motivationError: clearMotivationError
          ? null
          : motivationError ?? this.motivationError,
      mindfulnessError: clearMindfulnessError
          ? null
          : mindfulnessError ?? this.mindfulnessError,
    );
  }

  @override
  List<Object?> get props => [
    dashboardStatus,
    motivationStatus,
    mindfulnessStatus,
    dashboard,
    motivation,
    activities,
    dashboardError,
    motivationError,
    mindfulnessError,
  ];
}
