/// API Configuration - ค่า config ทั้งหมดสำหรับเชื่อมต่อ Backend
class ApiConfig {
  // Base URL
  static const String baseUrl = 'https://se-lab.aboutblank.in.th/api';

  // Auth Endpoints
  static const String loginEndpoint = '/auth/login';

  // Camera Endpoints
  static const String camerasEndpoint = '/cameras';
  static const String camerasMapEndpoint = '/cameras/map';
  static const String camerasTotalEndpoint = '/cameras/total';

  // Category Endpoints
  static const String categoryEndpoint = '/categories';

  // License Plate Endpoints
  static const String licensePlateSearchEndpoint = '/license-plates/search';

  // Accident Endpoints
  static const String accidentsEndpoint = '/accidents';

  // HLS Streaming
  static const String hlsBaseUrl = 'https://se-lab.aboutblank.in.th';
  static const String hlsStartEndpoint = '/api/stream/hls/start';
}
