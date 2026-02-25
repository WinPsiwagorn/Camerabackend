import '/presentation/widgets/map/views/map_view_component_widget.dart';
import '/presentation/widgets/map/views/marker_info_popup_widget.dart';
import '/presentation/widgets/nav/views/nav_bar_main_widget.dart';
import '/presentation/widgets/camera/views/preview_overlay_widget.dart';
import '/data/repositories/camera_repository.dart';
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

    // On page load action - Load cameras from repository
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      await _loadCameras();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  /// Load cameras from repository
  Future<void> _loadCameras() async {
    safeSetState(() {
      _model.isLoading = true;
      _model.errorMessage = null;
    });

    try {
      final cameras = await CameraRepository().getCamerasForMap();
      
      // Calculate statistics
      _model.totalCameras = cameras.length;
      _model.onlineCameras = cameras.where((c) => c.status == 'online').length;
      _model.offlineCameras = cameras.where((c) => c.status == 'offline').length;
      
      // Convert CameraModel to dynamic for compatibility with existing widgets
      _model.cameraDocuments = cameras.map((camera) => {
        'id': camera.id,
        'name': camera.name,
        'latLong': camera.latLong,
        'address': camera.address,
        'rtspUrl': camera.rtspUrl,
        'status': camera.status,
        'categories': camera.categories,
      }).toList();
      
      safeSetState(() {
        _model.isLoading = false;
      });
    } catch (e) {
      safeSetState(() {
        _model.isLoading = false;
        _model.errorMessage = 'Failed to load cameras: ${e.toString()}';
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading cameras: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
    }
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
          child: Stack(
            children: [
              // Map Container
              Container(
                width: MediaQuery.sizeOf(context).width * 1.0,
                height: MediaQuery.sizeOf(context).height * 1.0,
                decoration: BoxDecoration(
                  color: Colors.black,
                ),
                child: Stack(
                  children: [
                    // Loading State
                    if (_model.isLoading)
                      Container(
                        color: Colors.black.withOpacity(0.7),
                        child: Center(
                          child: Container(
                            padding: EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 20,
                                        offset: Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CircularProgressIndicator(
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          Color(0xFF3B82F6),
                                        ),
                                        strokeWidth: 3,
                                      ),
                                      SizedBox(height: 20),
                                      Text(
                                        'Loading cameras...',
                                        style: TextStyle(
                                          color: Color(0xFF111827),
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'Please wait',
                                        style: TextStyle(
                                          color: Color(0xFF6B7280),
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          // Error State
                          if (!_model.isLoading && _model.errorMessage != null)
                            Container(
                              color: Colors.black.withOpacity(0.7),
                              child: Center(
                                child: Container(
                                  margin: EdgeInsets.all(32),
                                  padding: EdgeInsets.all(32),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 20,
                                        offset: Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Color(0xFFFEE2E2),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.error_outline,
                                          color: Color(0xFFDC2626),
                                          size: 48,
                                        ),
                                      ),
                                      SizedBox(height: 20),
                                      Text(
                                        'Error Loading Map',
                                        style: TextStyle(
                                          color: Color(0xFF111827),
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 12),
                                      Container(
                                        constraints: BoxConstraints(maxWidth: 400),
                                        child: Text(
                                          _model.errorMessage!,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Color(0xFF6B7280),
                                            fontSize: 14,
                                            height: 1.5,
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: 24),
                                      ElevatedButton.icon(
                                        onPressed: _loadCameras,
                                        icon: Icon(Icons.refresh, size: 20),
                                        label: Text(
                                          'Retry',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Color(0xFF3B82F6),
                                          foregroundColor: Colors.white,
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 32,
                                            vertical: 16,
                                          ),
                                          elevation: 2,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          // Empty State
                          if (!_model.isLoading && 
                              _model.errorMessage == null && 
                              _model.cameraDocuments.isEmpty)
                            Container(
                              color: Colors.black.withOpacity(0.7),
                              child: Center(
                                child: Container(
                                  margin: EdgeInsets.all(32),
                                  padding: EdgeInsets.all(32),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 20,
                                        offset: Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Color(0xFFF3F4F6),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.videocam_off_outlined,
                                          color: Color(0xFF6B7280),
                                          size: 48,
                                        ),
                                      ),
                                      SizedBox(height: 20),
                                      Text(
                                        'No Cameras Found',
                                        style: TextStyle(
                                          color: Color(0xFF111827),
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 12),
                                      Container(
                                        constraints: BoxConstraints(maxWidth: 400),
                                        child: Text(
                                          'There are no cameras configured yet. Add cameras to see them on the map.',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Color(0xFF6B7280),
                                            fontSize: 14,
                                            height: 1.5,
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: 24),
                                      ElevatedButton.icon(
                                        onPressed: _loadCameras,
                                        icon: Icon(Icons.refresh, size: 20),
                                        label: Text(
                                          'Refresh',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Color(0xFF3B82F6),
                                          foregroundColor: Colors.white,
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 32,
                                            vertical: 16,
                                          ),
                                          elevation: 2,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          // Map View
                          if (!_model.isLoading && 
                              _model.errorMessage == null && 
                              _model.cameraDocuments.isNotEmpty)
                            Stack(
                              children: [
                                Align(
                                  alignment: AlignmentDirectional(0.0, 0.0),
                                  child: wrapWithModel(
                                  model: _model.mapViewComponentModel,
                                  updateCallback: () => safeSetState(() {}),
                                  child: MapViewComponentWidget(
                                    initialLatitude: 19.9105, // Chiang Rai, Thailand
                                    initialLongitude: 99.8406,
                                    initialZoom: 13.0, // Wider view to see more of Chiang Rai
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
              // Floating Dashboard - Compact Design
              if (!_model.isLoading && _model.errorMessage == null)
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 16,
                          offset: Offset(0, 4),
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Total
                        _buildMiniBadge(
                          icon: Icons.camera_alt,
                          count: _model.totalCameras,
                          color: Color(0xFF3B82F6),
                        ),
                        SizedBox(width: 6),
                        // Online
                        _buildMiniBadge(
                          icon: Icons.check_circle,
                          count: _model.onlineCameras,
                          color: Color(0xFF10B981),
                        ),
                        SizedBox(width: 6),
                        // Offline
                        _buildMiniBadge(
                          icon: Icons.cancel,
                          count: _model.offlineCameras,
                          color: Color(0xFFEF4444),
                        ),
                        SizedBox(width: 8),
                        Container(
                          width: 1,
                          height: 20,
                          color: Color(0xFFE5E7EB),
                        ),
                        SizedBox(width: 8),
                        // Refresh button
                        InkWell(
                          onTap: _loadCameras,
                          borderRadius: BorderRadius.circular(6),
                          child: Padding(
                            padding: EdgeInsets.all(4),
                            child: Icon(
                              Icons.refresh,
                              size: 18,
                              color: Color(0xFF3B82F6),
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

  /// Build mini badge for stats
  Widget _buildMiniBadge({
    required IconData icon,
    required int count,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color,
          ),
          SizedBox(width: 3),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}
