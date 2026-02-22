import '/core/state/app_state.dart';
import '/data/services/api_manager.dart';
import '/utils/flutter_flow_util.dart';
import '/core/config/api_config.dart';
import '/data/models/camera_model.dart';
import '/data/models/category_model.dart';
import '/data/models/api_response_model.dart';

export '/data/services/api_manager.dart' show ApiCallResponse;

/// Camera Service - จัดการ API ทั้งหมดที่เกี่ยวข้องกับกล้อง
class CameraService {
  static final CameraService _instance = CameraService._internal();
  factory CameraService() => _instance;
  CameraService._internal();

  static String get _baseUrl => ApiConfig.baseUrl;

  /// Returns Authorization header map if token is available.
  Map<String, dynamic> get _authHeader {
    final token = AppState().authToken;
    if (token.isEmpty) return {};
    return {'Authorization': 'Bearer $token'};
  }

  /// ดึงรายการกล้องทั้งหมด (พร้อม pagination)
  Future<ApiCallResponse> getCameras({
    String? page,
    String? limit,
    String? search,
  }) async {
    return ApiManager.instance.makeApiCall(
      callName: 'Get Camera',
      apiUrl: '$_baseUrl${ApiConfig.camerasEndpoint}',
      callType: ApiCallType.GET,
      headers: _authHeader,
      params: {
        if (page != null && page.isNotEmpty) 'page': page,
        if (limit != null && limit.isNotEmpty) 'limit': limit,
        if (search != null && search.isNotEmpty) 'search': search,
      },
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  /// ดึงข้อมูลกล้องตาม ID
  Future<ApiCallResponse> getCameraById(String cameraId) async {
    return ApiManager.instance.makeApiCall(
      callName: 'Get Camera by ID',
      apiUrl: '$_baseUrl${ApiConfig.camerasEndpoint}/$cameraId',
      callType: ApiCallType.GET,
      headers: _authHeader,
      params: {},
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  /// สร้างกล้องใหม่
  Future<ApiCallResponse> createCamera({
    String? name,
    String? latLong,
    String? address,
    String? rtspUrl,
  }) async {
    final body = '''
{
  "name": "${_escape(name)}",
  "latLong": "${_escape(latLong)}",
  "address": "${_escape(address)}",
  "rtspUrl": "${_escape(rtspUrl)}"
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'Create Camera',
      apiUrl: '$_baseUrl${ApiConfig.camerasEndpoint}',
      callType: ApiCallType.POST,
      headers: {..._authHeader, 'Content-Type': 'application/json'},
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

  /// แก้ไขข้อมูลกล้อง
  Future<ApiCallResponse> editCamera({
    required String cameraId,
    String? name,
    String? latLong,
    String? address,
    String? rtspUrl,
  }) async {
    final body = '''
{
  "name": "${_escape(name)}",
  "latLong": "${_escape(latLong)}",
  "address": "${_escape(address)}",
  "rtspUrl": "${_escape(rtspUrl)}"
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'Edit Camera by ID',
      apiUrl: '$_baseUrl${ApiConfig.camerasEndpoint}/$cameraId',
      callType: ApiCallType.PATCH,
      headers: {..._authHeader, 'Content-Type': 'application/json'},
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

  /// ลบกล้อง
  Future<ApiCallResponse> deleteCamera(String cameraId) async {
    return ApiManager.instance.makeApiCall(
      callName: 'Delete Camera by ID',
      apiUrl: '$_baseUrl${ApiConfig.camerasEndpoint}/$cameraId',
      callType: ApiCallType.DELETE,
      headers: _authHeader,
      params: {},
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  /// ดึงสถิติกล้อง (total / online / offline)
  Future<ApiCallResponse> getCamerasTotal() async {
    return ApiManager.instance.makeApiCall(
      callName: 'Get Cameras Total',
      apiUrl: '$_baseUrl${ApiConfig.camerasTotalEndpoint}',
      callType: ApiCallType.GET,
      headers: _authHeader,
      params: {},
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  /// ดึงข้อมูลกล้องสำหรับแผนที่
  Future<ApiCallResponse> getCamerasForMap() async {
    return ApiManager.instance.makeApiCall(
      callName: 'Get Camera for map',
      apiUrl: '$_baseUrl${ApiConfig.camerasMapEndpoint}',
      callType: ApiCallType.GET,
      headers: _authHeader,
      params: {},
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  /// เพิ่ม Category ให้กล้อง
  Future<ApiCallResponse> addCategoryToCamera({
    required String categoryId,
    required String cameraId,
  }) async {
    final body = '''
{
  "cameraId": "${_escape(cameraId)}"
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'Add Category to Camera',
      apiUrl: '$_baseUrl${ApiConfig.categoryEndpoint}/$categoryId/cameras',
      callType: ApiCallType.POST,
      headers: {..._authHeader, 'Content-Type': 'application/json'},
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

  /// ดึงกล้องตาม Category ID
  Future<ApiCallResponse> getCamerasByCategoryId(String categoryId) async {
    return ApiManager.instance.makeApiCall(
      callName: 'Get Camera by Category ID',
      apiUrl: '$_baseUrl${ApiConfig.categoryEndpoint}/$categoryId/cameras',
      callType: ApiCallType.GET,
      headers: _authHeader,
      params: {},
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  /// ลบ Category ออกจากกล้อง
  Future<ApiCallResponse> deleteCategoryFromCamera({
    required String categoryId,
    required String cameraId,
  }) async {
    return ApiManager.instance.makeApiCall(
      callName: 'Delete Category from Camera',
      apiUrl:
          '$_baseUrl${ApiConfig.categoryEndpoint}/$categoryId/cameras/$cameraId',
      callType: ApiCallType.DELETE,
      headers: _authHeader,
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

  /// ดึง data array จาก API response
  List? parseDataList(dynamic response) => getJsonField(
        response,
        r'$.data[:]',
        true,
      ) as List?;

  List<String>? parseNames(dynamic response) => (getJsonField(
        response,
        r'$.data[:].name',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();

  List<String>? parseIds(dynamic response) => (getJsonField(
        response,
        r'$.data[:].id',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();

  List<String>? parseStatuses(dynamic response) => (getJsonField(
        response,
        r'$.data[:].status',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();

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
