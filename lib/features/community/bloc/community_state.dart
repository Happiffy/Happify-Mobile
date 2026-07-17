import 'package:equatable/equatable.dart';

enum CommunityFeedStatus { initial, loading, success, empty, failure }

enum CommunityHeatmapStatus { initial, loading, success, empty, failure }

class CommunityState extends Equatable {
  const CommunityState({
    this.feedStatus = CommunityFeedStatus.initial,
    this.heatmapStatus = CommunityHeatmapStatus.initial,
    this.posts = const [],
    this.nextCursor,
    this.heatmapItems = const [],
    this.heatmapStartDate,
    this.heatmapEndDate,
    this.loadingMoreFeed = false,
    this.composing = false,
    this.busyTargetIds = const <String>{},
    this.contributingHeatmap = false,
    this.feedError,
    this.heatmapError,
    this.actionError,
    this.actionMessage,
    this.actionVersion = 0,
  });

  final CommunityFeedStatus feedStatus;
  final CommunityHeatmapStatus heatmapStatus;
  final List<Map<String, dynamic>> posts;
  final String? nextCursor;
  final List<Map<String, dynamic>> heatmapItems;
  final DateTime? heatmapStartDate;
  final DateTime? heatmapEndDate;
  final bool loadingMoreFeed;
  final bool composing;
  final Set<String> busyTargetIds;
  final bool contributingHeatmap;
  final String? feedError;
  final String? heatmapError;
  final String? actionError;
  final String? actionMessage;
  final int actionVersion;

  bool get hasMoreFeed => nextCursor != null;
  bool get isBusy =>
      loadingMoreFeed ||
      composing ||
      busyTargetIds.isNotEmpty ||
      contributingHeatmap;

  CommunityState copyWith({
    CommunityFeedStatus? feedStatus,
    CommunityHeatmapStatus? heatmapStatus,
    List<Map<String, dynamic>>? posts,
    String? nextCursor,
    bool clearNextCursor = false,
    List<Map<String, dynamic>>? heatmapItems,
    DateTime? heatmapStartDate,
    DateTime? heatmapEndDate,
    bool clearHeatmapDates = false,
    bool? loadingMoreFeed,
    bool? composing,
    Set<String>? busyTargetIds,
    bool? contributingHeatmap,
    String? feedError,
    bool clearFeedError = false,
    String? heatmapError,
    bool clearHeatmapError = false,
    String? actionError,
    bool clearActionError = false,
    String? actionMessage,
    bool clearActionMessage = false,
    int? actionVersion,
  }) {
    return CommunityState(
      feedStatus: feedStatus ?? this.feedStatus,
      heatmapStatus: heatmapStatus ?? this.heatmapStatus,
      posts: posts ?? this.posts,
      nextCursor: clearNextCursor ? null : nextCursor ?? this.nextCursor,
      heatmapItems: heatmapItems ?? this.heatmapItems,
      heatmapStartDate: clearHeatmapDates
          ? null
          : heatmapStartDate ?? this.heatmapStartDate,
      heatmapEndDate: clearHeatmapDates
          ? null
          : heatmapEndDate ?? this.heatmapEndDate,
      loadingMoreFeed: loadingMoreFeed ?? this.loadingMoreFeed,
      composing: composing ?? this.composing,
      busyTargetIds: busyTargetIds ?? this.busyTargetIds,
      contributingHeatmap: contributingHeatmap ?? this.contributingHeatmap,
      feedError: clearFeedError ? null : feedError ?? this.feedError,
      heatmapError: clearHeatmapError
          ? null
          : heatmapError ?? this.heatmapError,
      actionError: clearActionError ? null : actionError ?? this.actionError,
      actionMessage: clearActionMessage
          ? null
          : actionMessage ?? this.actionMessage,
      actionVersion: actionVersion ?? this.actionVersion,
    );
  }

  @override
  List<Object?> get props => [
    feedStatus,
    heatmapStatus,
    posts,
    nextCursor,
    heatmapItems,
    heatmapStartDate,
    heatmapEndDate,
    loadingMoreFeed,
    composing,
    busyTargetIds,
    contributingHeatmap,
    feedError,
    heatmapError,
    actionError,
    actionMessage,
    actionVersion,
  ];
}
