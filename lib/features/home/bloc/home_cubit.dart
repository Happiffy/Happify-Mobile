import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/app_services.dart';
import '../data/home_repository.dart';
import 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit({required this.repository}) : super(const HomeState());

  final HomeRepository repository;
  bool _loading = false;

  Future<void> load() async {
    if (_loading) return;
    _loading = true;
    emit(
      state.copyWith(
        dashboardStatus: HomeSectionStatus.loading,
        motivationStatus: HomeSectionStatus.loading,
        mindfulnessStatus: HomeSectionStatus.loading,
        clearDashboardError: true,
        clearMotivationError: true,
        clearMindfulnessError: true,
      ),
    );
    await Future.wait<void>([
      _loadDashboard(),
      _loadMotivation(),
      _loadMindfulness(),
    ]);
    _loading = false;
  }

  Future<void> loadDashboard() async {
    emit(
      state.copyWith(
        dashboardStatus: HomeSectionStatus.loading,
        clearDashboardError: true,
      ),
    );
    await _loadDashboard();
  }

  Future<void> loadMotivation() async {
    emit(
      state.copyWith(
        motivationStatus: HomeSectionStatus.loading,
        clearMotivationError: true,
      ),
    );
    await _loadMotivation();
  }

  Future<void> loadMindfulness() async {
    emit(
      state.copyWith(
        mindfulnessStatus: HomeSectionStatus.loading,
        clearMindfulnessError: true,
      ),
    );
    await _loadMindfulness();
  }

  Future<void> _loadDashboard() async {
    try {
      final dashboard = await repository.dashboard();
      emit(
        state.copyWith(
          dashboardStatus: HomeSectionStatus.success,
          dashboard: dashboard,
          clearDashboardError: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          dashboardStatus: HomeSectionStatus.failure,
          dashboardError: failureMessage(error),
        ),
      );
    }
  }

  Future<void> _loadMotivation() async {
    try {
      final motivation = await repository.motivation();
      emit(
        state.copyWith(
          motivationStatus: HomeSectionStatus.success,
          motivation: motivation,
          clearMotivation: motivation == null,
          clearMotivationError: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          motivationStatus: HomeSectionStatus.failure,
          motivationError: failureMessage(error),
        ),
      );
    }
  }

  Future<void> _loadMindfulness() async {
    try {
      final activities = await repository.mindfulness();
      emit(
        state.copyWith(
          mindfulnessStatus: HomeSectionStatus.success,
          activities: activities,
          clearMindfulnessError: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          mindfulnessStatus: HomeSectionStatus.failure,
          mindfulnessError: failureMessage(error),
        ),
      );
    }
  }
}
