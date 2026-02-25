import '/data/services/license_plate_service.dart';
import '/data/models/license_plate_model.dart';

/// License Plate Repository - ตัวกลางที่เชื่อม UI กับ LicensePlateService
class LicensePlateRepository {
  final LicensePlateService _service;

  LicensePlateRepository({LicensePlateService? service})
      : _service = service ?? LicensePlateService();

  /// ค้นหาทะเบียนรถจากข้อความ
  Future<List<LicensePlateModel>> searchLicensePlates(
      String licensePlate) async {
    try {
      final response =
          await _service.searchLicensePlates(licensePlate: licensePlate);
      if (response.succeeded && response.jsonBody != null) {
        final data = response.jsonBody;
        if (data is List) {
          return data
              .map((json) =>
                  LicensePlateModel.fromJson(Map<String, dynamic>.from(json)))
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('Error searching license plates: $e');
      return [];
    }
  }
}
