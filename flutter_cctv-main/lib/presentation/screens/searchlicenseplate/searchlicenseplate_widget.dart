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
    _model.searchBarController.addListener(() => safeSetState(() {}));

    SchedulerBinding.instance.addPostFrameCallback((_) async {
      final fullPlate = Uri.base.queryParameters['fullPlate'] ?? '';
      if (fullPlate.isNotEmpty) {
        _model.searchBarController.text = fullPlate;
      }
      await _fetchPlates(page: 1, search: fullPlate);
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

        _model.listOfPlates = _model.listOfPlates
          ..sort((a, b) {
            final plateA = (a['licensePlate']?['fullPlate'] ?? '').toString().toLowerCase();
            final plateB = (b['licensePlate']?['fullPlate'] ?? '').toString().toLowerCase();
            final searchLower = search.toLowerCase();
            final aStartsWith = plateA.startsWith(searchLower);
            final bStartsWith = plateB.startsWith(searchLower);
            if (aStartsWith && !bStartsWith) return -1;
            if (!aStartsWith && bStartsWith) return 1;
            final timeA = a['timestamp'] ?? '';
            final timeB = b['timestamp'] ?? '';
            return timeB.compareTo(timeA);
          });

        _model.totalItems = _model.listOfPlates.length;
        _model.totalPages =
            (_model.totalItems / ListPlatePageModel.pageSize).ceil().clamp(1, 9999);
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

  List<Map<String, dynamic>> _parsePlateList(dynamic body) {
    List<dynamic> raw;
    if (body is List) {
      raw = body;
    } else {
      final dataField = getJsonField(body, r'$.data');
      raw = dataField is List ? dataField : [];
    }
    return raw
        .map((item) => item is Map<String, dynamic> ? item : <String, dynamic>{})
        .toList();
  }

  List<Map<String, dynamic>> _sortPlates(
      List<Map<String, dynamic>> list, String search) {
    final searchLower = search.toLowerCase();
    return list
      ..sort((a, b) {
        final plateA =
            (a['licensePlate']?['fullPlate'] ?? '').toString().toLowerCase();
        final plateB =
            (b['licensePlate']?['fullPlate'] ?? '').toString().toLowerCase();
        final aStarts = plateA.startsWith(searchLower);
        final bStarts = plateB.startsWith(searchLower);
        if (aStarts && !bStarts) return -1;
        if (!aStarts && bStarts) return 1;
        return (b['timestamp'] ?? '').compareTo(a['timestamp'] ?? '');
      });
  }

  void _onSearchChanged(String value) {
    EasyDebounce.debounce(
      'plate_search',
      const Duration(milliseconds: 500),
      () => _fetchPlates(page: 1, search: value),
    );
  }

  
  /// "20260215_224822" → "15/02/2026 22:48:22"
  static String _formatTimestamp(String raw) {
    try {
      if (raw.length < 15) return raw;
      final y = raw.substring(0, 4);
      final mo = raw.substring(4, 6);
      final d = raw.substring(6, 8);
      final h = raw.substring(9, 11);
      final mi = raw.substring(11, 13);
      final s = raw.substring(13, 15);
      return '$d/$mo/$y $h:$mi:$s';
    } catch (_) {
      return raw;
    }
  }

  void _openImageViewer(
    BuildContext context,
    String imageUrl, {
    String? plateText,
    String? province,
  }) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => _ImageViewerDialog(
        imageUrl: imageUrl,
        plateText: plateText,
        province: province,
      ),
    );
  }

  
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
                // Title
                Text(
                  'Search License Plate',
                  style: FlutterFlowTheme.of(context).headlineLarge.override(
                        fontFamily:
                            FlutterFlowTheme.of(context).headlineLargeFamily,
                        color: const Color(0xFF111827),
                        letterSpacing: 0,
                        useGoogleFonts: !FlutterFlowTheme.of(context)
                            .headlineLargeIsCustom,
                      ),
                ),
                const SizedBox(height: 24),

                // Main card
                _MainCard(
                  model: _model,
                  onSearchChanged: _onSearchChanged,
                  onClearSearch: () {
                    _model.searchBarController.clear();
                    _fetchPlates(page: 1);
                  },
                  onPageChanged: (page) =>
                      _fetchPlates(page: page, search: _model.searchQuery),
                  buildTable: () => _buildDataTable(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  

  Widget _buildDataTable(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(2.0),
          1: FlexColumnWidth(2.0),
          2: FlexColumnWidth(2.2),
          3: FlexColumnWidth(2.0),
        },
        border: TableBorder(
          horizontalInside: BorderSide(color: Colors.grey.shade200),
        ),
        children: [
          _buildTableHeader(context),
          ..._buildTableRows(context),
        ],
      ),
    );
  }

  TableRow _buildTableHeader(BuildContext context) {
    return TableRow(
      decoration: BoxDecoration(color: FlutterFlowTheme.of(context).primary),
      children: ['Full License Plate', 'Camera ID', 'Timestamp', 'Image']
          .map(
            (col) => TableCell(
              verticalAlignment: TableCellVerticalAlignment.middle,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                child: Text(
                  col,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: AppTextStyles.tableHeader,
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  List<TableRow> _buildTableRows(BuildContext context) {
    return _model.listOfPlates.asMap().entries.map((entry) {
      final i = entry.key;
      final item = entry.value;

      final plate = item['licensePlate'] as Map<String, dynamic>?;
      final fullPlate = plate?['fullPlate'] as String? ?? '-';
      final province = plate?['province'] as String? ?? '';
      final cameraId = item['cameraId'] as String? ?? '-';
      final timestamp = item['timestamp'] as String? ?? '-';
      final imageUrl = item['imageUrl'] as String? ?? '';

      return TableRow(
        decoration: BoxDecoration(
          color: i % 2 == 1 ? const Color(0xFFF9FAFB) : Colors.white,
        ),
        children: [
          // Full plate + province
          _PlateCell(fullPlate: fullPlate, province: province),

          // Camera ID
          _IconLabelCell(
            icon: Icons.videocam_outlined,
            label: cameraId,
            fontSize: AppTextStyles.tableCell,
          ),

          // Timestamp
          _IconLabelCell(
            icon: Icons.access_time,
            label: _formatTimestamp(timestamp),
            fontSize: AppTextStyles.tableTimestamp,
            labelColor: const Color(0xFF6B7280),
            iconColor: Colors.grey.shade400,
          ),

          // Image thumbnail
          TableCell(
            verticalAlignment: TableCellVerticalAlignment.middle,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: imageUrl.isEmpty
                  ? const Icon(Icons.no_photography_outlined,
                      color: Color(0xFFD1D5DB), size: 28)
                  : _HoverableImage(
                      imageUrl: imageUrl,
                      fullPlate: fullPlate,
                      province: province,
                      onTap: () => _openImageViewer(
                        context,
                        imageUrl,
                        plateText: fullPlate,
                        province: province,
                      ),
                    ),
            ),
          ),
        ],
      );
    }).toList();
  }
}



class _MainCard extends StatelessWidget {
  final ListPlatePageModel model;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final ValueChanged<int> onPageChanged;
  final Widget Function() buildTable;

  const _MainCard({
    required this.model,
    required this.onSearchChanged,
    required this.onClearSearch,
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
                _SearchBar(
                  controller: model.searchBarController,
                  focusNode: model.searchBarFocusNode,
                  onChanged: onSearchChanged,
                  onClear: onClearSearch,
                ),
                const Spacer(),
                _TotalBadge(total: model.totalItems),
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
                      FlutterFlowTheme.of(context).primary,
                    ),
                  ),
                ),
              )
            else if (model.listOfPlates.isEmpty)
              const _EmptyState()
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: MediaQuery.of(context).size.width - 88,
                  ),
                  child: buildTable(),
                ),
              ),

            const SizedBox(height: 20),

            // Pagination
            if (!model.isLoading && model.totalPages > 1)
              Column(
                children: [
                  const Divider(height: 1, color: Color(0xFFE5E7EB)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Page ${model.currentPage} of ${model.totalPages}  '
                        '(Total ${model.totalItems} items)',
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


class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
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
      width: MediaQuery.of(context).size.width * 0.5,
      height: 48,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: 'Search license plate, camera...',
          hintStyle: const TextStyle(
              color: Color(0xFF9CA3AF), fontSize: AppTextStyles.labelNormal),
          prefixIcon:
              const Icon(Icons.search, color: Color(0xFF9CA3AF), size: 22),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close,
                      size: 20, color: Color(0xFF9CA3AF)),
                  onPressed: onClear,
                )
              : null,
          filled: true,
          fillColor: const Color(0xFFF9FAFB),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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

class _TotalBadge extends StatelessWidget {
  final int total;

  const _TotalBadge({required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.directions_car,
              size: 15, color: FlutterFlowTheme.of(context).primary),
          const SizedBox(width: 6),
          Text(
            'Total $total items',
            style: TextStyle(
              color: FlutterFlowTheme.of(context).primary,
              fontWeight: FontWeight.w600,
              fontSize: AppTextStyles.badge,
            ),
          ),
        ],
      ),
    );
  }
}


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
            Icon(Icons.no_crash, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'No license plate data found',
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


// _Pagination
class _Pagination extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onPageChanged;

  const _Pagination({
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final start = (currentPage - 2).clamp(1, totalPages);
    final end = (currentPage + 2).clamp(1, totalPages);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _PageNavBtn(
          icon: Icons.chevron_left,
          enabled: currentPage > 1,
          onTap: () => onPageChanged(currentPage - 1),
        ),
        const SizedBox(width: 4),
        for (int p = start; p <= end; p++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: _PageNumberBtn(
              page: p,
              isActive: p == currentPage,
              onTap: () => onPageChanged(p),
            ),
          ),
        const SizedBox(width: 4),
        _PageNavBtn(
          icon: Icons.chevron_right,
          enabled: currentPage < totalPages,
          onTap: () => onPageChanged(currentPage + 1),
        ),
      ],
    );
  }
}

