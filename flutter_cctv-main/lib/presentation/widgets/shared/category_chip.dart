import 'package:flutter/material.dart';

class CategoryChip extends StatelessWidget {
  final String name;
  final double fontSize;
  final EdgeInsetsGeometry padding;

  const CategoryChip({
    super.key,
    required this.name,
    this.fontSize = 14,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  });

  static const List<_ChipColor> _chipPalette = [
    _ChipColor(bg: Color(0xFFEDE9FE), text: Color(0xFF5B21B6)), // violet
    _ChipColor(bg: Color(0xFFDBEAFE), text: Color(0xFF1D4ED8)), // blue
    _ChipColor(bg: Color(0xFFD1FAE5), text: Color(0xFF065F46)), // green
    _ChipColor(bg: Color(0xFFFEF3C7), text: Color(0xFF92400E)), // amber
    _ChipColor(bg: Color(0xFFFCE7F3), text: Color(0xFF9F1239)), // rose
    _ChipColor(bg: Color(0xFFCCFBF1), text: Color(0xFF115E59)), // teal
    _ChipColor(bg: Color(0xFFE0E7FF), text: Color(0xFF3730A3)), // indigo
    _ChipColor(bg: Color(0xFFFFEDD5), text: Color(0xFF9A3412)), // orange
    _ChipColor(bg: Color(0xFFF3E8FF), text: Color(0xFF6B21A8)), // purple
    _ChipColor(bg: Color(0xFFD1FAE5), text: Color(0xFF047857)), // emerald
    _ChipColor(bg: Color(0xFFE0F2FE), text: Color(0xFF075985)), // sky
    _ChipColor(bg: Color(0xFFFEE2E2), text: Color(0xFFB91C1C)), // red
  ];

  static _ChipColor colorFor(String name) {
    final idx = name.codeUnits.fold(0, (a, b) => a + b) % _chipPalette.length;
    return _chipPalette[idx];
  }

  @override
  Widget build(BuildContext context) {
    final col = colorFor(name);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: col.bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        name,
        style: TextStyle(
          color: col.text,
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ChipColor {
  final Color bg;
  final Color text;
  const _ChipColor({required this.bg, required this.text});
}