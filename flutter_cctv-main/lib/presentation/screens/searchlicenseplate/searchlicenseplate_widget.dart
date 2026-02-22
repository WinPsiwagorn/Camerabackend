import '/data/services/index.dart';
import '/presentation/widgets/nav/views/nav_bar_main_widget.dart';
import '/utils/flutter_flow/theme.dart';
import '/utils/flutter_flow/util.dart';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'searchlicenseplate_model.dart';
export 'searchlicenseplate_model.dart';

class ListPlatePageWidget extends StatefulWidget {
  const ListPlatePageWidget({super.key});

  static String routeName = 'ListPlatePage';
  static String routePath = '/list-plate';

  @override
  State<ListPlatePageWidget> createState() => _ListPlatePageWidgetState();
}

class _ListPlatePageWidgetState extends State<ListPlatePageWidget> {
  late ListPlatePageModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ListPlatePageModel());

    SchedulerBinding.instance.addPostFrameCallback((_) async {
      await _fetchPlates(page: 1);
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

  Future<void> _fetchPlates({required int page, String search = ''}) async {
    if (!mounted) return;
    safeSetState(() => _model.isLoading = true);

    try {
      final response = await LicensePlateService().searchLicensePlates(
        licensePlate: search.isNotEmpty ? search : null,
      );

      if (response.succeeded) {
        final body = response.jsonBody;
        if (body is List) {
          _model.listOfPlates = body
              .map((item) => item is Map<String, dynamic>
                  ? item
                  : <String, dynamic>{})
              .toList();
        } else {
          // Try parsing as object with data array
          final dataList = getJsonField(body, r'$.data');
          if (dataList is List) {
            _model.listOfPlates = dataList
                .map((item) => item is Map<String, dynamic>
                    ? item
                    : <String, dynamic>{})
                .toList();
          } else {
            _model.listOfPlates = [];
          }
        }
        _model.totalItems = _model.listOfPlates.length;
        _model.totalPages = (_model.totalItems / ListPlatePageModel.pageSize).ceil().clamp(1, 9999);
      } else {
        debugPrint('API error: ${response.statusCode}');
        _model.listOfPlates = [];
      }

      _model.currentPage = page;
      _model.searchQuery = search;
    } catch (e) {
      debugPrint('Error fetching plates: $e');
    } finally {
      if (mounted) safeSetState(() => _model.isLoading = false);
    }
  }

  void _onSearchChanged(String value) {
    EasyDebounce.debounce(
      'plate_search',
      const Duration(milliseconds: 500),
      () => _fetchPlates(page: 1, search: value),
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String _formatTimestamp(String raw) {
    // "20260215_224822" → "15/02/2026 22:48:22"
    try {
      if (raw.length < 15) return raw;
      final date = raw.substring(0, 8);
      final time = raw.substring(9, 15);
      final y = date.substring(0, 4);
      final mo = date.substring(4, 6);
      final d = date.substring(6, 8);
      final h = time.substring(0, 2);
      final mi = time.substring(2, 4);
      final s = time.substring(4, 6);
      return '$d/$mo/$y $h:$mi:$s';
    } catch (_) {
      return raw;
    }
  }

  // ---------------------------------------------------------------------------
  // Full-screen image viewer
  // ---------------------------------------------------------------------------

  void _openImageViewer(BuildContext context, String imageUrl,
      {String? plateText, String? province}) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            // Dismiss on tap outside image
            GestureDetector(
              onTap: () => Navigator.of(ctx).pop(),
              child: Container(color: Colors.transparent),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Image
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.92,
                      maxHeight: MediaQuery.of(context).size.height * 0.78,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: InteractiveViewer(
                        minScale: 0.8,
                        maxScale: 5.0,
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.contain,
                          loadingBuilder: (ctx, child, progress) {
                            if (progress == null) return child;
                            return SizedBox(
                              width: 300,
                              height: 200,
                              child: Center(
                                child: CircularProgressIndicator(
                                  value: progress.expectedTotalBytes != null
                                      ? progress.cumulativeBytesLoaded /
                                          progress.expectedTotalBytes!
                                      : null,
                                  color: Colors.white,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (_, __, ___) => Container(
                            width: 300,
                            height: 200,
                            color: Colors.grey.shade800,
                            child: const Center(
                              child: Icon(Icons.broken_image,
                                  color: Colors.white54, size: 48),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (plateText != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            plateText,
                            style: GoogleFonts.sarabun(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF111827),
                            ),
                          ),
                          if (province != null && province.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                province,
                                style: GoogleFonts.sarabun(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF6B7280),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  // Close button
                  TextButton.icon(
                    onPressed: () => Navigator.of(ctx).pop(),
                    icon: const Icon(Icons.close, color: Colors.white70),
                    label: const Text('close',
                        style: TextStyle(color: Colors.white70)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Table
  // ---------------------------------------------------------------------------

  Widget _buildDataTable(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(2.0), // fullPlate
          1: FlexColumnWidth(2.0), // cameraId
          2: FlexColumnWidth(2.2), // timestamp
          3: FlexColumnWidth(2.0), // imageUrl (thumbnail)
        },
        border: TableBorder(
          horizontalInside: BorderSide(color: Colors.grey.shade200),
        ),
        children: [
          // ── Header ──────────────────────────────────────────────────────────
          TableRow(
            decoration: BoxDecoration(
              color: FlutterFlowTheme.of(context).primary,
            ),
            children: ['Full License Plate', 'Camera ID', 'Timestamp', 'Image']
                .map(
                  (col) => TableCell(
                    verticalAlignment: TableCellVerticalAlignment.middle,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 14),
                      child: Text(
                        col,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),

          // ── Data rows ───────────────────────────────────────────────────────
          ..._model.listOfPlates.asMap().entries.map((entry) {
            final i = entry.key;
            final item = entry.value;
            final isOdd = i % 2 == 1;

            final plate = item['licensePlate'] as Map<String, dynamic>?;
            final fullPlate = plate?['fullPlate'] as String? ?? '-';
            final province = plate?['province'] as String? ?? '';
            final cameraId = item['cameraId'] as String? ?? '-';
            final timestamp = item['timestamp'] as String? ?? '-';
            final imageUrl = item['imageUrl'] as String? ?? '';

            return TableRow(
              decoration: BoxDecoration(
                color: isOdd ? const Color(0xFFF9FAFB) : Colors.white,
              ),
              children: [
                // ── fullPlate ──────────────────────────────────────────────
                TableCell(
                  verticalAlignment: TableCellVerticalAlignment.middle,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          fullPlate,
                          style: GoogleFonts.sarabun(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF111827),
                          ),
                        ),
                        if (province.isNotEmpty)
                          Text(
                            province,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // ── cameraId ───────────────────────────────────────────────
                TableCell(
                  verticalAlignment: TableCellVerticalAlignment.middle,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.videocam_outlined,
                            size: 15, color: Colors.grey.shade500),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            cameraId,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF374151),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── timestamp ──────────────────────────────────────────────
                TableCell(
                  verticalAlignment: TableCellVerticalAlignment.middle,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.access_time,
                            size: 14, color: Colors.grey.shade400),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            _formatTimestamp(timestamp),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── imageUrl (thumbnail → full screen on tap) ──────────────
                TableCell(
                  verticalAlignment: TableCellVerticalAlignment.middle,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    child: imageUrl.isEmpty
                        ? const Icon(Icons.no_photography_outlined,
                            color: Color(0xFFD1D5DB), size: 28)
                        : GestureDetector(
                            onTap: () => _openImageViewer(
                              context,
                              imageUrl,
                              plateText: fullPlate,
                              province: province,
                            ),
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Image.network(
                                    imageUrl,
                                    width: 90,
                                    height: 54,
                                    fit: BoxFit.cover,
                                    loadingBuilder:
                                        (ctx, child, progress) =>
                                            progress == null
                                                ? child
                                                : Container(
                                                    width: 90,
                                                    height: 54,
                                                    color: const Color(
                                                        0xFFF3F4F6),
                                                    child: const Center(
                                                      child: SizedBox(
                                                        width: 18,
                                                        height: 18,
                                                        child:
                                                            CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 90,
                                      height: 54,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF3F4F6),
                                        borderRadius:
                                            BorderRadius.circular(6),
                                      ),
                                      child: const Icon(Icons.broken_image,
                                          color: Color(0xFFD1D5DB),
                                          size: 24),
                                    ),
                                  ),
                                ),
                                // Play/zoom overlay
                                Positioned(
                                  right: 4,
                                  bottom: 4,
                                  child: Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Icon(
                                      Icons.zoom_in,
                                      color: Colors.white,
                                      size: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
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

  // ---------------------------------------------------------------------------
  // Pagination
  // ---------------------------------------------------------------------------

  Widget _buildPagination(BuildContext context) {
    final total = _model.totalPages;
    final current = _model.currentPage;
    final start = (current - 2).clamp(1, total);
    final end = (current + 2).clamp(1, total);
    final pageNums = [for (int p = start; p <= end; p++) p];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _pageNavBtn(
          icon: Icons.chevron_left,
          enabled: current > 1,
          onTap: () =>
              _fetchPlates(page: current - 1, search: _model.searchQuery),
        ),
        const SizedBox(width: 4),
        ...pageNums.map(
          (p) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: GestureDetector(
              onTap: p == current
                  ? null
                  : () => _fetchPlates(
                      page: p, search: _model.searchQuery),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: p == current
                      ? FlutterFlowTheme.of(context).primary
                      : Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: p == current
                        ? FlutterFlowTheme.of(context).primary
                        : const Color(0xFFD1D5DB),
                  ),
                ),
                child: Center(
                  child: Text(
                    '$p',
                    style: TextStyle(
                      color: p == current
                          ? Colors.white
                          : const Color(0xFF374151),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
        _pageNavBtn(
          icon: Icons.chevron_right,
          enabled: current < total,
          onTap: () =>
              _fetchPlates(page: current + 1, search: _model.searchQuery),
        ),
      ],
    );
  }

  Widget _pageNavBtn({
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
        child: Icon(icon,
            size: 20,
            color: enabled
                ? const Color(0xFF374151)
                : const Color(0xFFD1D5DB)),
      ),
    );
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
                  'search license plate',
                  style: FlutterFlowTheme.of(context).headlineLarge.override(
                        fontFamily: FlutterFlowTheme.of(context)
                            .headlineLargeFamily,
                        color: const Color(0xFF111827),
                        letterSpacing: 0,
                        useGoogleFonts: !FlutterFlowTheme.of(context)
                            .headlineLargeIsCustom,
                      ),
                ),
                const SizedBox(height: 24),

                // ── Main card ────────────────────────────────────────────────
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
                        // ── Toolbar ───────────────────────────────────────────
                        Row(
                          children: [
                            // Total badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 7),
                              decoration: BoxDecoration(
                                color: FlutterFlowTheme.of(context)
                                    .primary
                                    .withOpacity(0.08),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.directions_car,
                                      size: 15,
                                      color: FlutterFlowTheme.of(context)
                                          .primary),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Total ${_model.totalItems} items',
                                    style: TextStyle(
                                      color: FlutterFlowTheme.of(context)
                                          .primary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Search
                            Expanded(
                              child: SizedBox(
                                height: 42,
                                child: TextField(
                                  controller: _model.searchBarController,
                                  focusNode: _model.searchBarFocusNode,
                                  onChanged: _onSearchChanged,
                                  decoration: InputDecoration(
                                    hintText: 'Search license plate, camera...',
                                    hintStyle: const TextStyle(
                                        color: Color(0xFF9CA3AF),
                                        fontSize: 14),
                                    prefixIcon: const Icon(Icons.search,
                                        color: Color(0xFF9CA3AF), size: 20),
                                    suffixIcon: (_model.searchBarController
                                                    .text
                                                    .isNotEmpty)
                                        ? IconButton(
                                            icon: const Icon(Icons.close,
                                                size: 18,
                                                color: Color(0xFF9CA3AF)),
                                            onPressed: () {
                                              _model.searchBarController
                                                  .clear();
                                              _fetchPlates(page: 1);
                                            },
                                          )
                                        : null,
                                    filled: true,
                                    fillColor: const Color(0xFFF9FAFB),
                                    contentPadding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 14, vertical: 10),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(
                                          color: Color(0xFFE5E7EB)),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(
                                          color: Color(0xFFE5E7EB)),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                          color: FlutterFlowTheme.of(context)
                                              .primary),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // ── Table / Loading / Empty ───────────────────────────
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
                            : _model.listOfPlates.isEmpty
                                ? SizedBox(
                                    height: 200,
                                    child: Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.no_crash,
                                              size: 48,
                                              color: Colors.grey.shade400),
                                          const SizedBox(height: 12),
                                          Text(
                                            'No license plate data found',
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
                                          minWidth:
                                              MediaQuery.of(context)
                                                      .size
                                                      .width -
                                                  88),
                                      child: _buildDataTable(context),
                                    ),
                                  ),

                        const SizedBox(height: 20),

                        // ── Pagination ────────────────────────────────────────
                        if (!_model.isLoading && _model.totalPages > 1)
                          Column(
                            children: [
                              const Divider(
                                  height: 1, color: Color(0xFFE5E7EB)),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Page ${_model.currentPage} of ${_model.totalPages}  '
                                    '(Total ${_model.totalItems} items)',
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