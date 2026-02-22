import '/presentation/widgets/nav_bar_main_widget.dart';
import '/utils/flutter_flow_util.dart';
import 'searchlicenseplate_widget.dart' show ListPlatePageWidget;
import 'package:flutter/material.dart';

class ListPlatePageModel extends FlutterFlowModel<ListPlatePageWidget> {
  // Data
  List<Map<String, dynamic>> listOfPlates = [];

  // Pagination
  int currentPage = 1;
  int totalPages = 1;
  int totalItems = 0;
  static const int pageSize = 10;

  // State
  bool isLoading = false;
  String searchQuery = '';

  // NavBar
  late NavBarMainModel navBarMainModel;

  // Search bar
  late TextEditingController searchBarController;
  FocusNode? searchBarFocusNode;

  @override
  void initState(BuildContext context) {
    navBarMainModel = createModel(context, () => NavBarMainModel());
    searchBarController = TextEditingController();
    searchBarFocusNode = FocusNode();
  }

  @override
  void dispose() {
    navBarMainModel.dispose();
    searchBarController.dispose();
    searchBarFocusNode?.dispose();
  }
}