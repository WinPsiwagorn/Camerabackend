import '/utils/flutter_flow/util.dart';
import '/utils/app_text_styles.dart';
import '/presentation/widgets/index.dart' as custom_widgets;
import 'package:flutter/material.dart';
import '../models/preview_overlay_model.dart';
export '../models/preview_overlay_model.dart';

class PreviewOverlayWidget extends StatefulWidget {
  const PreviewOverlayWidget({
    super.key,
    required this.onClose,
    required this.onRemoveTapped,
    required this.cameraList,
  });

  final Future Function()? onClose;
  final Future Function(dynamic cameraToRemove)? onRemoveTapped;
  final List<dynamic>? cameraList;

  @override
  State<PreviewOverlayWidget> createState() => _PreviewOverlayWidgetState();
}

class _PreviewOverlayWidgetState extends State<PreviewOverlayWidget> {
  late PreviewOverlayModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => PreviewOverlayModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final panelWidth = MediaQuery.sizeOf(context).width * 0.3;
    final feedItems = widget.cameraList!.toList().take(3).toList();

    return SizedBox.expand(
      child: Stack(
        children: [
          // ── Side panel ──────────────────────────────────────────────────────
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: panelWidth,
            child: Container(
              decoration: const BoxDecoration(
                color: Color.fromARGB(255, 232, 232, 237),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black38,
                    blurRadius: 24,
                    offset: Offset(4, 0),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ─────────────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Color(0xFF1F2937), width: 1),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Back button
                        InkWell(
                          onTap: () async => widget.onClose?.call(),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 252, 250, 250),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: Color.fromARGB(179, 9, 9, 9),
                              size: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Title
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Live Preview',
                                style: TextStyle(
                                  color: Color.fromARGB(255, 0, 0, 0),
                                  fontSize: AppTextStyles.commandTitle,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.2,
                                ),
                              ),
                              SizedBox(height: 1),
                              Row(
                                children: [
                                  _PulseDot(),
                                  SizedBox(width: 5),
                                  Text(
                                    'Live',
                                    style: TextStyle(
                                      color: Color(0xFF10B981),
                                      fontSize: AppTextStyles.commandSmall,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Camera count badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 246, 247, 247),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${feedItems.length}/3',
                            style: const TextStyle(
                              color: Color.fromARGB(137, 19, 19, 19),
                              fontSize: AppTextStyles.commandSmall,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Camera feed list ────────────────────────────────────────
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: feedItems.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = feedItems[index];
                        final itemName = item['name']?.toString() ?? '';
                        final itemId = item['id']?.toString() ?? '';
                        debugPrint('[PreviewOverlay] name=$itemName id=$itemId');

                        return _CameraCard(
                          name: itemName,
                          id: itemId,
                          panelWidth: panelWidth - 24,
                          onRemove: () async =>
                              widget.onRemoveTapped?.call(item),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
// ── Camera feed card ───────────────────────────────────────────────────────────

class _CameraCard extends StatelessWidget {
  const _CameraCard({
    required this.name,
    required this.id,
    required this.panelWidth,
    required this.onRemove,
  });

  final String name;
  final String id;
  final double panelWidth;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF374151), width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Video player ──────────────────────────────────────────────────
          Stack(
            children: [
              SizedBox(
                width: panelWidth,
                height: 180,
                child: id.isNotEmpty
                    ? custom_widgets.HlsPlayer(
                        key: ValueKey('hls-$id'),
                        width: panelWidth,
                        height: 180,
                        hlsUrl: '',
                        streamName: id,
                      )
                    : const _NoStreamPlaceholder(),
              ),
              // Camera index badge top-left
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFF10B981),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'LIVE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: AppTextStyles.commandSmall,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Remove button top-right
              Positioned(
                top: 6,
                right: 6,
                child: InkWell(
                  onTap: onRemove,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(137, 255, 255, 255),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: Color.fromARGB(179, 17, 1, 1),
                      size: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // ── Camera name ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 9),
            child: Row(
              children: [
                const Icon(Icons.videocam_rounded,
                    color: Color(0xFF6B7280), size: 14),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    name,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: AppTextStyles.commandSmall,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── No stream placeholder ──────────────────────────────────────────────────────

class _NoStreamPlaceholder extends StatelessWidget {
  const _NoStreamPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF111827),
      alignment: Alignment.center,
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.videocam_off_rounded, color: Color(0xFF4B5563), size: 28),
          SizedBox(height: 6),
          Text(
            'No Camera ID',
            style: TextStyle(
              color: Color(0xFF6B7280),
              fontSize: AppTextStyles.commandSmall,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Animated pulse dot ─────────────────────────────────────────────────────────

class _PulseDot extends StatefulWidget {
  const _PulseDot();

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: 6,
        height: 6,
        decoration: const BoxDecoration(
          color: Color(0xFF10B981),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}