import 'package:collection/collection.dart';
import 'enums.dart';

/// Identifies which column is sorted and in which direction.
class TablexColumnSort {
  const TablexColumnSort({required this.field, required this.direction});

  /// The [TablexColumnBase.fieldKey] of the sorted column.
  final String field;
  final TablexSortDirection direction;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TablexColumnSort &&
          field == other.field &&
          direction == other.direction;

  @override
  int get hashCode => Object.hash(field, direction);
}

/// A single column-level filter condition passed to [TablexFetchTask].
///
/// [field] matches a [TablexColumnBase.fieldKey]. [operator] describes the
/// comparison. [value] is the primary operand; [valueTo] is only used for
/// [TablexFilterOperator.between].
class TablexColumnFilter {
  const TablexColumnFilter({
    required this.field,
    required this.operator,
    required this.value,
    this.valueTo,
  });

  final String field;
  final TablexFilterOperator operator;

  /// Primary filter value.
  final dynamic value;

  /// Upper bound for [TablexFilterOperator.between]; otherwise `null`.
  final dynamic valueTo;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TablexColumnFilter &&
          field == other.field &&
          operator == other.operator &&
          value == other.value &&
          valueTo == other.valueTo;

  @override
  int get hashCode => Object.hash(field, operator, value, valueTo);
}

/// The complete query state sent to [TablexFetchTask] on every fetch.
///
/// [page] and [pageSize] control pagination. [sort] is `null` when no column
/// is sorted. [filters] lists every active column filter. [params] carries
/// any additional key/value pairs set via [TablexController.setParam].
///
/// [TablexQuery] is immutable. Use [copyWith] to produce modified copies,
/// or drive changes through [TablexController] which handles
/// equality-guarded updates automatically.
class TablexQuery {
  const TablexQuery({
    this.page = 1,
    this.pageSize = 25,
    this.sort,
    this.filters = const [],
    this.params = const {},
  });

  /// Current 1-based page number.
  final int page;

  /// Number of rows per page.
  final int pageSize;

  /// Active sort, or `null` for the default server ordering.
  final TablexColumnSort? sort;

  /// Active column filters. Empty when no filters are applied.
  final List<TablexColumnFilter> filters;

  /// Arbitrary extra parameters (e.g. a search term, a status filter) that
  /// don't map to a specific column.
  final Map<String, dynamic> params;

  TablexQuery copyWith({
    int? page,
    int? pageSize,
    TablexColumnSort? sort,
    bool clearSort = false,
    List<TablexColumnFilter>? filters,
    Map<String, dynamic>? params,
  }) =>
      TablexQuery(
        page: page ?? this.page,
        pageSize: pageSize ?? this.pageSize,
        sort: clearSort ? null : (sort ?? this.sort),
        filters: filters ?? this.filters,
        params: params ?? this.params,
      );

  static const _eq = DeepCollectionEquality();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TablexQuery &&
          page == other.page &&
          pageSize == other.pageSize &&
          sort == other.sort &&
          _eq.equals(filters, other.filters) &&
          _eq.equals(params, other.params);

  @override
  int get hashCode => Object.hash(
        page,
        pageSize,
        sort,
        _eq.hash(filters),
        _eq.hash(params),
      );
}
