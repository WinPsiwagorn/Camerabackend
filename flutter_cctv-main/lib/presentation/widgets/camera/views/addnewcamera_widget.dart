import '/data/services/index.dart';
import '/utils/flutter_flow/theme.dart';
import '/utils/flutter_flow/util.dart';
import '/utils/flutter_flow/widgets.dart';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/addnewcamera_model.dart';
export '../models/addnewcamera_model.dart';

class AddnewcameraWidget extends StatefulWidget {
  const AddnewcameraWidget({super.key});

  @override
  State<AddnewcameraWidget> createState() => _AddnewcameraWidgetState();
}

class _AddnewcameraWidgetState extends State<AddnewcameraWidget> {
  late AddnewcameraModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AddnewcameraModel());
    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.maybeDispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Submit
  // ---------------------------------------------------------------------------

  Future<void> _submit() async {
    // Validate form
    if (!(_model.formKey.currentState?.validate() ?? false)) return;

    safeSetState(() => _model.isSubmitting = true);

    try {
      final response = await CameraService().createCamera(
        name: _model.textController1?.text.trim(),
        latLong: _model.textController2?.text.trim(),
        address: _model.textController3?.text.trim(),
        rtspUrl: _model.textController4?.text.trim(),
      );

      if (!mounted) return;

      if (response.succeeded) {
        // Close dialog and signal success to caller (pop(true) so parent can refresh)
        Navigator.of(context).pop(true);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Added camera "${_model.textController1?.text}" successfully',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: const Color(0xFF16A34A),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      } else {
        // API returned error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to create camera (${response.statusCode})',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: FlutterFlowTheme.of(context).error,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error creating camera: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error occurred: $e',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: FlutterFlowTheme.of(context).error,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } finally {
      if (mounted) safeSetState(() => _model.isSubmitting = false);
    }
  }

  // ---------------------------------------------------------------------------
  // UI helpers
  // ---------------------------------------------------------------------------

  Widget _field({
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode,
    String hint = '',
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
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
              color: const Color(0xFF374151), fontSize: 12, fontWeight: FontWeight.w600,
            ),
            children: required
                ? [const TextSpan(text: ' *', style: TextStyle(color: Color(0xFFEF4444)))]
                : [],
          ),
        ),
        const SizedBox(height: 5),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          autofocus: false,
          keyboardType: keyboardType,
          maxLines: maxLines,
          enabled: !_model.isSubmitting,
          style: const TextStyle(color: Color(0xFF111827), fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
            filled: true,
            fillColor: _model.isSubmitting ? const Color(0xFFF3F4F6) : const Color(0xFFF9FAFB),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(7), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(7), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(7), borderSide: BorderSide(color: primary, width: 1.5)),
            errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(7), borderSide: const BorderSide(color: Color(0xFFEF4444))),
            focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(7), borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5)),
            errorStyle: const TextStyle(fontSize: 11),
          ),
          cursorColor: primary,
          validator: validator,
        ),
      ],
    );
  }

  @override
Widget build(BuildContext context) {
  final theme = FlutterFlowTheme.of(context);
  final primary = theme.primary;

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
                      Icons.add_a_photo_outlined,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text(
                      'Add New Camera',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _model.isSubmitting
                        ? null
                        : () => Navigator.of(context).pop(false),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            // ================= BODY =================
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(28),
                child: Form(
                  key: _model.formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      _field(
                        label: 'Camera Name',
                        hint: 'e.g. C8 T.T.San Tai, M.10',
                        controller: _model.textController1!,
                        focusNode: _model.textFieldFocusNode1!,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty)
                                ? 'Required'
                                : null,
                      ),
                      const SizedBox(height: 18),

                      _field(
                        label: 'LatLong',
                        hint: '20.412001,99.994481',
                        controller: _model.textController2!,
                        focusNode: _model.textFieldFocusNode2!,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty)
                            return 'Required';
                          final p = v.trim().split(',');
                          if (p.length != 2)
                            return 'Format: lat,long';
                          if (double.tryParse(p[0].trim()) == null ||
                              double.tryParse(p[1].trim()) == null)
                            return 'Must be numbers';
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),

                      _field(
                        label: 'Address',
                        hint: 'ที่อยู่',
                        controller: _model.textController3!,
                        focusNode: _model.textFieldFocusNode3!,
                        maxLines: 2,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty)
                                ? 'Required'
                                : null,
                      ),
                      const SizedBox(height: 18),

                      _field(
                        label: 'RTSP URL',
                        hint: 'rtsp://...',
                        controller: _model.textController4!,
                        focusNode: _model.textFieldFocusNode4!,
                        keyboardType: TextInputType.url,
                        required: false,
                        validator: (v) {
                          if (v != null && v.trim().isNotEmpty) {
                            if (!v.trim().startsWith('rtsp://') &&
                                !v.trim().startsWith('http://') &&
                                !v.trim().startsWith('https://')) {
                              return 'Must start with rtsp://, http://, or https://';
                            }
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 32),

                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _model.isSubmitting
                                  ? null
                                  : () => Navigator.of(context).pop(false),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(14),
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
                              onPressed: _model.isSubmitting
                                  ? null
                                  : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primary,
                                disabledBackgroundColor:
                                    primary.withOpacity(0.6),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(14),
                                ),
                                elevation: 0,
                              ),
                              child: _model.isSubmitting
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child:
                                          CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        valueColor:
                                            AlwaysStoppedAnimation(
                                                Colors.white),
                                      ),
                                    )
                                  : const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.add,
                                            size: 18,
                                            color: Colors.white),
                                        SizedBox(width: 8),
                                        Text(
                                          'Save',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight:
                                                FontWeight.w700,
                                            fontSize: 15,
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
            ),
          ],
        ),
      ),
    ),
  );
}
}