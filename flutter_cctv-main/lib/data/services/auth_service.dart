import '/data/services/api_manager.dart';
import '/core/config/api_config.dart';

export '/data/services/api_manager.dart' show ApiCallResponse;

/// Auth Service - จัดการ API สำหรับ Authentication
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  /// Login ด้วย username + password
  Future<ApiCallResponse> login({
    String? username,
    String? password,
  }) async {
    final body = '''
{
  "username": "${_escape(username)}",
  "password": "${_escape(password)}"
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'login',
      apiUrl: '${ApiConfig.baseUrl}${ApiConfig.loginEndpoint}',
      callType: ApiCallType.POST,
      headers: {
        'Content-Type': 'application/json',
      },
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
