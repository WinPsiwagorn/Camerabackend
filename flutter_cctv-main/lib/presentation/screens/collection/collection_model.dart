import '/data/services/index.dart';
import '/presentation/widgets/nav_bar_main_widget.dart';
import '/utils/flutter_flow_data_table.dart';
import '/utils/flutter_flow_icon_button.dart';
import '/utils/flutter_flow_theme.dart';
import '/utils/flutter_flow_util.dart';
import '/utils/flutter_flow_widgets.dart';
import 'dart:ui';
import 'collection_widget.dart' show CollectionWidget;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:text_search/text_search.dart';

class CollectionModel extends FlutterFlowModel<CollectionWidget> {
  ///  Local state fields for this page.

  bool? isMenuOpen;

  bool filterAssignedCategory = false;
  
  bool filterUnassignedCategory = false;

  Map<String, bool> expandedCategories = {};

  List<String> selectedCameras = [];
  void addToSelectedCameras(String item) => selectedCameras.add(item);
  void removeFromSelectedCameras(String item) => selectedCameras.remove(item);
  void removeAtIndexFromSelectedCameras(int index) =>
      selectedCameras.removeAt(index);
  void insertAtIndexInSelectedCameras(int index, String item) =>
      selectedCameras.insert(index, item);
  void updateSelectedCamerasAtIndex(int index, Function(String) updateFn) =>
      selectedCameras[index] = updateFn(selectedCameras[index]);

  // Pagination state
  List<dynamic> listOfCameras = [];
  int currentPage = 1;
  int totalPages = 1;
  int totalCameras = 0;
  static const int pageSize = 10;
  bool isLoading = false;
  String searchQuery = '';

  ///  State fields for stateful widgets in this page.

  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode;
  TextEditingController? textController;
  String? Function(BuildContext, String?)? textControllerValidator;
  // Stores action output result for [Backend Call - API (Get Camera)] action in search.
  ApiCallResponse? apiResultSearch;
  // Stores action output result for [Backend Call - API (Add Category to Camera)] action in Button widget.
  ApiCallResponse? apiResultvxw;
  // Stores action output result for [Backend Call - API (Get Camera)] action in Button widget.
  ApiCallResponse? apiResult7uc;
  // State field(s) for PaginatedDataTable widget.
  final paginatedDataTableController =
      FlutterFlowDataTableController<dynamic>();

  // Model for NavBarMain component.
  late NavBarMainModel navBarMainModel;

  @override
  void initState(BuildContext context) {
    navBarMainModel = createModel(context, () => NavBarMainModel());
  }

  @override
  void dispose() {
    textFieldFocusNode?.dispose();
    textController?.dispose();

    paginatedDataTableController.dispose();
    navBarMainModel.dispose();
  }
}
