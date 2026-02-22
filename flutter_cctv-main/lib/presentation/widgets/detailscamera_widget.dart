import '/utils/flutter_flow_icon_button.dart';
import '/utils/flutter_flow_theme.dart';
import '/utils/flutter_flow_util.dart';
import '/utils/flutter_flow_widgets.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'detailscamera_model.dart';
export 'detailscamera_model.dart';

class DetailscameraWidget extends StatefulWidget {
  const DetailscameraWidget({
    super.key,
    required this.cameraData,
  });

  final dynamic? cameraData;

  @override
  State<DetailscameraWidget> createState() => _DetailscameraWidgetState();
}

class _DetailscameraWidgetState extends State<DetailscameraWidget> {
  late DetailscameraModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => DetailscameraModel());

    _model.textController1 ??=
        TextEditingController(text: widget!.cameraData?['address']);
    _model.textFieldFocusNode1 ??= FocusNode();

    _model.textController2 ??=
        TextEditingController(text: widget!.cameraData?['latLong']?.toString());
    _model.textFieldFocusNode2 ??= FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
Widget build(BuildContext context) {
  final data = widget!.cameraData;
  final isOnline = data?['status'] == 'online';
  final name = data?['name']?.toString() ?? '-';
  final latLong = data?['latLong']?.toString() ?? '-';
  final address = data?['address']?.toString() ?? '-';
  final rtspUrl = data?['rtspUrl']?.toString() ?? '';
  final cats = data?['categories'];

  final primary = FlutterFlowTheme.of(context).primary;

  return Dialog(
    backgroundColor: Colors.transparent,
    insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
    child: Center(
      child: Container(
        width: 520,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 40,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            // ================= HEADER =================
            Container(
              padding: const EdgeInsets.fromLTRB(28, 22, 20, 22),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    primary,
                    primary.withOpacity(0.85),
                  ],
                ),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.videocam_outlined,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Status Badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isOnline
                          ? const Color(0xFF16A34A)
                          : const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isOnline ? 'Online' : 'Offline',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            // ================= BODY =================
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    _infoCard("LatLong", latLong),
                    _infoCard("Address", address),

                    if (rtspUrl.isNotEmpty)
                      _infoCard("RTSP URL", rtspUrl),

                    const SizedBox(height: 4),
                    _sectionLabel("Categories"),
                    const SizedBox(height: 8),
                    if (cats != null && cats is List && cats.isNotEmpty)
                      _categoryChips(cats)
                    else
                      const Text('-', style: TextStyle(color: Color(0xFF6B7280), fontSize: 14)),

                    const SizedBox(height: 30),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          padding:
                              const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          "Close",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _infoCard(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              color: const Color(0xFF6B7280),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF111827),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.plusJakartaSans(
        color: const Color(0xFF6B7280),
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }

  static const List<List<Color>> _catPalette = [
    [Color(0xFFEDE9FE), Color(0xFF5B21B6)],
    [Color(0xFFDBEAFE), Color(0xFF1E40AF)],
    [Color(0xFFD1FAE5), Color(0xFF065F46)],
    [Color(0xFFFEF3C7), Color(0xFF92400E)],
  ];

  Widget _categoryChips(List cats) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: cats.map((c) {
        final name = (c is Map ? c['name']?.toString() : c.toString()) ?? '';
        final idx = name.codeUnits.fold(0, (a, b) => a + b) % _catPalette.length;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _catPalette[idx][0],
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            name,
            style: TextStyle(
              color: _catPalette[idx][1],
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      }).toList(),
    );
  }
}