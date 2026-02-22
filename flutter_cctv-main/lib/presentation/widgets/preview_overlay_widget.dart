import '/utils/flutter_flow_theme.dart';
import '/utils/flutter_flow_util.dart';
import '/utils/flutter_flow_widgets.dart';
import 'dart:ui';
import '/presentation/widgets/index.dart' as custom_widgets;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'preview_overlay_model.dart';
export 'preview_overlay_model.dart';

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
    return Stack(
      children: [
        Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            Container(
              width: MediaQuery.sizeOf(context).width * 0.3,
              height: MediaQuery.sizeOf(context).height * 1.0,
              decoration: BoxDecoration(
                color: Colors.white,
              ),
              child: Stack(
                children: [
                  Builder(
                    builder: (context) {
                      final feeditem =
                          widget!.cameraList!.toList().take(3).toList();

                      return ListView.builder(
                        padding: EdgeInsets.fromLTRB(
                          0,
                          80.0,
                          0,
                          0,
                        ),
                        shrinkWrap: true,
                        scrollDirection: Axis.vertical,
                        itemCount: feeditem.length,
                        itemBuilder: (context, feeditemIndex) {
                          final feeditemItem = feeditem[feeditemIndex];
                          return Column(
                            mainAxisSize: MainAxisSize.max,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    0.0, 0.0, 5.0, 0.0),
                                child: Row(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          5.0, 0.0, 0.0, 0.0),
                                      child: Text(
                                        feeditemItem.name,
                                        textAlign: TextAlign.start,
                                        style: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .override(
                                              fontFamily:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyMediumFamily,
                                              letterSpacing: 0.0,
                                              useGoogleFonts:
                                                  !FlutterFlowTheme.of(context)
                                                      .bodyMediumIsCustom,
                                            ),
                                      ),
                                    ),
                                    Align(
                                      alignment: AlignmentDirectional(1.0, 0.0),
                                      child: InkWell(
                                        splashColor: Colors.transparent,
                                        focusColor: Colors.transparent,
                                        hoverColor: Colors.transparent,
                                        highlightColor: Colors.transparent,
                                        onTap: () async {
                                          await widget.onRemoveTapped?.call(
                                            feeditemItem,
                                          );
                                        },
                                        child: Icon(
                                          Icons.delete_outline,
                                          color: Color(0xFFFF0000),
                                          size: 28.0,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.max,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  if (feeditemItem.url != null &&
                                      feeditemItem.url != '')
                                    Container(
                                      width: MediaQuery.sizeOf(context).width *
                                          0.3,
                                      height: 210.0,
                                      child: custom_widgets.HlsPlayer(
                                        width:
                                            MediaQuery.sizeOf(context).width *
                                                0.3,
                                        height: 210.0,
                                        hlsUrl: feeditemItem.url,
                                        streamName: feeditemItem.reference.id,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Wrap(
                        spacing: 0.0,
                        runSpacing: 0.0,
                        alignment: WrapAlignment.start,
                        crossAxisAlignment: WrapCrossAlignment.start,
                        direction: Axis.horizontal,
                        runAlignment: WrapAlignment.start,
                        verticalDirection: VerticalDirection.down,
                        clipBehavior: Clip.none,
                        children: [
                          Align(
                            alignment: AlignmentDirectional(1.0, -1.0),
                            child: Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                  20.0, 20.0, 0.0, 0.0),
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
                                  color:
                                      FlutterFlowTheme.of(context).primaryText,
                                  size: 34.0,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
