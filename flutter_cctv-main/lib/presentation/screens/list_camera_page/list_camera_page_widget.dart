import '/data/services/index.dart';
import '/presentation/widgets/camera/views/addnewcamera_widget.dart';
import '/presentation/widgets/camera/views/detailscamera_widget.dart';
import '/presentation/widgets/camera/views/editdatacamera_widget.dart';
import '/presentation/widgets/nav/views/nav_bar_main_widget.dart';
import '/utils/flutter_flow/icon_button.dart';
import '/utils/flutter_flow/theme.dart';
import '/utils/flutter_flow/util.dart';
import '/utils/flutter_flow/widgets.dart';
import 'dart:ui';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'list_camera_page_model.dart';
export 'list_camera_page_model.dart';

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

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ListCameraPageModel());

    // Rebuild when search text changes (so X button shows/hides)
    _model.searchBarTextController?.addListener(() => safeSetState(() {}));

    SchedulerBinding.instance.addPostFrameCallback((_) async {
      await _fetchCameras(page: 1);
      await _fetchCameraStats();
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

  /// Fetch a page of cameras from the API.
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
        _model.listOFcamera = dataList;

        // Parse meta from API response
        final meta = getJsonField(response.jsonBody, r'$.meta');
        if (meta != null && meta is Map<String, dynamic>) {
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

  /// Fetch summary counts (total / online / offline) from API.
  Future<void> _fetchCameraStats() async {
    try {
      final response = await CameraService().getCamerasTotal();

      if (response.succeeded) {
        final body = response.jsonBody;
        final total = body?['total'];
        final online = body?['online'];
        final offline = body?['offline'];

        _model.totalCameras = (total is int) ? total : int.tryParse(total?.toString() ?? '') ?? 0;
        _model.onlineCameras = (online is int) ? online : int.tryParse(online?.toString() ?? '') ?? 0;
        _model.offlineCameras = (offline is int) ? offline : int.tryParse(offline?.toString() ?? '') ?? 0;
      }

      if (mounted) safeSetState(() {});
    } catch (e) {
      debugPrint('Error fetching camera stats: $e');
    }
  }

  void _onSearchChanged(String value) {
    EasyDebounce.debounce(
      'camera_search',
      const Duration(milliseconds: 500),
      () => _fetchCameras(page: 1, search: value),
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

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
      spacing: 4,
      runSpacing: 4,
      children: names.map((name) {
        final col = _colorFor(name);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: col.bg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            name,
            style: TextStyle(
              color: col.text,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      }).toList(),
    );
  }

  // ---------------------------------------------------------------------------
  // UI builders
  // ---------------------------------------------------------------------------

  Widget _statCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String label,
    required int count,
  }) {
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
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  count.toString(),
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF15161E),
                    fontSize: 34,
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

  Widget _buildDataTable(BuildContext context) {
    final columns = ['Name', 'LatLong', 'Address', 'Status', 'Category', 'Action'];
    final columnWidths = <int, TableColumnWidth>{
      0: const FlexColumnWidth(2),
      1: const FlexColumnWidth(2),
      2: const FlexColumnWidth(3),
      3: const FlexColumnWidth(1.5),
      4: const FlexColumnWidth(1.5),
      5: const FlexColumnWidth(2),
    };

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Table(
        columnWidths: columnWidths,
        border: TableBorder(
          horizontalInside: BorderSide(color: Colors.grey.shade200),
        ),
        children: [
          // Header row
          TableRow(
            decoration: BoxDecoration(
              color: FlutterFlowTheme.of(context).primary,
            ),
            children: columns
                .map(
                  (col) => TableCell(
                    verticalAlignment: TableCellVerticalAlignment.middle,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 14),
                      child: Text(
                        col,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          // Data rows
          ..._model.listOFcamera.asMap().entries.map((entry) {
            final i = entry.key;
            final item = entry.value;
            final isOdd = i % 2 == 1;
            final status =
                getJsonField(item, r'$.status')?.toString() ?? 'unknown';
            final isOnline = status == 'online';

            return TableRow(
              decoration: BoxDecoration(
                color: isOdd ? const Color(0xFFF9FAFB) : Colors.white,
              ),
              children: [
                // Name
                _tableCell(
                  getJsonField(item, r'$.name')?.toString() ?? '-',
                ),
                // LatLong
                _tableCell(
                  getJsonField(item, r'$.latLong')?.toString() ?? '-',
                  fontSize: 12,
                  color: const Color(0xFF6B7280),
                ),
                // Address
                _tableCell(
                  getJsonField(item, r'$.address')?.toString() ?? '-',
                  fontSize: 12,
                ),
                // Status badge
                TableCell(
                  verticalAlignment: TableCellVerticalAlignment.middle,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 10),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isOnline
                              ? const Color(0xFFDCFCE7)
                              : const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isOnline
                                    ? const Color(0xFF16A34A)
                                    : const Color(0xFFDC2626),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isOnline ? 'Online' : 'Offline',
                              style: TextStyle(
                                color: isOnline
                                    ? const Color(0xFF15803D)
                                    : const Color(0xFFDC2626),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                // Categories
                TableCell(
                  verticalAlignment: TableCellVerticalAlignment.middle,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                    child: _buildCategoryChips(item),
                  ),
                ),
                // Actions
                TableCell(
                  verticalAlignment: TableCellVerticalAlignment.middle,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 4, vertical: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _actionButton(
                          icon: Icons.remove_red_eye_outlined,
                          tooltip: 'View details',
                          color: FlutterFlowTheme.of(context).primary,
                          onPressed: () async {
                            await showDialog(
                              context: context,
                              builder: (ctx) => DetailscameraWidget(
                                cameraData: item,
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 3),
                        _actionButton(
                          icon: Icons.edit_outlined,
                          tooltip: 'Edit',
                          color: const Color(0xFFF59E0B),
                          onPressed: () async {
                            final result = await showDialog(
                              context: context,
                              builder: (ctx) => EditdatacameraWidget(
                                cameraData: item,
                              ),
                            );
                            if (result == true) {
                              await _fetchCameras(
                                  page: _model.currentPage,
                                  search: _model.searchQuery);
                              await _fetchCameraStats();
                            }
                          },
                        ),
                        const SizedBox(width: 3),
                        _actionButton(
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

  TableCell _tableCell(String text,
      {double fontSize = 13, Color? color}) {
    return TableCell(
      verticalAlignment: TableCellVerticalAlignment.middle,
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Text(
          text,
          style: TextStyle(
            fontSize: fontSize,
            color: color ?? const Color(0xFF111827),
          ),
        ),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String tooltip,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 15, color: color),
        ),
      ),
    );
  }

  Widget _buildPagination(BuildContext context) {
    final total = _model.totalPages;
    final current = _model.currentPage;

    // Build visible page numbers with ellipsis logic
    final List<int?> pageNums = []; // null = ellipsis
    if (total <= 7) {
      for (int p = 1; p <= total; p++) pageNums.add(p);
    } else {
      pageNums.add(1);
      if (current > 3) pageNums.add(null); // ...
      final start = (current - 1).clamp(2, total - 1);
      final end = (current + 1).clamp(2, total - 1);
      for (int p = start; p <= end; p++) pageNums.add(p);
      if (current < total - 2) pageNums.add(null); // ...
      pageNums.add(total);
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // First
        _pageNavButton(
          icon: Icons.first_page,
          enabled: current > 1,
          onTap: () => _fetchCameras(page: 1, search: _model.searchQuery),
        ),
        const SizedBox(width: 2),
        // Prev
        _pageNavButton(
          icon: Icons.chevron_left,
          enabled: current > 1,
          onTap: () => _fetchCameras(
              page: current - 1, search: _model.searchQuery),
        ),
        const SizedBox(width: 4),
        // Page buttons
        ...pageNums.map(
          (p) {
            if (p == null) {
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Text('...', style: TextStyle(color: Color(0xFF6B7280), fontSize: 14)),
              );
            }
            final isActive = p == current;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: InkWell(
                onTap: isActive
                    ? null
                    : () => _fetchCameras(page: p, search: _model.searchQuery),
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
                        color: isActive ? Colors.white : const Color(0xFF374151),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(width: 4),
        // Next
        _pageNavButton(
          icon: Icons.chevron_right,
          enabled: current < total,
          onTap: () => _fetchCameras(
              page: current + 1, search: _model.searchQuery),
        ),
        const SizedBox(width: 2),
        // Last
        _pageNavButton(
          icon: Icons.last_page,
          enabled: current < total,
          onTap: () => _fetchCameras(page: total, search: _model.searchQuery),
        ),
      ],
    );
  }

  Widget _pageNavButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: enabled
                ? const Color(0xFFD1D5DB)
                : const Color(0xFFE5E7EB),
          ),
        ),
        child: Icon(
          icon,
          size: 20,
          color: enabled
              ? const Color(0xFF374151)
              : const Color(0xFFD1D5DB),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, dynamic item) async {
    final name = getJsonField(item, r'$.name')?.toString() ?? 'กล้องนี้';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ยืนยันการลบ'),
        content: Text('คุณต้องการลบ "$name" ใช่หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            onPressed: () => Navigator.pop(ctx, true),
            child:
                const Text('ลบ', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final cameraId = getJsonField(item, r'$.id')?.toString() ?? '';
      if (cameraId.isEmpty) return;

      final response = await CameraService().deleteCamera(cameraId);
      if (mounted) {
        if (response.succeeded) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('ลบ "$name" เรียบร้อยแล้ว'),
              backgroundColor: const Color(0xFF16A34A),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('ลบไม่สำเร็จ: ${response.statusCode}'),
              backgroundColor: const Color(0xFFEF4444),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          );
        }
      }
      await _fetchCameras(
          page: _model.currentPage, search: _model.searchQuery);
      await _fetchCameraStats();
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
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
          toolbarHeight: MediaQuery.sizeOf(context).height * 0.05,
          elevation: 2,
        ),
        body: SafeArea(
          top: true,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Page title ───────────────────────────────────────────────
                Text(
                  'List Cameras',
                  style: FlutterFlowTheme.of(context).headlineLarge.override(
                        fontFamily:
                            FlutterFlowTheme.of(context).headlineLargeFamily,
                        color: const Color(0xFF111827),
                        letterSpacing: 0,
                        useGoogleFonts: !FlutterFlowTheme.of(context)
                            .headlineLargeIsCustom,
                      ),
                ),
                const SizedBox(height: 20),

                // ── Summary cards ────────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _statCard(
                      context: context,
                      icon: Icons.camera_outdoor,
                      iconColor: FlutterFlowTheme.of(context).primary,
                      label: 'Total cameras',
                      count: _model.totalCameras,
                    ),
                    const SizedBox(width: 16),
                    _statCard(
                      context: context,
                      icon: Icons.wifi,
                      iconColor: const Color(0xFF16A34A),
                      label: 'Online',
                      count: _model.onlineCameras,
                    ),
                    const SizedBox(width: 16),
                    _statCard(
                      context: context,
                      icon: Icons.wifi_off,
                      iconColor: const Color(0xFFDC2626),
                      label: 'Offline',
                      count: _model.offlineCameras,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Card containing toolbar + table + pagination ──────────────
                Container(
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
                        // ── Toolbar: Search + Add camera ──────────────────────
                        Row(
                          children: [
                            // Search field
                            Expanded(
                              child: SizedBox(
                                height: 44,
                                child: TextField(
                                  controller:
                                      _model.searchBarTextController,
                                  focusNode: _model.searchBarFocusNode,
                                  onChanged: _onSearchChanged,
                                  decoration: InputDecoration(
                                    hintText: 'Search cameras...',
                                    hintStyle: const TextStyle(
                                        color: Color(0xFF9CA3AF),
                                        fontSize: 14),
                                    prefixIcon: const Icon(
                                        Icons.search,
                                        color: Color(0xFF9CA3AF),
                                        size: 20),
                                    suffixIcon: (_model
                                                    .searchBarTextController
                                                    ?.text
                                                    .isNotEmpty ??
                                                false)
                                        ? IconButton(
                                            icon: const Icon(Icons.close,
                                                size: 18,
                                                color: Color(0xFF9CA3AF)),
                                            onPressed: () {
                                              _model
                                                  .searchBarTextController
                                                  ?.clear();
                                              _fetchCameras(page: 1, search: '');
                                            },
                                          )
                                        : null,
                                    filled: true,
                                    fillColor: const Color(0xFFF9FAFB),
                                    contentPadding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 14, vertical: 10),
                                    border: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(8),
                                      borderSide: const BorderSide(
                                          color: Color(0xFFE5E7EB)),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(8),
                                      borderSide: const BorderSide(
                                          color: Color(0xFFE5E7EB)),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                          color: FlutterFlowTheme.of(context)
                                              .primary),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Add Camera button
                            ElevatedButton.icon(
                              onPressed: () async {
                                await showDialog(
                                  context: context,
                                  builder: (ctx) =>
                                      const AddnewcameraWidget(),
                                );
                                // Refresh after adding
                                await _fetchCameras(
                                    page: 1,
                                    search: _model.searchQuery);
                                await _fetchCameraStats();
                              },
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Add Camera'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    FlutterFlowTheme.of(context).primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 18, vertical: 12),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                                textStyle: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // ── Table ─────────────────────────────────────────────
                        _model.isLoading
                            ? SizedBox(
                                height: 300,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    valueColor:
                                        AlwaysStoppedAnimation<Color>(
                                      FlutterFlowTheme.of(context).primary,
                                    ),
                                  ),
                                ),
                              )
                            : _model.listOFcamera.isEmpty
                                ? SizedBox(
                                    height: 200,
                                    child: Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.videocam_off,
                                              size: 48,
                                              color: Colors.grey.shade400),
                                          const SizedBox(height: 12),
                                          Text(
                                            'No camera data found',
                                            style: TextStyle(
                                                color: Colors.grey.shade500,
                                                fontSize: 15),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                : SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                          minWidth: MediaQuery.of(context)
                                                  .size
                                                  .width -
                                              88),
                                      child: _buildDataTable(context),
                                    ),
                                  ),

                        const SizedBox(height: 20),

                        // ── Pagination ────────────────────────────────────────
                        if (!_model.isLoading)
                          Column(
                            children: [
                              const Divider(height: 1, color: Color(0xFFE5E7EB)),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Page ${_model.currentPage} of ${_model.totalPages}  '
                                    '(Total ${_model.totalCameras} items)',
                                    style: const TextStyle(
                                      color: Color(0xFF6B7280),
                                      fontSize: 13,
                                    ),
                                  ),
                                  _buildPagination(context),
                                ],
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
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