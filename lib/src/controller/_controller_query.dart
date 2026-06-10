part of 'controller.dart';

extension TablexControllerQuery<T> on TablexController<T> {
  // ── Query ─────────────────────────────────────────────────────────────────

  /// Replaces the entire query at once. Use the individual setters below for
  /// targeted updates — they guard against unnecessary rebuilds.
  void updateQuery(TablexQuery query) {
    _checkDisposed();
    if (_state.query == query) return;
    _state = _state.copyWith(query: query);
    _notify();
  }

  /// Sets an arbitrary extra parameter under [key] in [TablexQuery.params].
  ///
  /// If [resetPage] is `true` (the default), the page is reset to 1 so the
  /// user sees results from the beginning after the parameter changes.
  void setParam(String key, dynamic value, {bool resetPage = true}) {
    _checkDisposed();
    final newParams = Map<String, dynamic>.from(_state.query.params)
      ..[key] = value;
    final newQuery = _state.query.copyWith(
      params: newParams,
      page: resetPage ? 1 : null,
    );
    if (_state.query == newQuery) return;
    _state = _state.copyWith(query: newQuery);
    _notify();
  }

  /// Removes an extra parameter by [key] from [TablexQuery.params].
  void removeParam(String key, {bool resetPage = true}) {
    _checkDisposed();
    if (!_state.query.params.containsKey(key)) return;
    final newParams = Map<String, dynamic>.from(_state.query.params)
      ..remove(key);
    final newQuery = _state.query.copyWith(
      params: newParams,
      page: resetPage ? 1 : null,
    );
    _state = _state.copyWith(query: newQuery);
    _notify();
  }

  /// Clears all extra parameters from [TablexQuery.params].
  void clearParams({bool resetPage = true}) {
    _checkDisposed();
    if (_state.query.params.isEmpty) return;
    final newQuery = _state.query.copyWith(
      params: const {},
      page: resetPage ? 1 : null,
    );
    _state = _state.copyWith(query: newQuery);
    _notify();
  }

  // ── Pagination ────────────────────────────────────────────────────────────

  /// Navigates to a specific [page] number (1-based).
  void goToPage(int page) {
    _checkDisposed();
    if (_state.query.page == page) return;
    _state = _state.copyWith(query: _state.query.copyWith(page: page));
    _notify();
  }

  /// Advances to the next page.
  void nextPage() => goToPage(_state.query.page + 1);

  /// Goes back to the previous page. No-op if already on page 1.
  void previousPage() {
    if (_state.query.page > 1) goToPage(_state.query.page - 1);
  }

  /// Changes the page size and resets to page 1.
  void setPageSize(int size) {
    _checkDisposed();
    final newQuery = _state.query.copyWith(pageSize: size, page: 1);
    if (_state.query == newQuery) return;
    _state = _state.copyWith(query: newQuery);
    _notify();
  }

  // ── Sort / filter ─────────────────────────────────────────────────────────

  /// Sets the active sort. Pass `null` to clear sorting and return to the
  /// default server ordering.
  void setSort(TablexColumnSort? sort) {
    _checkDisposed();
    final newQuery = sort == null
        ? _state.query.copyWith(clearSort: true, page: 1)
        : _state.query.copyWith(sort: sort, page: 1);
    if (_state.query == newQuery) return;
    _state = _state.copyWith(query: newQuery);
    _notify();
  }

  /// Replaces the active column filters. Pass an empty list to clear all.
  void setFilters(List<TablexColumnFilter> filters) {
    _checkDisposed();
    final newQuery = _state.query.copyWith(filters: filters, page: 1);
    if (_state.query == newQuery) return;
    _state = _state.copyWith(query: newQuery);
    _notify();
  }

  // ── Loading / meta / error ────────────────────────────────────────────────

  /// Forces the grid to re-fetch the current page, invalidating the page cache.
  ///
  /// Use this after an out-of-band data mutation (e.g. after the user saves
  /// an edit) to sync the grid with the server.
  void refresh() {
    _checkDisposed();
    _refreshSignal.value++;
    _notify();
  }

  /// Updates the loading flag. Normally managed by the widget layer — you only
  /// need this when driving data manually via [replaceRows] / [appendRows].
  void setLoading(bool loading) {
    _checkDisposed();
    if (_state.isLoading == loading) return;
    _state = _state.copyWith(isLoading: loading);
    _notify();
  }

  /// Stores the [TablexResponseMeta] returned by the last fetch. Pass `null`
  /// to clear it.
  void setMeta(TablexResponseMeta? meta) {
    _checkDisposed();
    if (meta == null) {
      _state = _state.copyWith(clearMeta: true);
    } else {
      _state = _state.copyWith(meta: meta);
    }
    _notify();
  }

  /// Stores a fetch error so the [TablexErrorBuilder] can display it. Pass
  /// `null` to clear any previous error.
  void setError(Object? error) {
    _checkDisposed();
    if (error == null) {
      _state = _state.copyWith(clearError: true);
    } else {
      _state = _state.copyWith(error: error);
    }
    _notify();
  }
}
