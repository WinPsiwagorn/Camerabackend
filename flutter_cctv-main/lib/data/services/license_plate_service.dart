import '/data/services/api_manager.dart';
import '/utils/flutter_flow/util.dart';
import '/core/config/api_config.dart';

export '/data/services/api_manager.dart' show ApiCallResponse;

/// License Plate Service - จัดการ API สำหรับค้นหาทะเบียนรถ
class LicensePlateService {
  static final LicensePlateService _instance =
      LicensePlateService._internal();
  factory LicensePlateService() => _instance;
  LicensePlateService._internal();

  /// ค้นหาทะเบียนรถ
  Future<ApiCallResponse> searchLicensePlates({
    String? licensePlate,
  }) async {
    return ApiManager.instance.makeApiCall(
      callName: 'Search License Plates',
      apiUrl: '${ApiConfig.baseUrl}${ApiConfig.licensePlateSearchEndpoint}',
      callType: ApiCallType.GET,
      headers: {
        'Content-Type': 'application/json',
      },
      params: {
        if (licensePlate != null) 'licensePlate': licensePlate,
      },
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  // --- JSON Response Helpers ---

  String? parseTimestamp(dynamic response) =>
      castToType<String>(getJsonField(response, r'$[:].timestamp'));

  String? parseCameraId(dynamic response) =>
      castToType<String>(getJsonField(response, r'$[:].cameraId'));

  String? parseFullPlate(dynamic response) =>
      castToType<String>(getJsonField(response, r'$[:].licensePlate.fullPlate'));

  String? parseImageUrl(dynamic response) =>
      castToType<String>(getJsonField(response, r'$[:].imageUrl'));

  String? parseProvince(dynamic response) =>
      castToType<String>(getJsonField(response, r'$[:].licensePlate.province'));

  dynamic parseLicensePlateData(dynamic response) =>
      getJsonField(response, r'$[:].licensePlate');
}
