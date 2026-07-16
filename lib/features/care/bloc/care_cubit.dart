import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/app_services.dart';
import '../data/care_repository.dart';
import 'care_state.dart';

class CareCubit extends Cubit<CareState> {
  CareCubit({required this.repository, String? initialSessionId})
    : _initialSessionId = initialSessionId,
      super(const CareState());

  final CareRepository repository;
  final String? _initialSessionId;
  bool _initialSessionConsumed = false;
  bool _loading = false;

  Future<void> load() => _load(refreshing: false);

  Future<void> refresh() => _load(refreshing: true);

  Future<void> _load({required bool refreshing}) async {
    if (_loading) return;
    _loading = true;
    emit(
      state.copyWith(
        status: refreshing ? CareStatus.refreshing : CareStatus.loading,
        clearError: true,
      ),
    );
    try {
      final overview = await repository.loadOverview();
      final pendingChatId = _initialSessionConsumed ? null : _initialSessionId;
      _initialSessionConsumed = true;
      emit(
        state.copyWith(
          status: CareStatus.success,
          overview: overview,
          pendingChatId: pendingChatId,
          clearPendingChat: pendingChatId == null,
          clearError: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: CareStatus.failure,
          errorMessage: failureMessage(error),
        ),
      );
    } finally {
      _loading = false;
    }
  }

  void consumePendingChat() {
    if (state.pendingChatId == null) return;
    emit(state.copyWith(clearPendingChat: true));
  }

  Future<bool> requestCare({
    required String reason,
    Map<String, dynamic>? provider,
  }) async {
    if (state.submitting) return false;
    emit(state.copyWith(submitting: true, clearError: true));
    try {
      await repository.createReferral(reason: reason, provider: provider);
      emit(state.copyWith(submitting: false));
      await refresh();
      return true;
    } catch (error) {
      emit(
        state.copyWith(submitting: false, errorMessage: failureMessage(error)),
      );
      return false;
    }
  }
}
