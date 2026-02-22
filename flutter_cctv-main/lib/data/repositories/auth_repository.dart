import '/data/services/auth_service.dart';
import '/data/services/api_manager.dart';

/// Auth Repository - ตัวกลางที่เชื่อม UI กับ AuthService
class AuthRepository {
  final AuthService _service;

  AuthRepository({AuthService? service})
      : _service = service ?? AuthService();

  /// เข้าสู่ระบบ
  Future<ApiCallResponse> login({
    required String username,
    required String password,
  }) async {
    try {
      return await _service.login(
        username: username,
        password: password,
      );
    } catch (e) {
      print('Error logging in: $e');
      return ApiCallResponse(null, {}, -1);
    }
  }
}
