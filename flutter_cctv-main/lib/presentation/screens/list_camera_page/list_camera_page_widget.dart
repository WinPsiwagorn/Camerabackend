import '/data/services/index.dart';
import '/presentation/widgets/camera/views/addnewcamera_widget.dart';
import '/presentation/widgets/camera/views/detailscamera_widget.dart';
import '/presentation/widgets/camera/views/editdatacamera_widget.dart';
import '/presentation/widgets/nav/views/nav_bar_main_widget.dart';
import '/presentation/widgets/shared/category_chip.dart';
import '/presentation/widgets/shared/status_chip.dart';
import '/utils/flutter_flow/theme.dart';
import '/utils/flutter_flow/util.dart';
import '/utils/flutter_flow/widgets.dart';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'list_camera_page_model.dart';
export 'list_camera_page_model.dart';

// =============================================================================
// Page
// =============================================================================

class ListCameraPageWidget extends StatefulWidget {
  const ListCameraPageWidget({super.key});

  static String routeName = 'ListCameraPage';
  static String routePath = '/list-camera';

  @override
  State<ListCameraPageWidget> createState() => _ListCameraPageWidgetState();
}

class _ListCameraPageWidgetState extends State<ListCameraPageWidget> {
  late ListCameraPageModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ListCameraPageModel());
    _model.searchBarTextController?.addListener(() => safeSetState(() {}));

    SchedulerBinding.instance.addPostFrameCallback((_) async {
      // ดึงพร้อมกันทั้งคู่ ไม่ต้อง await ทีละอัน
      await Future.wait([_fetchCameras(page: 1), _fetchCameraStats()]);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Data fetching
  // ---------------------------------------------------------------------------

  Future<void> _fetchCameras({required int page, String search = ''}) async {
    if (!mounted) return;
    safeSetState(() => _model.isLoading = true);

    try {
      final response = await CameraService().getCameras(
        page: page.toString(),
        limit: ListCameraPageModel.pageSize.toString(),
        search: search.isNotEmpty ? search : null,
      );

      if (response.succeeded) {
        final dataList = CameraService().parseDataList(response.jsonBody) ?? [];

        // ── Sort: exact/prefix name match float to top ──────────────────────
        final q = search.toLowerCase();
        if (q.isNotEmpty) {
          dataList.sort((a, b) {
            final nameA =
                (getJsonField(a, r'$.name')?.toString() ?? '').toLowerCase();
            final nameB =
                (getJsonField(b, r'$.name')?.toString() ?? '').toLowerCase();
            final aExact = nameA == q;
            final bExact = nameB == q;
            if (aExact && !bExact) return -1;
            if (!aExact && bExact) return 1;
            final aStarts = nameA.startsWith(q);
            final bStarts = nameB.startsWith(q);
            if (aStarts && !bStarts) return -1;
            if (!aStarts && bStarts) return 1;
            final aContains = nameA.contains(q);
            final bContains = nameB.contains(q);
            if (aContains && !bContains) return -1;
            if (!aContains && bContains) return 1;
            return nameA.compareTo(nameB);
          });
        }

        _model.listOFcamera = dataList;

        final meta = getJsonField(response.jsonBody, r'$.meta');
        if (meta is Map<String, dynamic>) {
          _model.totalCameras = (meta['totalItems'] as int?) ?? dataList.length;
          _model.totalPages = (meta['totalPages'] as int?) ?? 1;
        } else {
          _model.totalCameras = dataList.length;
          _model.totalPages = 1;
        }
      } else {
        debugPrint('API error: ${response.statusCode}');
        _model.listOFcamera = [];
      }

      _model.currentPage = page;
      _model.searchQuery = search;
    } catch (e) {
      debugPrint('Error fetching cameras: $e');
    } finally {
      if (mounted) safeSetState(() => _model.isLoading = false);
    }
  }

  Future<void> _fetchCameraStats() async {
    try {
      final response = await CameraService().getCamerasTotal();
      if (response.succeeded) {
        final body = response.jsonBody;
        _model.totalCameras = _parseInt(body?['total']);
        _model.onlineCameras = _parseInt(body?['online']);
        _model.offlineCameras = _parseInt(body?['offline']);
      }
      if (mounted) safeSetState(() {});
    } catch (e) {
      debugPrint('Error fetching camera stats: $e');
    }
  }

  static int _parseInt(dynamic v) =>
      v is int ? v : int.tryParse(v?.toString() ?? '') ?? 0;

  void _onSearchChanged(String value) {
    EasyDebounce.debounce(
      'camera_search',
      const Duration(milliseconds: 400),
      () => _fetchCameras(page: 1, search: value),
    );
  }

  Future<void> _refresh() =>
      Future.wait([_fetchCameras(page: 1, search: _model.searchQuery), _fetchCameraStats()]);

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  Future<void> _confirmDelete(BuildContext context, dynamic item) async {
    final name = getJsonField(item, r'$.name')?.toString() ?? 'this camera';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text('Are you sure you want to delete "$name"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final cameraId = getJsonField(item, r'$.id')?.toString() ?? '';
    if (cameraId.isEmpty) return;

    final response = await CameraService().deleteCamera(cameraId);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(response.succeeded
          ? 'Deleted "$name" successfully'
          : 'Failed to delete: ${response.statusCode}'),
      backgroundColor:
          response.succeeded ? const Color(0xFF16A34A) : const Color(0xFFEF4444),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ));

    await Future.wait([
      _fetchCameras(page: _model.currentPage, search: _model.searchQuery),
      _fetchCameraStats(),
    ]);
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: const Color(0xFFF3F4F6),
        appBar: AppBar(
          backgroundColor: Colors.white,
          automaticallyImplyLeading: false,
          title: wrapWithModel(
            model: _model.navBarMainModel,
            updateCallback: () => safeSetState(() {}),
            child: NavBarMainWidget(),
          ),
          centerTitle: false,
          toolbarHeight: AppTextStyles.navBarHeight,
          elevation: 2,
        ),
        body: SafeArea(
          top: true,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  'List Cameras',
                  style: FlutterFlowTheme.of(context).headlineLarge.override(
                        fontFamily: FlutterFlowTheme.of(context)
                            .headlineLargeFamily,
                        color: const Color(0xFF111827),
                        letterSpacing: 0,
                        useGoogleFonts: !FlutterFlowTheme.of(context)
                            .headlineLargeIsCustom,
                      ),
                ),
                const SizedBox(height: 20),

                // Stat cards
                _CameraStatRow(model: _model),
                const SizedBox(height: 24),

                // Main card
                _CameraTableCard(
                  model: _model,
                  onSearchChanged: _onSearchChanged,
                  onClearSearch: () {
                    _model.searchBarTextController?.clear();
                    _fetchCameras(page: 1, search: '');
                  },
                  onAddCamera: () async {
                    await showDialog(
                      context: context,
                      builder: (_) => const AddnewcameraWidget(),
                    );
                    await _refresh();
                  },
                  onPageChanged: (p) =>
                      _fetchCameras(page: p, search: _model.searchQuery),
                  buildTable: () => _buildDataTable(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Table
  // ---------------------------------------------------------------------------

  Widget _buildDataTable(BuildContext context) {
    const columns = ['Name', 'LatLong', 'Address', 'Status', 'Category', 'Action'];
    const columnWidths = <int, TableColumnWidth>{
      0: FlexColumnWidth(2),
      1: FlexColumnWidth(2),
      2: FlexColumnWidth(3),
      3: FlexColumnWidth(1.5),
      4: FlexColumnWidth(1.5),
      5: FlexColumnWidth(2),
    };

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Table(
        columnWidths: columnWidths,
        border: TableBorder(
            horizontalInside: BorderSide(color: Colors.grey.shade200)),
        children: [
          // Header
          TableRow(
            decoration:
                BoxDecoration(color: FlutterFlowTheme.of(context).primary),
            children: columns
                .map((col) => TableCell(
                      verticalAlignment: TableCellVerticalAlignment.middle,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 14),
                        child: Text(
                          col,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: AppTextStyles.tableHeader,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
          // Data rows
          ..._model.listOFcamera.asMap().entries.map((entry) {
            final i = entry.key;
            final item = entry.value;
            final name = getJsonField(item, r'$.name')?.toString() ?? '-';
            final status =
                getJsonField(item, r'$.status')?.toString() ?? 'unknown';

            return TableRow(
              decoration: BoxDecoration(
                color: i % 2 == 1 ? const Color(0xFFF9FAFB) : Colors.white,
              ),
              children: [
                // Name (highlight match)
                _NameCell(
                  name: name,
                  search: _model.searchQuery,
                ),
                // LatLong
                _TextCell(
                  getJsonField(item, r'$.latLong')?.toString() ?? '-',
                  fontSize: AppTextStyles.tableTimestamp,
                  color: const Color(0xFF6B7280),
                ),
                // Address
                _TextCell(
                  getJsonField(item, r'$.address')?.toString() ?? '-',
                  fontSize: AppTextStyles.tableTimestamp,
                ),
                // Status
                TableCell(
                  verticalAlignment: TableCellVerticalAlignment.middle,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    child: StatusChip(
                      status: status,
                      fontSize: AppTextStyles.commandSmall,
                    ),
                  ),
                ),
                // Categories
                TableCell(
                  verticalAlignment: TableCellVerticalAlignment.middle,
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: _buildCategoryChips(item),
                  ),
                ),
                // Actions
                TableCell(
                  verticalAlignment: TableCellVerticalAlignment.middle,
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _ActionBtn(
                          icon: Icons.remove_red_eye_outlined,
                          tooltip: 'View details',
                          color: FlutterFlowTheme.of(context).primary,
                          onPressed: () => showDialog(
                            context: context,
                            builder: (_) =>
                                DetailscameraWidget(cameraData: item),
                          ),
                        ),
                        _ActionBtn(
                          icon: Icons.edit_outlined,
                          tooltip: 'Edit',
                          color: const Color(0xFFF59E0B),
                          onPressed: () async {
                            final result = await showDialog<bool>(
                              context: context,
                              builder: (_) =>
                                  EditdatacameraWidget(cameraData: item),
                            );
                            if (result == true) {
                              await Future.wait([
                                _fetchCameras(
                                    page: _model.currentPage,
                                    search: _model.searchQuery),
                                _fetchCameraStats(),
                              ]);
                            }
                          },
                        ),
                        _ActionBtn(
                          icon: Icons.delete_outline,
                          tooltip: 'Delete',
                          color: const Color(0xFFEF4444),
                          onPressed: () => _confirmDelete(context, item),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCategoryChips(dynamic item) {
    final cats = getJsonField(item, r'$.categories');
    if (cats == null || (cats is List && cats.isEmpty)) {
      return const SizedBox.shrink();
    }
    final list = cats is List ? cats : [cats];
    final names = list
        .map((c) => c is Map ? c['name']?.toString() ?? '' : c.toString())
        .where((n) => n.isNotEmpty)
        .toList();
    if (names.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: names
          .map((n) =>
              CategoryChip(name: n, fontSize: AppTextStyles.tableStatus))
          .toList(),
    );
  }
}

// =============================================================================
// _CameraStatRow  — stat cards ที่ rebuild แค่ส่วนของตัวเอง
// =============================================================================

class _CameraStatRow extends StatelessWidget {
  final ListCameraPageModel model;
  const _CameraStatRow({required this.model});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _StatCard(
          icon: Icons.camera_outdoor,
          iconColor: FlutterFlowTheme.of(context).primary,
          label: 'Total cameras',
          count: model.totalCameras,
        ),
        const SizedBox(width: 16),
        _StatCard(
          icon: Icons.wifi,
          iconColor: const Color(0xFF16A34A),
          label: 'Online',
          count: model.onlineCameras,
        ),
        const SizedBox(width: 16),
        _StatCard(
          icon: Icons.wifi_off,
          iconColor: const Color(0xFFDC2626),
          label: 'Offline',
          count: model.offlineCameras,
        ),
      ],
    );
  }
}

// =============================================================================
// _StatCard
// =============================================================================

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final int count;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 110,
      constraints: const BoxConstraints(minWidth: 180, maxWidth: 260),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 26),
            ),
            const SizedBox(width: 16),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFF606A85),
                    fontSize: AppTextStyles.badge,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  count.toString(),
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF15161E),
                    fontSize: AppTextStyles.statCardHero,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// _CameraTableCard  — card wrapper: toolbar + table + pagination
// =============================================================================

class _CameraTableCard extends StatelessWidget {
  final ListCameraPageModel model;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final VoidCallback onAddCamera;
  final ValueChanged<int> onPageChanged;
  final Widget Function() buildTable;

  const _CameraTableCard({
    required this.model,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onAddCamera,
    required this.onPageChanged,
    required this.buildTable,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Toolbar
            Row(
              children: [
                Expanded(
                  child: _SearchBar(
                    controller: model.searchBarTextController,
                    focusNode: model.searchBarFocusNode,
                    onChanged: onSearchChanged,
                    onClear: onClearSearch,
                  ),
                ),
                const SizedBox(width: 12),
                _AddCameraButton(onPressed: onAddCamera),
              ],
            ),
            const SizedBox(height: 16),

            // Table / Loading / Empty
            if (model.isLoading)
              SizedBox(
                height: 300,
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                        FlutterFlowTheme.of(context).primary),
                  ),
                ),
              )
            else if (model.listOFcamera.isEmpty)
              const _EmptyState()
            else
              LayoutBuilder(builder: (context, constraints) {
                const double minWidth = 1100;
                final w = constraints.maxWidth;
                if (w >= minWidth) return buildTable();
                if (w >= 800) {
                  return Transform.scale(
                    scale: w / minWidth,
                    alignment: Alignment.topLeft,
                    child: SizedBox(width: minWidth, child: buildTable()),
                  );
                }
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(width: minWidth, child: buildTable()),
                );
              }),

            const SizedBox(height: 20),

            // Pagination
            if (!model.isLoading)
              Column(
                children: [
                  const Divider(height: 1, color: Color(0xFFE5E7EB)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Page ${model.currentPage} of ${model.totalPages}  '
                        '(Total ${model.totalCameras} items)',
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: AppTextStyles.labelSmall,
                        ),
                      ),
                      _Pagination(
                        currentPage: model.currentPage,
                        totalPages: model.totalPages,
                        onPageChanged: onPageChanged,
                      ),
                    ],
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// _SearchBar
// =============================================================================

class _SearchBar extends StatelessWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchBar({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: 'Search cameras by name...',
          hintStyle: const TextStyle(
              color: Color(0xFF9CA3AF), fontSize: AppTextStyles.labelNormal),
          prefixIcon: const Icon(Icons.search, color: Color(0xFF9CA3AF), size: 20),
          suffixIcon: (controller?.text.isNotEmpty ?? false)
              ? IconButton(
                  icon: const Icon(Icons.close, size: 18, color: Color(0xFF9CA3AF)),
                  onPressed: onClear,
                )
              : null,
          filled: true,
          fillColor: const Color(0xFFF9FAFB),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide:
                BorderSide(color: FlutterFlowTheme.of(context).primary),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// _AddCameraButton
// =============================================================================

class _AddCameraButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _AddCameraButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.add, size: 18),
      label: const Text('Add Camera'),
      style: ElevatedButton.styleFrom(
        backgroundColor: FlutterFlowTheme.of(context).primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(
            fontWeight: FontWeight.w600, fontSize: AppTextStyles.labelNormal),
      ),
    );
  }
}

// =============================================================================
// _EmptyState
// =============================================================================

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.videocam_off, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'No camera data found',
              style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: AppTextStyles.labelNormal),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// _NameCell  — แสดง name และ highlight ส่วนที่ตรงกับ search
// =============================================================================

class _NameCell extends StatelessWidget {
  final String name;
  final String search;

  const _NameCell({required this.name, required this.search});

  @override
  Widget build(BuildContext context) {
    return TableCell(
      verticalAlignment: TableCellVerticalAlignment.middle,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: search.isEmpty
            ? Text(name,
                style: const TextStyle(
                    fontSize: AppTextStyles.tableCell,
                    color: Color(0xFF111827)))
            : _HighlightText(text: name, query: search),
      ),
    );
  }
}

/// Highlights matching substring in bold + primary color
class _HighlightText extends StatelessWidget {
  final String text;
  final String query;

  const _HighlightText({required this.text, required this.query});

  @override
  Widget build(BuildContext context) {
    final q = query.toLowerCase();
    final lower = text.toLowerCase();
    final idx = lower.indexOf(q);
    if (idx < 0) {
      return Text(text,
          style: const TextStyle(
              fontSize: AppTextStyles.tableCell, color: Color(0xFF111827)));
    }
    return RichText(
      text: TextSpan(
        style: const TextStyle(
            fontSize: AppTextStyles.tableCell, color: Color(0xFF111827)),
        children: [
          if (idx > 0) TextSpan(text: text.substring(0, idx)),
          TextSpan(
            text: text.substring(idx, idx + query.length),
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: FlutterFlowTheme.of(context).primary,
              backgroundColor:
                  FlutterFlowTheme.of(context).primary.withOpacity(0.1),
            ),
          ),
          if (idx + query.length < text.length)
            TextSpan(text: text.substring(idx + query.length)),
        ],
      ),
    );
  }
}

