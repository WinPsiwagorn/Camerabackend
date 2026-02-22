import '/presentation/widgets/map/views/map_view_component_widget.dart';
import '/presentation/widgets/map/views/marker_info_popup_widget.dart';
import '/presentation/widgets/nav/views/nav_bar_main_widget.dart';
import '/presentation/widgets/camera/views/preview_overlay_widget.dart';
import '/utils/flutter_flow/theme.dart';
import '/utils/flutter_flow/util.dart';
import '/utils/flutter_flow/widgets.dart';
import 'dart:ui';
import 'map_view_widget.dart' show MapViewWidget;
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class MapViewModel extends FlutterFlowModel<MapViewWidget> {
  ///  Local state fields for this page.

  List<String> activeCctvFeeds = [];
  void addToActiveCctvFeeds(String item) => activeCctvFeeds.add(item);
  void removeFromActiveCctvFeeds(String item) => activeCctvFeeds.remove(item);
  void removeAtIndexFromActiveCctvFeeds(int index) =>
      activeCctvFeeds.removeAt(index);
  void insertAtIndexInActiveCctvFeeds(int index, String item) =>
      activeCctvFeeds.insert(index, item);
  void updateActiveCctvFeedsAtIndex(int index, Function(String) updateFn) =>
      activeCctvFeeds[index] = updateFn(activeCctvFeeds[index]);

  List<dynamic> cameraDocuments = [];
  void addToCameraDocuments(dynamic item) => cameraDocuments.add(item);
  void removeFromCameraDocuments(dynamic item) =>
      cameraDocuments.remove(item);
  void removeAtIndexFromCameraDocuments(int index) =>
      cameraDocuments.removeAt(index);
  void insertAtIndexInCameraDocuments(int index, dynamic item) =>
      cameraDocuments.insert(index, item);
  void updateCameraDocumentsAtIndex(
          int index, Function(dynamic) updateFn) =>
      cameraDocuments[index] = updateFn(cameraDocuments[index]);

  List<dynamic> previewList = [];
  void addToPreviewList(dynamic item) => previewList.add(item);
  void removeFromPreviewList(dynamic item) => previewList.remove(item);
  void removeAtIndexFromPreviewList(int index) => previewList.removeAt(index);
  void insertAtIndexInPreviewList(int index, dynamic item) =>
      previewList.insert(index, item);
  void updatePreviewListAtIndex(int index, Function(dynamic) updateFn) =>
      previewList[index] = updateFn(previewList[index]);

  ///  State fields for stateful widgets in this page.

  // Stores action output result for [Firestore Query - Query a collection] action in MapView widget.
  List<dynamic>? cameraListFromFB;
  // Model for MapViewComponent component.
  late MapViewComponentModel mapViewComponentModel;
  // Model for previewOverlay component.
  late PreviewOverlayModel previewOverlayModel;
  // Model for NavBarMain component.
  late NavBarMainModel navBarMainModel;

  @override
  void initState(BuildContext context) {
    mapViewComponentModel = createModel(context, () => MapViewComponentModel());
    previewOverlayModel = createModel(context, () => PreviewOverlayModel());
    navBarMainModel = createModel(context, () => NavBarMainModel());
  }

  @override
  void dispose() {
    mapViewComponentModel.dispose();
    previewOverlayModel.dispose();
    navBarMainModel.dispose();
  }
}
