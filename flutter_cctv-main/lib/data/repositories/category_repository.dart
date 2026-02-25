import '/data/services/category_service.dart';
import '/data/models/category_model.dart';

/// Category Repository - ตัวกลางที่เชื่อม UI กับ CategoryService
class CategoryRepository {
  final CategoryService _service;

  CategoryRepository({CategoryService? service})
      : _service = service ?? CategoryService();

  /// ดึงรายการ Category ทั้งหมด
  Future<List<CategoryModel>> getCategories({
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final response = await _service.getCategories(
        page: page.toString(),
        limit: limit.toString(),
      );
      if (response.succeeded) {
        final dataList = _service.parseDataList(response.jsonBody);
        if (dataList != null) {
          return dataList
              .map((json) =>
                  CategoryModel.fromJson(Map<String, dynamic>.from(json)))
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('Error fetching categories: $e');
      return [];
    }
  }

  /// ดึง Category ตาม ID
  Future<CategoryModel?> getCategoryById(String id) async {
    try {
      final response = await _service.getCategoryById(id);
      if (response.succeeded && response.jsonBody != null) {
        return CategoryModel.fromJson(
            Map<String, dynamic>.from(response.jsonBody));
      }
      return null;
    } catch (e) {
      print('Error fetching category: $e');
      return null;
    }
  }

  /// สร้าง Category ใหม่
  Future<bool> createCategory(String name) async {
    try {
      final response = await _service.createCategory(name: name);
      return response.succeeded;
    } catch (e) {
      print('Error creating category: $e');
      return false;
    }
  }

  /// แก้ไข Category
  Future<bool> updateCategory({
    required String categoryId,
    required String name,
  }) async {
    try {
      final response = await _service.editCategory(
        categoryId: categoryId,
        name: name,
      );
      return response.succeeded;
    } catch (e) {
      print('Error updating category: $e');
      return false;
    }
  }

  /// ลบ Category
  Future<bool> deleteCategory(String categoryId) async {
    try {
      final response = await _service.deleteCategory(categoryId);
      return response.succeeded;
    } catch (e) {
      print('Error deleting category: $e');
      return false;
    }
  }
}
