import '/utils/flutter_flow/theme.dart';
import '/utils/flutter_flow/util.dart';
import '/utils/flutter_flow/widgets.dart';
import 'dart:ui';
import '/presentation/widgets/index.dart' as custom_widgets;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/preview_overlay_model.dart';
export '../models/preview_overlay_model.dart';

class PreviewOverlayWidget extends StatefulWidget {
  const PreviewOverlayWidget({
    super.key,
    required this.onClose,
    required this.onRemoveTapped,
    required this.cameraList,
  });

  final Future Function()? onClose;
  final Future Function(dynamic cameraToRemove)? onRemoveTapped;
  final List<dynamic>? cameraList;

  @override
  State<PreviewOverlayWidget> createState() => _PreviewOverlayWidgetState();
}

class _PreviewOverlayWidgetState extends State<PreviewOverlayWidget> {
  late PreviewOverlayModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => PreviewOverlayModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Stack(
        children: [
          // Side panel — 30% width, full height of parent
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: MediaQuery.sizeOf(context).width * 0.3,
            child: ColoredBox(
              color: Colors.white,
              child: Stack(
                children: [
                  // Camera list
                  Builder(
                    builder: (context) {
                      final feeditem =
                          widget.cameraList!.toList().take(3).toList();
                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(0, 80, 0, 0),
                        shrinkWrap: false,
                        scrollDirection: Axis.vertical,
                        itemCount: feeditem.length,
                        itemBuilder: (context, feeditemIndex) {
                          final feeditemItem = feeditem[feeditemIndex];
                          final itemName =
                              feeditemItem['name']?.toString() ?? '';
                          final itemUrl =
                              feeditemItem['rtspUrl']?.toString() ?? '';
                          final itemId =
                              feeditemItem['id']?.toString() ?? '';
                          // Debug: log what we got
                          debugPrint('[PreviewOverlay] name=$itemName id=$itemId rtspUrl=$itemUrl');
                          final panelWidth = MediaQuery.sizeOf(context).width * 0.3;
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsetsDirectional.fromSTEB(
                                    0, 0, 5, 0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsetsDirectional
                                            .fromSTEB(5, 0, 0, 0),
                                        child: Text(
                                          itemName,
                                          textAlign: TextAlign.start,
                                          overflow: TextOverflow.ellipsis,
                                          style: FlutterFlowTheme.of(context)
                                              .bodyMedium
                                              .override(
                                                fontFamily:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyMediumFamily,
                                                letterSpacing: 0.0,
                                                useGoogleFonts: !FlutterFlowTheme
                                                        .of(context)
                                                    .bodyMediumIsCustom,
                                              ),
                                        ),
                                      ),
                                    ),
                                    InkWell(
                                      splashColor: Colors.transparent,
                                      focusColor: Colors.transparent,
                                      hoverColor: Colors.transparent,
                                      highlightColor: Colors.transparent,
                                      onTap: () async {
                                        await widget.onRemoveTapped
                                            ?.call(feeditemItem);
                                      },
                                      child: const Icon(
                                        Icons.delete_outline,
                                        color: Color(0xFFFF0000),
                                        size: 28.0,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Video player area — always 210px tall
                              SizedBox(
                                width: panelWidth,
                                height: 210.0,
                                child: itemUrl.isNotEmpty
                                    ? custom_widgets.HlsPlayer(
                                        key: ValueKey('hls-$itemId'),
                                        width: panelWidth,
                                        height: 210.0,
                                        hlsUrl: itemUrl,
                                        streamName: itemId,
                                      )
                                    : Container(
                                        color: Colors.black,
                                        alignment: Alignment.center,
                                        child: const Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.videocam_off,
                                                color: Colors.white54,
                                                size: 32),
                                            SizedBox(height: 8),
                                            Text('No stream URL',
                                                style: TextStyle(
                                                    color: Colors.white54,
                                                    fontSize: 12)),
                                          ],
                                        ),
                                      ),
                              ),
                              const Divider(height: 1, color: Color(0xFFE5E7EB)),
                            ],
                          );
                        },
                      );
                    },
                  ),
                  // Close / back button pinned to top
                  Positioned(
                    top: 20,
                    left: 20,
                    child: InkWell(
                      splashColor: Colors.transparent,
                      focusColor: Colors.transparent,
                      hoverColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      onTap: () async {
                        await widget.onClose?.call();
                      },
                      child: Icon(
                        Icons.arrow_back,
                        color: FlutterFlowTheme.of(context).primaryText,
                        size: 34.0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
