// Automatic FlutterFlow imports
import '/utils/flutter_flow/theme.dart';
import '/utils/flutter_flow/util.dart';
import '../index.dart'; // Imports other custom widgets
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'dart:convert';
import 'package:http/http.dart' as http; // <-- ใช้ยิง POST

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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCameras();
  }

  Future<void> _fetchCameras() async {
    try {
      final uri = Uri.parse('$kApiBaseUrl/api/cameras');
      final resp = await http.get(uri).timeout(const Duration(seconds: 10));
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final List<dynamic> jsonList = jsonDecode(resp.body) is List
            ? jsonDecode(resp.body)
            : (jsonDecode(resp.body)['data'] as List? ?? []);
        setState(() {
          _cameras = jsonList
              .map((e) => CameraInfo.fromJson(e as Map<String, dynamic>))
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
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

  @override
  Widget build(BuildContext context) {
    final totalTiles = gridSize * gridSize;

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Container(
        color: Colors.black,
        child: SafeArea(
          child: Column(
            children: [
              // แถบควบคุมด้านบน (ปุ่มหมุน layout)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: _cycleLayout,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white24, width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.grid_view_rounded,
                              color: Colors.white,
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${gridSize}x$gridSize',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Live Cameras',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // พื้นที่กริดกล้อง
              Expanded(
                child: Builder(
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
                      padding: const EdgeInsets.all(8.0),
                      itemCount: totalTiles,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: gridSize,
                        crossAxisSpacing: 6,
                        mainAxisSpacing: 6,
                        childAspectRatio: 16 / 9,
                      ),
                      itemBuilder: (context, index) {
                        final cam = (index < cams.length) ? cams[index] : null;
                        final fut = (cam != null && cam.rtspUrl.isNotEmpty)
                            ? _ensureHls(cam)
                            : null;

                        return _VideoTile(
                          index: index,
                          camera: cam,
                          hlsFuture: fut,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
