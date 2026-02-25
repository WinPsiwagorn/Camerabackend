// Automatic FlutterFlow imports
import '/utils/flutter_flow/theme.dart';
import '/utils/flutter_flow/util.dart';
import '../index.dart'; // Imports other custom widgets
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'dart:convert';
import 'package:http/http.dart' as http; // <-- ใช้ยิง POST
import '/data/services/category_service.dart';
import '/data/services/camera_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ====== ตั้งค่า BASE URL ของ backend (แก้ให้ตรงระบบคุณ) ======
const String kApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://se-lab.aboutblank.in.th', // <-- เปลี่ยนเป็นของคุณ
);

class CameraInfo {
  final String id;
  final String name;

  /// flow ใหม่: url คือ RTSP
  final String rtspUrl;

  CameraInfo({
    required this.id,
    required this.name,
    required this.rtspUrl,
  });

  factory CameraInfo.fromJson(Map<String, dynamic> data, {String? docId}) {
    // Debug: Print the camera data structure
    print('📷 Parsing camera: ${data.keys.toList()}');
    
    return CameraInfo(
      id: docId ?? data['id']?.toString() ?? '',
      name: (data['name'] as String?)?.trim().isNotEmpty == true
          ? (data['name'] as String)
          : 'Camera',
      rtspUrl: (data['rtspUrl'] as String? ?? 
                data['url'] as String? ?? 
                data['URL'] as String? ?? 
                data['rtsp_url'] as String? ?? '').trim(),
    );
  }
}

class _VideoTile extends StatelessWidget {
  final int index;
  final CameraInfo? camera;
  final Future<String?>? hlsFuture;
  final bool isEditMode;
  final bool isSelected; // Track if this tile is selected for swapping

  const _VideoTile({
    Key? key,
    required this.index,
    required this.camera,
    required this.hlsFuture,
    this.isEditMode = false,
    this.isSelected = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final hasCam = camera != null;

    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Stack(
        children: [
          // Base layer: Video player or placeholder
          Positioned.fill(
            child: isEditMode
                // EDIT MODE: Show static placeholder instead of video
                // This completely avoids iframe pointer event blocking
                ? _editModePlaceholder(camera?.name ?? 'CAM ${index + 1}')
                // NORMAL MODE: Show live video stream
                : hasCam
                    ? FutureBuilder<String?>(
                        key: ValueKey(camera!.id), // Force rebuild on camera change
                        future: hlsFuture,
                        builder: (context, snap) {
                          if (snap.connectionState == ConnectionState.waiting) {
                            return _loading();
                          }
                          final hls = snap.data;
                          if (hls == null || hls.isEmpty) {
                            // No stream available (either error or no RTSP URL configured)
                            return _error('No stream');
                          }
                          return HlsPlayer(
                            key: ValueKey('${camera!.id}_$hls'), // Unique key for player
                            hlsUrl: hls,
                          );
                        },
                      )
                    : _noStream(index, null),
          ),
          // Camera name label
          Positioned(
            left: 4,
            top: 4,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  hasCam ? camera!.name : 'CAM ${index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _loading() => Container(
        color: Colors.black,
        alignment: Alignment.center,
        child: const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
        ),
      );

  Widget _error(String msg) => Container(
        color: Colors.black,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.redAccent,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              'STREAM UNAVAILABLE',
              style: const TextStyle(
                color: Colors.redAccent,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );

  Widget _noStream(int index, String? cameraName) => Container(
        color: Colors.black,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.video_camera_back_outlined,
              color: Colors.white24,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              'EMPTY SLOT ${index + 1}',
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );

  Widget _editModePlaceholder(String cameraName) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.grey[900]!,
              Colors.grey[800]!,
            ],
          ),
        ),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pause_circle_outline,
              color: Colors.white.withOpacity(0.6),
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              cameraName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Stream paused in edit mode',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 9,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );

  Widget _dragPlaceholder(String cameraName) => Container(
        color: Colors.black87,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.videocam,
              color: Colors.white54,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              cameraName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              'PAUSED',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 9,
              ),
            ),
          ],
        ),
      );
}

