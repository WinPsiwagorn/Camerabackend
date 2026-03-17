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
  dynamic _selectedCamera;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => MapViewModel());
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      await _loadCameras();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  Future<void> _loadCameras() async {
    safeSetState(() {
      _model.isLoading = true;
      _model.errorMessage = null;
    });

    try {
      final cameras = await CameraRepository().getCamerasForMap();

      _model.totalCameras = cameras.length;
      _model.onlineCameras = cameras.where((c) => c.status == 'online').length;
      _model.offlineCameras = cameras.where((c) => c.status == 'offline').length;

      _model.cameraDocuments = cameras.map((camera) => <String, dynamic>{
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
        _model.errorMessage = 'Failed to load cameras: $e';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading cameras: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  // ── helpers ──────────────────────────────────────────────────────────────

  Widget _stateOverlay({required Widget child}) => Container(
        color: Colors.black.withOpacity(0.7),
        alignment: Alignment.center,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: child,
          ),
        ),
      );

  ButtonStyle get _btnStyle => ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF3B82F6),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      );

  // ── states ────────────────────────────────────────────────────────────────

  Widget _loadingState() => _stateOverlay(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
              strokeWidth: 3,
            ),
            const SizedBox(height: 20),
            Text(
              'Loading cameras...',
              style: TextStyle(
                color: const Color(0xFF111827),
                fontSize: AppTextStyles.tableHeader,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please wait',
              style: TextStyle(
                color: const Color(0xFF6B7280),
                fontSize: AppTextStyles.labelSmall,
              ),
            ),
          ],
        ),
      );

  Widget _errorState() => _stateOverlay(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFFEE2E2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline,
                  color: Color(0xFFDC2626), size: 48),
            ),
            const SizedBox(height: 20),
            Text(
              'Error Loading Map',
              style: TextStyle(
                color: const Color(0xFF111827),
                fontSize: AppTextStyles.sectionTitle,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Text(
                _model.errorMessage ?? '',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color(0xFF6B7280),
                  fontSize: AppTextStyles.labelNormal,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadCameras,
              icon: const Icon(Icons.refresh, size: 20),
              label: Text('Retry',
                  style: TextStyle(
                      fontSize: AppTextStyles.labelNormal,
                      fontWeight: FontWeight.w600)),
              style: _btnStyle,
            ),
          ],
        ),
      );

  Widget _emptyState() => _stateOverlay(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFF3F4F6),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.videocam_off_outlined,
                  color: Color(0xFF6B7280), size: 48),
            ),
            const SizedBox(height: 20),
            Text(
              'No Cameras Found',
              style: TextStyle(
                color: const Color(0xFF111827),
                fontSize: AppTextStyles.sectionTitle,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Text(
                'There are no cameras configured yet. Add cameras to see them on the map.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color(0xFF6B7280),
                  fontSize: AppTextStyles.labelNormal,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadCameras,
              icon: const Icon(Icons.refresh, size: 20),
              label: Text('Refresh',
                  style: TextStyle(
                      fontSize: AppTextStyles.labelNormal,
                      fontWeight: FontWeight.w600)),
              style: _btnStyle,
            ),
          ],
        ),
      );

  Widget _mapView() => Stack(
        children: [
          // Full-size map
          Align(
            alignment: Alignment.center,
            child: wrapWithModel(
              model: _model.mapViewComponentModel,
              updateCallback: () => safeSetState(() {}),
              child: MapViewComponentWidget(
                initialLatitude: 19.9105,
                initialLongitude: 99.8406,
                initialZoom: 13.0,
                componentCameraDocs: _model.cameraDocuments,
                onMarkerTappedCallback: (tappedCamera) async {
                  safeSetState(() => _selectedCamera = tappedCamera);
                },
              ),
            ),
          ),
          // ── Camera info popup (no dialog barrier) ──────────────────────
          if (_selectedCamera != null)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => safeSetState(() => _selectedCamera = null),
              child: Align(
                alignment: Alignment.center,
                child: GestureDetector(
                  onTap: () {}, // absorb taps inside card
                  child: MarkerInfoPopupWidget(
                    cameraData: _selectedCamera,
                    onCloseTapped: () async =>
                        safeSetState(() => _selectedCamera = null),
                    onLiveFeedTapped: (streamUrl, cameraDoc) async {
                      _model.addToPreviewList(cameraDoc);
                      safeSetState(() => _selectedCamera = null);
                    },
                  ),
                ),
              ),
            ),

          // Preview panel
          if (_model.previewList.isNotEmpty)
            Align(
              alignment: AlignmentDirectional.centerStart,
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
                    _model.removeFromPreviewList(cameraToRemove);
                    safeSetState(() {});
                  },
                ),
              ),
            ),
        ],
      );

  Widget _miniBadge(IconData icon, int count, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 3),
            Text(
              '$count',
              style: TextStyle(
                fontSize: AppTextStyles.commandBody,
                fontWeight: FontWeight.bold,
                color: color,
                height: 1,
              ),
            ),
          ],
        ),
      );

  // ── build ─────────────────────────────────────────────────────────────────

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
          preferredSize: const Size.fromHeight(AppTextStyles.navBarHeight),
          child: AppBar(
            backgroundColor: Colors.white,
            automaticallyImplyLeading: false,
            title: wrapWithModel(
              model: _model.navBarMainModel,
              updateCallback: () => safeSetState(() {}),
              child: NavBarMainWidget(),
            ),
            actions: const [],
            centerTitle: false,
            elevation: 2.0,
          ),
        ),
        body: SafeArea(
          top: true,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  // ── map area (bounded) ──
                  SizedBox(
                    width: constraints.maxWidth,
                    height: constraints.maxHeight,
                    child: ColoredBox(
                      color: Colors.black,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (_model.isLoading) _loadingState(),
                          if (!_model.isLoading &&
                              _model.errorMessage != null)
                            _errorState(),
                          if (!_model.isLoading &&
                              _model.errorMessage == null &&
                              _model.cameraDocuments.isEmpty)
                            _emptyState(),
                          if (!_model.isLoading &&
                              _model.errorMessage == null &&
                              _model.cameraDocuments.isNotEmpty)
                            _mapView(),
                        ],
                      ),
                    ),
                  ),
                  // ── floating dashboard ──
                  if (!_model.isLoading && _model.errorMessage == null)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _miniBadge(Icons.camera_alt, _model.totalCameras,
                                const Color(0xFF3B82F6)),
                            const SizedBox(width: 6),
                            _miniBadge(Icons.check_circle,
                                _model.onlineCameras, const Color(0xFF10B981)),
                            const SizedBox(width: 6),
                            _miniBadge(Icons.cancel, _model.offlineCameras,
                                const Color(0xFFEF4444)),
                            const SizedBox(width: 8),
                            Container(
                                width: 1,
                                height: 20,
                                color: const Color(0xFFE5E7EB)),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: _loadCameras,
                              borderRadius: BorderRadius.circular(6),
                              child: const Padding(
                                padding: EdgeInsets.all(4),
                                child: Icon(Icons.refresh,
                                    size: 18, color: Color(0xFF3B82F6)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}