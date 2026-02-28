import '/utils/flutter_flow/icon_button.dart';
import '/utils/flutter_flow/theme.dart';
import '/utils/flutter_flow/util.dart';
import '/utils/flutter_flow/widgets.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/marker_info_popup_model.dart';
export '../models/marker_info_popup_model.dart';

class MarkerInfoPopupWidget extends StatefulWidget {
  const MarkerInfoPopupWidget({
    super.key,
    required this.cameraData,
    required this.onCloseTapped,
    this.onLiveFeedTapped,
  });

  final dynamic? cameraData;
  final Future Function()? onCloseTapped;
  final Future Function(String streamUrl, dynamic cameraDoc)?
      onLiveFeedTapped;

  @override
  State<MarkerInfoPopupWidget> createState() => _MarkerInfoPopupWidgetState();
}

class _MarkerInfoPopupWidgetState extends State<MarkerInfoPopupWidget> {
  late MarkerInfoPopupModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => MarkerInfoPopupModel());

    _model.textController1 ??=
        TextEditingController(text: widget.cameraData?['address']);
    _model.textFieldFocusNode1 ??= FocusNode();

    _model.textController2 ??=
        TextEditingController(text: widget.cameraData?['latLong']?.toString());
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
    final isOnline = widget.cameraData?['status']?.toString().toLowerCase() == 'online';
    final statusColor = isOnline ? Color(0xFF10B981) : Color(0xFFEF4444);
    final statusText = isOnline ? 'Online' : 'Offline';
    final cameraId = widget.cameraData?['id']?.toString() ?? '';
    final categories = widget.cameraData?['categories'] as List<dynamic>?;

    return Container(
      color: Colors.black.withOpacity(0.4),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
        child: Align(
          alignment: AlignmentDirectional(0.0, 0.0),
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Container(
              width: 520.0,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    blurRadius: 40.0,
                    color: Colors.black.withOpacity(0.25),
                    offset: Offset(0, 20),
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    blurRadius: 8.0,
                    color: Colors.black.withOpacity(0.1),
                    offset: Offset(0, 4),
                    spreadRadius: 0,
                  ),
                ],
                borderRadius: BorderRadius.circular(20.0),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Premium Header with formal gray color
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(24.0),
                    decoration: BoxDecoration(
                      color: Color(0xFF4B5563),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  // Premium camera icon badge
                                  Container(
                                    padding: EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.25),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.3),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.videocam_rounded,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  // Camera name and ID
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          valueOrDefault<String>(
                                            widget.cameraData?['name'],
                                            'Camera',
                                          ),
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: AppTextStyles.sectionTitle,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: -0.5,
                                            height: 1.2,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (cameraId.isNotEmpty) ...[
                                          SizedBox(height: 4),
                                          Text(
                                            'ID: $cameraId',
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(0.8),
                                              fontSize: AppTextStyles.commandBody,
                                              fontWeight: FontWeight.w500,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Close button with glass effect
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: IconButton(
                                onPressed: () => Navigator.pop(context),
                                icon: Icon(Icons.close_rounded, color: Colors.white),
                                iconSize: 20,
                                padding: EdgeInsets.all(8),
                                constraints: BoxConstraints(),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        // Status badge and categories
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            // Status badge with pulse effect
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: statusColor,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: statusColor.withOpacity(0.4),
                                    blurRadius: 8,
                                    spreadRadius: 0,
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.white.withOpacity(0.6),
                                          blurRadius: 4,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    statusText.toUpperCase(),
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: AppTextStyles.commandSmall,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Category tags
                            if (categories != null && categories.isNotEmpty)
                              ...categories.take(3).map((category) {
                                // category may be a plain String, a Map with 'name',
                                // or an object with a .name property — handle all cases
                                String categoryName;
                                try {
                                  if (category is String) {
                                    categoryName = category;
                                  } else if (category is Map) {
                                    categoryName = category['name']?.toString() ?? category.toString();
                                  } else {
                                    categoryName = (category as dynamic).name?.toString() ?? category.toString();
                                  }
                                } catch (_) {
                                  categoryName = category?.toString() ?? '';
                                }
                                return Container(
                                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.25),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.label_rounded,
                                        color: Colors.white,
                                        size: 12,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        categoryName,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: AppTextStyles.commandSmall,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Content with better spacing
                  Flexible(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Section title
                          Text(
                            'CAMERA DETAILS',
                            style: TextStyle(
                              fontSize: AppTextStyles.commandSmall,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade500,
                              letterSpacing: 1.2,
                            ),
                          ),
                          SizedBox(height: 16),

                          // Address
                          if (widget.cameraData?['address'] != null && 
                              widget.cameraData!['address'].toString().isNotEmpty)
                            _buildPremiumInfoCard(
                              Icons.location_on_rounded,
                              'Location',
                              widget.cameraData!['address'].toString(),
                              Color(0xFFEF4444),
                            ),

                          SizedBox(height: 12),

                          // Coordinates
                          if (widget.cameraData?['latLong'] != null)
                            _buildPremiumInfoCard(
                              Icons.my_location_rounded,
                              'Coordinates',
                              widget.cameraData!['latLong'].toString(),
                              Color(0xFF3B82F6),
                            ),

                          SizedBox(height: 12),

                          // RTSP URL (if available)
                          if (widget.cameraData?['rtspUrl'] != null &&
                              widget.cameraData!['rtspUrl'].toString().isNotEmpty)
                            _buildPremiumInfoCard(
                              Icons.link_rounded,
                              'Stream URL',
                              widget.cameraData!['rtspUrl'].toString(),
                              Color(0xFF8B5CF6),
                              isMonospace: true,
                              isCopyable: true,
                            ),

                          SizedBox(height: 24),

                          // Divider
                          Container(
                            height: 1,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  Colors.grey.shade300,
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),

                          SizedBox(height: 24),

                          // Action Buttons with better hierarchy
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: isOnline ? Color(0xFF6B7280) : null,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: isOnline
                                        ? [
                                            BoxShadow(
                                              color: Color(0xFF6B7280).withOpacity(0.3),
                                              blurRadius: 12,
                                              offset: Offset(0, 4),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: ElevatedButton(
                                    onPressed: isOnline
                                        ? () async {
                                            await widget.onLiveFeedTapped?.call(
                                              widget.cameraData?['rtspUrl'] ?? '',
                                              widget.cameraData,
                                            );
                                            Navigator.pop(context);
                                          }
                                        : null,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isOnline ? Colors.transparent : Colors.grey.shade200,
                                      foregroundColor: isOnline ? Colors.white : Colors.grey.shade500,
                                      shadowColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: EdgeInsets.zero,
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          isOnline ? Icons.play_circle_fill_rounded : Icons.videocam_off_rounded,
                                          size: 22,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          isOnline ? 'View Live Feed' : 'Camera Offline',
                                          style: TextStyle(
                                            fontSize: AppTextStyles.labelNormal,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          
                          // Helpful hint for offline cameras
                          if (!isOnline)
                            Padding(
                              padding: EdgeInsets.only(top: 12),
                              child: Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Color(0xFFFEF2F2),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Color(0xFFFECACA),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline_rounded,
                                      color: Color(0xFFEF4444),
                                      size: 16,
                                    ),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'This camera is currently offline and unavailable for viewing',
                                        style: TextStyle(
                                          color: Color(0xFFDC2626),
                                          fontSize: AppTextStyles.commandBody,
                                          fontWeight: FontWeight.w500,
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumInfoCard(
    IconData icon,
    String label,
    String value,
    Color accentColor, {
    bool isMonospace = false,
    bool isCopyable = false,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon with colored background
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: accentColor.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Icon(icon, color: accentColor, size: 20),
          ),
          SizedBox(width: 14),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    fontSize: AppTextStyles.commandSmall,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade500,
                    letterSpacing: 0.8,
                  ),
                ),
                SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        value,
                        style: TextStyle(
                          fontSize: AppTextStyles.labelNormal,
                          color: Colors.grey.shade800,
                          fontWeight: FontWeight.w600,
                          fontFamily: isMonospace ? 'monospace' : null,
                          height: 1.4,
                        ),
                      ),
                    ),
                    if (isCopyable) ...[
                      SizedBox(width: 8),
                      InkWell(
                        onTap: () {
                          // Copy to clipboard functionality
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Copied to clipboard'),
                              duration: Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        child: Container(
                          padding: EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: accentColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            Icons.content_copy_rounded,
                            color: accentColor,
                            size: 14,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}