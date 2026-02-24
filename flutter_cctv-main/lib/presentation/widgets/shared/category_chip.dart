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