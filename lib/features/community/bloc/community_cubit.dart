import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/app_services.dart';
import '../data/community_repository.dart';
import 'community_state.dart';

class CommunityCubit extends Cubit<CommunityState> {
  CommunityCubit({required this.repository, this.pageSize = 5})
    : super(const CommunityState());

  final CommunityRepository repository;
  final int pageSize;
  bool _loadingFeed = false;
  bool _loadingHeatmap = false;
  bool _loadingMore = false;
  bool _composing = false;

  Future<void> load() async {
    if (_loadingFeed || _loadingHeatmap) return;
    _loadingFeed = true;
    _loadingHeatmap = true;
    emit(
      state.copyWith(
        feedStatus: CommunityFeedStatus.loading,
        heatmapStatus: CommunityHeatmapStatus.loading,
        clearFeedError: true,
        clearHeatmapError: true,
      ),
    );
    await Future.wait([_requestFirstFeedPage(), _requestHeatmap()]);
  }

  Future<void> refresh() => load();

  Future<void> loadFeed() async {
    if (_loadingFeed) return;
    _loadingFeed = true;
    emit(
      state.copyWith(
        feedStatus: CommunityFeedStatus.loading,
        clearFeedError: true,
      ),
    );
    await _requestFirstFeedPage();
  }

  Future<void> loadHeatmap() async {
    if (_loadingHeatmap) return;
    _loadingHeatmap = true;
    emit(
      state.copyWith(
        heatmapStatus: CommunityHeatmapStatus.loading,
        clearHeatmapError: true,
      ),
    );
    await _requestHeatmap();
  }

  Future<void> _requestFirstFeedPage() async {
    try {
      final page = await repository.loadFeed(limit: pageSize);
      emit(
        state.copyWith(
          feedStatus: page.items.isEmpty
              ? CommunityFeedStatus.empty
              : CommunityFeedStatus.success,
          posts: List.unmodifiable(page.items),
          nextCursor: page.nextCursor,
          clearNextCursor: page.nextCursor == null,
          clearFeedError: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          feedStatus: CommunityFeedStatus.failure,
          feedError: failureMessage(error),
        ),
      );
    } finally {
      _loadingFeed = false;
    }
  }

  Future<void> _requestHeatmap() async {
    try {
      final items = await repository.loadHeatmap();
      emit(
        state.copyWith(
          heatmapStatus: items.isEmpty
              ? CommunityHeatmapStatus.empty
              : CommunityHeatmapStatus.success,
          heatmapItems: List.unmodifiable(items),
          clearHeatmapError: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          heatmapStatus: CommunityHeatmapStatus.failure,
          heatmapError: failureMessage(error),
        ),
      );
    } finally {
      _loadingHeatmap = false;
    }
  }

  Future<void> loadMoreFeed() async {
    final cursor = state.nextCursor;
    if (_loadingMore || cursor == null || state.posts.isEmpty) return;
    _loadingMore = true;
    emit(state.copyWith(loadingMoreFeed: true, clearFeedError: true));
    try {
      final page = await repository.loadFeed(cursor: cursor, limit: pageSize);
      emit(
        state.copyWith(
          feedStatus: CommunityFeedStatus.success,
          posts: List.unmodifiable(_appendUnique(state.posts, page.items)),
          nextCursor: page.nextCursor,
          clearNextCursor: page.nextCursor == null,
          loadingMoreFeed: false,
          clearFeedError: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          loadingMoreFeed: false,
          feedError: failureMessage(error),
        ),
      );
    } finally {
      _loadingMore = false;
    }
  }

  Future<bool> createPost({
    required String alias,
    required String content,
    String? mood,
  }) async {
    final cleanAlias = alias.trim();
    final cleanContent = content.trim();
    if (cleanAlias.isEmpty || cleanContent.isEmpty || _composing) return false;
    _composing = true;
    emit(
      state.copyWith(
        composing: true,
        clearActionError: true,
        clearActionMessage: true,
      ),
    );
    try {
      await repository.createPost(
        alias: cleanAlias,
        content: cleanContent,
        mood: mood,
      );
      await _requestFirstFeedPage();
      emit(
        state.copyWith(
          composing: false,
          actionMessage: 'Community story shared.',
          clearActionError: true,
          actionVersion: state.actionVersion + 1,
        ),
      );
      return true;
    } catch (error) {
      emit(
        state.copyWith(
          composing: false,
          actionError: failureMessage(error),
          clearActionMessage: true,
          actionVersion: state.actionVersion + 1,
        ),
      );
      return false;
    } finally {
      _composing = false;
    }
  }

  Future<bool> support(String postId) => _runTargetAction(
    targetId: postId,
    action: () => repository.support(postId),
    refreshFeed: true,
  );

  Future<bool> comment(String postId, String content) {
    final cleanContent = content.trim();
    if (cleanContent.isEmpty) return Future.value(false);
    return _runTargetAction(
      targetId: postId,
      action: () => repository.comment(postId, cleanContent),
      refreshFeed: true,
      successMessage: 'Supportive comment added.',
    );
  }

  Future<bool> report({
    required String targetType,
    required String targetId,
    required String reason,
    String? details,
  }) => _runTargetAction(
    targetId: targetId,
    action: () => repository.report(
      targetType: targetType,
      targetId: targetId,
      reason: reason,
      details: details,
    ),
    successMessage: 'Report submitted for review.',
  );

  Future<bool> contributeHeatmap({
    required String regionKey,
    required String mood,
  }) async {
    if (state.contributingHeatmap || regionKey.trim().isEmpty) return false;
    emit(
      state.copyWith(
        contributingHeatmap: true,
        clearActionError: true,
        clearActionMessage: true,
      ),
    );
    try {
      await repository.contributeHeatmap(regionKey.trim(), mood);
      await _requestHeatmap();
      emit(
        state.copyWith(
          contributingHeatmap: false,
          actionMessage:
              'Coarse regional mood contribution saved. Exact coordinates were not sent.',
          clearActionError: true,
          actionVersion: state.actionVersion + 1,
        ),
      );
      return true;
    } catch (error) {
      emit(
        state.copyWith(
          contributingHeatmap: false,
          actionError: failureMessage(error),
          clearActionMessage: true,
          actionVersion: state.actionVersion + 1,
        ),
      );
      return false;
    }
  }

  Future<bool> _runTargetAction({
    required String targetId,
    required Future<void> Function() action,
    bool refreshFeed = false,
    String? successMessage,
  }) async {
    if (state.busyTargetIds.contains(targetId)) return false;
    emit(
      state.copyWith(
        busyTargetIds: Set.unmodifiable({...state.busyTargetIds, targetId}),
        clearActionError: true,
        clearActionMessage: true,
      ),
    );
    try {
      await action();
      if (refreshFeed) await _requestFirstFeedPage();
      final busy = {...state.busyTargetIds}..remove(targetId);
      emit(
        state.copyWith(
          busyTargetIds: Set.unmodifiable(busy),
          actionMessage: successMessage,
          clearActionMessage: successMessage == null,
          clearActionError: true,
          actionVersion: state.actionVersion + 1,
        ),
      );
      return true;
    } catch (error) {
      final busy = {...state.busyTargetIds}..remove(targetId);
      emit(
        state.copyWith(
          busyTargetIds: Set.unmodifiable(busy),
          actionError: failureMessage(error),
          clearActionMessage: true,
          actionVersion: state.actionVersion + 1,
        ),
      );
      return false;
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
}
