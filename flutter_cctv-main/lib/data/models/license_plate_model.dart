/// License Plate Data Model - โมเดลข้อมูลทะเบียนรถ
class LicensePlateModel {
  final String? timestamp;
  final String? cameraId;
  final String? imageUrl;
  final LicensePlateDetail? licensePlate;

  LicensePlateModel({
    this.timestamp,
    this.cameraId,
    this.imageUrl,
    this.licensePlate,
  });

  factory LicensePlateModel.fromJson(Map<String, dynamic> json) {
    return LicensePlateModel(
      timestamp: json['timestamp'] as String?,
      cameraId: json['cameraId'] as String?,
      imageUrl: json['imageUrl'] as String?,
      licensePlate: json['licensePlate'] != null
          ? LicensePlateDetail.fromJson(
              json['licensePlate'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (timestamp != null) 'timestamp': timestamp,
      if (cameraId != null) 'cameraId': cameraId,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (licensePlate != null) 'licensePlate': licensePlate?.toJson(),
    };
  }

  @override
  String toString() =>
      'LicensePlateModel(cameraId: $cameraId, plate: ${licensePlate?.fullPlate})';
}

/// รายละเอียดของทะเบียนรถ
class LicensePlateDetail {
  final String? fullPlate;
  final String? province;

  LicensePlateDetail({
    this.fullPlate,
    this.province,
  });

  factory LicensePlateDetail.fromJson(Map<String, dynamic> json) {
    return LicensePlateDetail(
      fullPlate: json['fullPlate'] as String?,
      province: json['province'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (fullPlate != null) 'fullPlate': fullPlate,
      if (province != null) 'province': province,
    };
  }
}
