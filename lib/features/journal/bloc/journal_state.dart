import 'package:equatable/equatable.dart';

enum JournalStatus { initial, loading, success, empty, failure }

class JournalState extends Equatable {
  const JournalState({
    this.status = JournalStatus.initial,
    this.entries = const [],
    this.page = 1,
    this.hasMore = false,
    this.creating = false,
    this.loadingMore = false,
    this.errorMessage,
    this.actionError,
    this.lastCreatedRisk,
  });

  final JournalStatus status;
  final List<Map<String, dynamic>> entries;
  final int page;
  final bool hasMore;
  final bool creating;
  final bool loadingMore;
  final String? errorMessage;
  final String? actionError;
  final String? lastCreatedRisk;

  bool get isBusy => status == JournalStatus.loading || creating || loadingMore;

  JournalState copyWith({
    JournalStatus? status,
    List<Map<String, dynamic>>? entries,
    int? page,
    bool? hasMore,
    bool? creating,
    bool? loadingMore,
    String? errorMessage,
    bool clearError = false,
    String? actionError,
    bool clearActionError = false,
    String? lastCreatedRisk,
    bool clearLastCreatedRisk = false,
  }) {
    return JournalState(
      status: status ?? this.status,
      entries: entries ?? this.entries,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      creating: creating ?? this.creating,
      loadingMore: loadingMore ?? this.loadingMore,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      actionError: clearActionError ? null : actionError ?? this.actionError,
      lastCreatedRisk: clearLastCreatedRisk
          ? null
          : lastCreatedRisk ?? this.lastCreatedRisk,
    );
  }

  @override
  List<Object?> get props => [
    status,
    entries,
    page,
    hasMore,
    creating,
    loadingMore,
    errorMessage,
    actionError,
    lastCreatedRisk,
  ];
}
