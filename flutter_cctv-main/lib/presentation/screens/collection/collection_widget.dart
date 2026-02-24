import '/data/services/index.dart';
import '/presentation/widgets/nav_bar_main_widget.dart';
import '/presentation/widgets/shared/category_chip.dart';
import '/utils/flutter_flow_data_table.dart';
import '/utils/flutter_flow_icon_button.dart';
import '/utils/flutter_flow_theme.dart';
import '/utils/flutter_flow_util.dart';
import '/utils/flutter_flow_widgets.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:text_search/text_search.dart';
import 'collection_model.dart';
export 'collection_model.dart';

class CollectionWidget extends StatefulWidget {
  const CollectionWidget({super.key});

  static String routeName = 'Collection';
  static String routePath = '/Collection';

  @override
  State<CollectionWidget> createState() => _CollectionWidgetState();
}

class _CollectionWidgetState extends State<CollectionWidget> {
  late CollectionModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => CollectionModel());

    _model.textController ??= TextEditingController();
    _model.textFieldFocusNode ??= FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  /// Fixed palette of background/text color pairs for category chips.
  static const List<_ChipColor> _chipPalette = [
    _ChipColor(bg: Color(0xFFEDE9FE), text: Color(0xFF5B21B6)), // violet
    _ChipColor(bg: Color(0xFFDBEAFE), text: Color(0xFF1D4ED8)), // blue
    _ChipColor(bg: Color(0xFFD1FAE5), text: Color(0xFF065F46)), // green
    _ChipColor(bg: Color(0xFFFEF3C7), text: Color(0xFF92400E)), // amber
  ];

  /// Returns a consistent color for a given category name.
  _ChipColor _colorFor(String name) {
    final idx = name.codeUnits.fold(0, (a, b) => a + b) % _chipPalette.length;
    return _chipPalette[idx];
  }

  Widget _buildCategoryChips(dynamic item) {
  final cats = getJsonField(item, r'$.categories');
  if (cats == null || (cats is List && cats.isEmpty)) {
    return const SizedBox.shrink();
  }
  final list = cats is List ? cats : [cats];
  final names = list
      .map((c) {
        if (c is Map) return c['name']?.toString() ?? '';
        return c.toString();
      })
      .where((n) => n.isNotEmpty)
      .toList();
  if (names.isEmpty) {
    return const SizedBox.shrink();
  }
  return Wrap(
    spacing: 6,
    runSpacing: 6,
    children: names.map((name) {
      return CategoryChip(
        name: name,
        fontSize: AppTextStyles.tableStatus, // หรือ 14
      );
    }).toList(),
  );
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
        body: NestedScrollView(
          floatHeaderSlivers: true,
          physics: NeverScrollableScrollPhysics(),
          headerSliverBuilder: (context, _) => [
            SliverAppBar(
              pinned: true,
              floating: true,
              backgroundColor: Colors.white,
              iconTheme: IconThemeData(color: Color(0xFFD6C6C6)),
              automaticallyImplyLeading: false,
              title: wrapWithModel(
                model: _model.navBarMainModel,
                updateCallback: () => safeSetState(() {}),
                child: NavBarMainWidget(),
              ),
              actions: [],
              centerTitle: true,
              elevation: 0.0,
            )
          ],
          body: Builder(
            builder: (context) {
              return SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Search bar and action buttons row
                    Center(
                      child: Container(
                        width: double.infinity,
                        constraints: BoxConstraints(maxWidth: 1680.0),
                        padding: EdgeInsetsDirectional.fromSTEB(
                            60.0, 8.0, 60.0, 8.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    0.0, 0.0, 20.0, 0.0),
                                child: TextFormField(
                                  controller: _model.textController,
                                  focusNode: _model.textFieldFocusNode,
                                  onFieldSubmitted: (_) async {
                                    // Perform search using text field value
                                    if (_model.textController.text.isNotEmpty) {
                                      _model.apiResultSearch =
                                          await CameraService().getCameras(limit: '100');

                                      if (_model.apiResultSearch?.succeeded ??
                                          false) {
                                        final allCameras = CameraService()
                                            .parseDataList(_model
                                                .apiResultSearch!.jsonBody);
                                        final searchTerm = _model
                                            .textController.text
                                            .toLowerCase();

                                        _model.simpleSearchResults = allCameras
                                                ?.where((camera) {
                                              final name = getJsonField(
                                                      camera, r'$.name')
                                                  .toString()
                                                  .toLowerCase();
                                              final address = getJsonField(
                                                      camera, r'$.address')
                                                  .toString()
                                                  .toLowerCase();
                                              final status = getJsonField(
                                                      camera, r'$.status')
                                                  .toString()
                                                  .toLowerCase();
                                              final categories = getJsonField(
                                                      camera, r'$.categories')
                                                  .toString()
                                                  .toLowerCase();
                                              return name
                                                      .contains(searchTerm) ||
                                                  address
                                                      .contains(searchTerm) ||
                                                  status.contains(searchTerm) ||
                                                  categories
                                                      .contains(searchTerm);
                                            }).toList() ??
                                            [];

                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Row(
                                              children: [
                                                Icon(Icons.check_circle,
                                                    color: Colors.white),
                                                SizedBox(width: 8.0),
                                                Text(
                                                    'Found ${_model.simpleSearchResults.length} camera(s)'),
                                              ],
                                            ),
                                            duration:
                                                Duration(milliseconds: 2000),
                                            backgroundColor: Color(0xFF39D2C0),
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                      } else {
                                        safeSetState(() {
                                          _model.simpleSearchResults = [];
                                        });
                                      }
                                    } else {
                                      safeSetState(() {
                                        _model.simpleSearchResults = [];
                                      });
                                    }
                                  },
                                  autofocus: false,
                                  enabled: true,
                                  obscureText: false,
                                  decoration: InputDecoration(
                                    isDense: true,
                                    labelStyle: FlutterFlowTheme.of(context)
                                        .labelMedium
                                        .override(
                                          fontFamily:
                                              FlutterFlowTheme.of(context)
                                                  .labelMediumFamily,
                                          letterSpacing: 0.0,
                                          useGoogleFonts:
                                              !FlutterFlowTheme.of(context)
                                                  .labelMediumIsCustom,
                                        ),
                                    hintText:
                                        'Search cameras by name, address, status, or categories...',
                                    hintStyle: FlutterFlowTheme.of(context)
                                        .labelMedium
                                        .override(
                                          fontFamily:
                                              FlutterFlowTheme.of(context)
                                                  .labelMediumFamily,
                                          letterSpacing: 0.0,
                                          useGoogleFonts:
                                              !FlutterFlowTheme.of(context)
                                                  .labelMediumIsCustom,
                                        ),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Colors.black,
                                        width: 1.0,
                                      ),
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Color(0x00000000),
                                        width: 1.0,
                                      ),
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color:
                                            FlutterFlowTheme.of(context).error,
                                        width: 1.0,
                                      ),
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    focusedErrorBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color:
                                            FlutterFlowTheme.of(context).error,
                                        width: 1.0,
                                      ),
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    filled: true,
                                    fillColor: FlutterFlowTheme.of(context)
                                        .secondaryBackground,
                                  ),
                                  style: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .override(
                                        fontFamily: FlutterFlowTheme.of(context)
                                            .bodyMediumFamily,
                                        letterSpacing: 0.0,
                                        useGoogleFonts:
                                            !FlutterFlowTheme.of(context)
                                                .bodyMediumIsCustom,
                                      ),
                                  cursorColor:
                                      FlutterFlowTheme.of(context).primaryText,
                                  enableInteractiveSelection: true,
                                  validator: _model.textControllerValidator
                                      .asValidator(context),
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                  0.0, 0.0, 12.0, 0.0),
                              child: FlutterFlowIconButton(
                                borderColor: Color(0xFF4B39EF),
                                borderRadius: 12.0,
                                borderWidth: 2.0,
                                buttonSize: 50.0,
                                fillColor: Color(0xFFE0E3E7),
                                icon: Icon(
                                  Icons.filter_list_rounded,
                                  color: Color(0xFF4B39EF),
                                  size: 26.0,
                                ),
                                onPressed: () async {
                                  // Show filter dialog
                                  await showDialog(
                                    context: context,
                                    builder: (BuildContext dialogContext) {
                                      return StatefulBuilder(
                                        builder: (context, setDialogState) {
                                          return AlertDialog(
                                            title: Row(
                                              children: [
                                                Icon(Icons.filter_list_rounded,
                                                    color: Color(0xFF4B39EF)),
                                                SizedBox(width: 8.0),
                                                Text('Filter Cameras'),
                                              ],
                                            ),
                                            content: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text('Filter by Category',
                                                    style: FlutterFlowTheme.of(
                                                            context)
                                                        .bodyLarge
                                                        .override(
                                                          fontFamily:
                                                              'Readex Pro',
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        )),
                                                SizedBox(height: 8.0),
                                                CheckboxListTile(
                                                  title: Row(
                                                    children: [
                                                      Icon(
                                                          Icons
                                                              .label_outlined,
                                                          size: 20.0,
                                                          color: Color(
                                                              0xFF39D2C0)),
                                                      SizedBox(width: 8.0),
                                                      Text(
                                                          'Cameras with Categories'),
                                                    ],
                                                  ),
                                                  subtitle: Text(
                                                      'Show only cameras assigned to categories',
                                                      style: FlutterFlowTheme
                                                              .of(context)
                                                          .bodySmall),
                                                  value: _model
                                                      .filterAssignedCategory,
                                                  onChanged: (value) {
                                                    setDialogState(() {
                                                      _model.filterAssignedCategory =
                                                          value ?? false;
                                                      // If both are selected, deselect the other
                                                      if (_model
                                                              .filterAssignedCategory &&
                                                          _model
                                                              .filterUnassignedCategory) {
                                                        _model.filterUnassignedCategory =
                                                            false;
                                                      }
                                                    });
                                                  },
                                                  activeColor:
                                                      Color(0xFF39D2C0),
                                                  controlAffinity:
                                                      ListTileControlAffinity
                                                          .leading,
                                                ),
                                                CheckboxListTile(
                                                  title: Row(
                                                    children: [
                                                      Icon(
                                                          Icons
                                                              .label_off_outlined,
                                                          size: 20.0,
                                                          color: Color(
                                                              0xFFFF5963)),
                                                      SizedBox(width: 8.0),
                                                      Text(
                                                          'Cameras without Categories'),
                                                    ],
                                                  ),
                                                  subtitle: Text(
                                                      'Show only cameras not assigned to any category',
                                                      style: FlutterFlowTheme
                                                              .of(context)
                                                          .bodySmall),
                                                  value: _model
                                                      .filterUnassignedCategory,
                                                  onChanged: (value) {
                                                    setDialogState(() {
                                                      _model.filterUnassignedCategory =
                                                          value ?? false;
                                                      // If both are selected, deselect the other
                                                      if (_model
                                                              .filterUnassignedCategory &&
                                                          _model
                                                              .filterAssignedCategory) {
                                                        _model.filterAssignedCategory =
                                                            false;
                                                      }
                                                    });
                                                  },
                                                  activeColor:
                                                      Color(0xFFFF5963),
                                                  controlAffinity:
                                                      ListTileControlAffinity
                                                          .leading,
                                                ),
                                              ],
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () {
                                                  // Reset filters
                                                  safeSetState(() {
                                                    _model.filterAssignedCategory =
                                                        false;
                                                    _model.filterUnassignedCategory =
                                                        false;
                                                  });
                                                  Navigator.pop(dialogContext);
                                                },
                                                child: Text('Clear'),
                                              ),
                                              ElevatedButton(
                                                onPressed: () {
                                                  Navigator.pop(dialogContext);
                                                  safeSetState(() {});
                                                  
                                                  String filterMessage = '';
                                                  if (_model
                                                      .filterAssignedCategory) {
                                                    filterMessage =
                                                        'Showing cameras with categories';
                                                  } else if (_model
                                                      .filterUnassignedCategory) {
                                                    filterMessage =
                                                        'Showing cameras without categories';
                                                  } else {
                                                    filterMessage =
                                                        'Showing all cameras';
                                                  }
                                                  
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    SnackBar(
                                                      content: Row(
                                                        children: [
                                                          Icon(
                                                              Icons
                                                                  .filter_list_rounded,
                                                              color:
                                                                  Colors.white),
                                                          SizedBox(width: 8.0),
                                                          Text(filterMessage),
                                                        ],
                                                      ),
                                                      backgroundColor:
                                                          Color(0xFF4B39EF),
                                                      behavior: SnackBarBehavior
                                                          .floating,
                                                    ),
                                                  );
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      Color(0xFF4B39EF),
                                                ),
                                                child: Text('Apply'),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                            Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                  0.0, 0.0, 12.0, 0.0),
                              child: FlutterFlowIconButton(
                                borderColor: Color(0xFF39D2C0),
                                borderRadius: 12.0,
                                borderWidth: 2.0,
                                buttonSize: 50.0,
                                fillColor: Color(0xFFE0F2F1),
                                icon: Icon(
                                  Icons.search_rounded,
                                  color: Color(0xFF39D2C0),
                                  size: 26.0,
                                ),
                                onPressed: () async {
                                  if (_model.textController.text.isNotEmpty) {
                                    _model.apiResultSearch =
                                        await CameraService().getCameras(limit: '100');

                                    if (_model.apiResultSearch?.succeeded ??
                                        false) {
                                      final allCameras = CameraService()
                                          .parseDataList(
                                              _model.apiResultSearch!.jsonBody);
                                      final searchTerm = _model
                                          .textController.text
                                          .toLowerCase();

                                      _model.simpleSearchResults = allCameras
                                              ?.where((camera) {
                                            final name =
                                                getJsonField(camera, r'$.name')
                                                    .toString()
                                                    .toLowerCase();
                                            final address = getJsonField(
                                                    camera, r'$.address')
                                                .toString()
                                                .toLowerCase();
                                            final status = getJsonField(
                                                    camera, r'$.status')
                                                .toString()
                                                .toLowerCase();
                                            final categories = getJsonField(
                                                    camera, r'$.categories')
                                                .toString()
                                                .toLowerCase();
                                            return name.contains(searchTerm) ||
                                                address.contains(searchTerm) ||
                                                status.contains(searchTerm) ||
                                                categories.contains(searchTerm);
                                          }).toList() ??
                                          [];

                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Row(
                                            children: [
                                              Icon(Icons.check_circle,
                                                  color: Colors.white),
                                              SizedBox(width: 8.0),
                                              Text(
                                                  'Found ${_model.simpleSearchResults.length} camera(s)'),
                                            ],
                                          ),
                                          duration:
                                              Duration(milliseconds: 2500),
                                          backgroundColor: Color(0xFF39D2C0),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    } else {
                                      _model.simpleSearchResults = [];
                                    }
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Row(
                                          children: [
                                            Icon(Icons.info_outline,
                                                color: Colors.white),
                                            SizedBox(width: 8.0),
                                            Text('Please enter a search term'),
                                          ],
                                        ),
                                        duration: Duration(milliseconds: 2000),
                                        backgroundColor: Color(0xFFFF5963),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                  safeSetState(() {});
                                },
                              ),
                            ),
                            Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                  0.0, 0.0, 12.0, 0.0),
                              child: FlutterFlowIconButton(
                                borderColor: Color(0xFFFF5963),
                                borderRadius: 12.0,
                                borderWidth: 2.0,
                                buttonSize: 50.0,
                                fillColor: Color(0xFFFFEBEE),
                                icon: Icon(
                                  Icons.clear_all_rounded,
                                  color: Color(0xFFFF5963),
                                  size: 26.0,
                                ),
                                onPressed: () async {
                                  // Clear search and reset to show all cameras
                                  safeSetState(() {
                                    _model.textController?.clear();
                                    _model.simpleSearchResults = [];
                                  });

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Row(
                                        children: [
                                          Icon(Icons.refresh_rounded,
                                              color: Colors.white),
                                          SizedBox(width: 8.0),
                                          Text(
                                              'Search cleared, showing all cameras'),
                                        ],
                                      ),
                                      duration: Duration(milliseconds: 2000),
                                      backgroundColor: Color(0xFF6C757D),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                              ),
                            ),
                            Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                  0.0, 0.0, 12.0, 0.0),
                              child: FFButtonWidget(
                                onPressed: () async {
                                  // Show comprehensive category management dialog
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext dialogContext) {
                                      // State for the dialog
                                      Map<String, bool> expandedMap = {};
                                      Map<String, List<dynamic>> categoryCameras = {};
                                      
                                      return StatefulBuilder(
                                        builder: (context, setDialogState) {
                                          return FutureBuilder<ApiCallResponse>(
                                            future: CategoryService().getCategories(limit: '100'),
                                            builder: (context, snapshot) {
                                              if (!snapshot.hasData) {
                                                return Center(
                                                  child: SizedBox(
                                                    width: 50.0,
                                                    height: 50.0,
                                                    child: CircularProgressIndicator(
                                                      valueColor:
                                                          AlwaysStoppedAnimation<Color>(
                                                        FlutterFlowTheme.of(context)
                                                            .primary,
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              }
                                              
                                              final categoriesResponse = snapshot.data!;
                                              final categories = CategoryService().parseDataList(
                                                categoriesResponse.jsonBody) ?? [];
                                              
                                              // Fetch all cameras once for efficient filtering
                                              return FutureBuilder<ApiCallResponse>(
                                                future: CameraService().getCameras(limit: '100'),
                                                builder: (context, allCamerasSnapshot) {
                                                  final allCameras = allCamerasSnapshot.hasData
                                                      ? (CameraService().parseDataList(
                                                              allCamerasSnapshot.data!.jsonBody) ?? [])
                                                      : [];
                                                  
                                                  return AlertDialog(
                                                title: Row(
                                                  children: [
                                                    Icon(Icons.video_library,
                                                        color: Color(0xFF4B39EF)),
                                                    SizedBox(width: 8.0),
                                                    Text('Manage Categories'),
                                                    Spacer(),
                                                    IconButton(
                                                      icon: Icon(Icons.add_circle, color: Color(0xFF4B39EF)),
                                                      tooltip: 'Create New Category',
                                                      onPressed: () async {
                                                        // Show create category dialog
                                                        final TextEditingController newCategoryController = 
                                                            TextEditingController();
                                                        
                                                        await showDialog(
                                                          context: context,
                                                          builder: (createContext) {
                                                            return AlertDialog(
                                                              title: Row(
                                                                children: [
                                                                  Icon(Icons.create_new_folder_outlined,
                                                                      color: Color(0xFF4B39EF)),
                                                                  SizedBox(width: 8.0),
                                                                  Text('Create New Category'),
                                                                ],
                                                              ),
                                                              content: TextField(
                                                                controller: newCategoryController,
                                                                decoration: InputDecoration(
                                                                  labelText: 'Category Name *',
                                                                  hintText: 'e.g., Entrance Cameras',
                                                                  border: OutlineInputBorder(
                                                                    borderRadius: BorderRadius.circular(8.0),
                                                                  ),
                                                                  prefixIcon: Icon(Icons.label_outlined,
                                                                      color: Color(0xFF4B39EF)),
                                                                ),
                                                                autofocus: true,
                                                              ),
                                                              actions: [
                                                                TextButton(
                                                                  onPressed: () => Navigator.pop(createContext),
                                                                  child: Text('Cancel'),
                                                                ),
                                                                ElevatedButton(
                                                                  onPressed: () async {
                                                                    final name = newCategoryController.text.trim();
                                                                    if (name.isEmpty) {
                                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                                        SnackBar(
                                                                          content: Text('Please enter a category name'),
                                                                          backgroundColor: Colors.red,
                                                                        ),
                                                                      );
                                                                      return;
                                                                    }
                                                                    
                                                                    Navigator.pop(createContext);
                                                                    
                                                                    // Show loading
                                                                    showDialog(
                                                                      context: context,
                                                                      barrierDismissible: false,
                                                                      builder: (loadingContext) => Center(
                                                                        child: CircularProgressIndicator(),
                                                                      ),
                                                                    );
                                                                    
                                                                    final createResponse = await CategoryService()
                                                                        .createCategory(name: name);
                                                                    
                                                                    Navigator.pop(context);
                                                                    
                                                                    if (createResponse.succeeded) {
                                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                                        SnackBar(
                                                                          content: Text('Category "$name" created!'),
                                                                          backgroundColor: Color(0xFF4CAF50),
                                                                        ),
                                                                      );
                                                                      // Refresh the dialog
                                                                      setDialogState(() {});
                                                                    } else {
                                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                                        SnackBar(
                                                                          content: Text('Failed to create category'),
                                                                          backgroundColor: Colors.red,
                                                                        ),
                                                                      );
                                                                    }
                                                                  },
                                                                  style: ElevatedButton.styleFrom(
                                                                    backgroundColor: Color(0xFF4B39EF),
                                                                  ),
                                                                  child: Text('Create',
                                                                      style: TextStyle(color: Colors.white)),
                                                                ),
                                                              ],
                                                            );
                                                          },
                                                        );
                                                      },
                                                    ),
                                                  ],
                                                ),
                                                content: Container(
                                                  width: 600.0,
                                                  height: 500.0,
                                                  child: categories.isEmpty
                                                      ? Column(
                                                          mainAxisSize: MainAxisSize.min,
                                                          mainAxisAlignment: MainAxisAlignment.center,
                                                          children: [
                                                            Icon(
                                                              Icons.category_outlined,
                                                              size: 64.0,
                                                              color: FlutterFlowTheme.of(context)
                                                                  .secondaryText,
                                                            ),
                                                            SizedBox(height: 16.0),
                                                            Text(
                                                              'No categories yet',
                                                              style: FlutterFlowTheme.of(context)
                                                                  .titleMedium,
                                                            ),
                                                            SizedBox(height: 8.0),
                                                            Text(
                                                              'Click the + icon above to create your first category',
                                                              style: FlutterFlowTheme.of(context)
                                                                  .bodySmall,
                                                              textAlign: TextAlign.center,
                                                            ),
                                                          ],
                                                        )
                                                      : ListView.builder(
                                                          shrinkWrap: true,
                                                          itemCount: categories.length,
                                                          itemBuilder: (context, index) {
                                                            final category = categories[index];
                                                            final categoryId = getJsonField(category, r'$.id').toString();
                                                            final categoryName = getJsonField(category, r'$.name').toString();
                                                            final isExpanded = expandedMap[categoryId] ?? false;
                                                            
                                                            return Card(
                                                              margin: EdgeInsets.symmetric(vertical: 4.0),
                                                              elevation: 2.0,
                                                              child: Column(
                                                                children: [
                                                                  ListTile(
                                                                    leading: CircleAvatar(
                                                                      backgroundColor: Color(0xFF4B39EF),
                                                                      child: Icon(
                                                                        Icons.folder,
                                                                        color: Colors.white,
                                                                        size: 20.0,
                                                                      ),
                                                                    ),
                                                                    title: Text(
                                                                      categoryName,
                                                                      style: FlutterFlowTheme.of(context)
                                                                          .titleMedium
                                                                          .override(
                                                                            fontFamily: 'Readex Pro',
                                                                            fontWeight: FontWeight.w600,
                                                                          ),
                                                                    ),
                                                                    trailing: Row(
                                                                      mainAxisSize: MainAxisSize.min,
                                                                      children: [
                                                                        IconButton(
                                                                          icon: Icon(
                                                                            isExpanded 
                                                                                ? Icons.expand_less 
                                                                                : Icons.expand_more,
                                                                            color: Color(0xFF4B39EF),
                                                                          ),
                                                                          tooltip: isExpanded ? 'Collapse' : 'Expand',
                                                                          onPressed: () {
                                                                            setDialogState(() {
                                                                              expandedMap[categoryId] = !isExpanded;
                                                                            });
                                                                          },
                                                                        ),
                                                                        IconButton(
                                                                          icon: Icon(
                                                                            Icons.edit,
                                                                            color: Color(0xFF4B39EF),
                                                                            size: 20.0,
                                                                          ),
                                                                          tooltip: 'Edit Name',
                                                                          onPressed: () async {
                                                                            final TextEditingController editController =
                                                                                TextEditingController(text: categoryName);
                                                                            
                                                                            await showDialog(
                                                                              context: context,
                                                                              builder: (editContext) {
                                                                                return AlertDialog(
                                                                                  title: Text('Edit Category'),
                                                                                  content: TextField(
                                                                                    controller: editController,
                                                                                    decoration: InputDecoration(
                                                                                      labelText: 'Category Name',
                                                                                      border: OutlineInputBorder(),
                                                                                    ),
                                                                                    autofocus: true,
                                                                                  ),
                                                                                  actions: [
                                                                                    TextButton(
                                                                                      onPressed: () =>
                                                                                          Navigator.pop(editContext),
                                                                                      child: Text('Cancel'),
                                                                                    ),
                                                                                    ElevatedButton(
                                                                                      onPressed: () async {
                                                                                        final newName = editController.text.trim();
                                                                                        if (newName.isEmpty) {
                                                                                          ScaffoldMessenger.of(context)
                                                                                              .showSnackBar(
                                                                                            SnackBar(
                                                                                              content: Text(
                                                                                                  'Please enter a name'),
                                                                                              backgroundColor: Colors.red,
                                                                                            ),
                                                                                          );
                                                                                          return;
                                                                                        }
                                                                                        
                                                                                        Navigator.pop(editContext);
                                                                                        
                                                                                        showDialog(
                                                                                          context: context,
                                                                                          barrierDismissible: false,
                                                                                          builder: (loadingContext) =>
                                                                                              Center(
                                                                                            child:
                                                                                                CircularProgressIndicator(),
                                                                                          ),
                                                                                        );
                                                                                        
                                                                                        final updateResponse =
                                                                                            await CategoryService()
                                                                                                .editCategory(
                                                                                          categoryId: categoryId,
                                                                                          name: newName,
                                                                                        );
                                                                                        
                                                                                        Navigator.pop(context);
                                                                                        
                                                                                        if (updateResponse.succeeded) {
                                                                                          ScaffoldMessenger.of(context)
                                                                                              .showSnackBar(
                                                                                            SnackBar(
                                                                                              content: Text(
                                                                                                  'Category updated!'),
                                                                                              backgroundColor:
                                                                                                  Color(0xFF4CAF50),
                                                                                            ),
                                                                                          );
                                                                                          setDialogState(() {});
                                                                                        } else {
                                                                                          ScaffoldMessenger.of(context)
                                                                                              .showSnackBar(
                                                                                            SnackBar(
                                                                                              content: Text(
                                                                                                  'Failed to update'),
                                                                                              backgroundColor: Colors.red,
                                                                                            ),
                                                                                          );
                                                                                        }
                                                                                      },
                                                                                      style: ElevatedButton.styleFrom(
                                                                                        backgroundColor:
                                                                                            Color(0xFF4B39EF),
                                                                                      ),
                                                                                      child: Text('Save',
                                                                                          style: TextStyle(
                                                                                              color: Colors.white)),
                                                                                    ),
                                                                                  ],
                                                                                );
                                                                              },
                                                                            );
                                                                          },
                                                                        ),
                                                                        IconButton(
                                                                          icon: Icon(
                                                                            Icons.delete,
                                                                            color: Colors.red,
                                                                            size: 20.0,
                                                                          ),
                                                                          tooltip: 'Delete',
                                                                          onPressed: () async {
                                                                            final confirmDelete =
                                                                                await showDialog<bool>(
                                                                              context: context,
                                                                              builder: (confirmContext) {
                                                                                return AlertDialog(
                                                                                  title: Row(
                                                                                    children: [
                                                                                      Icon(Icons.warning,
                                                                                          color: Colors.red),
                                                                                      SizedBox(width: 8.0),
                                                                                      Text('Delete Category'),
                                                                                    ],
                                                                                  ),
                                                                                  content: Text(
                                                                                    'Delete "$categoryName"?\n\nCameras will not be deleted.',
                                                                                  ),
                                                                                  actions: [
                                                                                    TextButton(
                                                                                      onPressed: () =>
                                                                                          Navigator.pop(
                                                                                              confirmContext, false),
                                                                                      child: Text('Cancel'),
                                                                                    ),
                                                                                    ElevatedButton(
                                                                                      onPressed: () =>
                                                                                          Navigator.pop(
                                                                                              confirmContext, true),
                                                                                      style:
                                                                                          ElevatedButton.styleFrom(
                                                                                        backgroundColor: Colors.red,
                                                                                      ),
                                                                                      child: Text('Delete',
                                                                                          style: TextStyle(
                                                                                              color: Colors.white)),
                                                                                    ),
                                                                                  ],
                                                                                );
                                                                              },
                                                                            );
                                                                            
                                                                            if (confirmDelete == true) {
                                                                              showDialog(
                                                                                context: context,
                                                                                barrierDismissible: false,
                                                                                builder: (loadingContext) => Center(
                                                                                  child: CircularProgressIndicator(),
                                                                                ),
                                                                              );
                                                                              
                                                                              final deleteResponse =
                                                                                  await CategoryService()
                                                                                      .deleteCategory(categoryId);
                                                                              
                                                                              Navigator.pop(context);
                                                                              
                                                                              if (deleteResponse.succeeded) {
                                                                                ScaffoldMessenger.of(context)
                                                                                    .showSnackBar(
                                                                                  SnackBar(
                                                                                    content:
                                                                                        Text('Category deleted!'),
                                                                                    backgroundColor:
                                                                                        Color(0xFF4CAF50),
                                                                                  ),
                                                                                );
                                                                                setDialogState(() {});
                                                                              } else {
                                                                                ScaffoldMessenger.of(context)
                                                                                    .showSnackBar(
                                                                                  SnackBar(
                                                                                    content: Text('Failed to delete'),
                                                                                    backgroundColor: Colors.red,
                                                                                  ),
                                                                                );
                                                                              }
                                                                            }
                                                                          },
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                  if (isExpanded)
                                                                    Container(
                                                                      padding: EdgeInsets.all(12.0),
                                                                      color: Colors.grey[50],
                                                                      child: Builder(
                                                                        builder: (context) {
                                                                          // Filter cameras that belong to this category
                                                                          final cameras = allCameras.where((camera) {
                                                                            final cameraCategories = getJsonField(
                                                                              camera,
                                                                              r'$.categories',
                                                                            );
                                                                            if (cameraCategories == null) return false;
                                                                            
                                                                            // Check if this category ID is in the camera's categories
                                                                            final categoriesList = cameraCategories is List 
                                                                                ? cameraCategories 
                                                                                : [cameraCategories];
                                                                            
                                                                            return categoriesList.any((cat) => 
                                                                              getJsonField(cat, r'$.id').toString() == categoryId
                                                                            );
                                                                          }).toList();
                                                                          
                                                                          return Column(
                                                                            crossAxisAlignment:
                                                                                CrossAxisAlignment.start,
                                                                            children: [
                                                                              Row(
                                                                                mainAxisAlignment:
                                                                                    MainAxisAlignment.spaceBetween,
                                                                                children: [
                                                                                  Text(
                                                                                    'Cameras (${cameras.length})',
                                                                                    style: FlutterFlowTheme.of(
                                                                                            context)
                                                                                        .labelLarge
                                                                                        .override(
                                                                                          fontFamily: 'Readex Pro',
                                                                                          fontWeight:
                                                                                              FontWeight.w600,
                                                                                        ),
                                                                                  ),
                                                                                  ElevatedButton.icon(
                                                                                    onPressed: () async {
                                                                                      // Filter out cameras already in this category
                                                                                      final currentCameraIds =
                                                                                          cameras
                                                                                              .map((c) =>
                                                                                                  getJsonField(
                                                                                                      c, r'$.id')
                                                                                                  .toString())
                                                                                              .toSet();
                                                                                      final availableCameras =
                                                                                          allCameras
                                                                                              .where((c) =>
                                                                                                  !currentCameraIds
                                                                                                      .contains(getJsonField(
                                                                                                              c,
                                                                                                              r'$.id')
                                                                                                          .toString()))
                                                                                              .toList();
                                                                                      
                                                                                      if (availableCameras.isEmpty) {
                                                                                        ScaffoldMessenger.of(context)
                                                                                            .showSnackBar(
                                                                                          SnackBar(
                                                                                            content: Text(
                                                                                                'All cameras are already in this category'),
                                                                                            backgroundColor:
                                                                                                Color(0xFFFFA726),
                                                                                          ),
                                                                                        );
                                                                                        return;
                                                                                      }
                                                                                      
                                                                                      await showDialog(
                                                                                        context: context,
                                                                                        builder: (addContext) {
                                                                                          return StatefulBuilder(
                                                                                            builder: (context, setSearchState) {
                                                                                              final searchController = TextEditingController();
                                                                                              String searchQuery = '';
                                                                                              
                                                                                              final filteredCameras = availableCameras.where((camera) {
                                                                                                final cameraName = getJsonField(camera, r'$.name').toString().toLowerCase();
                                                                                                return cameraName.contains(searchQuery.toLowerCase());
                                                                                              }).toList();
                                                                                              
                                                                                              return AlertDialog(
                                                                                                title: Text('Add Cameras to "$categoryName"'),
                                                                                                content: Container(
                                                                                                  width: 500,
                                                                                                  height: 400,
                                                                                                  child: Column(
                                                                                                    children: [
                                                                                                      // Search field
                                                                                                      TextField(
                                                                                                        controller: searchController,
                                                                                                        decoration: InputDecoration(
                                                                                                          prefixIcon: Icon(Icons.search),
                                                                                                          hintText: 'Search cameras...',
                                                                                                          border: OutlineInputBorder(
                                                                                                            borderRadius: BorderRadius.circular(8),
                                                                                                          ),
                                                                                                          contentPadding: EdgeInsets.symmetric(
                                                                                                            horizontal: 12,
                                                                                                            vertical: 8,
                                                                                                          ),
                                                                                                        ),
                                                                                                        onChanged: (value) {
                                                                                                          setSearchState(() {
                                                                                                            searchQuery = value;
                                                                                                          });
                                                                                                        },
                                                                                                      ),
                                                                                                      SizedBox(height: 16),
                                                                                                      // Results count
                                                                                                      Align(
                                                                                                        alignment: Alignment.centerLeft,
                                                                                                        child: Text(
                                                                                                          '${filteredCameras.length} camera(s) available',
                                                                                                          style: TextStyle(
                                                                                                            fontSize: AppTextStyles.commandBody,
                                                                                                            color: Colors.grey[600],
                                                                                                          ),
                                                                                                        ),
                                                                                                      ),
                                                                                                      SizedBox(height: 8),
                                                                                                      Divider(height: 1),
                                                                                                      SizedBox(height: 8),
                                                                                                      // Camera list
                                                                                                      Expanded(
                                                                                                        child: filteredCameras.isEmpty
                                                                                                          ? Center(
                                                                                                              child: Text(
                                                                                                                'No cameras found',
                                                                                                                style: TextStyle(color: Colors.grey),
                                                                                                              ),
                                                                                                            )
                                                                                                          : ListView.builder(
                                                                                                              itemCount: filteredCameras.length,
                                                                                                              itemBuilder: (context, idx) {
                                                                                                                final camera = filteredCameras[idx];
                                                                                                                final cameraId = getJsonField(camera, r'$.id').toString();
                                                                                                                final cameraName = getJsonField(camera, r'$.name').toString();
                                                                                                                
                                                                                                                return ListTile(
                                                                                                                  leading: Icon(
                                                                                                                    Icons.videocam,
                                                                                                                    color: Color(0xFF39D2C0),
                                                                                                                  ),
                                                                                                                  title: Text(cameraName),
                                                                                                                  trailing: IconButton(
                                                                                                                    icon: Icon(
                                                                                                                      Icons.add_circle,
                                                                                                                      color: Color(0xFF4B39EF),
                                                                                                                    ),
                                                                                                                    onPressed: () async {
                                                                                                        // Close the selection dialog first
                                                                                                        Navigator.of(addContext).pop();
                                                                                                        
                                                                                                        // Capture navigator and scaffold messenger before async
                                                                                                        final navigator = Navigator.of(context, rootNavigator: true);
                                                                                                        final scaffoldMessenger = ScaffoldMessenger.of(context);
                                                                                                        
                                                                                                        // Show loading
                                                                                                        bool isLoadingShown = false;
                                                                                                        try {
                                                                                                          showDialog(
                                                                                                            context: context,
                                                                                                            barrierDismissible: false,
                                                                                                            builder: (loadingContext) {
                                                                                                              isLoadingShown = true;
                                                                                                              return WillPopScope(
                                                                                                                onWillPop: () async => false,
                                                                                                                child: Center(
                                                                                                                  child: CircularProgressIndicator(),
                                                                                                                ),
                                                                                                              );
                                                                                                            },
                                                                                                          );
                                                                                                          
                                                                                                          final addResponse = await CameraService()
                                                                                                              .addCategoryToCamera(
                                                                                                            categoryId: categoryId,
                                                                                                            cameraId: cameraId,
                                                                                                          );
                                                                                                          
                                                                                                          // Close loading if still mounted
                                                                                                          if (isLoadingShown) {
                                                                                                            try {
                                                                                                              if (navigator.canPop()) navigator.pop();
                                                                                                            } catch (_) {}
                                                                                                          }
                                                                                                          
                                                                                                          // Show result if still mounted
                                                                                                          if (!mounted) return;
                                                                                                          
                                                                                                          if (addResponse.succeeded) {
                                                                                                            scaffoldMessenger.showSnackBar(
                                                                                                              SnackBar(
                                                                                                                content: Text('Camera added!'),
                                                                                                                backgroundColor: Color(0xFF4CAF50),
                                                                                                              ),
                                                                                                            );
                                                                                                            setDialogState(() {});
                                                                                                            Future.delayed(Duration(milliseconds: 100), () {
                                                                                                              if (mounted) safeSetState(() {});
                                                                                                            });
                                                                                                          } else {
                                                                                                            scaffoldMessenger.showSnackBar(
                                                                                                              SnackBar(
                                                                                                                content: Text('Failed to add camera'),
                                                                                                                backgroundColor: Colors.red,
                                                                                                              ),
                                                                                                            );
                                                                                                          }
                                                                                                        } catch (e) {
                                                                                                          // Ensure loading closes
                                                                                                          if (isLoadingShown) {
                                                                                                            try {
                                                                                                              if (navigator.canPop()) navigator.pop();
                                                                                                            } catch (_) {}
                                                                                                          }
                                                                                                          if (mounted) {
                                                                                                            scaffoldMessenger.showSnackBar(
                                                                                                              SnackBar(
                                                                                                                content: Text('Error: ${e.toString()}'),
                                                                                                                backgroundColor: Colors.red,
                                                                                                              ),
                                                                                                            );
                                                                                                          }
                                                                                                        }
                                                                                                      },
                                                                                                    ),
                                                                                                  );
                                                                                                },
                                                                                              ),
                                                                                      ),
                                                                                    ],
                                                                                  ),
                                                                                ),
                                                                                actions: [
                                                                                  TextButton(
                                                                                    onPressed: () => Navigator.pop(addContext),
                                                                                    child: Text('Close'),
                                                                                  ),
                                                                                ],
                                                                              );
                                                                            },
                                                                          );
                                                                        },
                                                                      );
                                                                                    },
                                                                                    icon: Icon(Icons.add,
                                                                                        size: 16.0),
                                                                                    label: Text('Add Camera'),
                                                                                    style: ElevatedButton.styleFrom(
                                                                                      backgroundColor:
                                                                                          Color(0xFF39D2C0),
                                                                                      foregroundColor: Colors.white,
                                                                                      padding: EdgeInsets.symmetric(
                                                                                          horizontal: 12.0,
                                                                                          vertical: 8.0),
                                                                                    ),
                                                                                  ),
                                                                                ],
                                                                              ),
                                                                              SizedBox(height: 8.0),
                                                                              if (cameras.isEmpty)
                                                                                Padding(
                                                                                  padding: EdgeInsets.all(16.0),
                                                                                  child: Center(
                                                                                    child: Text(
                                                                                      'No cameras in this category',
                                                                                      style: FlutterFlowTheme.of(
                                                                                              context)
                                                                                          .bodySmall
                                                                                          .override(
                                                                                            fontFamily:
                                                                                                'Readex Pro',
                                                                                            fontStyle:
                                                                                                FontStyle.italic,
                                                                                          ),
                                                                                    ),
                                                                                  ),
                                                                                )
                                                                              else
                                                                                ...cameras.map((camera) {
                                                                                  final cameraId = getJsonField(
                                                                                          camera, r'$.id')
                                                                                      .toString();
                                                                                  final cameraName =
                                                                                      getJsonField(camera,
                                                                                              r'$.name')
                                                                                          .toString();
                                                                                  
                                                                                  return ListTile(
                                                                                    dense: true,
                                                                                    leading: Icon(
                                                                                        Icons.videocam,
                                                                                        color:
                                                                                            Color(0xFF39D2C0),
                                                                                        size: 20.0),
                                                                                    title: Text(
                                                                                      cameraName,
                                                                                      style:
                                                                                          FlutterFlowTheme.of(
                                                                                                  context)
                                                                                              .bodyMedium,
                                                                                    ),
                                                                                    trailing: IconButton(
                                                                                      icon: Icon(
                                                                                        Icons.remove_circle,
                                                                                        color: Colors.red,
                                                                                        size: 20.0,
                                                                                      ),
                                                                                      tooltip: 'Remove',
                                                                                      onPressed: () async {
                                                                                        final confirmRemove =
                                                                                            await showDialog<
                                                                                                bool>(
                                                                                          context: context,
                                                                                          builder:
                                                                                              (confirmContext) {
                                                                                            return AlertDialog(
                                                                                              title: Text(
                                                                                                  'Remove Camera'),
                                                                                              content: Text(
                                                                                                  'Remove "$cameraName" from "$categoryName"?'),
                                                                                              actions: [
                                                                                                TextButton(
                                                                                                  onPressed: () =>
                                                                                                      Navigator.pop(
                                                                                                          confirmContext,
                                                                                                          false),
                                                                                                  child: Text(
                                                                                                      'Cancel'),
                                                                                                ),
                                                                                                ElevatedButton(
                                                                                                  onPressed: () =>
                                                                                                      Navigator.pop(
                                                                                                          confirmContext,
                                                                                                          true),
                                                                                                  style: ElevatedButton
                                                                                                      .styleFrom(
                                                                                                    backgroundColor:
                                                                                                        Colors
                                                                                                            .red,
                                                                                                  ),
                                                                                                  child: Text(
                                                                                                      'Remove',
                                                                                                      style: TextStyle(
                                                                                                          color: Colors
                                                                                                              .white)),
                                                                                                ),
                                                                                              ],
                                                                                            );
                                                                                          },
                                                                                        );
                                                                                        
                                                                                        if (confirmRemove == true) {
                                                                                          // Capture navigator and scaffold messenger before async
                                                                                          final navigator = Navigator.of(context, rootNavigator: true);
                                                                                          final scaffoldMessenger = ScaffoldMessenger.of(context);
                                                                                          
                                                                                          // Show loading
                                                                                          bool isLoadingShown = false;
                                                                                          try {
                                                                                            showDialog(
                                                                                              context: context,
                                                                                              barrierDismissible: false,
                                                                                              builder: (loadingContext) {
                                                                                                isLoadingShown = true;
                                                                                                return WillPopScope(
                                                                                                  onWillPop: () async => false,
                                                                                                  child: Center(
                                                                                                    child: CircularProgressIndicator(),
                                                                                                  ),
                                                                                                );
                                                                                              },
                                                                                            );
                                                                                            
                                                                                            final removeResponse =
                                                                                                await CameraService()
                                                                                                    .deleteCategoryFromCamera(
                                                                                              categoryId: categoryId,
                                                                                              cameraId: cameraId,
                                                                                            );
                                                                                            
                                                                                            // Close loading if still mounted
                                                                                            if (isLoadingShown) {
                                                                                              try {
                                                                                                if (navigator.canPop()) navigator.pop();
                                                                                              } catch (_) {}
                                                                                            }
                                                                                            
                                                                                            // Show result if still mounted
                                                                                            if (!mounted) return;
                                                                                            
                                                                                            if (removeResponse.succeeded) {
                                                                                              scaffoldMessenger.showSnackBar(
                                                                                                SnackBar(
                                                                                                  content: Text('Camera removed!'),
                                                                                                  backgroundColor: Color(0xFF4CAF50),
                                                                                                ),
                                                                                              );
                                                                                              setDialogState(() {});
                                                                                              Future.delayed(Duration(milliseconds: 100), () {
                                                                                                if (mounted) safeSetState(() {});
                                                                                              });
                                                                                            } else {
                                                                                              scaffoldMessenger.showSnackBar(
                                                                                                SnackBar(
                                                                                                  content: Text('Failed to remove camera'),
                                                                                                  backgroundColor: Colors.red,
                                                                                                ),
                                                                                              );
                                                                                            }
                                                                                          } catch (e) {
                                                                                            // Ensure loading closes
                                                                                            if (isLoadingShown) {
                                                                                              try {
                                                                                                if (navigator.canPop()) navigator.pop();
                                                                                              } catch (_) {}
                                                                                            }
                                                                                            if (mounted) {
                                                                                              scaffoldMessenger.showSnackBar(
                                                                                                SnackBar(
                                                                                                  content: Text('Error: ${e.toString()}'),
                                                                                                  backgroundColor: Colors.red,
                                                                                                ),
                                                                                              );
                                                                                            }
                                                                                          }
                                                                                        }
                                                                                      },
                                                                                    ),
                                                                                  );
                                                                                }).toList(),
                                                                            ],
                                                                          );
                                                                        },
                                                                      ),
                                                                    ),
                                                                ],
                                                              ),
                                                            );
                                                          },
                                                        ),
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () {
                                                      Navigator.pop(dialogContext);
                                                      safeSetState(() {});
                                                    },
                                                    child: Text('Close'),
                                                  ),
                                                ],
                                              );
                                                },
                                              );
                                            },
                                          );
                                        },
                                      );
                                    },
                                  );
                                },
                                text: 'Manage Categories',
                                icon: Icon(
                                  Icons.settings,
                                  size: 22.0,
                                  color: Colors.white,
                                ),
                                options: FFButtonOptions(
                                  height: 50.0,
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      20.0, 0.0, 20.0, 0.0),
                                  iconPadding: EdgeInsetsDirectional.fromSTEB(
                                      0.0, 0.0, 0.0, 0.0),
                                  color: Color(0xFF05FFFF),
                                  textStyle: FlutterFlowTheme.of(context)
                                      .titleSmall
                                      .override(
                                        fontFamily: FlutterFlowTheme.of(context)
                                            .titleSmallFamily,
                                        color: Colors.black,
                                        letterSpacing: 0.0,
                                        useGoogleFonts:
                                            !FlutterFlowTheme.of(context)
                                                .titleSmallIsCustom,
                                      ),
                                  elevation: 0.0,
                                  borderSide: BorderSide(
                                    color: Color(0xFF05FFFF),
                                  ),
                                  borderRadius: BorderRadius.circular(10.0),
                                  hoverColor: Color(0xFF00E5E5),
                                  hoverBorderSide: BorderSide(
                                    color: Color(0xFF05FFFF),
                                  ),
                                  hoverTextColor: Colors.black,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Expanded content area (no scroll)
                    Expanded(
                      child: FutureBuilder<ApiCallResponse>(
                        future: CameraService().getCameras(limit: '100'),
                        builder: (context, snapshot) {
                          // Customize what your widget looks like when it's loading.
                          if (!snapshot.hasData) {
                            return Center(
                              child: SizedBox(
                                width: 50.0,
                                height: 50.0,
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    FlutterFlowTheme.of(context).primary,
                                  ),
                                ),
                              ),
                            );
                          }
                          final columnGetCameraResponse = snapshot.data!;

                          // Handle API errors
                          if (!columnGetCameraResponse.succeeded) {
                            return Center(
                              child: Padding(
                                padding: EdgeInsets.all(50.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      size: 60.0,
                                      color: FlutterFlowTheme.of(context).error,
                                    ),
                                    SizedBox(height: 16.0),
                                    Text(
                                      'Failed to load cameras',
                                      style: FlutterFlowTheme.of(context)
                                          .headlineSmall,
                                    ),
                                    SizedBox(height: 8.0),
                                    Text(
                                      'Status Code: ${columnGetCameraResponse.statusCode}',
                                      style: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .override(
                                            fontFamily: 'Readex Pro',
                                            color: FlutterFlowTheme.of(context)
                                                .error,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    SizedBox(height: 8.0),
                                    Text(
                                      columnGetCameraResponse
                                              .exceptionMessage.isNotEmpty
                                          ? 'Error: ${columnGetCameraResponse.exceptionMessage}'
                                          : 'Response: ${columnGetCameraResponse.bodyText}',
                                      style: FlutterFlowTheme.of(context)
                                          .bodySmall,
                                      textAlign: TextAlign.center,
                                      maxLines: 5,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: 8.0),
                                    Text(
                                      'Please check your connection and try again',
                                      style: FlutterFlowTheme.of(context)
                                          .bodyMedium,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          return LayoutBuilder(
                            builder: (context, constraints) {
                              return Center(
                                child: Container(
                                  width: double.infinity,
                                  constraints: BoxConstraints(
                                    maxWidth: 1680.0,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.transparent,
                                  ),
                                  child: Padding(
                                    padding: EdgeInsetsDirectional.fromSTEB(
                                        60.0, 16.0, 60.0, 32.0),
                                    child: Builder(
                                      builder: (context) {
                                        // Use search results if available, otherwise use all cameras
                                        var cameraItems = _model
                                                .simpleSearchResults.isNotEmpty
                                            ? _model.simpleSearchResults
                                            : getJsonField(
                                                columnGetCameraResponse
                                                    .jsonBody,
                                                r'''$.data''',
                                              ).toList();
                                        
                                        // Apply category filters
                                        if (_model.filterAssignedCategory) {
                                          cameraItems = cameraItems.where((camera) {
                                            final categories = getJsonField(camera, r'$.categories');
                                            // Check if camera has categories assigned
                                            return categories != null && 
                                                   (categories is List ? categories.isNotEmpty : true);
                                          }).toList();
                                        } else if (_model.filterUnassignedCategory) {
                                          cameraItems = cameraItems.where((camera) {
                                            final categories = getJsonField(camera, r'$.categories');
                                            // Check if camera has no categories assigned
                                            return categories == null || 
                                                   (categories is List ? categories.isEmpty : false);
                                          }).toList();
                                        }
                                        
                                        if (cameraItems.isEmpty) {
                                          return Center(
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.search_off_rounded,
                                                  size: 80.0,
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .secondaryText,
                                                ),
                                                SizedBox(height: 16.0),
                                                Text(
                                                  _model.textController.text
                                                          .isNotEmpty
                                                      ? 'No cameras found matching "${_model.textController.text}"'
                                                      : _model.filterAssignedCategory
                                                          ? 'No cameras with categories found'
                                                          : _model.filterUnassignedCategory
                                                              ? 'No cameras without categories found'
                                                              : 'No cameras available',
                                                  style: FlutterFlowTheme.of(
                                                          context)
                                                      .titleMedium,
                                                  textAlign: TextAlign.center,
                                                ),
                                                if (_model.filterAssignedCategory ||
                                                    _model.filterUnassignedCategory)
                                                  Padding(
                                                    padding: EdgeInsets.only(
                                                        top: 12.0),
                                                    child: Text(
                                                      'Try clearing the filter',
                                                      style: FlutterFlowTheme
                                                              .of(context)
                                                          .bodySmall
                                                          .override(
                                                            fontFamily:
                                                                'Readex Pro',
                                                            fontStyle: FontStyle
                                                                .italic,
                                                          ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          );
                                        }

                                        return Container(
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(12.0),
                                            boxShadow: [
                                              BoxShadow(
                                                blurRadius: 8.0,
                                                color: Color(0x1A000000),
                                                offset: Offset(0.0, 2.0),
                                                spreadRadius: 0.0,
                                              ),
                                            ],
                                          ),
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(12.0),
                                            child:
                                                FlutterFlowDataTable<dynamic>(
                                              controller: _model
                                                  .paginatedDataTableController,
                                              data: cameraItems,
                                              columnsBuilder: (onSortChanged) =>
                                                  [
                                                DataColumn2(
                                                  size: ColumnSize.L,
                                                  label: DefaultTextStyle.merge(
                                                    softWrap: true,
                                                    child: Text(
                                                      'Name',
                                                      style: FlutterFlowTheme
                                                              .of(context)
                                                          .labelMedium
                                                          .override(
                                                            fontFamily:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .labelMediumFamily,
                                                            color: Colors.white,
                                                            fontSize: AppTextStyles.tableHeader,
                                                            letterSpacing: 0.0,
                                                            useGoogleFonts:
                                                                !FlutterFlowTheme.of(
                                                                        context)
                                                                    .labelMediumIsCustom,
                                                          ),
                                                    ),
                                                  ),
                                                ),
                                                DataColumn2(
                                                  size: ColumnSize.L,
                                                  label: DefaultTextStyle.merge(
                                                    softWrap: true,
                                                    child: Text(
                                                      'Address',
                                                      style: FlutterFlowTheme
                                                              .of(context)
                                                          .labelMedium
                                                          .override(
                                                            fontFamily:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .labelMediumFamily,
                                                            color: Colors.white,
                                                            fontSize: AppTextStyles.tableHeader,
                                                            letterSpacing: 0.0,
                                                            useGoogleFonts:
                                                                !FlutterFlowTheme.of(
                                                                        context)
                                                                    .labelMediumIsCustom,
                                                          ),
                                                    ),
                                                  ),
                                                ),
                                                DataColumn2(
                                                  size: ColumnSize.S,
                                                  label: DefaultTextStyle.merge(
                                                    softWrap: true,
                                                    child: Text(
                                                      'Status',
                                                      style: FlutterFlowTheme
                                                              .of(context)
                                                          .labelMedium
                                                          .override(
                                                            fontFamily:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .labelMediumFamily,
                                                            color: Colors.white,
                                                            fontSize: AppTextStyles.tableHeader,
                                                            letterSpacing: 0.0,
                                                            useGoogleFonts:
                                                                !FlutterFlowTheme.of(
                                                                        context)
                                                                    .labelMediumIsCustom,
                                                          ),
                                                    ),
                                                  ),
                                                ),
                                                DataColumn2(
                                                  size: ColumnSize.L,
                                                  label: DefaultTextStyle.merge(
                                                    softWrap: true,
                                                    child: Text(
                                                      'Categories',
                                                      style: FlutterFlowTheme
                                                              .of(context)
                                                          .labelMedium
                                                          .override(
                                                            fontFamily:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .labelMediumFamily,
                                                            color: Colors.white,
                                                            fontSize: AppTextStyles.tableHeader,
                                                            letterSpacing: 0.0,
                                                            useGoogleFonts:
                                                                !FlutterFlowTheme.of(
                                                                        context)
                                                                    .labelMediumIsCustom,
                                                          ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                              dataRowBuilder: (cameraItemsItem,
                                                      cameraItemsIndex,
                                                      selected,
                                                      onSelectChanged) =>
                                                  DataRow(
                                                color:
                                                    MaterialStateProperty.all(
                                                  cameraItemsIndex % 2 == 0
                                                      ? FlutterFlowTheme.of(
                                                              context)
                                                          .secondaryBackground
                                                      : FlutterFlowTheme.of(
                                                              context)
                                                          .primaryBackground,
                                                ),
                                                cells: [
                                                  Text(
                                                        getJsonField(
                                                          cameraItemsItem,
                                                          r'''$.name''',
                                                        ).toString(),
                                                        style: FlutterFlowTheme
                                                                .of(context)
                                                            .bodySmall
                                                            .override(
                                                              fontFamily:
                                                                  FlutterFlowTheme.of(
                                                                          context)
                                                                      .bodySmallFamily,
                                                              fontSize: AppTextStyles.tableCell,
                                                              letterSpacing:
                                                                  0.0,
                                                              useGoogleFonts:
                                                                  !FlutterFlowTheme.of(
                                                                          context)
                                                                      .bodySmallIsCustom,
                                                            ),
                                                      ),
                                                  Text(
                                                    getJsonField(
                                                      cameraItemsItem,
                                                      r'''$.address''',
                                                    ).toString(),
                                                    style: FlutterFlowTheme.of(
                                                            context)
                                                        .bodySmall
                                                        .override(
                                                          fontFamily:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .bodySmallFamily,
                                                          fontSize: AppTextStyles.tableCell,
                                                          letterSpacing: 0.0,
                                                          useGoogleFonts:
                                                              !FlutterFlowTheme
                                                                      .of(context)
                                                                  .bodySmallIsCustom,
                                                        ),
                                                  ),
                                                  Text(
                                                    getJsonField(
                                                      cameraItemsItem,
                                                      r'''$.status''',
                                                    ).toString(),
                                                    style: FlutterFlowTheme.of(
                                                            context)
                                                        .bodySmall
                                                        .override(
                                                          fontFamily:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .bodySmallFamily,
                                                          fontSize: AppTextStyles.tableCell,
                                                          letterSpacing: 0.0,
                                                          useGoogleFonts:
                                                              !FlutterFlowTheme
                                                                      .of(context)
                                                                  .bodySmallIsCustom,
                                                        ),
                                                  ),
                                                  _buildCategoryChips(cameraItemsItem),
                                                ]
                                                    .map((c) => DataCell(c))
                                                    .toList(),
                                              ),
                                              emptyBuilder: () => Center(
                                                child: Image.asset(
                                                  'assets/images/Screenshot_2024_1228_145217.png',
                                                  fit: BoxFit.contain,
                                                ),
                                              ),
                                              paginated: true,
                                              selectable: false,
                                              hidePaginator: false,
                                              showFirstLastButtons: false,
                                              height:
                                                  constraints.maxHeight - 48.0,
                                              headingRowHeight: 56.0,
                                              dataRowHeight: 64.0,
                                              columnSpacing: 16.0,
                                              headingRowColor:
                                                  FlutterFlowTheme.of(context)
                                                      .primary,
                                              borderRadius:
                                                  BorderRadius.circular(12.0),
                                              addHorizontalDivider: true,
                                              addTopAndBottomDivider: false,
                                              hideDefaultHorizontalDivider:
                                                  true,
                                              horizontalDividerColor:
                                                  FlutterFlowTheme.of(context)
                                                      .secondaryBackground,
                                              horizontalDividerThickness: 1.0,
                                              addVerticalDivider: false,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Immutable color pair used for category chips.
class _ChipColor {
  final Color bg;
  final Color text;
  const _ChipColor({required this.bg, required this.text});
}
