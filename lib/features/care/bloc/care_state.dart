import 'package:equatable/equatable.dart';

import '../data/care_repository.dart';

enum CareStatus { initial, loading, refreshing, success, failure }

class CareState extends Equatable {
  const CareState({
    this.status = CareStatus.initial,
    this.overview = const CareOverview(providers: [], referrals: [], chats: []),
    this.pendingChatId,
    this.submitting = false,
    this.errorMessage,
  });

  final CareStatus status;
  final CareOverview overview;
  final String? pendingChatId;
  final bool submitting;
  final String? errorMessage;

  CareState copyWith({
    CareStatus? status,
    CareOverview? overview,
    String? pendingChatId,
    bool clearPendingChat = false,
    bool? submitting,
    String? errorMessage,
    bool clearError = false,
  }) {
    return CareState(
      status: status ?? this.status,
      overview: overview ?? this.overview,
      pendingChatId: clearPendingChat
          ? null
          : pendingChatId ?? this.pendingChatId,
      submitting: submitting ?? this.submitting,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    overview.providers,
    overview.referrals,
    overview.chats,
    pendingChatId,
    submitting,
    errorMessage,
  ];
}
