import '/utils/flutter_flow/theme.dart';
import '/utils/flutter_flow/util.dart';
import '/utils/flutter_flow/widgets.dart';
import '/presentation/widgets/index.dart' as custom_widgets;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/map_view_component_model.dart';
export '../models/map_view_component_model.dart';

class MapViewComponentWidget extends StatefulWidget {
  const MapViewComponentWidget({
    super.key,
    required this.initialLatitude,
    required this.initialLongitude,
    required this.initialZoom,
    required this.onMarkerTappedCallback,
    required this.componentCameraDocs,
  });

  final double? initialLatitude;
  final double? initialLongitude;
  final double? initialZoom;
  final Future Function(dynamic tappedCamera)? onMarkerTappedCallback;
  final List<dynamic>? componentCameraDocs;

  @override
  State<MapViewComponentWidget> createState() => _MapViewComponentWidgetState();
}

class _MapViewComponentWidgetState extends State<MapViewComponentWidget> {
  late MapViewComponentModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => MapViewComponentModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.sizeOf(context).width * 1.0,
      height: MediaQuery.sizeOf(context).height * 1.0,
      child: custom_widgets.InteractiveMap(
        width: MediaQuery.sizeOf(context).width * 1.0,
        height: MediaQuery.sizeOf(context).height * 1.0,
        initialZoom: widget!.initialZoom!,
        cameraDocs: widget!.componentCameraDocs!,
        onMarkerTap: (tappedCamera) async {
          await widget.onMarkerTappedCallback?.call(
            tappedCamera,
          );
        },
      ),
    );
  }
}
