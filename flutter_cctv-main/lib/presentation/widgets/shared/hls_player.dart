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
  final String? streamName; // สำหรับกรณี RTSP ต้องใช้ docId
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
          setState(() => _error = 'Missing streamName for RTSP source');
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
    final body = jsonEncode({
      'streamName': streamName,
      'rtspUrl': rtspUrl,
    });

    final resp = await http
        .post(uri, headers: {'Content-Type': 'application/json'}, body: body)
        .timeout(const Duration(seconds: 10));

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      try {
        final obj = jsonDecode(resp.body);
        final path = obj['message'] ?? obj['url'] ?? obj['hls'] ?? resp.body;
        if (path is String && path.isNotEmpty) {
          if (path.startsWith('http')) return path;
          return '$kApiBaseUrl$path';
        }
      } catch (_) {
        final bodyText = resp.body.trim();
        if (bodyText.startsWith('/')) return '$kApiBaseUrl$bodyText';
      }
      throw Exception('Invalid response format: ${resp.body}');
    } else {
      throw Exception('HTTP ${resp.statusCode}: ${resp.body}');
    }
  }

  void _registerView(String finalUrl) {
    if (!kIsWeb) return;

    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      // Create container div with explicit dimensions
      final container = web.document.createElement('div') as web.HTMLDivElement;
      container.style.width = '100%';
      container.style.height = '100%';
      container.style.overflow = 'hidden';
      container.style.pointerEvents = 'none'; // Allow clicks to pass through to Flutter
      
      final iframe = web.HTMLIFrameElement();
      iframe.width = '100%';
      iframe.height = '100%';
      iframe.style.border = 'none';
      iframe.style.display = 'block';
      iframe.style.pointerEvents = 'none'; // Allow clicks to pass through to Flutter
      iframe.allow = 'autoplay; fullscreen';
      iframe.setAttribute('allowfullscreen', '');

      iframe.srcdoc = '''
<!DOCTYPE html>
<html>
  <head>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <script src="https://cdn.jsdelivr.net/npm/hls.js@latest"></script>
    <style>
      html, body { margin: 0; padding: 0; height: 100%; background: #000; overflow: hidden; }
      .wrap { position: relative; width: 100%; height: 100%; }
      video { width: 100%; height: 100%; background: #000; display: block; }
      //#fsBtn {
        //position: absolute; right: 12px; bottom: 12px;
        //padding: 10px 12px; border-radius: 10px; border: none;
        //background: rgba(255,255,255,0.12); color: #fff; font-size: 18px; line-height: 1;
        //cursor: pointer; backdrop-filter: blur(4px);
      //}
      //#fsBtn:hover { background: rgba(255,255,255,0.2); }
      //#fsBtn:active { background: rgba(255,255,255,0.28); }
      video::-webkit-media-controls { display: none !important; }
      video::-webkit-media-controls-enclosure { display: none !important; }
    </style>
  </head>
  <body>
    <div class="wrap">
      <video id="video" autoplay muted playsinline></video>
    </div>
    <script>
      const video = document.getElementById('video');
      video.muted = true;

      function tryPlay() {
        const p = video.play();
        if (p && typeof p.catch === 'function') {
          p.catch((e) => console.warn('Autoplay prevented:', e));
        }
      }

      if (typeof Hls !== 'undefined' && Hls.isSupported()) {
        console.log('Loading HLS stream:', "$finalUrl");
        
        // First, check if manifest exists and is valid
        fetch("$finalUrl")
          .then(response => {
            console.log('Manifest response status:', response.status);
            return response.text();
          })
          .then(text => {
            console.log('Manifest content:', text.substring(0, 500));
            if (!text.includes('#EXTM3U')) {
              console.error('Invalid HLS manifest - missing #EXTM3U header');
              document.body.innerHTML = '<p style="color:orange;text-align:center;padding:16px;">Invalid HLS stream format</p>';
              return;
            }
            
            // If valid, initialize HLS.js with optimized config
            const hls = new Hls({
              debug: false,
              enableWorker: true,
              lowLatencyMode: true,
              backBufferLength: 90,
              
              // Improved buffering settings
              maxBufferLength: 30,
              maxMaxBufferLength: 600,
              maxBufferSize: 60 * 1000 * 1000,
              maxBufferHole: 0.5,
              
              // Network settings
              manifestLoadingTimeOut: 10000,
              manifestLoadingMaxRetry: 3,
              manifestLoadingRetryDelay: 1000,
              levelLoadingTimeOut: 10000,
              levelLoadingMaxRetry: 4,
              fragLoadingTimeOut: 20000,
              fragLoadingMaxRetry: 6,
              fragLoadingRetryDelay: 1000,
              
              // XHR setup for headers
              xhrSetup: function(xhr, url) {
                xhr.setRequestHeader("ngrok-skip-browser-warning", "anyvalue");
              }
            });
            
            hls.loadSource("$finalUrl");
            hls.attachMedia(video);
            
            hls.on(Hls.Events.MANIFEST_PARSED, function () { 
              console.log('HLS manifest parsed successfully');
              tryPlay(); 
            });
            
            hls.on(Hls.Events.LEVEL_LOADED, function () { 
              if (video.paused) tryPlay(); 
            });
            
            hls.on(Hls.Events.ERROR, function (event, data) {
              console.error('HLS Error:', data.type, data.details, data.fatal);
              
              // Auto-recover from network errors
              if (data.fatal) {
                switch (data.type) {
                  case Hls.ErrorTypes.NETWORK_ERROR:
                    console.log('Network error, attempting to recover...');
                    hls.startLoad();
                    break;
                  case Hls.ErrorTypes.MEDIA_ERROR:
                    console.log('Media error, attempting to recover...');
                    hls.recoverMediaError();
                    break;
                  default:
                    console.error('Fatal error, unable to recover');
                    document.body.innerHTML = '<p style="color:orange;text-align:center;padding:16px;">Stream Error: ' + data.details + '</p>';
                    hls.destroy();
                    break;
                }
              }
            });
          })
          .catch(err => {
            console.error('Failed to fetch manifest:', err);
            document.body.innerHTML = '<p style="color:red;text-align:center;padding:16px;">Failed to load stream</p>';
          });
      } else if (video.canPlayType('application/vnd.apple.mpegurl')) {
        video.src = "$finalUrl";
        tryPlay();
      } else {
        document.body.innerHTML = '<p style="color:white;text-align:center;padding:16px;">HLS not supported.</p>';
      }
    </script>
  </body>
</html>
'''
          .toJS;

      container.appendChild(iframe);
      return container;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Container(
        color: Colors.black,
        alignment: Alignment.center,
        child: Text(
          '❌ $_error',
          style: const TextStyle(color: Colors.redAccent, fontSize: AppTextStyles.commandBody),
          textAlign: TextAlign.center,
        ),
      );
    }

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
      return const Center(
          child: Text('⚠️ HLS player is only supported on Web.'));
    }

    _registerView(_resolvedUrl!);
    final width = widget.width ?? MediaQuery.of(context).size.width;
    final height = widget.height ?? width * 9 / 16;

    return SizedBox(
        width: width,
        height: height,
        child: HtmlElementView(viewType: _viewType));
  }
}
