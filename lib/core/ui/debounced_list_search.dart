import 'dart:async';

import 'package:flutter/foundation.dart';

import '../logging/app_log.dart';

/// Explicit phases for debounced remote list search.
enum ListSearchPhase { idle, loading, data, error }

/// Debounced search with loading / data / error states (no silent empty fallback).
class DebouncedListSearchController<T> {
  DebouncedListSearchController({
    required this.search,
    required this.onChanged,
    this.debounce = const Duration(milliseconds: 350),
  });

  final Future<List<T>> Function(String query) search;
  final VoidCallback onChanged;
  final Duration debounce;

  String _query = '';
  ListSearchPhase _phase = ListSearchPhase.idle;
  List<T>? _results;
  Object? _error;
  Timer? _debounceTimer;

  String get query => _query;
  ListSearchPhase get phase => _phase;
  List<T>? get results => _results;
  Object? get error => _error;
  bool get isActive => _query.isNotEmpty;

  void onQueryChanged(String value) {
    _query = value.trim();
    _debounceTimer?.cancel();
    if (_query.isEmpty) {
      _phase = ListSearchPhase.idle;
      _results = null;
      _error = null;
      onChanged();
      return;
    }
    _phase = ListSearchPhase.loading;
    _error = null;
    onChanged();
    _debounceTimer = Timer(debounce, _runSearch);
  }

  Future<void> retry() async {
    if (_query.isEmpty) return;
    _phase = ListSearchPhase.loading;
    _error = null;
    onChanged();
    await _runSearch();
  }

  Future<void> _runSearch() async {
    final query = _query;
    try {
      final results = await search(query);
      if (_query != query) return;
      _results = results;
      _phase = ListSearchPhase.data;
      _error = null;
      onChanged();
    } catch (e, st) {
      if (_query != query) return;
      _results = null;
      _phase = ListSearchPhase.error;
      _error = e;
      AppLog.warn('DebouncedListSearchController search failed', e, st);
      onChanged();
    }
  }

  void dispose() {
    _debounceTimer?.cancel();
  }
}
