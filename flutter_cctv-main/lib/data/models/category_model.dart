/// Category Data Model - โมเดลข้อมูลหมวดหมู่
class CategoryModel {
  final String? id;
  final String? name;

  CategoryModel({
    this.id,
    this.name,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String?,
      name: json['name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (name != null) 'name': name,
    };
  }

  /// JSON body สำหรับ create/edit category
  Map<String, dynamic> toCreateJson() {
    return {
      'name': name ?? '',
    };
  }

  CategoryModel copyWith({
    String? id,
    String? name,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
    );
  }

  @override
  String toString() => 'CategoryModel(id: $id, name: $name)';
}
