// Automatic FlutterFlow imports
import '/utils/flutter_flow/theme.dart';
import '/utils/flutter_flow/util.dart';
import '../../index.dart'; // Imports other custom widgets
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import '/utils/app_text_styles.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:latlong2/latlong.dart' as latlong;

// ── Cluster data class ────────────────────────────────────────────────────────

class _Cluster {
  final latlong.LatLng centroid;
  final List<dynamic> docs;
  _Cluster({required this.centroid, required this.docs});
  bool get isSingle => docs.length == 1;
}

// ── Widget ────────────────────────────────────────────────────────────────────

class InteractiveMap extends StatefulWidget {
  const InteractiveMap({
    Key? key,
    this.width,
    this.height,
    required this.initialZoom,
    required this.cameraDocs,
    required this.onMarkerTap,
  }) : super(key: key);

  final double? width;
  final double? height;
  final double initialZoom;
  final List<dynamic> cameraDocs;
  final Future<dynamic> Function(dynamic tappedCamera) onMarkerTap;

  @override
  State<InteractiveMap> createState() => _InteractiveMapState();
}

class _InteractiveMapState extends State<InteractiveMap> {
  final _tileProvider = CancellableNetworkTileProvider();
  late final MapController _mapController;
  LatLngBounds? _currentBounds;
  double _currentZoom = 13.0;

  static const latlong.LatLng _chiangRai = latlong.LatLng(19.9105, 99.8406);

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  // ── Viewport ───────────────────────────────────────────────────────────────

  bool _inViewport(latlong.LatLng point) {
    if (_currentBounds == null) return true;
    final dLat = (_currentBounds!.north - _currentBounds!.south) * 0.2;
    final dLng = (_currentBounds!.east - _currentBounds!.west) * 0.2;
    return point.latitude  >= _currentBounds!.south - dLat &&
           point.latitude  <= _currentBounds!.north + dLat &&
           point.longitude >= _currentBounds!.west  - dLng &&
           point.longitude <= _currentBounds!.east  + dLng;
  }

  /// Update viewport bounds when map position changes
  void _onPositionChanged(MapPosition position, bool hasGesture) {
    try {
      final bounds = _mapController.camera.visibleBounds;
      final zoom  = _mapController.camera.zoom;
      if (bounds != _currentBounds || zoom != _currentZoom) {
        setState(() {
          _currentBounds = bounds;
          _currentZoom   = zoom;
        });
      }
    } catch (_) {}
  }

  // ── Clustering ─────────────────────────────────────────────────────────────

  double get _clusterThreshold {
    if (_currentZoom >= 16) return 0.0008;
    if (_currentZoom >= 14) return 0.003;
    if (_currentZoom >= 12) return 0.01;
    if (_currentZoom >= 10) return 0.05;
    return 0.15;
  }

  List<_Cluster> _buildClusters(List<dynamic> docs) {
    final assigned = <int>{};
    final clusters = <_Cluster>[];

    for (int i = 0; i < docs.length; i++) {
      if (assigned.contains(i)) continue;
      final pI = _parseLatLng(docs[i]['latLong']);
      if (pI == null) continue;

      final group = <dynamic>[docs[i]];
      assigned.add(i);

      for (int j = i + 1; j < docs.length; j++) {
        if (assigned.contains(j)) continue;
        final pJ = _parseLatLng(docs[j]['latLong']);
        if (pJ == null) continue;
        if ((pI.latitude  - pJ.latitude).abs()  <= _clusterThreshold &&
            (pI.longitude - pJ.longitude).abs() <= _clusterThreshold) {
          group.add(docs[j]);
          assigned.add(j);
        }
      }

      final lat = group
          .map((d) => _parseLatLng(d['latLong'])!.latitude)
          .reduce((a, b) => a + b) / group.length;
      final lng = group
          .map((d) => _parseLatLng(d['latLong'])!.longitude)
          .reduce((a, b) => a + b) / group.length;

      clusters.add(_Cluster(centroid: latlong.LatLng(lat, lng), docs: group));
    }
    return clusters;
  }

  // ── LatLng parser ──────────────────────────────────────────────────────────

  latlong.LatLng? _parseLatLng(dynamic data) {
    if (data == null) return null;
    try {
      if (data is String) {
        final parts = data.split(',');
        if (parts.length == 2) {
          final lat = double.tryParse(parts[0].trim());
          final lng = double.tryParse(parts[1].trim());
          if (lat != null && lng != null) return latlong.LatLng(lat, lng);
        }
      } else if (data is Map) {
        final lat = data['latitude'];
        final lng = data['longitude'];
        if (lat != null && lng != null) {
          return latlong.LatLng(
            lat is double ? lat : double.parse(lat.toString()),
            lng is double ? lng : double.parse(lng.toString()),
          );
        }
      } else {
        // Try to access as object with properties
        try {
          final lat = (data as dynamic).latitude;
          final lng = (data as dynamic).longitude;
          if (lat != null && lng != null) {
            return latlong.LatLng(
              lat is double ? lat : double.parse(lat.toString()),
              lng is double ? lng : double.parse(lng.toString()),
            );
          }
        } catch (_) {}
      }
    } catch (_) {}
    return null;
  }

