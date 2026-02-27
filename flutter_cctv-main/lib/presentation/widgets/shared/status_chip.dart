import 'package:flutter/material.dart';

/// A chip that displays camera online / offline status.
///
/// Usage:
/// ```dart
/// StatusChip(status: 'online')
/// StatusChip(status: 'offline')
/// StatusChip(status: item['status'])
/// ```
class StatusChip extends StatelessWidget {
  final String status;

  /// Font size of the label text (defaults to 12).
  final double fontSize;

  /// Inner padding (defaults to symmetric horizontal 12, vertical 10).
  final EdgeInsetsGeometry padding;

  const StatusChip({
    super.key,
    required this.status,
    this.fontSize = 12,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
  });

  bool get _isOnline => status.toLowerCase() == 'online';

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: _isOnline
              ? const Color(0xFFDCFCE7) // green-100
              : const Color(0xFFFEE2E2), // red-100
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Dot indicator
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isOnline
                    ? const Color(0xFF16A34A) // green-600
                    : const Color(0xFFDC2626), // red-600
              ),
            ),
            const SizedBox(width: 4),
            Text(
              _isOnline ? 'Online' : 'Offline',
              style: TextStyle(
                color: _isOnline
                    ? const Color(0xFF15803D) // green-700
                    : const Color(0xFFDC2626), // red-600
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}