class CommandWidget extends StatefulWidget {
  const CommandWidget({
    Key? key,
    this.width,
    this.height,
  }) : super(key: key);

  final double? width;
  final double? height;

  @override
  State<CommandWidget> createState() => _CommandWidgetState();
}

class _CommandWidgetState extends State<CommandWidget> {
  int gridSize = 2; // เริ่มที่ 2x2

  // cache: docId -> Future<HLS url>
  final Map<String, Future<String?>> _hlsCache = {};
  List<CameraInfo> _cameras = [];
  List<dynamic> _categories = [];
  bool _isLoading = true;
  bool _isLoadingCategories = true;
  String? _errorMessage; // Add error message state
  
  // Category filtering
  String? _selectedCategoryId; // null = "All Cameras"
  
  // Layout editing
  bool _isEditMode = false;
  Map<int, String> _gridPositions = {}; // position -> cameraId
  int? _selectedTileIndex; // Track selected tile for swapping (null = none selected)
  int _rebuildKey = 0; // Force rebuild after position changes
  
  @override
  void initState() {
    super.initState();
    print('🚀 CommandWidget initialized');
    print('API Base URL: $kApiBaseUrl');
    _fetchCategories();
    _fetchCameras();
    _loadGridLayout();
  }

  Future<void> _fetchCategories() async {
    try {
      print('🔄 Fetching categories from API...');
      print('API URL: http://se-lab.aboutblank.in.th/api/category');
      final response = await CategoryService().getCategories();
      print('📡 Category Response Status: ${response.statusCode}');
      print('📡 Category Response Body Type: ${response.jsonBody.runtimeType}');
      print('📡 Category Response Body: ${response.jsonBody}');
      
      if (response.succeeded) {
        final List<dynamic> jsonList = response.jsonBody is List
            ? response.jsonBody
            : (response.jsonBody['data'] as List? ?? []);
        print('✅ Categories loaded: ${jsonList.length} items');
        print('Categories: $jsonList');
        setState(() {
          _categories = jsonList;
          _isLoadingCategories = false;
        });
      } else {
        print('❌ Failed to load categories');
        print('Status Code: ${response.statusCode}');
        print('Headers: ${response.headers}');
        print('Body: ${response.jsonBody}');
        print('Exception: ${response.exception}');
        setState(() => _isLoadingCategories = false);
      }
    } catch (e, stackTrace) {
      print('❌ Error fetching categories: $e');
      print('Stack trace: $stackTrace');
      setState(() => _isLoadingCategories = false);
    }
  }

  Future<void> _fetchCameras() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final categoryFilter = _selectedCategoryId ?? "All";
      print('🔄 Fetching cameras... (Category: $categoryFilter)');
      
      final response = _selectedCategoryId == null
          ? await CameraService().getCameras(limit: '100')
          : await CameraService().getCamerasByCategoryId(_selectedCategoryId!);
      
      print('📡 Camera Response Status: ${response.statusCode}');
      print('📡 Camera Response Succeeded: ${response.succeeded}');
      
