import '/utils/flutter_flow_theme.dart';
import '/utils/flutter_flow_util.dart';
import 'addnewcamera_widget.dart' show AddnewcameraWidget;
import 'package:flutter/material.dart';

class AddnewcameraModel extends FlutterFlowModel<AddnewcameraWidget> {
  ///  State fields for stateful widgets in this component.

  final formKey = GlobalKey<FormState>();

  // Name
  FocusNode? textFieldFocusNode1;
  TextEditingController? textController1;
  String? Function(BuildContext, String?)? textController1Validator;

  // LatLong
  FocusNode? textFieldFocusNode2;
  TextEditingController? textController2;
  String? Function(BuildContext, String?)? textController2Validator;

  // Address
  FocusNode? textFieldFocusNode3;
  TextEditingController? textController3;
  String? Function(BuildContext, String?)? textController3Validator;

  // RTSP URL (optional)
  FocusNode? textFieldFocusNode4;
  TextEditingController? textController4;
  String? Function(BuildContext, String?)? textController4Validator;

  // Categories (comma-separated input)
  FocusNode? textFieldFocusNode5;
  TextEditingController? textController5;
  String? Function(BuildContext, String?)? textController5Validator;

  // Loading/submitting state
  bool isSubmitting = false;

  @override
  void initState(BuildContext context) {
    textController1 ??= TextEditingController();
    textFieldFocusNode1 ??= FocusNode();

    textController2 ??= TextEditingController();
    textFieldFocusNode2 ??= FocusNode();

    textController3 ??= TextEditingController();
    textFieldFocusNode3 ??= FocusNode();

    textController4 ??= TextEditingController();
    textFieldFocusNode4 ??= FocusNode();

    textController5 ??= TextEditingController();
    textFieldFocusNode5 ??= FocusNode();
  }

  @override
  void dispose() {
    textFieldFocusNode1?.dispose();
    textController1?.dispose();

    textFieldFocusNode2?.dispose();
    textController2?.dispose();

    textFieldFocusNode3?.dispose();
    textController3?.dispose();

    textFieldFocusNode4?.dispose();
    textController4?.dispose();

    textFieldFocusNode5?.dispose();
    textController5?.dispose();
  }

  /// Build the JSON body to POST to the API
  Map<String, dynamic> toJson() {
    final categoriesRaw = textController5?.text.trim() ?? '';
    final categories = categoriesRaw.isEmpty
        ? <String>[]
        : categoriesRaw.split(',').map((e) => e.trim()).toList();

    return {
      'name': textController1?.text.trim() ?? '',
      'latLong': textController2?.text.trim().isEmpty == true
          ? null
          : textController2?.text.trim(),
      'address': textController3?.text.trim() ?? '',
      'status': null,
      'categories': categories.isEmpty ? null : categories,
      'lastSeen': null,
      // rtspUrl is extra metadata – include if your API supports it
      if ((textController4?.text.trim() ?? '').isNotEmpty)
        'rtspUrl': textController4!.text.trim(),
    };
  }
}