// Automatic FlutterFlow imports
import '/utils/flutter_flow/theme.dart';
import '/utils/flutter_flow/util.dart';
import '../../index.dart'; // Imports other custom widgets
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:latlong2/latlong.dart' as latlong; // Use alias

class InteractiveMap extends StatefulWidget {
  const InteractiveMap({
    Key? key,
    this.width,
    this.height,
    required this.initialZoom,
    required this.cameraDocs,
    required this.onMarkerTap, // This action is PASSED IN from FlutterFlow
  }) : super(key: key);

  final double? width;
  final double? height;
  final double initialZoom;
  final List<dynamic> cameraDocs;
  final Future<dynamic> Function(dynamic tappedCamera) onMarkerTap;

  @override
  _InteractiveMapState createState() => _InteractiveMapState();
}

class _InteractiveMapState extends State<InteractiveMap> {
  final myTileProvider = CancellableNetworkTileProvider();
  late MapController _mapController;
  LatLngBounds? _currentBounds;
  
  // Chiang Rai, Thailand - Default center point
  static const latlong.LatLng chiangRaiCenter = latlong.LatLng(19.9105, 99.8406);

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  /// Check if a point is within the current viewport (with buffer)
  bool _isPointInViewport(latlong.LatLng point) {
    if (_currentBounds == null) return true; // Show all initially
    
    // Add buffer zone (20% extra on each side) for smoother experience
    final latBuffer = (_currentBounds!.north - _currentBounds!.south) * 0.2;
    final lngBuffer = (_currentBounds!.east - _currentBounds!.west) * 0.2;
    
    return point.latitude >= (_currentBounds!.south - latBuffer) &&
           point.latitude <= (_currentBounds!.north + latBuffer) &&
           point.longitude >= (_currentBounds!.west - lngBuffer) &&
           point.longitude <= (_currentBounds!.east + lngBuffer);
  }

  /// Update viewport bounds when map position changes
  void _onPositionChanged(MapPosition position, bool hasGesture) {
    try {
      final bounds = _mapController.camera.visibleBounds;
      if (bounds != _currentBounds) {
        setState(() {
          _currentBounds = bounds;
        });
      }
    } catch (e) {
      // Bounds calculation might fail, continue without optimization
    }
  }

  @override
  void didUpdateWidget(InteractiveMap oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Only move camera if we're getting first camera data
    if (oldWidget.cameraDocs.isEmpty && widget.cameraDocs.isNotEmpty) {
      // Try to find a camera near Chiang Rai, otherwise use first camera
      var targetDoc = widget.cameraDocs.firstWhere(
        (doc) {
          if (doc['latLong'] == null) return false;
          try {
            latlong.LatLng? point = _parseLatLng(doc['latLong']);
            if (point == null) return false;
            // Check if camera is within 50km of Chiang Rai
            final distance = const latlong.Distance().as(
              latlong.LengthUnit.Kilometer,
              point,
              chiangRaiCenter,
            );
            return distance < 50;
          } catch (e) {
            return false;
          }
        },
        orElse: () => widget.cameraDocs.first,
      );

      if (targetDoc != null && targetDoc['latLong'] != null) {
        final point = _parseLatLng(targetDoc['latLong']);
        if (point != null) {
          _mapController.move(point, widget.initialZoom);
        }
      }
    }
  }

  /// Parse latLong from various formats
  latlong.LatLng? _parseLatLng(dynamic latLongData) {
    if (latLongData == null) return null;
    
    try {
      if (latLongData is String) {
        // Parse string format: "20.412001,99.994481"
        final parts = latLongData.split(',');
        if (parts.length == 2) {
          final lat = double.tryParse(parts[0].trim());
          final lng = double.tryParse(parts[1].trim());
          if (lat != null && lng != null) {
            return latlong.LatLng(lat, lng);
          }
        }
      } else if (latLongData is Map) {
        // Handle Map with latitude/longitude keys
        final lat = latLongData['latitude'];
        final lng = latLongData['longitude'];
        if (lat != null && lng != null) {
          return latlong.LatLng(
            lat is double ? lat : double.parse(lat.toString()),
            lng is double ? lng : double.parse(lng.toString()),
          );
        }
      } else {
        // Try to access as object with properties
        try {
          final lat = (latLongData as dynamic).latitude;
          final lng = (latLongData as dynamic).longitude;
          if (lat != null && lng != null) {
            return latlong.LatLng(
              lat is double ? lat : double.parse(lat.toString()),
              lng is double ? lng : double.parse(lng.toString()),
            );
          }
        } catch (_) {
          return null;
        }
      }
    } catch (e) {
      return null;
    }
    
    return null;
  }

  @override
  Widget build(BuildContext context) {
    List<Marker> visibleMarkers = [];
    int totalCameras = 0;
    int renderedCameras = 0;

    for (var doc in widget.cameraDocs) {
      totalCameras++;
      
      // Parse latLong using helper function
      final point = _parseLatLng(doc['latLong']);
      
      if (point != null) {
        // Only render markers within viewport (performance optimization)
        if (!_isPointInViewport(point)) {
          continue; // Skip markers outside viewport
        }
        
        renderedCameras++;

        // Determine marker color based on camera status
        final status = doc['status']?.toString().toLowerCase() ?? 'offline';
        Color markerColor = status == 'online'
            ? const Color(0xFF10B981) // Green for Online
            : const Color(0xFFEF4444); // Red for Offline

        visibleMarkers.add(
          Marker(
            width: 60.0,
            height: 60.0,
            point: point,
            child: GestureDetector(
              onTap: () {
                widget.onMarkerTap(doc);
              },
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer glow effect
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: markerColor.withOpacity(0.2),
                    ),
                  ),
                  // Main marker
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: markerColor, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 6,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        Icons.videocam,
                        color: markerColor,
                        size: 28.0,
                      ),
                    ),
                  ),
                  // Status indicator dot
                  Positioned(
                    top: 5,
                    right: 5,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: markerColor,
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
            ),
          ),
        );
      }
    }

    // Debug: Print rendering stats
    if (totalCameras > 0) {
      print('Map Performance: Rendering $renderedCameras/$totalCameras cameras');
    }

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: chiangRaiCenter, // Default to Chiang Rai
        initialZoom: widget.initialZoom,
        onPositionChanged: _onPositionChanged,
        // Performance optimizations
        keepAlive: true,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.app',
          tileProvider: myTileProvider,
          maxNativeZoom: 19,
          keepBuffer: 2, // Keep tiles in buffer for smooth panning
        ),
        MarkerLayer(
          markers: visibleMarkers,
          rotate: false, // Disable rotation for better performance
        ),
      ],
    );
  }
}