class _PageNavBtn extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _PageNavBtn({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

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
}

class _PageNumberBtn extends StatelessWidget {
  final int page;
  final bool isActive;
  final VoidCallback onTap;

  const _PageNumberBtn({
    required this.page,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isActive ? null : onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isActive ? FlutterFlowTheme.of(context).primary : Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isActive
                ? FlutterFlowTheme.of(context).primary
                : const Color(0xFFD1D5DB),
          ),
        ),
        child: Center(
          child: Text(
            '$page',
            style: TextStyle(
              color: isActive ? Colors.white : const Color(0xFF374151),
              fontWeight: FontWeight.w600,
              fontSize: AppTextStyles.badge,
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Table cell widgets
// =============================================================================

/// License plate number + province sub-text
class _PlateCell extends StatelessWidget {
  final String fullPlate;
  final String province;

  const _PlateCell({required this.fullPlate, required this.province});

  @override
  Widget build(BuildContext context) {
    return TableCell(
      verticalAlignment: TableCellVerticalAlignment.middle,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              fullPlate,
              style: GoogleFonts.sarabun(
                fontSize: AppTextStyles.tablePlate,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF111827),
              ),
            ),
            if (province.isNotEmpty)
              Text(
                province,
                style: const TextStyle(
                  fontSize: AppTextStyles.tableProvince,
                  color: Color(0xFF6B7280),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A cell with a leading icon and a text label (used for cameraId & timestamp)
class _IconLabelCell extends StatelessWidget {
  final IconData icon;
  final String label;
  final double fontSize;
  final Color labelColor;
  final Color iconColor;

  const _IconLabelCell({
    required this.icon,
    required this.label,
    required this.fontSize,
    this.labelColor = const Color(0xFF374151),
    this.iconColor = const Color(0xFF9CA3AF),
  });

  @override
  Widget build(BuildContext context) {
    return TableCell(
      verticalAlignment: TableCellVerticalAlignment.middle,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24, color: iconColor),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                style: TextStyle(fontSize: fontSize, color: labelColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// _ImageViewerDialog  (extracted from inline showDialog builder)

class _ImageViewerDialog extends StatelessWidget {
  final String imageUrl;
  final String? plateText;
  final String? province;

  const _ImageViewerDialog({
    required this.imageUrl,
    this.plateText,
    this.province,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Stack(
        children: [
          // Dismiss on tap outside
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
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

                // Plate info
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
                          plateText!,
                          style: GoogleFonts.sarabun(
                            fontSize: AppTextStyles.tablePlate,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF111827),
                          ),
                        ),
                        if (province != null && province!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              province!,
                              style: GoogleFonts.sarabun(
                                fontSize: AppTextStyles.tableProvince,
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
                TextButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Colors.white70),
                  label: const Text('close',
                      style: TextStyle(color: Colors.white70)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


// _HoverableImage
class _HoverableImage extends StatefulWidget {
  final String imageUrl;
  final String fullPlate;
  final String province;
  final VoidCallback onTap;

  const _HoverableImage({
    required this.imageUrl,
    required this.fullPlate,
    required this.province,
    required this.onTap,
  });

  @override
  State<_HoverableImage> createState() => _HoverableImageState();
}

class _HoverableImageState extends State<_HoverableImage> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 90,
          height: 54,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: _isHovering
                  ? FlutterFlowTheme.of(context).primary
                  : Colors.grey.shade300,
              width: _isHovering ? 2 : 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  widget.imageUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (ctx, child, progress) => progress == null
                      ? child
                      : Container(
                          color: const Color(0xFFF3F4F6),
                          child: const Center(
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        ),
                  errorBuilder: (_, __, ___) => Container(
                    color: const Color(0xFFF3F4F6),
                    child: const Icon(Icons.broken_image,
                        color: Color(0xFFD1D5DB), size: 24),
                  ),
                ),
                // Hover overlay
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: _isHovering ? 1.0 : 0.0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: FlutterFlowTheme.of(context)
                          .primary
                          .withOpacity(0.3),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.zoom_in,
                        color: Colors.white,
                        size: 32,
                        shadows: [Shadow(color: Colors.black45, blurRadius: 4)],
                      ),
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
