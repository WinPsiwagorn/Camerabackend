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
    return CameraInfo(
      id: docId ?? data['id']?.toString() ?? '',
      name: (data['name'] as String?)?.trim().isNotEmpty == true
          ? (data['name'] as String)
          : 'Camera',
      rtspUrl: (data['url'] as String? ?? data['URL'] as String? ?? '').trim(),
    );
  }
}

class _VideoTile extends StatelessWidget {
  final int index;
  final CameraInfo? camera;
  final Future<String?>? hlsFuture; // <-- เพิ่ม future ของ HLS URL

  const _VideoTile({
    Key? key,
    required this.index,
    required this.camera,
    required this.hlsFuture,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final hasCam = camera != null && camera!.rtspUrl.isNotEmpty;

    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Stack(
        children: [
          Positioned.fill(
            child: hasCam
                ? FutureBuilder<String?>(
                    future: hlsFuture,
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return _loading();
                      }
                      if (snap.hasError) {
                        return _error(snap.error.toString());
                      }
                      final hls = snap.data;
                      if (hls == null || hls.isEmpty) {
                        return _error('Start HLS failed');
                      }
                      return HlsPlayer(hlsUrl: hls);
                    },
                  )
                : _noStream(index),
          ),
          Positioned(
            left: 4,
            top: 4,
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
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white10, width: 1),
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
        child: Text(
          'ERROR\n$msg',
          style: const TextStyle(color: Colors.redAccent, fontSize: 12),
          textAlign: TextAlign.center,
        ),
      );

  Widget _noStream(int index) => Container(
        color: Colors.black,
        alignment: Alignment.center,
        child: Text(
          'NO STREAM ${index + 1}',
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
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
  
  // Category filtering
  String? _selectedCategoryId; // null = "All Cameras"
  
  // Layout editing
  bool _isEditMode = false;
  Map<int, String> _gridPositions = {}; // position -> cameraId
  
  @override
  void initState() {
    super.initState();
    _fetchCategories();
    _fetchCameras();
    _loadGridLayout();
  }

  Future<void> _fetchCategories() async {
    try {
      final response = await CategoryService().getCategories();
      if (response.succeeded) {
        final List<dynamic> jsonList = response.jsonBody is List
            ? response.jsonBody
            : (response.jsonBody['data'] as List? ?? []);
        setState(() {
          _categories = jsonList;
          _isLoadingCategories = false;
        });
      } else {
        setState(() => _isLoadingCategories = false);
      }
    } catch (e) {
      setState(() => _isLoadingCategories = false);
    }
  }

  Future<void> _fetchCameras() async {
    setState(() => _isLoading = true);
    try {
      final response = _selectedCategoryId == null
          ? await CameraService().getCameras(limit: '1000')  // Fetch up to 1000 cameras
          : await CameraService().getCamerasByCategoryId(_selectedCategoryId!);
      
      if (response.succeeded) {
        final List<dynamic> jsonList = response.jsonBody is List
            ? response.jsonBody
            : (response.jsonBody['data'] as List? ?? []);
        setState(() {
          _cameras = jsonList
              .map((e) => CameraInfo.fromJson(e as Map<String, dynamic>))
              .toList();
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
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

  /// ยิง POST ไปเริ่ม HLS:
  /// POST { rtspUrl, streamName }
  /// response: {"message": "/api/hls/<stream>/stream.m3u8"} หรือ String เดี่ยว
  Future<String?> _startHls(CameraInfo cam) async {
    if (cam.rtspUrl.isEmpty) return null;

    final uri = Uri.parse('$kApiBaseUrl/api/stream/hls/start');
    try {
      final resp = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'rtspUrl': cam.rtspUrl,
              'streamName': cam.id, // ใช้ docId เป็นชื่อ stream
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        // พยายาม parse เป็น JSON ก่อน
        String? path;
        try {
          final obj = jsonDecode(resp.body);
          if (obj is Map && obj['message'] is String) {
            path = obj['message'] as String;
          }
        } catch (_) {
          // ถ้าไม่ใช่ JSON อาจเป็น string ตรง ๆ
          final body = resp.body.trim();
          if (body.startsWith('/')) path = body;
        }

        if (path == null || path.isEmpty) {
          throw Exception('Invalid response: ${resp.body}');
        }

        // ต่อให้เป็น HLS เต็ม URL
        final hlsUrl = path.startsWith('http')
            ? path
            : '$kApiBaseUrl$path'; // ประกอบ base + path

        return hlsUrl;
      } else {
        throw Exception('HTTP ${resp.statusCode}: ${resp.body}');
      }
    } catch (e) {
      // ถ้าล้มเหลว ให้ลบ cache เพื่อให้กด refresh แล้วลองใหม่ได้
      _hlsCache.remove(cam.id);
      rethrow;
    }
  }
  
  /// Build a draggable video tile for edit mode
  Widget _buildDraggableVideoTile({
    required int index,
    required CameraInfo? camera,
    required Future<String?>? hlsFuture,
  }) {
    return DragTarget<_DragData>(
      onAcceptWithDetails: (details) {
        setState(() {
          final fromIndex = details.data.fromIndex;
          final fromCameraId = details.data.cameraId;
          
          // Swap positions
          final toCameraId = _gridPositions[index];
          
          if (fromCameraId != null) {
            _gridPositions[index] = fromCameraId;
          } else {
            _gridPositions.remove(index);
          }
          
          if (toCameraId != null) {
            _gridPositions[fromIndex] = toCameraId;
          } else {
            _gridPositions.remove(fromIndex);
          }
        });
      },
      builder: (context, candidateData, rejectedData) {
        final isHovered = candidateData.isNotEmpty;
        
        return LongPressDraggable<_DragData>(
          data: _DragData(
            fromIndex: index,
            cameraId: camera?.id,
          ),
          hapticFeedbackOnStart: false,
          feedback: Material(
            color: Colors.transparent,
            child: Transform.scale(
              scale: 1.1,
              child: Container(
                width: 250,
                height: 140,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.5),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.blue, width: 3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: _VideoTile(
                          index: index,
                          camera: camera,
                          hlsFuture: hlsFuture,
                        ),
                      ),
                    ),
                    // Dragging indicator overlay
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue, width: 3),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.open_with,
                            color: Colors.white,
                            size: 48,
                            shadows: [
                              Shadow(
                                color: Colors.black,
                                blurRadius: 4,
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
          ),
          childWhenDragging: Container(
            decoration: BoxDecoration(
              color: Colors.black45,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.blue.withOpacity(0.5), width: 2),
            ),
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.swap_horiz,
                        color: Colors.blue.withOpacity(0.7),
                        size: 32,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Moving...',
                        style: TextStyle(
                          color: Colors.blue.withOpacity(0.7),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: isHovered ? Colors.green : (_isEditMode ? Colors.blue.withOpacity(0.5) : Colors.white24),
                width: isHovered ? 3 : 1,
              ),
              borderRadius: BorderRadius.circular(6),
              boxShadow: isHovered
                  ? [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.5),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: Stack(
              children: [
                _VideoTile(
                  index: index,
                  camera: camera,
                  hlsFuture: hlsFuture,
                ),
                // Edit mode indicator icon
                if (_isEditMode && !isHovered)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(
                        Icons.drag_indicator,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ),
                // Drop target indicator
                if (isHovered)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.swap_calls,
                          color: Colors.white,
                          size: 32,
                          shadows: [
                            Shadow(
                              color: Colors.black,
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
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

                  final cams = _cameras;

                  // ถ้า RTSP ของ doc ไหนเปลี่ยน -> รื้อ cache อันนั้น เพื่อยิงใหม่
                  // (ตรงนี้ทำง่าย ๆ เวลา build)
                  for (final cam in cams) {
                    final cached = _hlsCache[cam.id];
                    // ถ้าอยาก detect การเปลี่ยนจริง ๆ ให้ cache rtsp ล่าสุดด้วย
                    // ที่นี่เอาแบบง่าย: ถ้าไม่มี future ค่อยสร้าง
                    if (cached == null && cam.rtspUrl.isNotEmpty) {
                      _hlsCache[cam.id] = _startHls(cam);
                    }
                  }

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
                          fut = (cam.rtspUrl.isNotEmpty) ? _ensureHls(cam) : null;
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
                          fut = (cam.rtspUrl.isNotEmpty) ? _ensureHls(cam) : null;
                        } else {
                          cam = null;
                        }
                      } else if (index < cams.length) {
                        // Fill with cameras in order
                        cam = cams[index];
                        fut = (cam.rtspUrl.isNotEmpty) ? _ensureHls(cam) : null;
                      }

                      if (_isEditMode) {
                        return _buildDraggableVideoTile(
                          index: index,
                          camera: cam,
                          hlsFuture: fut,
                        );
                      } else {
                        return _VideoTile(
                          index: index,
                          camera: cam,
                          hlsFuture: fut,
                        );
                      }
                    },
                  );
                },
              ),

              // Floating controls
              Positioned(
                top: 12,
                left: 12,
                right: 12,
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
                        const SizedBox(width: 8),
                        
                        // Edit layout button
                        _buildFloatingButton(
                          onTap: () {
                            setState(() {
                              _isEditMode = !_isEditMode;
                              if (!_isEditMode) {
                                _saveGridLayout();
                              }
                            });
                          },
                          icon: _isEditMode ? Icons.save : Icons.edit,
                          label: _isEditMode ? 'Save' : 'Edit',
                          isActive: _isEditMode,
                        ),
                      ],
                    ),
                    
                    // Right side: Category filter
                    _isLoadingCategories
                        ? Container(
                            height: 36,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white24, width: 1),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          )
                        : PopupMenuButton<String?>(
                            offset: const Offset(0, 45),
                            color: Colors.black.withOpacity(0.95),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(color: Colors.white24, width: 1),
                            ),
                            child: Container(
                              constraints: const BoxConstraints(minHeight: 36),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white24, width: 1),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.filter_list_rounded,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
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
                                          fontSize: 11,
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
                                            'Show first ${gridSize * gridSize} cameras',
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
                              setState(() {
                                _selectedCategoryId = value;
                              });
                              _fetchCameras();
                            },
                          ),
                  ],
                ),
              ),

              // Edit mode instruction banner
              if (_isEditMode)
                Positioned(
                  bottom: 20,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.touch_app, color: Colors.white, size: 16),
                          SizedBox(width: 8),
                          Text(
                            'Long press and drag to rearrange',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive 
            ? Colors.blue.withOpacity(0.9)
            : Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? Colors.blue : Colors.white24,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Data class for drag and drop operations
class _DragData {
  final int fromIndex;
  final String? cameraId;

  _DragData({
    required this.fromIndex,
    this.cameraId,
  });
}
