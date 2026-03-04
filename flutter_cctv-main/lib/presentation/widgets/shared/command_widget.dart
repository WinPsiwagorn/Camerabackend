// Automatic FlutterFlow imports
import '/utils/flutter_flow/theme.dart';
import '/utils/flutter_flow/util.dart';
import '../index.dart'; // Imports other custom widgets
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'dart:async';
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

/// Carries the HLS URL (null = failed) together with a human-readable error
/// reason so the tile can display exactly what went wrong.
class _HlsResult {
  final String? url;
  final String? error;
  _HlsResult({this.url, this.error});
}

// ─── TODO [2]: Informative HLS loading tile ─────────────────────────────────
class _StreamLoadingTile extends StatefulWidget {
  final String cameraName;
  const _StreamLoadingTile({Key? key, required this.cameraName})
      : super(key: key);
  @override
  State<_StreamLoadingTile> createState() => _StreamLoadingTileState();
}

class _StreamLoadingTileState extends State<_StreamLoadingTile> {
  Timer? _timer;
  bool _isSlow = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 10), () {
      if (mounted) setState(() => _isSlow = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            widget.cameraName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          const LinearProgressIndicator(
            color: Colors.white54,
            backgroundColor: Colors.white12,
          ),
          const SizedBox(height: 6),
          Text(
            _isSlow ? 'Taking longer than usual…' : 'Starting stream…',
            style: TextStyle(
              color: Colors.white.withOpacity(0.55),
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── TODO [3]: Pulsing accident overlay widget ────────────────────────────────
class _AccidentOverlay extends StatefulWidget {
  final String? timestamp;
  const _AccidentOverlay({Key? key, this.timestamp}) : super(key: key);
  @override
  State<_AccidentOverlay> createState() => _AccidentOverlayState();
}

class _AccidentOverlayState extends State<_AccidentOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 1.0, end: 0.25).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatTs(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    final local = dt.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}:'
        '${local.second.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacity,
      builder: (context, _) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: Colors.red.withOpacity(_opacity.value),
              width: 3,
            ),
            color: Colors.red.withOpacity(0.07 * _opacity.value),
          ),
          child: Stack(
            children: [
              // Warning badge — top-right corner
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.88),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          color: Colors.white, size: 10),
                      const SizedBox(width: 3),
                      Text(
                        'ACCIDENT  ${_formatTs(widget.timestamp)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _VideoTile extends StatefulWidget {
  final int index;
  final CameraInfo? camera;
  final Future<_HlsResult>? hlsFuture;
  final bool isEditMode;
  final bool isSelected;

  const _VideoTile({
    Key? key,
    required this.index,
    required this.camera,
    required this.hlsFuture,
    this.isEditMode = false,
    this.isSelected = false,
  }) : super(key: key);

  @override
  State<_VideoTile> createState() => _VideoTileState();
}

class _VideoTileState extends State<_VideoTile> {
  /// While this is false the tile keeps showing the loading spinner even after
  /// the HLS future resolved to null, giving the stream a grace period to be
  /// ready before we declare it unavailable.
  bool _gracePeriodDone = false;
  Timer? _graceTimer;

  @override
  void dispose() {
    _graceTimer?.cancel();
    super.dispose();
  }

  void _startGrace() {
    if (_graceTimer != null) return;
    _graceTimer = Timer(const Duration(seconds: 6), () {
      if (mounted) setState(() => _gracePeriodDone = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasCam = widget.camera != null;

    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Stack(
        children: [
          Positioned.fill(
            child: widget.isEditMode
                ? _editModePlaceholder(widget.camera?.name ?? 'CAM ${widget.index + 1}')
                : hasCam
                    ? FutureBuilder<_HlsResult>(
                        // Use normalized key (id || name) so cameras with
                        // empty id don't all share the same ValueKey('').
                        key: ValueKey(widget.camera!.id.isNotEmpty
                            ? widget.camera!.id
                            : widget.camera!.name),
                        future: widget.hlsFuture,
                        builder: (context, snap) {
                          if (snap.connectionState == ConnectionState.waiting) {
                            return _StreamLoadingTile(cameraName: widget.camera!.name);
                          }
                          final result = snap.data;
                          final hls = result?.url;
                          if (hls == null || hls.isEmpty) {
                            // Honour grace period before declaring failure
                            _startGrace();
                            if (!_gracePeriodDone) {
                              return _StreamLoadingTile(cameraName: widget.camera!.name);
                            }
                            return _errorTile(result?.error ?? 'Stream unavailable');
                          }
                          return HlsPlayer(
                            key: ValueKey(
                              '${widget.camera!.id.isNotEmpty ? widget.camera!.id : widget.camera!.name}_$hls',
                            ),
                            hlsUrl: hls,
                          );
                        },
                      )
                    : _noStream(widget.index),
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
                  hasCam ? widget.camera!.name : 'CAM ${widget.index + 1}',
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

  Widget _errorTile(String reason) {
    // Classify the reason into an icon + colour for quick visual scanning
    IconData icon;
    Color accent;
    if (reason.contains('timed out') || reason.contains('unreachable')) {
      icon = Icons.wifi_off_rounded;
      accent = Colors.orange;
    } else if (reason.contains('No RTSP') || reason.contains('not configured')) {
      icon = Icons.videocam_off_rounded;
      accent = Colors.grey;
    } else if (reason.contains('400') || reason.contains('Bad request')) {
      icon = Icons.error_outline_rounded;
      accent = Colors.amber;
    } else {
      icon = Icons.signal_wifi_statusbar_connected_no_internet_4_rounded;
      accent = Colors.redAccent;
    }

    return Container(
      color: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: accent, size: 26),
          const SizedBox(height: 6),
          Text(
            'Stream Unavailable',
            style: TextStyle(
              color: accent,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              reason,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 9,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _noStream(int index) => Container(
        color: Colors.black,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.video_camera_back_outlined, color: Colors.white24, size: 32),
            const SizedBox(height: 8),
            Text(
              'EMPTY SLOT ${index + 1}',
              style: const TextStyle(color: Colors.white54, fontSize: 10),
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
            colors: [Colors.grey[900]!, Colors.grey[800]!],
          ),
        ),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pause_circle_outline,
                color: Colors.white.withOpacity(0.6), size: 48),
            const SizedBox(height: 12),
            Text(
              cameraName,
              style: const TextStyle(
                  color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
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
                style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 9),
                textAlign: TextAlign.center,
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

  // cache: docId -> Future<_HlsResult (url + error reason)>
  final Map<String, Future<_HlsResult>> _hlsCache = {};
  List<CameraInfo> _cameras = [];
  List<dynamic> _categories = [];
  bool _isLoading = true;
  bool _isLoadingCategories = true;
  String? _errorMessage;

  // Monotonically increasing token — every time _fetchCameras starts we
  // snapshot the token; if it changed by the time the response arrives we
  // know a newer request already won and we discard the stale result.
  int _fetchSeq = 0;
  
  // Category filtering
  String? _selectedCategoryId; // null = "All Cameras"
  
  // Layout editing
  bool _isEditMode = false;
  Map<int, String> _gridPositions = {}; // position -> cameraId (normalized: id || name)
  int? _selectedTileIndex; // Track selected tile for swapping (null = none selected)
  // Cached slot array from the last build — lets click handlers look up the
  // real CameraInfo at each grid position without re-running slot assignment.
  List<CameraInfo?> _currentSlots = [];

  // ─── TODO [3]: Accident alert state ─────────────────────────────────────────
  Map<String, Map<String, dynamic>> _latestAccidents = {}; // cameraId → accident
  Timer? _accidentPollTimer;

  // Focus / full-screen stream
  CameraInfo? _focusedCamera;
  Future<_HlsResult>? _focusedHlsFuture;

  @override
  void initState() {
    super.initState();
    print('🚀 CommandWidget initialized');
    print('API Base URL: $kApiBaseUrl');
    _fetchCategories();
    _fetchCameras();
    _loadGridLayout();
    _pollAccidents();
    _accidentPollTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _pollAccidents(),
    );
  }

  @override
  void dispose() {
    _accidentPollTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchCategories() async {
    try {
      print('🔄 Fetching categories from API...');
      print('API URL: $kApiBaseUrl/api/categories');
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
    // Grab a token for this specific request. If a newer call to _fetchCameras
    // starts before this one finishes, _fetchSeq will have advanced and we
    // will silently discard the stale response.
    _fetchSeq++;
    final mySeq = _fetchSeq;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final categoryFilter = _selectedCategoryId ?? 'All';
      print('🔄 Fetching cameras... (Category: $categoryFilter, seq=$mySeq)');

      final response = _selectedCategoryId == null
          ? await CameraService().getCameras(limit: '100')
          : await CameraService().getCamerasByCategoryId(_selectedCategoryId!);

      // Discard if a newer request has already resolved
      if (mySeq != _fetchSeq) {
        print('⚠️ Discarding stale camera response (seq=$mySeq, current=$_fetchSeq)');
        return;
      }

      print('📡 Camera Response Status: ${response.statusCode}');
      print('📡 Camera Response Succeeded: ${response.succeeded}');

      if (response.succeeded) {
        final List<dynamic> jsonList = response.jsonBody is List
            ? response.jsonBody
            : (response.jsonBody['data'] as List? ?? []);
        print('✅ Cameras loaded: ${jsonList.length} items');

        // Deduplicate by id — if the API returns two entries with the
        // same id the second one would cause the same stream to appear in
        // two tiles (because _ensureHls caches by id).
        final seenIds = <String>{};
        final parsedCams = <CameraInfo>[];
        for (final e in jsonList) {
          final cam = CameraInfo.fromJson(e as Map<String, dynamic>);
          final key = cam.id.isNotEmpty ? cam.id : cam.name;
          if (seenIds.add(key)) parsedCams.add(cam);
        }

        // Build the set of valid cache keys for the new camera list.
        final validKeys = <String>{
          for (final c in parsedCams) c.id.isNotEmpty ? c.id : c.name,
        };
        // Remove any cache entries that belong to cameras no longer in the
        // list — stale futures could serve the wrong stream.
        _hlsCache.removeWhere((key, _) => !validKeys.contains(key));

        setState(() {
          _cameras = parsedCams;
          _isLoading = false;
          _errorMessage = null;
        });

        print('✅ Parsed ${_cameras.length} cameras (${_hlsCache.length} HLS cache entries retained)');

      } else if (response.statusCode == 404 && _selectedCategoryId != null) {
        // 404 from getCamerasByCategoryId = category exists but has 0 cameras
        print('ℹ️ 404 for category $_selectedCategoryId → treating as empty list');
        _hlsCache.clear(); // No cameras → no valid cache entries
        setState(() {
          _cameras = [];
          _isLoading = false;
          _errorMessage = null;
        });
      } else {
        final errorMsg = 'API Error: ${response.statusCode}';
        print('❌ Failed to load cameras: ${response.statusCode}');
        setState(() {
          _isLoading = false;
          _errorMessage = errorMsg;
        });
      }
    } catch (e, stackTrace) {
      if (_fetchSeq != mySeq) return; // Already superseded
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
      // Clear saved positions when changing grid size so that stale entries
      // from a different grid size never interfere with slot assignment.
      _gridPositions = {};
    });
  }

  /// [truncate] = true for the compact category chip/button label.
  /// Pass truncate: false when displaying the full name (e.g. empty-state message).
  String _getCategoryName(String categoryId, {bool truncate = true}) {
    try {
      final category = _categories.firstWhere(
        (cat) => cat['id']?.toString() == categoryId,
        orElse: () => {'name': 'Unknown'},
      );
      final name = category['name']?.toString() ?? 'Unknown';
      if (!truncate) return name;
      return name.length > 9 ? '${name.substring(0, 9)}...' : name;
    } catch (e) {
      return 'Unknown';
    }
  }

  // ─── TODO [3]: Poll accidents endpoint every 30 s ───────────────────────────
  Future<void> _pollAccidents() async {
    try {
      final resp = await http
          .get(Uri.parse('$kApiBaseUrl/api/accidents?limit=100'))
          .timeout(const Duration(seconds: 10));
      if (resp.statusCode != 200) return;
      final body = jsonDecode(resp.body);
      final List<dynamic> list =
          body is List ? body : (body['data'] as List? ?? []);
      final now = DateTime.now();
      final Map<String, Map<String, dynamic>> fresh = {};
      for (final a in list) {
        if (a is! Map<String, dynamic>) continue;
        final cameraId = a['cameraId']?.toString();
        if (cameraId == null || cameraId.isEmpty) continue;
        // TTL: only show accidents from the last 5 minutes
        final ts = DateTime.tryParse(a['timestamp']?.toString() ?? '');
        if (ts != null && now.difference(ts).inMinutes >= 5) continue;
        // Keep the most-recent accident per camera
        if (!fresh.containsKey(cameraId)) fresh[cameraId] = a;
      }
      if (mounted) setState(() => _latestAccidents = fresh);
    } catch (_) {
      // Silently ignore poll errors — next tick will retry
    }
  }

  // ─── TODO [3]: Wrap a tile child with the accident overlay if needed ──────────
  Widget _withAccidentOverlay(int index, CameraInfo? cam, Widget child) {
    if (cam == null || cam.id.isEmpty) return child;
    final accident = _latestAccidents[cam.id];
    if (accident == null) return child;
    return Stack(
      children: [
        child,
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => _showAccidentDialog(cam, accident),
            child: _AccidentOverlay(
              timestamp: accident['timestamp']?.toString(),
            ),
          ),
        ),
      ],
    );
  }

  // ─── TODO [3]: Full-screen accident detail dialog ─────────────────────────────
  void _showAccidentDialog(
      CameraInfo camera, Map<String, dynamic> accident) {
    final imageUrl = accident['imageUrl']?.toString() ?? '';
    final timestamp = accident['timestamp']?.toString() ?? '';
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF1A1A1A),
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Accident Detected — ${camera.name}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white12, height: 1),
            // Accident image
            if (imageUrl.isNotEmpty)
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 400),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (_, child, progress) => progress == null
                      ? child
                      : const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: CircularProgressIndicator(
                                color: Colors.white54),
                          )),
                  errorBuilder: (_, __, ___) => const Padding(
                    padding: EdgeInsets.all(24),
                    child: Icon(Icons.broken_image,
                        color: Colors.white24, size: 64),
                  ),
                ),
              )
            else
              const Padding(
                padding: EdgeInsets.all(24),
                child: Icon(Icons.image_not_supported,
                    color: Colors.white24, size: 64),
              ),
            // Timestamp
            if (timestamp.isNotEmpty)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'Detected at: $timestamp',
                  style: const TextStyle(
                      color: Colors.white54, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            // Dismiss button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Dismiss'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Returns a cached [_HlsResult]; starts the stream on first call.
  Future<_HlsResult> _ensureHls(CameraInfo cam) {
    // Use id if available, fall back to name so two cameras with id=''
    // don't collide on the same cache entry.
    final cacheKey = cam.id.isNotEmpty ? cam.id : cam.name;
    final cached = _hlsCache[cacheKey];
    if (cached != null) return cached;
    final fut = _startHls(cam);
    _hlsCache[cacheKey] = fut;
    return fut;
  }

  /// Start HLS stream and return [_HlsResult] containing either the URL or
  /// a human-readable error reason explaining exactly why it failed.
  Future<_HlsResult> _startHls(CameraInfo cam) async {
    final uri = Uri.parse('$kApiBaseUrl/api/stream/hls/start');
    try {
      print('🎬 Starting stream for camera: ${cam.name} (ID: ${cam.id})');

      final resp = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'cameraId': cam.id}),
          )
          .timeout(const Duration(seconds: 15));

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final obj = jsonDecode(resp.body);
        String? hlsUrl;
        if (obj is Map) hlsUrl = obj['hlsUrl'] as String?;

        if (hlsUrl == null || hlsUrl.isEmpty) {
          print('⚠️ No HLS URL in response for ${cam.name}');
          return _HlsResult(error: 'Server returned no HLS URL');
        }

        String finalUrl = hlsUrl;
        if (!hlsUrl.startsWith('http')) {
          finalUrl = '$kApiBaseUrl$hlsUrl';
          print('🔗 Converted relative URL: $finalUrl');
        }
        print('✅ Stream started for ${cam.name} → $finalUrl');
        return _HlsResult(url: finalUrl);

      } else if (resp.statusCode == 400) {
        try {
          final errorObj = jsonDecode(resp.body);
          final errorMsg = errorObj['error']?.toString() ?? resp.body;
          print('❌ ${cam.name}: $errorMsg');
          if (errorMsg.contains('No RTSP URL configured')) {
            return _HlsResult(error: 'No RTSP URL configured for this camera');
          }
          return _HlsResult(error: 'Bad request: $errorMsg');
        } catch (_) {
          return _HlsResult(error: 'Bad request (400): ${resp.body.length > 80 ? resp.body.substring(0, 80) : resp.body}');
        }
      } else {
        print('❌ HTTP ${resp.statusCode} for ${cam.name}: ${resp.body}');
        return _HlsResult(
          error: 'HTTP ${resp.statusCode}: ${resp.body.length > 80 ? resp.body.substring(0, 80) : resp.body}',
        );
      }
    } catch (e) {
      // Remove using the SAME normalized key used when storing the future,
      // so the next call can retry instead of reusing a broken future.
      final removeKey = cam.id.isNotEmpty ? cam.id : cam.name;
      _hlsCache.remove(removeKey);
      if (e.toString().contains('TimeoutException')) {
        print('⏱️ Stream timeout for ${cam.name}');
        return _HlsResult(error: 'Connection timed out — server unreachable');
      }
      print('❌ Exception for ${cam.name}: $e');
      return _HlsResult(error: 'Unexpected error: $e');
    }
  }
  
  /// Pre-computes a dedup-safe slot assignment: honours saved [_gridPositions]
  /// first, then fills remaining empty slots with cameras not yet placed.
  /// Guarantees every camera id appears in at most one slot.
  List<CameraInfo?> _buildSlotAssignment(List<CameraInfo> cams, int totalTiles) {
    final slots = List<CameraInfo?>.filled(totalTiles, null);
    final placedIds = <String>{};

    // 1st pass: honour saved positions.
    // Sort entries so lower positions win when the same cameraId appears in
    // _gridPositions more than once (corrupted state guard).
    final sortedEntries = _gridPositions.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    for (final entry in sortedEntries) {
      final pos = entry.key;
      final cameraId = entry.value;
      if (pos >= totalTiles) continue;
      // Skip if this cameraId was already placed from a lower-position entry
      if (placedIds.contains(cameraId)) continue;
      try {
        final cam = cams.firstWhere(
          (c) => (c.id.isNotEmpty ? c.id : c.name) == cameraId,
        );
        final camKey = cam.id.isNotEmpty ? cam.id : cam.name;
        slots[pos] = cam;
        placedIds.add(camKey);
      } catch (_) {
        // Camera no longer in current list — leave slot empty
      }
    }

    // 2nd pass: fill remaining empty slots with cameras not yet placed.
    // Use a set so even if `cams` itself had duplicate ids (shouldn't happen
    // after the dedup in _fetchCameras, but be safe) we never place twice.
    final unplacedSeen = <String>{};
    final unplaced = <CameraInfo>[];
    for (final cam in cams) {
      final key = cam.id.isNotEmpty ? cam.id : cam.name;
      if (!placedIds.contains(key) && unplacedSeen.add(key)) {
        unplaced.add(cam);
      }
    }

    int ui = 0;
    for (int i = 0; i < totalTiles && ui < unplaced.length; i++) {
      if (slots[i] == null) slots[i] = unplaced[ui++];
    }
    return slots;
  }

  /// Build a clickable video tile for edit mode (click-to-select swap)
  Widget _buildClickableVideoTile({
    required int index,
    required CameraInfo? camera,
    required Future<_HlsResult>? hlsFuture,
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
                        // Derive the camera key at each slot from the
                        // authoritative _currentSlots list (not _cameras order).
                        String? _camKey(int idx) {
                          final cam = idx < _currentSlots.length
                              ? _currentSlots[idx]
                              : null;
                          if (cam == null) return null;
                          return cam.id.isNotEmpty ? cam.id : cam.name;
                        }
                        final fromCameraId = _camKey(fromIndex);
                        final toCameraId   = _camKey(toIndex);
                        
                        print('🔄 Swapping: Position $fromIndex ($fromCameraId) <-> Position $toIndex ($toCameraId)');
                        
                        // Perform the swap in _gridPositions
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
                        
                        // Clear selection
                        _selectedTileIndex = null;
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
                              _hlsCache.clear();
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

                  // ─── TODO [1]: Category-aware empty state ───────────────
                  if (cams.isEmpty) {
                    if (_selectedCategoryId != null) {
                      // Category selected but has 0 cameras
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.folder_open,
                              color: Colors.white38,
                              size: 64,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'There is no camera in this category',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'You can add cameras manually from the Collection page',
                              style: TextStyle(
                                color: Colors.white38,
                                fontSize: 13,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    } else {
                      // No cameras in the system at all
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
                                _hlsCache.clear();
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
                  }

                  // Streams are started on-demand when cameras are displayed in the grid
                  // This avoids unnecessary 400 errors for cameras without RTSP URLs

                  // Pre-compute slot assignment to prevent the same camera
                  // appearing in multiple grid cells at once.
                  final slots = _buildSlotAssignment(cams, totalTiles);
                  // Cache so click/swap handlers know which camera is at each
                  // position (mutating a plain field, not calling setState).
                  _currentSlots = slots;
                  // Sync _gridPositions back to the ACTUAL displayed layout
                  // after the frame is painted — keeps build() pure.
                  final syncedPositions = <int, String>{};
                  for (int _si = 0; _si < slots.length; _si++) {
                    final _sc = slots[_si];
                    if (_sc != null) {
                      syncedPositions[_si] =
                          _sc.id.isNotEmpty ? _sc.id : _sc.name;
                    }
                  }
                  // Only schedule a post-frame update when the map actually
                  // differs to avoid unnecessary work on every rebuild.
                  if (!_mapsEqual(_gridPositions, syncedPositions)) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) setState(() => _gridPositions = syncedPositions);
                    });
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
                      final cam = slots[index];
                      final Future<_HlsResult>? fut =
                          cam != null ? _ensureHls(cam) : null;

                      // Edit mode: tap-to-swap tiles
                      if (_isEditMode) {
                        return _withAccidentOverlay(
                          index,
                          cam,
                          _buildClickableVideoTile(
                            index: index,
                            camera: cam,
                            hlsFuture: fut,
                          ),
                        );
                      }

                      // Normal mode: double-tap to enter full-screen focus
                      // Key includes the slot INDEX so tiles at different
                      // positions always have unique keys even when camera.id
                      // is empty, preventing Flutter from reusing widget state.
                      final tile = _VideoTile(
                        key: cam != null
                            ? ValueKey('tile_${index}_${cam.id}_$gridSize')
                            : ValueKey('empty_$index'),
                        index: index,
                        camera: cam,
                        hlsFuture: fut,
                        isEditMode: false,
                      );
                      return _withAccidentOverlay(
                        index,
                        cam,
                        GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onDoubleTap: cam != null
                              ? () => setState(() {
                                    _focusedCamera = cam;
                                    _focusedHlsFuture = fut;
                                  })
                              : null,
                          child: tile,
                        ),
                      );
                    },
                  );

                },
              ),

              // Grid size + Edit buttons — top-left floating
              Positioned(
                top: 8,
                left: 8,
                child: IgnorePointer(
                  ignoring: false,
                  child: Material(
                    elevation: 10,
                    color: Colors.transparent,
                    child: Row(
                      children: [
                        _buildFloatingButton(
                          onTap: _cycleLayout,
                          icon: Icons.grid_view_rounded,
                          label: '${gridSize}x$gridSize',
                        ),
                        const SizedBox(width: 6),
                        _buildFloatingButton(
                          onTap: () {
                            setState(() {
                              _isEditMode = !_isEditMode;
                              if (!_isEditMode) {
                                _saveGridLayout();
                                _selectedTileIndex = null;
                              } else {
                                _selectedTileIndex = null;
                              }
                            });
                          },
                          icon: _isEditMode ? Icons.check : Icons.edit,
                          label: _isEditMode ? 'Done' : 'Edit',
                          isActive: _isEditMode,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Category filter — top-right floating
              Positioned(
                top: 8,
                right: 8,
                child: IgnorePointer(
                  ignoring: false,
                  child: Material(
                    elevation: 10,
                    color: Colors.transparent,
                    child: MouseRegion(
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
                                          fontSize: AppTextStyles.commandSmall,
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
                                              fontSize: AppTextStyles.commandBody,
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
                                              fontSize: AppTextStyles.commandSmall,
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
                                              fontSize: AppTextStyles.commandBody,
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
                                // Clear HLS cache when category changes so no
                                // stale stream futures from the previous list
                                // survive into the new camera assignment.
                                _hlsCache.clear();
                                _fetchCameras();
                              } else {
                                print('ℹ️ Same filter selected, no action needed');
                              }
                            },
                          ),
                    ), // End MouseRegion (category filter)
                  ), // End Material
                ), // End IgnorePointer
              ), // End category Positioned

              // Edit mode instruction banner
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
                            'Tap to select · tap another to swap',
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

              // Full-screen focus overlay — shown when a tile is double-tapped
              if (_focusedCamera != null)
                Positioned.fill(
                  child: Container(
                    color: Colors.black,
                    child: Stack(
                      children: [
                        // Full-screen stream
                        Positioned.fill(
                          child: GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            // Double-tap anywhere in the focus overlay exits —
                            // including when the stream is in an error state.
                            onDoubleTap: () =>
                                setState(() => _focusedCamera = null),
                            child: FutureBuilder<_HlsResult>(
                            key: ValueKey('focus_${_focusedCamera!.id}'),
                            future: _focusedHlsFuture,
                            builder: (context, snap) {
                              if (snap.connectionState ==
                                  ConnectionState.waiting) {
                                return _StreamLoadingTile(
                                    cameraName: _focusedCamera!.name);
                              }
                              final hls = snap.data?.url;
                              if (hls == null || hls.isEmpty) {
                                return Center(
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.signal_wifi_statusbar_connected_no_internet_4_rounded,
                                        color: Colors.redAccent,
                                        size: 48,
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        snap.data?.error ??
                                            'Stream unavailable',
                                        style: const TextStyle(
                                            color: Colors.white60,
                                            fontSize: 14),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 16),
                                      const Text(
                                        'Double-tap to exit',
                                        style: TextStyle(
                                            color: Colors.white30,
                                            fontSize: 11),
                                      ),
                                    ],
                                  ),
                                );
                              }
                              return HlsPlayer(
                                key: ValueKey(
                                    'focus_${_focusedCamera!.id}_$hls'),
                                hlsUrl: hls,
                              );
                            },
                          ),
                          ),
                        ),
                        // Camera name badge (top-left)
                        Positioned(
                          top: 12,
                          left: 12,
                          child: IgnorePointer(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _focusedCamera!.name,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                        ),
                        // Exit button (top-right)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _focusedCamera = null),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.75),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.fullscreen_exit,
                                  color: Colors.white, size: 20),
                            ),
                          ),
                        ),
                        // Double-tap hint (bottom-centre)
                        Positioned(
                          bottom: 16,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: IgnorePointer(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Text(
                                  'Double-tap stream · tap ✕ to exit',
                                  style: TextStyle(
                                      color: Colors.white70, fontSize: 11),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Shallow equality check for two [Map<int,String>] instances.
  bool _mapsEqual(Map<int, String> a, Map<int, String> b) {
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (b[entry.key] != entry.value) return false;
    }
    return true;
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
                ? Colors.blue.withOpacity(0.55)
                : Colors.black.withOpacity(0.35),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isActive ? Colors.blueAccent.withOpacity(0.8) : Colors.white.withOpacity(0.18),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 14),
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