// =============================================================================
// _TextCell  — generic text table cell
// =============================================================================

class _TextCell extends StatelessWidget {
  final String text;
  final double fontSize;
  final Color? color;

  const _TextCell(this.text,
      {this.fontSize = AppTextStyles.tableCell, this.color});

  @override
  Widget build(BuildContext context) {
    return TableCell(
      verticalAlignment: TableCellVerticalAlignment.middle,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Text(
          text,
          style:
              TextStyle(fontSize: fontSize, color: color ?? const Color(0xFF111827)),
        ),
      ),
    );
  }
}

// =============================================================================
// _ActionBtn
// =============================================================================

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onPressed;

  const _ActionBtn({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: AppTextStyles.tableCell + 12,
          height: AppTextStyles.tableCell + 12,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: AppTextStyles.tableCell, color: color),
        ),
      ),
    );
  }
}

// =============================================================================
// _Pagination
// =============================================================================

class _Pagination extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onPageChanged;

  const _Pagination({
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
  });

  List<int?> get _pageNums {
    final total = totalPages;
    final current = currentPage;
    if (total <= 7) return [for (int p = 1; p <= total; p++) p];
    final nums = <int?>[1];
    if (current > 3) nums.add(null);
    final start = (current - 1).clamp(2, total - 1);
    final end = (current + 1).clamp(2, total - 1);
    for (int p = start; p <= end; p++) nums.add(p);
    if (current < total - 2) nums.add(null);
    nums.add(total);
    return nums;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _NavBtn(
          icon: Icons.first_page,
          enabled: currentPage > 1,
          onTap: () => onPageChanged(1),
        ),
        const SizedBox(width: 2),
        _NavBtn(
          icon: Icons.chevron_left,
          enabled: currentPage > 1,
          onTap: () => onPageChanged(currentPage - 1),
        ),
        const SizedBox(width: 4),
        ..._pageNums.map((p) {
          if (p == null) {
            return const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Text('...',
                  style: TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: AppTextStyles.labelNormal)),
            );
          }
          final isActive = p == currentPage;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: InkWell(
              onTap: isActive ? null : () => onPageChanged(p),
              borderRadius: BorderRadius.circular(6),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isActive
                      ? FlutterFlowTheme.of(context).primary
                      : Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isActive
                        ? FlutterFlowTheme.of(context).primary
                        : const Color(0xFFD1D5DB),
                  ),
                ),
                child: Center(
                  child: Text(
                    '$p',
                    style: TextStyle(
                      color:
                          isActive ? Colors.white : const Color(0xFF374151),
                      fontWeight: FontWeight.w600,
                      fontSize: AppTextStyles.badge,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
        const SizedBox(width: 4),
        _NavBtn(
          icon: Icons.chevron_right,
          enabled: currentPage < totalPages,
          onTap: () => onPageChanged(currentPage + 1),
        ),
        const SizedBox(width: 2),
        _NavBtn(
          icon: Icons.last_page,
          enabled: currentPage < totalPages,
          onTap: () => onPageChanged(totalPages),
        ),
      ],
    );
  }
}

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _NavBtn(
      {required this.icon, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color:
                enabled ? const Color(0xFFD1D5DB) : const Color(0xFFE5E7EB),
          ),
        ),
        child: Icon(icon,
            size: 20,
            color: enabled
                ? const Color(0xFF374151)
                : const Color(0xFFD1D5DB)),
      ),
    );
  }
}