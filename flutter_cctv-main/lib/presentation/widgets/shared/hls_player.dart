// Automatic FlutterFlow imports
import '/utils/flutter_flow/theme.dart';
import '/utils/flutter_flow/util.dart';
import '../index.dart'; // Imports other custom widgets
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'dart:js_interop';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:ui_web' as ui_web;
import 'package:web/web.dart' as web;
import 'package:flutter/foundation.dart';

// ตั้งค่า Base URL ของ Backend
const String kApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://se-lab.aboutblank.in.th',
);

class HlsPlayer extends StatefulWidget {
  /// ตอนนี้ parameter นี้รับได้ทั้ง HLS URL หรือ RTSP URL
  final String hlsUrl;
  final String? streamName;
  final double? width;
  final double? height;

  const HlsPlayer({
    Key? key,
    required this.hlsUrl,
    this.streamName,
    this.width,
    this.height,
  }) : super(key: key);

  @override
  State<HlsPlayer> createState() => _HlsPlayerWebState();
}

class _HlsPlayerWebState extends State<HlsPlayer> {
  late final String _viewType;
  String? _resolvedUrl;
  String? _error;

  @override
  void initState() {
    super.initState();
    _viewType = 'hls-view-${DateTime.now().millisecondsSinceEpoch}';
    _initPlayer();
  }

