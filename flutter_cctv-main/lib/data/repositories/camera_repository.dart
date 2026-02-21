import '/data/services/camera_service.dart';
import '/data/models/camera_model.dart';
import '/data/models/api_response_model.dart';

/// Camera Repository - ตัวกลางที่เชื่อม UI กับ CameraService
/// ทำหน้าที่แปลง API Response เป็น Model objects
class CameraRepository {
  final CameraService _service;

  CameraRepository({CameraService? service})
      : _service = service ?? CameraService();

  /// ดึงรายการกล้องทั้งหมด
  Future<List<CameraModel>> getCameras({
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final response = await _service.getCameras(
        page: page.toString(),
        limit: limit.toString(),
      );
      if (response.succeeded) {
        final dataList = _service.parseDataList(response.jsonBody);
        if (dataList != null) {
          return dataList
              .map((json) =>
                  CameraModel.fromJson(Map<String, dynamic>.from(json)))
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('Error fetching cameras: $e');
      return [];
    }
  }

  /// ดึงข้อมูลกล้องตาม ID
  Future<CameraModel?> getCameraById(String id) async {
    try {
      final response = await _service.getCameraById(id);
      if (response.succeeded && response.jsonBody != null) {
        return CameraModel.fromJson(
            Map<String, dynamic>.from(response.jsonBody));
      }
      return null;
    } catch (e) {
      print('Error fetching camera by id: $e');
      return null;
    }
  }

  /// สร้างกล้องใหม่
  Future<bool> createCamera({
    required String name,
    String? latLong,
    String? address,
    String? rtspUrl,
  }) async {
    try {
      final response = await _service.createCamera(
        name: name,
        latLong: latLong,
        address: address,
        rtspUrl: rtspUrl,
      );
      return response.succeeded;
    } catch (e) {
      print('Error creating camera: $e');
      return false;
    }
  }

  /// แก้ไขข้อมูลกล้อง
  Future<bool> updateCamera({
    required String cameraId,
    String? name,
    String? latLong,
    String? address,
    String? rtspUrl,
  }) async {
    try {
      final response = await _service.editCamera(
        cameraId: cameraId,
        name: name,
        latLong: latLong,
        address: address,
        rtspUrl: rtspUrl,
      );
      return response.succeeded;
    } catch (e) {
      print('Error updating camera: $e');
      return false;
    }
  }

  /// ลบกล้อง
  Future<bool> deleteCamera(String cameraId) async {
    try {
      final response = await _service.deleteCamera(cameraId);
      return response.succeeded;
    } catch (e) {
      print('Error deleting camera: $e');
      return false;
    }
  }

  /// ดึงข้อมูลกล้องสำหรับแผนที่
  Future<List<CameraModel>> getCamerasForMap() async {
    try {
      final response = await _service.getCamerasForMap();
      if (response.succeeded && response.jsonBody != null) {
        final data = response.jsonBody;
        if (data is List) {
          return data
              .map((json) =>
                  CameraModel.fromJson(Map<String, dynamic>.from(json)))
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('Error fetching cameras for map: $e');
      return [];
    }
  }

  /// เพิ่ม Category ให้กล้อง
  Future<bool> addCategoryToCamera({
    required String categoryId,
    required String cameraId,
  }) async {
    try {
      final response = await _service.addCategoryToCamera(
        categoryId: categoryId,
        cameraId: cameraId,
      );
      return response.succeeded;
    } catch (e) {
      print('Error adding category to camera: $e');
      return false;
    }
  }

  /// ลบ Category ออกจากกล้อง
  Future<bool> deleteCategoryFromCamera({
    required String categoryId,
    required String cameraId,
  }) async {
    try {
      final response = await _service.deleteCategoryFromCamera(
        categoryId: categoryId,
        cameraId: cameraId,
      );
      return response.succeeded;
    } catch (e) {
      print('Error removing category from camera: $e');
      return false;
    }
  }
}
