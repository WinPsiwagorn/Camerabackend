import '/presentation/widgets/map/views/map_view_component_widget.dart';
import '/presentation/widgets/map/views/marker_info_popup_widget.dart';
import '/presentation/widgets/nav/views/nav_bar_main_widget.dart';
import '/presentation/widgets/camera/views/preview_overlay_widget.dart';
import '/utils/flutter_flow/theme.dart';
import '/utils/flutter_flow/util.dart';
import '/utils/flutter_flow/widgets.dart';
import 'dart:ui';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'map_view_model.dart';
export 'map_view_model.dart';

class MapViewWidget extends StatefulWidget {
  const MapViewWidget({super.key});

  static String routeName = 'MapView';
  static String routePath = '/mapView';

  @override
  State<MapViewWidget> createState() => _MapViewWidgetState();
}

class _MapViewWidgetState extends State<MapViewWidget> {
  late MapViewModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => MapViewModel());

    // On page load action.
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      _model.cameraDocuments = [];
      // TODO: Replace with CameraRepository().getCameras()
      // Previously: _model.cameraListFromFB = await queryCamerasRecordOnce();
      _model.cameraListFromFB = [];
      _model.cameraDocuments =
          _model.cameraDocuments.toList().cast<dynamic>();
      safeSetState(() {});
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: Colors.white,
        appBar: PreferredSize(
          preferredSize:
              Size.fromHeight(MediaQuery.sizeOf(context).height * 0.05),
          child: AppBar(
            backgroundColor: Colors.white,
            automaticallyImplyLeading: false,
            title: wrapWithModel(
              model: _model.navBarMainModel,
              updateCallback: () => safeSetState(() {}),
              child: NavBarMainWidget(),
            ),
            actions: [],
            centerTitle: false,
            elevation: 2.0,
          ),
        ),
        body: SafeArea(
          top: true,
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              Flexible(
                child: SafeArea(
                  child: Container(
                    width: MediaQuery.sizeOf(context).width * 1.0,
                    height: MediaQuery.sizeOf(context).height * 1.0,
                    decoration: BoxDecoration(
                      color: Colors.black,
                    ),
                    child: Container(
                      width: MediaQuery.sizeOf(context).width * 1.0,
                      height: 100.0,
                      child: Stack(
                        children: [
                          Stack(
                            children: [
                              Align(
                                alignment: AlignmentDirectional(0.0, 0.0),
                                child: wrapWithModel(
                                  model: _model.mapViewComponentModel,
                                  updateCallback: () => safeSetState(() {}),
                                  child: MapViewComponentWidget(
                                    initialLatitude: 19.9105,
                                    initialLongitude: 99.8406,
                                    initialZoom: 16.0,
                                    componentCameraDocs: _model.cameraDocuments,
                                    onMarkerTappedCallback:
                                        (tappedCamera) async {
                                      showModalBottomSheet(
                                        isScrollControlled: true,
                                        backgroundColor: Colors.transparent,
                                        enableDrag: false,
                                        context: context,
                                        builder: (context) {
                                          return GestureDetector(
                                            onTap: () {
                                              FocusScope.of(context).unfocus();
                                              FocusManager.instance.primaryFocus
                                                  ?.unfocus();
                                            },
                                            child: Padding(
                                              padding: MediaQuery.viewInsetsOf(
                                                  context),
                                              child: MarkerInfoPopupWidget(
                                                cameraData: tappedCamera,
                                                onCloseTapped: () async {
                                                  Navigator.pop(context);
                                                },
                                                onLiveFeedTapped: (streamUrl,
                                                    cameraDoc) async {
                                                  _model.addToPreviewList(
                                                      cameraDoc);
                                                  safeSetState(() {});
                                                },
                                              ),
                                            ),
                                          );
                                        },
                                      ).then((value) => safeSetState(() {}));
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if ((_model.previewList.isNotEmpty) == true)
                            Align(
                              alignment: AlignmentDirectional(-1.0, 0.0),
                              child: wrapWithModel(
                                model: _model.previewOverlayModel,
                                updateCallback: () => safeSetState(() {}),
                                child: PreviewOverlayWidget(
                                  cameraList: _model.previewList,
                                  onClose: () async {
                                    _model.previewList = [];
                                    safeSetState(() {});
                                  },
                                  onRemoveTapped: (cameraToRemove) async {
                                    _model
                                        .removeFromPreviewList(cameraToRemove);
                                    safeSetState(() {});
                                  },
                                ),
                              ),
                            ),
                        ],
                      ),
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
}