  // ── Camera move on first data ──────────────────────────────────────────────

  @override
  void didUpdateWidget(InteractiveMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cameraDocs.isEmpty && widget.cameraDocs.isNotEmpty) {
      final target = widget.cameraDocs.firstWhere(
        (doc) {
          final p = _parseLatLng(doc['latLong']);
          if (p == null) return false;
          return const latlong.Distance().as(
                latlong.LengthUnit.Kilometer, p, _chiangRai) < 50;
        },
        orElse: () => widget.cameraDocs.first,
      );
      final p = _parseLatLng(target['latLong']);
      if (p != null) _mapController.move(p, widget.initialZoom);
    }
  }

  // ── Marker builders ────────────────────────────────────────────────────────

  Color _statusColor(dynamic doc) =>
      doc['status']?.toString().toLowerCase() == 'online'
          ? const Color(0xFF10B981)
          : const Color(0xFFEF4444);

  Widget _singleMarker(dynamic doc) {
    final color = _statusColor(doc);
    return GestureDetector(
      onTap: () => widget.onMarkerTap(doc),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.2),
            ),
          ),
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(child: Icon(Icons.videocam, color: color, size: 28)),
          ),
          Positioned(
            top: 5, right: 5,
            child: Container(
              width: 12, height: 12,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 2,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _clusterMarker(BuildContext ctx, _Cluster cluster) {
    final count = cluster.docs.length;
    final onlineCount = cluster.docs
        .where((d) => d['status']?.toString().toLowerCase() == 'online')
        .length;
    final color =
        onlineCount > 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    return GestureDetector(
      onTap: () => _showClusterPicker(ctx, cluster.docs),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 66, height: 66,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.15),
            ),
          ),
          Container(
            width: 54, height: 54,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.videocam, color: color, size: 20),
                Text(
                  '$count',
                  style: TextStyle(
                    color: color,
                    fontSize: AppTextStyles.commandSmall,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 3, right: 3,
            child: Container(
              width: 18, height: 18,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              alignment: Alignment.center,
              child: Text(
                '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Cluster picker ─────────────────────────────────────────────────────────

  void _showClusterPicker(BuildContext context, List<dynamic> docs) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: _ClusterPickerSheet(
            cameras: docs,
            onSelect: (doc) {
              Navigator.pop(context);
              widget.onMarkerTap(doc);
            },
          ),
        ),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final visibleDocs = widget.cameraDocs
        .where((doc) {
          final p = _parseLatLng(doc['latLong']);
          return p != null && _inViewport(p);
        })
        .toList();

    final clusters = _buildClusters(visibleDocs);
    debugPrint(
        'Map: ${visibleDocs.length}/${widget.cameraDocs.length} visible → ${clusters.length} clusters');

    final markers = clusters.map((c) => Marker(
          width: 66,
          height: 66,
          point: c.centroid,
          child: c.isSingle
              ? _singleMarker(c.docs.first)
              : _clusterMarker(context, c),
        )).toList();

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _chiangRai,
        initialZoom: widget.initialZoom,
        onPositionChanged: _onPositionChanged,
        // Performance optimizations
        keepAlive: true,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.app',
          tileProvider: _tileProvider,
          maxNativeZoom: 19,
          keepBuffer: 2,
        ),
        MarkerLayer(markers: markers, rotate: false),
      ],
    );
  }
}

// ── Cluster picker bottom sheet ────────────────────────────────────────────────

class _ClusterPickerSheet extends StatelessWidget {
  const _ClusterPickerSheet({
    required this.cameras,
    required this.onSelect,
  });

  final List<dynamic> cameras;
  final void Function(dynamic doc) onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
            decoration: const BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.videocam_rounded,
                      color: Colors.white, size: 16),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'showing cameras in this area',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: AppTextStyles.commandTitle,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${cameras.length} camera in this cluster',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: AppTextStyles.commandSmall,
                        ),
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.close_rounded,
                        color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
          ),
          // Camera list
          Flexible(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 4),
              shrinkWrap: true,
              itemCount: cameras.length,
              separatorBuilder: (_, __) => const Divider(
                  height: 1, color: Color(0xFFEEEEEE), indent: 60),
              itemBuilder: (_, i) {
                final doc      = cameras[i];
                final name     = doc['name']?.toString() ?? 'Camera ${i + 1}';
                final address  = doc['address']?.toString() ?? '';
                final isOnline =
                    doc['status']?.toString().toLowerCase() == 'online';

                return InkWell(
                  onTap: () => onSelect(doc),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        // Icon
                        Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.videocam_rounded,
                            color: isOnline
                                ? Colors.black87
                                : Colors.black26,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 14),
                        // Name + address
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontSize: AppTextStyles.commandTitle,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (address.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  address,
                                  style: const TextStyle(
                                    color: Colors.black38,
                                    fontSize: AppTextStyles.commandSmall,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Status badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isOnline
                                ? Colors.black
                                : const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            isOnline ? 'Online' : 'Offline',
                            style: TextStyle(
                              color: isOnline
                                  ? Colors.white
                                  : Colors.black38,
                              fontSize: AppTextStyles.commandSmall,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.chevron_right_rounded,
                            color: Colors.black26, size: 18),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}