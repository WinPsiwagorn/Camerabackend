import '/presentation/widgets/camera/views/addnewcamera_widget.dart';
import '/presentation/widgets/nav/views/nav_bar_main_widget.dart';
import '/utils/flutter_flow/theme.dart';
import '/utils/flutter_flow/util.dart';
import 'dart:ui';
import 'list_camera_page_widget.dart' show ListCameraPageWidget;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class ListCameraPageModel extends FlutterFlowModel<ListCameraPageWidget> {
  ///  Local state fields for this page.

  // All cameras on current page (fetched from API)
  List<dynamic> listOFcamera = [];

  // Stats
  int totalCameras = 0;
  int onlineCameras = 0;
  int offlineCameras = 0;

  // Pagination
  int currentPage = 1;
  int totalPages = 1;
  static const int pageSize = 10;
  bool isLoading = false;

  // Search
  String searchQuery = '';

  ///  State fields for stateful widgets in this page.

  // Model for NavBarMain component.
  late NavBarMainModel navBarMainModel;

  // State field(s) for searchBar widget.
  FocusNode? searchBarFocusNode;
  TextEditingController? searchBarTextController;
  String? Function(BuildContext, String?)? searchBarTextControllerValidator;

  @override
  void initState(BuildContext context) {
    navBarMainModel = createModel(context, () => NavBarMainModel());
    searchBarTextController ??= TextEditingController();
    searchBarFocusNode ??= FocusNode();
  }

  @override
  void dispose() {
    navBarMainModel.dispose();
    searchBarFocusNode?.dispose();
    searchBarTextController?.dispose();
  }
}