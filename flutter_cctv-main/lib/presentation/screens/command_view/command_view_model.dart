import '/presentation/widgets/nav/views/nav_bar_main_widget.dart';
import '/utils/flutter_flow/theme.dart';
import '/utils/flutter_flow/util.dart';
import '/utils/flutter_flow/widgets.dart';
import 'dart:ui';
import '/presentation/widgets/index.dart' as custom_widgets;
import 'command_view_widget.dart' show CommandViewWidget;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// TODO [1]: Handle "no CCTV in selected category" empty state
//   FILE: lib/presentation/widgets/shared/command_widget.dart
//   WHERE: `if (cams.isEmpty)` block inside the grid's StreamBuilder/builder (~line 795)
//
//   WHAT TO CHANGE:
//     Replace the single hard-coded empty-state widget with a conditional:
//
//       if (cams.isEmpty) {
//         if (_selectedCategoryId != null) {
//           // ── Category selected but has 0 cameras ──
//           final catName = _getCategoryName(_selectedCategoryId!);
//           return Center(child: Column(children: [
//             Icon(Icons.folder_open, color: Colors.white38, size: 64),
//             Text('No cameras in "$catName"'),          // category-specific message
//             Text('Add cameras via the Collection page',
//                  style: TextStyle(color: Colors.white38)),
//             // No Refresh button — user needs to go to Collection, not retry the API
//           ]));
//         } else {
//           // ── No cameras at all (original error UI) ──
//           return <existing Icons.videocam_off / "Check your API connection" widget>;
//         }
//       }
//
//   NOTE: _getCategoryName() already exists and truncates to 9 chars — remove the
//   truncation or increase the limit for this use-case so the name reads clearly.
// ─────────────────────────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────────────────────────
// TODO [2]: Informative loading tile while HLS stream is starting
//   FILE: lib/presentation/widgets/shared/command_widget.dart
//   WHERE: _VideoTile._loading() (StatelessWidget method, ~line 130) and the
//          FutureBuilder `ConnectionState.waiting` branch (~line 87)
//
//   WHAT TO CHANGE:
//     1. Extract a new StatefulWidget `_StreamLoadingTile` (replaces the _loading() call):
//
//          class _StreamLoadingTile extends StatefulWidget {
//            final String cameraName;
//          }
//          class _StreamLoadingTileState extends State<_StreamLoadingTile> {
//            late Timer _timer;
//            bool _isSlow = false;
//            @override void initState() {
//              _timer = Timer(const Duration(seconds: 10),
//                            () => setState(() => _isSlow = true));
//            }
//            @override void dispose() { _timer.cancel(); super.dispose(); }
//            Widget build(context) => Column(children: [
//              Text(widget.cameraName),    // camera name already on the field
//              LinearProgressIndicator(),
//              Text(_isSlow ? 'Taking longer than usual…' : 'Starting stream…'),
//            ]);
//          }
//
//     2. In `_VideoTile.build`, replace `return _loading()` with:
//          return _StreamLoadingTile(cameraName: camera!.name);
//        (camera is non-null here because the FutureBuilder only runs when hasCam=true)
//
//   NOTE: _VideoTile is currently a StatelessWidget — no change needed to the class
//   itself; only the waiting branch needs swapping.
// ─────────────────────────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────────────────────────
// TODO [3]: Accident alert overlay on video tiles
//   FILE: lib/presentation/widgets/shared/command_widget.dart
//         lib/data/services/camera_service.dart  (or new accident_service.dart)
//         lib/core/config/api_config.dart
//
//   STEP A — Add endpoint to api_config.dart:
//     static const String accidentsEndpoint = '/accidents';
//
//   STEP B — Add a fetch helper in _CommandWidgetState:
//     Map<String, Map<String,dynamic>> _latestAccidents = {};  // cameraId → accident
//     Timer? _accidentPollTimer;
//
//     Future<void> _pollAccidents() async {
//       final resp = await http.get(Uri.parse('$kApiBaseUrl/api/accidents?limit=100'));
//       if (resp.statusCode != 200) return;
//       final List list = jsonDecode(resp.body)['data'] ?? jsonDecode(resp.body);
//       final now = DateTime.now();
//       final Map<String,Map<String,dynamic>> fresh = {};
//       for (final a in list) {
//         final ts = DateTime.tryParse(a['timestamp'] ?? '');
//         if (ts != null && now.difference(ts).inMinutes < 5) {   // 5-min TTL
//           final id = a['cameraId'] as String?;
//           if (id != null) fresh[id] = a;
//         }
//       }
//       if (mounted) setState(() => _latestAccidents = fresh);
//     }
//
//     In initState: _pollAccidents(); _accidentPollTimer = Timer.periodic(30s, …);
//     In dispose:   _accidentPollTimer?.cancel();
//
//   STEP C — Add overlay in the grid itemBuilder:
//     The grid currently returns _buildClickableVideoTile (edit mode) OR _VideoTile
//     (normal mode). Wrap BOTH in a shared helper `_withAccidentOverlay(index, cam, child)`:
//
//       Widget _withAccidentOverlay(int index, CameraInfo? cam, Widget child) {
//         final accident = cam != null ? _latestAccidents[cam.id] : null;
//         return Stack(children: [
//           child,
//           if (accident != null)
//             Positioned.fill(child: GestureDetector(
//               onTap: () => _showAccidentDialog(accident),
//               child: _AccidentOverlay(timestamp: accident['timestamp']),
//             )),
//         ]);
//       }
//
//   STEP D — _AccidentOverlay widget (pulsing red border + icon):
//     StatefulWidget with AnimationController (repeat, reverse) driving a
//     Border color between Colors.red and Colors.red.withOpacity(0.3):
//       AnimatedBuilder → Container with BoxDecoration(border: Border.all(color: …))
//       + Positioned top-right: Icon(Icons.warning_amber_rounded, color: Colors.red)
//                              + Text(formattedTimestamp)
//
//   STEP E — _showAccidentDialog:
//     showDialog → full-screen image from accident['imageUrl']
//     + timestamp + camera name + Dismiss button.
// ─────────────────────────────────────────────────────────────────────────────

class CommandViewModel extends FlutterFlowModel<CommandViewWidget> {
  ///  Local state fields for this page.

  bool? isMenuOpen;

  ///  State fields for stateful widgets in this page.

  // Model for NavBarMain component.
  late NavBarMainModel navBarMainModel;

  @override
  void initState(BuildContext context) {
    navBarMainModel = createModel(context, () => NavBarMainModel());
  }

  @override
  void dispose() {
    navBarMainModel.dispose();
  }
}