  /// ถ้า URL เป็น RTSP จะเรียก backend เพื่อแปลงเป็น HLS
  Future<void> _initPlayer() async {
    try {
      final url = widget.hlsUrl.trim();
      if (url.startsWith('rtsp://')) {
        if (widget.streamName == null) {
          setState(() => _error = 'missing_stream_name');
          return;
        }

        final hlsUrl = await _requestHlsUrl(url, widget.streamName!);
        setState(() => _resolvedUrl = hlsUrl);
      } else {
        // ถ้าเป็น HLS อยู่แล้ว
        setState(() => _resolvedUrl = url);
      }
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  Future<String> _requestHlsUrl(String rtspUrl, String streamName) async {
    final uri = Uri.parse('$kApiBaseUrl/api/stream/hls/start');
    final body = jsonEncode({'streamName': streamName, 'rtspUrl': rtspUrl});

    debugPrint('[HlsPlayer] POST $uri body=$body');

    final resp = await http
        .post(uri, headers: {'Content-Type': 'application/json'}, body: body)
        .timeout(const Duration(seconds: 10));

    debugPrint('[HlsPlayer] response ${resp.statusCode}: ${resp.body}');

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      try {
        final obj = jsonDecode(resp.body);
        final path = obj['message'] ?? obj['url'] ?? obj['hls'] ?? resp.body;
        if (path is String && path.isNotEmpty) {
          final resolved = path.startsWith('http') ? path : '$kApiBaseUrl$path';
          debugPrint('[HlsPlayer] resolved: $resolved');
          return resolved;
        }
      } catch (_) {
        final bodyText = resp.body.trim();
        if (bodyText.startsWith('/')) return '$kApiBaseUrl$bodyText';
      }
      throw Exception('Invalid response: ${resp.body}');
    } else {
      throw Exception('HTTP ${resp.statusCode}');
    }
  }

  void _registerView(String finalUrl) {
    if (!kIsWeb) return;

    // Build the srcdoc HTML — use single quotes inside to avoid Dart string conflicts
    final html = '''<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width,initial-scale=1.0">
  <script src="https://cdn.jsdelivr.net/npm/hls.js@latest"></script>
  <style>
    html,body{margin:0;padding:0;height:100%;background:#111;overflow:hidden}
    .wrap{position:relative;width:100%;height:100%}
    video{width:100%;height:100%;background:#000;display:block}
    video::-webkit-media-controls{display:none!important}
    video::-webkit-media-controls-enclosure{display:none!important}
    .unavailable{display:flex;flex-direction:column;align-items:center;
      justify-content:center;height:100%;background:#111;color:#888;
      font-family:sans-serif;gap:8px;font-size:13px;font-weight:500}
  </style>
</head>
<body>
  <div class="wrap">
    <video id="video" autoplay muted playsinline></video>
  </div>
  <script>
    var video = document.getElementById('video');
    video.muted = true;

    function tryPlay() {
      var p = video.play();
      if (p && typeof p.catch === 'function') {
        p.catch(function(e) { console.warn('Autoplay prevented:', e); });
      }
    }

    function showUnavailable(reason) {
      document.body.innerHTML =
        '<div class="unavailable">' +
        '<svg width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="#555" stroke-width="1.5">' +
        '<path d="M15 10l4.553-2.069A1 1 0 0121 8.845v6.31a1 1 0 01-1.447.894L15 14' +
        'M3 8a2 2 0 012-2h8a2 2 0 012 2v8a2 2 0 01-2 2H5a2 2 0 01-2-2V8z"/>' +
        '<line x1="2" y1="2" x2="22" y2="22" stroke="#ef4444" stroke-width="1.5"/>' +
        '</svg>' +
        '<span>Stream Unavailable</span>' +
        '</div>';
      console.warn('[HLS] Unavailable:', reason);
    }

    if (typeof Hls !== 'undefined' && Hls.isSupported()) {
      fetch('$finalUrl', { headers: { 'ngrok-skip-browser-warning': 'anyvalue' } })
        .then(function(response) {
          if (!response.ok) throw new Error('HTTP ' + response.status);
          return response.text();
        })
        .then(function(text) {
          if (text.indexOf('#EXTM3U') === -1) {
            showUnavailable('invalid manifest');
            return;
          }
          var hls = new Hls({
            debug: false,
            enableWorker: true,
            lowLatencyMode: true,
            backBufferLength: 90,
            maxBufferLength: 30,
            maxMaxBufferLength: 600,
            maxBufferSize: 60000000,
            maxBufferHole: 0.5,
            manifestLoadingTimeOut: 10000,
            manifestLoadingMaxRetry: 3,
            manifestLoadingRetryDelay: 1000,
            levelLoadingTimeOut: 10000,
            levelLoadingMaxRetry: 4,
            fragLoadingTimeOut: 20000,
            fragLoadingMaxRetry: 6,
            fragLoadingRetryDelay: 1000,
            xhrSetup: function(xhr, url) {
              xhr.setRequestHeader('ngrok-skip-browser-warning', 'anyvalue');
            }
          });
          hls.loadSource('$finalUrl');
          hls.attachMedia(video);
          hls.on(Hls.Events.MANIFEST_PARSED, function() { tryPlay(); });
          hls.on(Hls.Events.LEVEL_LOADED, function() { if (video.paused) tryPlay(); });
          hls.on(Hls.Events.ERROR, function(event, data) {
            if (data.fatal) {
              if (data.type === Hls.ErrorTypes.NETWORK_ERROR) {
                hls.startLoad();
              } else if (data.type === Hls.ErrorTypes.MEDIA_ERROR) {
                hls.recoverMediaError();
              } else {
                showUnavailable(data.details);
                hls.destroy();
              }
            }
          });
        })
        .catch(function(err) { showUnavailable(err.message || String(err)); });

    } else if (video.canPlayType('application/vnd.apple.mpegurl')) {
      video.src = '$finalUrl';
      tryPlay();
    } else {
      showUnavailable('HLS not supported');
    }
  </script>
</body>
</html>''';

    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      final container =
          web.document.createElement('div') as web.HTMLDivElement;
      container.style.width = '100%';
      container.style.height = '100%';
      container.style.overflow = 'hidden';
      container.style.pointerEvents = 'none';

      final iframe = web.HTMLIFrameElement();
      iframe.width = '100%';
      iframe.height = '100%';
      iframe.style.border = 'none';
      iframe.style.display = 'block';
      iframe.style.pointerEvents = 'none';
      iframe.allow = 'autoplay; fullscreen';
      iframe.setAttribute('allowfullscreen', '');
      iframe.srcdoc = html.toJS;

      container.appendChild(iframe);
      return container;
    });
  }

  // ── build ────────────────────────────────────────────────────────────────

  Widget _unavailableWidget() => Container(
        color: const Color(0xFF111111),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.videocam_off_rounded,
                color: Colors.grey.shade600, size: 36),
            const SizedBox(height: 8),
            Text(
              'Stream Unavailable',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    if (_error != null) return _unavailableWidget();

    if (_resolvedUrl == null) {
      return Container(
        color: Colors.black,
        alignment: Alignment.center,
        child: const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
        ),
      );
    }

    if (!kIsWeb) {
      return _unavailableWidget();
    }

    _registerView(_resolvedUrl!);

    final w = widget.width ?? MediaQuery.of(context).size.width;
    final h = widget.height ?? w * 9 / 16;

    return SizedBox(
      width: w,
      height: h,
      child: HtmlElementView(viewType: _viewType),
    );
  }
}
