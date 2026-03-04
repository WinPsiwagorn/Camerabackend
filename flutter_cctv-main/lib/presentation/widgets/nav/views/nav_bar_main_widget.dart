import '/utils/flutter_flow/theme.dart';
import '/utils/flutter_flow/util.dart';
import '/utils/flutter_flow/widgets.dart';
import 'dart:ui';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/nav_bar_main_model.dart';
export '../models/nav_bar_main_model.dart';

class NavBarMainWidget extends StatefulWidget {
  const NavBarMainWidget({super.key});

  @override
  State<NavBarMainWidget> createState() => _NavBarMainWidgetState();
}

class _NavBarMainWidgetState extends State<NavBarMainWidget> {
  late NavBarMainModel _model;

  // Track which nav item is hovered
  String? _hoveredItem;

  static const _primaryColor = Color(0xFF4B39EF);

  static const _navItems = [
    _NavItemData(
      label: 'List Camera',
      icon: Icons.videocam_outlined,
      routeName: 'ListCameraPage',
    ),
    _NavItemData(
      label: 'Search Plate',
      icon: Icons.search_outlined,
      routeName: 'ListPlatePage',
    ),
    _NavItemData(
      label: 'Collection',
      icon: Icons.folder_outlined,
      routeName: 'Collection',
    ),
    _NavItemData(
      label: 'Command View',
      icon: Icons.dashboard_outlined,
      routeName: 'CommandView',
    ),
    _NavItemData(
      label: 'Map View',
      icon: Icons.map_outlined,
      routeName: 'MapView',
    ),
  ];

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => NavBarMainModel());
    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.maybeDispose();
    super.dispose();
  }

  String _currentRoute(BuildContext context) {
    return GoRouterState.of(context).name ?? '';
  }

  void _navigate(BuildContext context, String routeName) {
    context.pushNamed(
      routeName,
      extra: <String, dynamic>{
        '__transition_info__': TransitionInfo(
          hasTransition: true,
          transitionType: PageTransitionType.fade,
          duration: const Duration(milliseconds: 150),
        ),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentRoute = _currentRoute(context);

    return Row(
      mainAxisSize: MainAxisSize.max,
      children: [
        // ── Logo ────────────────────────────────────────────────────────────
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF4B39EF), Color(0xFF7B5CF0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: _primaryColor.withOpacity(0.35),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(Icons.remove_red_eye_rounded,
              color: Colors.white, size: 18),
        ),
        const SizedBox(width: 10),

        // ── Brand name ───────────────────────────────────────────────────────
        Text(
          'Central Eye',
          style: GoogleFonts.plusJakartaSans(
            color: const Color(0xFF111827),
            fontSize: AppTextStyles.navBrand,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),

        // ── Divider ──────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(width: 1, height: 20, color: const Color(0xFFE5E7EB)),
        ),

        // ── Nav links ────────────────────────────────────────────────────────
        Expanded(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: _navItems.map((item) {
              final isActive = currentRoute == item.routeName;
              final isHovered = _hoveredItem == item.label;
              return Padding(
                padding: const EdgeInsets.only(right: 2),
                child: _NavItemWidget(
                  data: item,
                  isActive: isActive,
                  isHovered: isHovered,
                  primaryColor: _primaryColor,
                  onHoverChanged: (v) => setState(
                      () => _hoveredItem = v ? item.label : null),
                  onTap: () => _navigate(context, item.routeName),
                ),
              );
            }).toList(),
          ),
        ),

        // ── Profile / Logout ─────────────────────────────────────────────────
        _ProfileButton(primaryColor: _primaryColor),

      ],
    );
  }
}

// ─── Data class ──────────────────────────────────────────────────────────────

class _NavItemData {
  final String label;
  final IconData icon;
  final String routeName;
  const _NavItemData(
      {required this.label, required this.icon, required this.routeName});
}

// ─── Nav item widget (stateless with hover) ───────────────────────────────────

class _NavItemWidget extends StatelessWidget {
  final _NavItemData data;
  final bool isActive;
  final bool isHovered;
  final Color primaryColor;
  final ValueChanged<bool> onHoverChanged;
  final VoidCallback onTap;

  const _NavItemWidget({
    required this.data,
    required this.isActive,
    required this.isHovered,
    required this.primaryColor,
    required this.onHoverChanged,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final showHighlight = isActive || isHovered;

    return MouseRegion(
      onEnter: (_) => onHoverChanged(true),
      onExit: (_) => onHoverChanged(false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isActive
                ? primaryColor.withOpacity(0.1)
                : isHovered
                    ? const Color(0xFFF3F4F6)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: isActive
                ? Border.all(color: primaryColor.withOpacity(0.25))
                : Border.all(color: Colors.transparent),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                data.icon,
                size: 15,
                color: isActive
                    ? primaryColor
                    : isHovered
                        ? const Color(0xFF374151)
                        : const Color(0xFF6B7280),
              ),
              const SizedBox(width: 5),
              Text(
                data.label,
                style: GoogleFonts.plusJakartaSans(
                  color: isActive
                      ? primaryColor
                      : isHovered
                          ? const Color(0xFF111827)
                          : const Color(0xFF4B5563),
                  fontSize: AppTextStyles.navItem,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Profile / Logout button ──────────────────────────────────────────────────

class _ProfileButton extends StatefulWidget {
  final Color primaryColor;
  const _ProfileButton({required this.primaryColor});

  @override
  State<_ProfileButton> createState() => _ProfileButtonState();
}

class _ProfileButtonState extends State<_ProfileButton> {
  bool _hovered = false;

  void _logout(BuildContext context) {
    AppState().clearAuth();
    context.goNamed('LoginPage');
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: PopupMenuButton<String>(
        offset: const Offset(0, 40),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        color: Colors.white,
        elevation: 8,
        tooltip: '',
        onSelected: (value) {
          if (value == 'logout') _logout(context);
        },
        itemBuilder: (_) => [
          PopupMenuItem<String>(
            enabled: false,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'admin',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF111827),
                  ),
                ),
                Text(
                  'Administrator',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          const PopupMenuDivider(),
          PopupMenuItem<String>(
            value: 'logout',
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                const Icon(Icons.logout_rounded,
                    size: 15, color: Color(0xFFEF4444)),
                const SizedBox(width: 8),
                Text(
                  'Logout',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFFEF4444),
                  ),
                ),
              ],
            ),
          ),
        ],
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _hovered
                ? widget.primaryColor.withOpacity(0.07)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color:
                  _hovered ? widget.primaryColor.withOpacity(0.3) : const Color(0xFFE5E7EB),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 13,
                backgroundColor: widget.primaryColor.withOpacity(0.12),
                child: Icon(Icons.person_rounded,
                    size: 15, color: widget.primaryColor),
              ),
              const SizedBox(width: 7),
              Text(
                'admin',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: AppTextStyles.navItem,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF374151),
                  letterSpacing: -0.1,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.keyboard_arrow_down_rounded,
                  size: 14, color: const Color(0xFF9CA3AF)),
            ],
          ),
        ),
      ),
    );
  }
}
