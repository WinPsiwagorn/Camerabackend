import '/presentation/widgets/nav/views/nav_bar_main_widget.dart';
import '/utils/flutter_flow/theme.dart';
import '/utils/flutter_flow/util.dart';
import '/utils/flutter_flow/widgets.dart';
import 'dart:ui';
import '/presentation/widgets/index.dart' as custom_widgets;
import 'command_view_widget.dart' show CommandViewWidget;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class CommandViewModel extends FlutterFlowModel<CommandViewWidget> {
  ///  Local state fields for this page.

  bool? isMenuOpen;

  ///  State fields for stateful widgets in this page.

  // Model for NavBarMain component.
  late NavBarMainModel navBarMainModel;

  @override
  void initState(BuildContext context) {
    navBarMainModel = createModel(context, () => NavBarMainModel());
  }

  @override
  void dispose() {
    navBarMainModel.dispose();
  }
}
