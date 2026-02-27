import '/data/services/index.dart';
import '/utils/flutter_flow/icon_button.dart';
import '/utils/flutter_flow/theme.dart';
import '/utils/flutter_flow/util.dart';
import '/utils/flutter_flow/widgets.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/editdatacamera_model.dart';
export '../models/editdatacamera_model.dart';

class EditdatacameraWidget extends StatefulWidget {
  const EditdatacameraWidget({
    super.key,
    required this.cameraData,
  });

  final dynamic? cameraData;

  @override
  State<EditdatacameraWidget> createState() => _EditdatacameraWidgetState();
}

class _EditdatacameraWidgetState extends State<EditdatacameraWidget> {
  late EditdatacameraModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => EditdatacameraModel());

    _model.textController1 ??=
        TextEditingController(text: widget!.cameraData?['name']);
    _model.textFieldFocusNode1 ??= FocusNode();
    _model.textFieldFocusNode1!.addListener(() => safeSetState(() {}));
    _model.textController2 ??=
        TextEditingController(text: widget!.cameraData?['latLong']?.toString());
    _model.textFieldFocusNode2 ??= FocusNode();

    _model.textController3 ??=
        TextEditingController(text: widget!.cameraData?['address']);
    _model.textFieldFocusNode3 ??= FocusNode();

    _model.textController4 ??=
        TextEditingController(text: widget!.cameraData?['rtspUrl']);
    _model.textFieldFocusNode4 ??= FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
Widget build(BuildContext context) {
  context.watch<AppState>();

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
                    const Color(0xFFFBBF24),
                    const Color(0xFFFCD34D),
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
                      Icons.edit_outlined,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text(
                      'Edit Camera',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: AppTextStyles.sectionTitle,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),

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

                    _editField(context, 'Camera Name',
                        _model.textController1!, _model.textFieldFocusNode1!,
                        hint: 'e.g. C8 T.T.San Tai'),

                    const SizedBox(height: 18),

                    _editField(context, 'LatLong',
                        _model.textController2!, _model.textFieldFocusNode2!,
                        hint: '20.412001,99.994481'),

                    const SizedBox(height: 18),

                    _editField(context, 'Address',
                        _model.textController3!, _model.textFieldFocusNode3!,
                        hint: 'ที่อยู่',
                        maxLines: 2),

                    const SizedBox(height: 18),

                    _editField(context, 'RTSP URL',
                        _model.textController4!, _model.textFieldFocusNode4!,
                        hint: 'rtsp://...',
                        required: false),

                    const SizedBox(height: 30),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              side: const BorderSide(
                                  color: Color(0xFFD1D5DB)),
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                color: Color(0xFF374151),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF59E0B),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                            ),
                            onPressed: () async {
                              final cameraId =
                                  widget!.cameraData?['id']?.toString() ?? '';
                              if (cameraId.isEmpty) return;

                              final response =
                                  await CameraService().editCamera(
                                cameraId: cameraId,
                                name:
                                    _model.textController1?.text ?? '',
                                latLong:
                                    _model.textController2?.text ?? '',
                                address:
                                    _model.textController3?.text ?? '',
                                rtspUrl:
                                    _model.textController4?.text ?? '',
                              );

                              if (!mounted) return;

                              if (response.succeeded) {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(
                                  SnackBar(
                                    content:
                                        const Text('saved successfully'),
                                    backgroundColor:
                                        const Color(0xFF16A34A),
                                    behavior:
                                        SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(8)),
                                  ),
                                );
                                Navigator.pop(context, true);
                              } else {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'Failed to save: ${response.statusCode}'),
                                    backgroundColor:
                                        const Color(0xFFEF4444),
                                    behavior:
                                        SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(8)),
                                  ),
                                );
                              }
                            },
                            child: const Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [
                                Icon(Icons.save_outlined,
                                    size: 18,
                                    color: Colors.white),
                                SizedBox(width: 8),
                                Text(
                                  'Save',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
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
  );
}

  Widget _editField(
    BuildContext context,
    String label,
    TextEditingController ctrl,
    FocusNode fn, {
    String hint = '',
    int maxLines = 1,
    bool required = true,
  }) {
    final primary = FlutterFlowTheme.of(context).primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: GoogleFonts.plusJakartaSans(
              color: const Color(0xFF374151),
              fontSize: AppTextStyles.labelSmall,
              fontWeight: FontWeight.w600,
            ),
            children: required
                ? [const TextSpan(text: ' *', style: TextStyle(color: Color(0xFFEF4444)))]
                : [],
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          focusNode: fn,
          maxLines: maxLines,
          style: const TextStyle(color: Color(0xFF111827), fontSize: AppTextStyles.labelNormal),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: AppTextStyles.labelNormal),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: primary, width: 1.5),
            ),
          ),
          cursorColor: primary,
        ),
      ],
    );
  }
}