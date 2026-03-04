import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ──────────────────────────────────────────────────────────────────────────────
/// AppTextStyles  –  แก้ขนาด font ทั้งโปรเจคที่นี่ที่เดียว
/// ──────────────────────────────────────────────────────────────────────────────
abstract class AppTextStyles {
  // ── Font sizes ────────────────────────────────────────────────────────────
  static const double displayLarge    = 36;   // hero title (login)
  static const double pageTitle       = 28;   // หัวข้อหน้า
  static const double statCardHero    = 34;   // ตัวเลขใหญ่บน stat card (list camera)
  static const double sectionTitle    = 22;   // หัวข้อ section / dialog header
  static const double navBrand        = 16;   // ชื่อแบรนด์ใน nav bar
  static const double navItem         = 13;   // nav item label
  static const double navBarHeight    = 56.0; // ความสูง AppBar (ทุกหน้า)
  static const double statCardTitle   = 14;   // label บน stat card
  static const double statCardValue   = 24;   // ตัวเลขบน stat card

  static const double tableHeader     = 16;   // header row ของตาราง
  static const double tablePlate      = 22;   // ทะเบียน (ตัวหลัก)
  static const double tableProvince   = 15;   // จังหวัดใต้ทะเบียน
  static const double tableCell       = 18;   // เซลล์ทั่วไป (Camera ID, ชื่อ ฯลฯ)
  static const double tableTimestamp  = 16;   // timestamp
  static const double tableStatus     = 14; //chip status

  static const double labelNormal     = 14;   // label ฟอร์ม / hint
  static const double labelSmall      = 13;   // label รอง
  static const double badge           = 13;   // badge / pill

  static const double commandTitle    = 14;   // หัวข้อใน command panel
  static const double commandBody     = 13;   // เนื้อหา command panel
  static const double commandSmall    = 11;   // ข้อความเล็กใน command panel

  // ── Ready-made TextStyles ─────────────────────────────────────────────────

  static TextStyle get pageTitleStyle => const TextStyle(
        fontSize: pageTitle,
        fontWeight: FontWeight.bold,
      );

  static TextStyle get sectionTitleStyle => const TextStyle(
        fontSize: sectionTitle,
        fontWeight: FontWeight.bold,
      );

  static TextStyle tableHeaderStyle({Color color = Colors.white}) => TextStyle(
        fontSize: tableHeader,
        fontWeight: FontWeight.w700,
        color: color,
      );

  static TextStyle tablePlateStyle({Color color = const Color(0xFF111827)}) =>
      GoogleFonts.sarabun(
        fontSize: tablePlate,
        fontWeight: FontWeight.w700,
        color: color,
      );

  static TextStyle get tableProvinceStyle => const TextStyle(
        fontSize: tableProvince,
        color: Color(0xFF6B7280),
      );

  static TextStyle get tableCellStyle => const TextStyle(
        fontSize: tableCell,
        color: Color(0xFF374151),
      );

  static TextStyle get tableTimestampStyle => const TextStyle(
        fontSize: tableTimestamp,
        color: Color(0xFF6B7280),
      );

  static TextStyle statCardTitleStyle({Color? color}) => TextStyle(
        fontSize: statCardTitle,
        color: color ?? Colors.grey.shade600,
      );

  static const TextStyle statCardValueStyle = TextStyle(
        fontSize: statCardValue,
        fontWeight: FontWeight.bold,
      );

  static TextStyle get labelStyle => const TextStyle(
        fontSize: labelNormal,
        color: Color(0xFF111827),
      );

  static TextStyle get hintStyle => const TextStyle(
        fontSize: labelNormal,
        color: Color(0xFF9CA3AF),
      );

  static TextStyle get badgeStyle => const TextStyle(
        fontSize: badge,
        fontWeight: FontWeight.w600,
      );

  static const TextStyle commandTitleStyle = TextStyle(
        fontSize: commandTitle,
        fontWeight: FontWeight.w600,
      );

  static const TextStyle commandBodyStyle = TextStyle(
        fontSize: commandBody,
      );

  static const TextStyle commandSmallStyle = TextStyle(
        fontSize: commandSmall,
        color: Color(0xFF6B7280),
      );
}
