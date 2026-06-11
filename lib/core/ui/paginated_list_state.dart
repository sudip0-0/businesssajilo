import 'package:flutter/material.dart';

import '../config/pagination.dart';

/// Manages offset-based pagination for list screens.
class PaginatedListState<T> {
  PaginatedListState({required this.loadPage, this.onChanged});

  final Future<List<T>> Function(int offset, int limit) loadPage;
  final VoidCallback? onChanged;

  final List<T> items = [];
  int _offset = 0;
  bool hasMore = true;
  bool loading = false;
  bool initialLoading = true;
  Object? error;

  Future<void> refresh() async {
    _offset = 0;
    hasMore = true;
    items.clear();
    error = null;
    initialLoading = true;
    await loadMore();
    initialLoading = false;
    onChanged?.call();
  }

  Future<void> loadMore() async {
    if (loading || !hasMore) return;
    loading = true;
    error = null;
    try {
      final page = await loadPage(_offset, kListPageSize);
      items.addAll(page);
      _offset += page.length;
      hasMore = page.length >= kListPageSize;
    } catch (e) {
      error = e;
    } finally {
      loading = false;
      onChanged?.call();
    }
  }

  void attachScrollController(ScrollController controller) {
    controller.addListener(() {
      if (!hasMore || loading) return;
      if (controller.position.pixels >=
          controller.position.maxScrollExtent - 200) {
        loadMore();
      }
    });
  }
}
