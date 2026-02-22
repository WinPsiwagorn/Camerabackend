import '/data/services/api_manager.dart';
import '/utils/flutter_flow_util.dart';
import '/core/config/api_config.dart';

export '/data/services/api_manager.dart' show ApiCallResponse;

/// Category Service - จัดการ API ทั้งหมดที่เกี่ยวข้องกับ Category
class CategoryService {
  static final CategoryService _instance = CategoryService._internal();
  factory CategoryService() => _instance;
  CategoryService._internal();

  static String get _baseUrl => ApiConfig.baseUrl;

  /// ดึงรายการ Category ทั้งหมด
  Future<ApiCallResponse> getCategories({
    String? page,
    String? limit,
  }) async {
    return ApiManager.instance.makeApiCall(
      callName: 'Get Category',
      apiUrl: '$_baseUrl${ApiConfig.categoryEndpoint}',
      callType: ApiCallType.GET,
      headers: {},
      params: {
        if (page != null && page.isNotEmpty) 'page': page,
        if (limit != null && limit.isNotEmpty) 'limit': limit,
      },
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  /// สร้าง Category ใหม่
  Future<ApiCallResponse> createCategory({String? name}) async {
    final body = '''
{
  "name": "${_escape(name)}"
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'Create Category',
      apiUrl: '$_baseUrl${ApiConfig.categoryEndpoint}',
      callType: ApiCallType.POST,
      headers: {},
      params: {},
      body: body,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  /// ดึง Category ตาม ID
  Future<ApiCallResponse> getCategoryById(String categoryId) async {
    return ApiManager.instance.makeApiCall(
      callName: 'Get Category by ID',
      apiUrl: '$_baseUrl${ApiConfig.categoryEndpoint}/$categoryId',
      callType: ApiCallType.GET,
      headers: {},
      params: {},
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  /// แก้ไข Category
  Future<ApiCallResponse> editCategory({
    required String categoryId,
    String? name,
  }) async {
    final body = '''
{
  "name": "${_escape(name)}"
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'Edit Category by ID',
      apiUrl: '$_baseUrl${ApiConfig.categoryEndpoint}/$categoryId',
      callType: ApiCallType.PATCH,
      headers: {},
      params: {},
      body: body,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  /// ลบ Category
  Future<ApiCallResponse> deleteCategory(String categoryId) async {
    return ApiManager.instance.makeApiCall(
      callName: 'Delete Category by ID',
      apiUrl: '$_baseUrl${ApiConfig.categoryEndpoint}/$categoryId',
      callType: ApiCallType.DELETE,
      headers: {},
      params: {},
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  // --- JSON Response Helpers ---

  List? parseDataList(dynamic response) => getJsonField(
        response,
        r'$.data',
        true,
      ) as List?;

  List<String>? parseIds(dynamic response) => (getJsonField(
        response,
        r'$.data[:].id',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();

  List<String>? parseNames(dynamic response) => (getJsonField(
        response,
        r'$.data[:].name',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();

  int? parseCurrentPage(dynamic response) => castToType<int>(getJsonField(
        response,
        r'$.meta.currentPage',
      ));

  /// Escape string for JSON
  String? _escape(String? input) {
    if (input == null) return null;
    return input
        .replaceAll('\\', '\\\\')
        .replaceAll('"', '\\"')
        .replaceAll('\n', '\\n')
        .replaceAll('\t', '\\t');
  }
}