      if (response.succeeded) {
        final List<dynamic> jsonList = response.jsonBody is List
            ? response.jsonBody
            : (response.jsonBody['data'] as List? ?? []);
        print('✅ Cameras loaded: ${jsonList.length} items');
        
        setState(() {
          _cameras = jsonList
              .map((e) => CameraInfo.fromJson(e as Map<String, dynamic>))
              .toList();
          _isLoading = false;
          _errorMessage = jsonList.isEmpty ? 'No cameras found' : null;
        });
        
        print('✅ Parsed ${_cameras.length} cameras');
        print('📺 Streams will be started using camera IDs (backend fetches RTSP)');
        
      } else {
        final errorMsg = 'API Error: ${response.statusCode}';
        print('❌ Failed to load cameras: ${response.statusCode}');
        setState(() {
          _isLoading = false;
          _errorMessage = errorMsg;
        });
      }
    } catch (e, stackTrace) {
      final errorMsg = 'Error: ${e.toString()}';
      print('❌ Error fetching cameras: $e');
      print('Stack trace: $stackTrace');
      setState(() {
        _isLoading = false;
        _errorMessage = errorMsg;
      });
    }
  }
  
  Future<void> _loadGridLayout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLayout = prefs.getString('command_grid_layout');
      if (savedLayout != null) {
        final Map<String, dynamic> layoutMap = jsonDecode(savedLayout);
        setState(() {
          _gridPositions = layoutMap.map(
            (key, value) => MapEntry(int.parse(key), value.toString()),
          );
        });
      }
    } catch (e) {
      // Ignore errors in loading saved layout
    }
  }
  
  Future<void> _saveGridLayout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final layoutMap = _gridPositions.map(
        (key, value) => MapEntry(key.toString(), value),
      );
      await prefs.setString('command_grid_layout', jsonEncode(layoutMap));
    } catch (e) {
      // Ignore errors in saving layout
    }
  }

  void _cycleLayout() {
    setState(() {
      if (gridSize == 2) {
        gridSize = 3;
      } else if (gridSize == 3) {
        gridSize = 4;
      } else {
        gridSize = 2;
      }
    });
  }

  String _getCategoryName(String categoryId) {
    try {
      final category = _categories.firstWhere(
        (cat) => cat['id']?.toString() == categoryId,
        orElse: () => {'name': 'Unknown'},
      );
      final name = category['name']?.toString() ?? 'Unknown';
      return name.length > 9 ? '${name.substring(0, 9)}...' : name;
    } catch (e) {
      return 'Unknown';
    }
  }

  /// เริ่ม HLS ถ้ายังไม่เคยเริ่ม หรือ RTSP เปลี่ยน
  Future<String?> _ensureHls(CameraInfo cam) {
    // ถ้าเคยยิงแล้ว และ future ยังอยู่ ใช้ซ้ำ
    final cached = _hlsCache[cam.id];
    if (cached != null) return cached;

    final fut = _startHls(cam);
    _hlsCache[cam.id] = fut;
    return fut;
  }

  /// Start HLS stream using camera ID
  /// POST { cameraId }
  /// Backend fetches RTSP URL from database automatically
  /// Response: { "hlsUrl": "..." }
  Future<String?> _startHls(CameraInfo cam) async {
    final uri = Uri.parse('$kApiBaseUrl/api/stream/hls/start');
    try {
      print('🎬 Starting stream for camera: ${cam.name} (ID: ${cam.id})');
      
      final resp = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'cameraId': cam.id, // Backend will fetch RTSP URL from database
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final obj = jsonDecode(resp.body);
        
        // Extract hlsUrl from response
        String? hlsUrl;
        if (obj is Map) {
          hlsUrl = obj['hlsUrl'] as String?;
        }

        if (hlsUrl == null || hlsUrl.isEmpty) {
          print('⚠️ No HLS URL in response for ${cam.name}');
          return null;
        }

        // Ensure URL is absolute
        String finalUrl = hlsUrl;
        if (!hlsUrl.startsWith('http')) {
          finalUrl = '$kApiBaseUrl$hlsUrl';
          print('🔗 Converted relative to absolute URL: $finalUrl');
        }

        print('✅ Stream started successfully for ${cam.name}');
        print('📺 HLS URL: $finalUrl');
        return finalUrl;
      } else if (resp.statusCode == 400) {
        // Handle 400 errors (camera not found or no RTSP URL configured)
        try {
          final errorObj = jsonDecode(resp.body);
          final errorMsg = errorObj['error'] ?? resp.body;
          
          if (errorMsg.toString().contains('No RTSP URL configured')) {
            print('⚠️ ${cam.name}: No RTSP URL configured in database');
            return null; // Gracefully return null instead of throwing
          }
          
          print('❌ ${cam.name}: $errorMsg');
          return null;
        } catch (_) {
          print('❌ ${cam.name}: ${resp.body}');
          return null;
        }
      } else {
        // Other HTTP errors
        print('❌ Failed to start stream for ${cam.name}: HTTP ${resp.statusCode}');
        print('Error: ${resp.body}');
        return null;
      }
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        print('⏱️ Stream start timeout for ${cam.name}');
      } else {
        print('❌ Exception starting stream for ${cam.name}: $e');
      }
      // Remove from cache to allow retry
      _hlsCache.remove(cam.id);
      return null; // Return null instead of rethrowing
    }
  }
  
  /// Build a clickable video tile for edit mode (click-to-select swap)
  Widget _buildClickableVideoTile({
    required int index,
    required CameraInfo? camera,
    required Future<String?>? hlsFuture,
  }) {
    final isSelected = _selectedTileIndex == index;
    
    return MouseRegion(
      cursor: _isEditMode ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected 
                ? Colors.orange // Selected tile = orange border
                : (_isEditMode ? Colors.blue.withOpacity(0.5) : Colors.white24),
            width: isSelected ? 3 : 1,
          ),
          borderRadius: BorderRadius.circular(6),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.6),
                    blurRadius: 12,
                    spreadRadius: 3,
                  ),
                ]
              : null,
        ),
        child: Stack(
          children: [
            // Video tile
            _VideoTile(
              index: index,
              camera: camera,
              hlsFuture: hlsFuture,
              isEditMode: _isEditMode,
              isSelected: isSelected,
            ),
            
            // Edit mode overlay with selection indicator
            if (_isEditMode)
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.orange.withOpacity(0.2)
                          : Colors.blue.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: isSelected
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: Colors.orange,
                                  size: 48,
                                  shadows: [
                                    Shadow(color: Colors.black, blurRadius: 4),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.orange,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'SELECTED - Click another to swap',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Icon(
                              Icons.touch_app,
                              color: Colors.white.withOpacity(0.3),
                              size: 32,
                            ),
                    ),
                  ),
                ),
              ),
            
            // Position number indicator in edit mode
            if (_isEditMode)
              Positioned(
                top: 4,
                left: 4,
                child: IgnorePointer(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.orange : Colors.blue.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            
            // CRITICAL: Transparent clickable overlay ON TOP in edit mode
            // This captures clicks ABOVE the video iframe
            if (_isEditMode)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque, // Capture all taps
                  onTap: () {
                    if (_selectedTileIndex == null) {
                      // First click: select this tile
                      setState(() => _selectedTileIndex = index);
                      print('✅ Selected tile $index for swapping');
                    } else if (_selectedTileIndex == index) {
                      // Click same tile: deselect
                      setState(() => _selectedTileIndex = null);
                      print('❌ Deselected tile $index');
                    } else {
                      // Second click: swap positions
                      final fromIndex = _selectedTileIndex!;
                      final toIndex = index;
                      
                      setState(() {
                        // Get actual camera IDs at both positions
                        final fromCameraId = _gridPositions.containsKey(fromIndex)
                            ? _gridPositions[fromIndex]
                            : (fromIndex < _cameras.length ? _cameras[fromIndex].id : null);
                            
                        final toCameraId = _gridPositions.containsKey(toIndex)
                            ? _gridPositions[toIndex]
                            : (toIndex < _cameras.length ? _cameras[toIndex].id : null);
                        
                        print('🔄 Swapping: Position $fromIndex ($fromCameraId) <-> Position $toIndex ($toCameraId)');
                        
                        // Perform the swap
                        if (fromCameraId != null) {
                          _gridPositions[toIndex] = fromCameraId;
                        } else {
                          _gridPositions.remove(toIndex);
                        }
                        
                        if (toCameraId != null) {
                          _gridPositions[fromIndex] = toCameraId;
                        } else {
                          _gridPositions.remove(fromIndex);
                        }
                        
                        print('📍 New grid positions: $_gridPositions');
                        
                        // Clear selection and force rebuild
                        _selectedTileIndex = null;
                        _rebuildKey++;
                      });
                    }
                  },
                  child: Container(
                    color: Colors.transparent, // Transparent but still catches events
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalTiles = gridSize * gridSize;

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Container(
        color: Colors.black,
        child: SafeArea(
          child: Stack(
            children: [
              // พื้นที่กริดกล้อง (เต็มหน้าจอ)
              Builder(
                builder: (context) {
                  if (_isLoading) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    );
                  }

                  if (_errorMessage != null) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.redAccent,
                            size: 64,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () {
                              _fetchCameras();
                              _fetchCategories();
                            },
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final cams = _cameras;
                  print('🎨 Building grid with ${cams.length} cameras');

                  if (cams.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.videocam_off,
                            color: Colors.white54,
                            size: 64,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No cameras available',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Check your API connection',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () {
                              _fetchCameras();
                              _fetchCategories();
                            },
                            icon: const Icon(Icons.refresh),
                            label: const Text('Refresh'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // Streams are started on-demand when cameras are displayed in the grid
                  // This avoids unnecessary 400 errors for cameras without RTSP URLs

                  return GridView.builder(
                    padding: const EdgeInsets.all(4.0),
                    itemCount: totalTiles,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: gridSize,
                      crossAxisSpacing: 4,
                      mainAxisSpacing: 4,
                      childAspectRatio: 16 / 9,
                    ),
                    itemBuilder: (context, index) {
                      // Get camera for this position
                      CameraInfo? cam;
                      Future<String?>? fut;
                      
                      if (_isEditMode && _gridPositions.containsKey(index)) {
                        // In edit mode with saved position
                        final cameraId = _gridPositions[index];
                        cam = cams.firstWhere(
                          (c) => c.id == cameraId,
                          orElse: () => CameraInfo(id: '', name: '', rtspUrl: ''),
                        );
                        if (cam.id.isNotEmpty) {
                          fut = _ensureHls(cam);
                        } else {
                          cam = null;
                        }
                      } else if (!_isEditMode && _gridPositions.containsKey(index)) {
                        // Normal mode with saved position
                        final cameraId = _gridPositions[index];
                        cam = cams.firstWhere(
                          (c) => c.id == cameraId,
                          orElse: () => CameraInfo(id: '', name: '', rtspUrl: ''),
                        );
                        if (cam.id.isNotEmpty) {
                          fut = _ensureHls(cam);
                        } else {
                          cam = null;
                        }
                      } else if (index < cams.length) {
                        // Fill with cameras in order
                        cam = cams[index];
                        fut = _ensureHls(cam);
                      }

                      if (_isEditMode) {
                        return _buildClickableVideoTile(
                          index: index,
                          camera: cam,
                          hlsFuture: fut,
                        );
                      } else {
                        return _VideoTile(
                          key: cam != null ? ValueKey('tile_${cam.id}') : ValueKey('empty_$index'),
                          index: index,
                          camera: cam,
                          hlsFuture: fut,
                          isEditMode: false,
                        );
                      }
                    },
                  );
                },
              ),

              // Floating controls (compact) - ALWAYS ON TOP
              Positioned(
                top: 8,
                left: 8,
                right: 8,
                child: IgnorePointer(
                  ignoring: false, // This widget and children receive pointer events
                  child: Material(
                    elevation: 10, // High elevation to ensure visual priority
                    color: Colors.transparent,
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Left side: Grid size and Edit buttons
                          Row(
                            children: [
                            // Grid size toggle
                            _buildFloatingButton(
                            onTap: _cycleLayout,
                            icon: Icons.grid_view_rounded,
                            label: '${gridSize}x$gridSize',
                          ),
                          const SizedBox(width: 6),
                          
                          // Edit layout button
                          _buildFloatingButton(
                            onTap: () {
                              setState(() {
                                _isEditMode = !_isEditMode;
                                if (!_isEditMode) {
                                  _saveGridLayout();
                                  _selectedTileIndex = null; // Clear selection when exiting edit mode
                                } else {
                                  _selectedTileIndex = null; // Clear selection when entering edit mode
                                }
                              });
                            },
                            icon: _isEditMode ? Icons.check : Icons.edit,
                            label: _isEditMode ? 'Done' : 'Edit',
                            isActive: _isEditMode,
                          ),
                        ],
                      ),
                    
                    // Right side: Category filter (compact)
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: _isLoadingCategories
                        ? Container(
                            height: 32,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.85),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white24, width: 1),
                            ),
                            child: const Center(
                              child: SizedBox(
                                width: 10,
                                height: 10,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.5,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          )
                        : PopupMenuButton<String?>(
                            key: ValueKey(_selectedCategoryId),
                            offset: const Offset(0, 38),
                            color: Colors.black.withOpacity(0.95),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: const BorderSide(color: Colors.white24, width: 1),
                            ),
                            child: Container(
                              constraints: const BoxConstraints(minHeight: 32),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.85),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.white24, width: 1),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.filter_list_rounded,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 6),
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _selectedCategoryId == null
                                            ? 'No Filter'
                                            : _getCategoryName(_selectedCategoryId!),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          height: 1.1,
                                        ),
                                      ),
                                      const SizedBox(height: 1),
                                      Text(
                                        () {
                                          final maxSlots = gridSize * gridSize;
                                          final total = _cameras.length;
                                          final showing = total > maxSlots ? maxSlots : total;
                                          return total > maxSlots 
                                            ? '$showing/$total cams'
                                            : '$showing cam${showing == 1 ? '' : 's'}';
                                        }(),
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.6),
                                          fontSize: 9,
                                          fontWeight: FontWeight.w500,
                                          height: 1.0,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                            itemBuilder: (context) => [
                              PopupMenuItem<String?>(
                                value: null,
                                enabled: true,
                                onTap: () {
                                  // Explicitly handle null selection
                                  Future.microtask(() {
                                    print('📂 No Filter tapped directly');
                                    if (_selectedCategoryId != null) {
                                      setState(() {
                                        _selectedCategoryId = null;
                                      });
                                      _fetchCameras();
                                    }
                                  });
                                },
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.grid_view_rounded,
                                      color: _selectedCategoryId == null
                                          ? Colors.blue
                                          : Colors.white70,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'No Filter',
                                            style: TextStyle(
                                              color: _selectedCategoryId == null
                                                  ? Colors.blue
                                                  : Colors.white,
                                              fontSize: 13,
                                              fontWeight: _selectedCategoryId == null
                                                  ? FontWeight.w600
                                                  : FontWeight.normal,
                                            ),
                                          ),
                                          Text(
                                            'Show all cameras',
                                            style: TextStyle(
                                              color: _selectedCategoryId == null
                                                  ? Colors.blue.withOpacity(0.7)
                                                  : Colors.white54,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (_selectedCategoryId == null)
                                      const Icon(
                                        Icons.check_rounded,
                                        color: Colors.blue,
                                        size: 16,
                                      ),
                                  ],
                                ),
                              ),
                              if (_categories.isNotEmpty) ...[
                                const PopupMenuDivider(height: 1),
                                ..._categories.map((category) {
                                  final id = category['id']?.toString();
                                  final name = category['name']?.toString() ?? 'Unknown';
                                  final isSelected = _selectedCategoryId == id;
                                  return PopupMenuItem<String?>(
                                    value: id,
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.folder_rounded,
                                          color: isSelected ? Colors.blue : Colors.white70,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            name,
                                            style: TextStyle(
                                              color: isSelected ? Colors.blue : Colors.white,
                                              fontSize: 13,
                                              fontWeight: isSelected
                                                  ? FontWeight.w600
                                                  : FontWeight.normal,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (isSelected)
                                          const Icon(
                                            Icons.check_rounded,
                                            color: Colors.blue,
                                            size: 16,
                                          ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ],
                            onSelected: (value) {
                              print('📂 Category filter selected: ${value ?? "No Filter (null)"}');
                              print('📂 Previous filter was: ${_selectedCategoryId ?? "No Filter (null)"}');
                              if (_selectedCategoryId != value) {
                                setState(() {
                                  _selectedCategoryId = value;
                                });
                                print('✅ Filter changed, fetching cameras...');
                                _fetchCameras();
                              } else {
                                print('ℹ️ Same filter selected, no action needed');
                              }
                            },
                          ),
                    ), // End MouseRegion
                    ],
                  ), // End Row (Material child)
                ), // End Material
            ), // End IgnorePointer
          ), // End Positioned

              // Edit mode instruction banner (compact)
              if (_isEditMode)
                Positioned(
                  bottom: 12,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.touch_app, color: Colors.white, size: 14),
                          SizedBox(width: 6),
                          Text(
                            'Drag to rearrange',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingButton({
    required VoidCallback onTap,
    required IconData icon,
    required String label,
    bool isActive = false,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isActive 
              ? Colors.blue.withOpacity(0.95)
              : Colors.black.withOpacity(0.85),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isActive ? Colors.blue : Colors.white24,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: 14,
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

