// Automatic FlutterFlow imports
import '/utils/flutter_flow/theme.dart';
import '/utils/flutter_flow/util.dart';
import '../../index.dart'; // Imports other custom widgets
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'package:flutter_map/flutter_map.dart';
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
  final myTileProvider = NetworkTileProvider();
  late MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void didUpdateWidget(InteractiveMap oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.cameraDocs.isEmpty && widget.cameraDocs.isNotEmpty) {
      final firstDoc = widget.cameraDocs
          .firstWhere((doc) => doc.latLong != null, orElse: () => null!);

      if (firstDoc != null) {
        final newCenter = latlong.LatLng(
            firstDoc.latLong!.latitude, firstDoc.latLong!.longitude);
        _mapController.move(newCenter, widget.initialZoom);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final latlong.LatLng defaultCenter =
        latlong.LatLng(19.9105, 99.8406); // Default

    List<Marker> allMarkers = [];
    List<latlong.LatLng> mapPoints = [];

    for (var doc in widget.cameraDocs) {
      if (doc.latLong != null) {
        final point =
            latlong.LatLng(doc.latLong!.latitude, doc.latLong!.longitude);
        mapPoints.add(point);

        // ---
        // --- YOUR MARKER CODE WITH STRING CHECK ---
        // ---

        // Determine marker color based on camera status
        //
        // --- !!! THIS IS THE FIXED LINE !!! ---
        //
        Color markerColor = doc.status == 'online'
            ? const Color(0xFF10B981)
            : const Color(0xFFEF4444); // Green for Online, Red for Offline
        //
        // --- !!! ---

        allMarkers.add(
          Marker(
            width: 60.0, // Slightly smaller for a more refined look
            height: 60.0,
            point: point,
            child: GestureDetector(
              onTap: () {
                widget.onMarkerTap(doc);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white, // White background for the marker
                  shape: BoxShape.circle, // Circular shape
                  border: Border.all(
                      color: markerColor, width: 3), // Status-based border
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    Icons.videocam, // Clear CCTV icon
                    color: markerColor, // Icon color matches status
                    size: 32.0, // Good size for visibility
                  ),
                ),
              ),
            ),
          ),
        );

        // ---
        // --- YOUR MARKER CODE ENDS HERE ---
        // ---
      }
    }

    final latlong.LatLng centerPoint =
        mapPoints.isEmpty ? defaultCenter : mapPoints[0];

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        center: centerPoint,
        zoom: widget.initialZoom,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.app',
          tileProvider: myTileProvider,
          maxNativeZoom: 19,
        ),
        MarkerLayer(markers: allMarkers),
      ],
    );
  }
}
