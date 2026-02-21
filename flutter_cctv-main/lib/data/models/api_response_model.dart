/// Pagination Meta Model - โมเดลสำหรับข้อมูล pagination
class PaginationMeta {
  final int? currentPage;
  final int? totalPages;
  final int? totalItems;
  final int? limit;
  final bool? hasNext;
  final bool? hasPrevious;

  PaginationMeta({
    this.currentPage,
    this.totalPages,
    this.totalItems,
    this.limit,
    this.hasNext,
    this.hasPrevious,
  });

  factory PaginationMeta.fromJson(Map<String, dynamic> json) {
    return PaginationMeta(
      currentPage: json['currentPage'] as int?,
      totalPages: json['totalPages'] as int?,
      totalItems: json['totalItems'] as int?,
      limit: json['limit'] as int?,
      hasNext: json['hasNext'] as bool?,
      hasPrevious: json['hasPrevious'] as bool?,
    );
  }
}

/// API Response wrapper ที่รวม data + meta
class ApiListResponse<T> {
  final List<T> data;
  final PaginationMeta? meta;

  ApiListResponse({
    required this.data,
    this.meta,
  });
}
