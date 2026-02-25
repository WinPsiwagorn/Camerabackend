// Automatic FlutterFlow imports
import '/utils/flutter_flow/theme.dart';
import '/utils/flutter_flow/util.dart';
import '../index.dart'; // Imports other custom widgets
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'package:intl/intl.dart';

class LicensePlateTable extends StatefulWidget {
  const LicensePlateTable({
    Key? key,
    this.width,
    this.height,
    this.data,
  }) : super(key: key);

  final double? width;
  final double? height;
  final List<dynamic>? data;

  @override
  State<LicensePlateTable> createState() => _LicensePlateTableState();
}

class _LicensePlateTableState extends State<LicensePlateTable> {
  int rowsPerPage = 5;
  int currentPage = 0;
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> filteredData = [];

  @override
  void initState() {
    super.initState();
    filteredData = widget.data ?? [];
  }

  @override
  void didUpdateWidget(covariant LicensePlateTable oldWidget) {
    super.didUpdateWidget(oldWidget);

    // รีเฟรชข้อมูลเมื่อ data เปลี่ยนจริง ๆ เท่านั้น
    if (oldWidget.data != widget.data) {
      filteredData = widget.data ?? [];
      currentPage = 0;
    }
  }

  void _search() {
    final keyword = _searchController.text.trim().toLowerCase();

    if (keyword.isEmpty) {
      setState(() {
        filteredData = widget.data ?? [];
        currentPage = 0;
      });
      return;
    }

    final results = (widget.data ?? []).where((rawItem) {
      if (rawItem == null || rawItem is! Map) return false;

      final item = Map<String, dynamic>.from(rawItem);

      final licensePlate = item['licensePlate'] is Map
          ? Map<String, dynamic>.from(item['licensePlate'])
          : {};

      final fullPlate =
          licensePlate['fullPlate']?.toString().toLowerCase() ?? '';

      final cameraId = item['cameraId']?.toString().toLowerCase() ?? '';

      final timestamp = item['timestamp']?.toString().toLowerCase() ?? '';

      return fullPlate.contains(keyword) ||
          cameraId.contains(keyword) ||
          timestamp.contains(keyword);
    }).toList();

    setState(() {
      filteredData = results;
      currentPage = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.data == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final start = currentPage * rowsPerPage;
    final end = (start + rowsPerPage) > filteredData.length
        ? filteredData.length
        : (start + rowsPerPage);

    final pageData =
        filteredData.isNotEmpty ? filteredData.sublist(start, end) : [];

    return Container(
      width: widget.width ?? double.infinity,
      height: widget.height,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSearchBar(),
          const SizedBox(height: 10),
          _buildHeader(),
          Expanded(
            child: filteredData.isEmpty
                ? const Center(child: Text("No Data Found"))
                : ListView.builder(
                    itemCount: pageData.length,
                    itemBuilder: (context, index) {
                      final rawItem = pageData[index];

                      if (rawItem == null || rawItem is! Map) {
                        return const SizedBox();
                      }

                      final item = Map<String, dynamic>.from(rawItem);

                      final licensePlate = item['licensePlate'] is Map
                          ? Map<String, dynamic>.from(item['licensePlate'])
                          : {};

                      final fullPlate = licensePlate['fullPlate'] ?? '-';

                      final cameraId = item['cameraId'] ?? '-';

                      final timestamp = item['timestamp'];

                      final imageUrl = item['imageUrl'];

                      final isEven = index % 2 == 0;

                      return Container(
                        color: isEven ? Colors.grey[200] : Colors.white,
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 8),
                        child: Row(
                          children: [
                            Expanded(
                                flex: 2, child: Text(fullPlate.toString())),
                            Expanded(flex: 2, child: Text(cameraId.toString())),
                            Expanded(
                                flex: 2,
                                child: Text(
                                  timestamp != null
                                      ? _formatDate(timestamp)
                                      : '-',
                                )),

                            // ✅ Picture Column
                            Expanded(
                              flex: 2,
                              child: imageUrl != null &&
                                      imageUrl.toString().trim().isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: SizedBox(
                                        height: 60,
                                        child: Image.network(
                                          imageUrl.toString().trim(),
                                          fit: BoxFit.cover,
                                          loadingBuilder: (context, child,
                                              loadingProgress) {
                                            if (loadingProgress == null) {
                                              return child;
                                            }
                                            return const Center(
                                              child: SizedBox(
                                                height: 20,
                                                width: 20,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                ),
                                              ),
                                            );
                                          },
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return const Center(
                                              child: Icon(
                                                Icons.broken_image,
                                                size: 28,
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    )
                                  : const Text('-'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          _buildPagination(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: "Search...",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            onSubmitted: (_) => _search(),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: _search,
          child: const Icon(Icons.search),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      child: const Row(
        children: [
          Expanded(
              flex: 2,
              child:
                  Text('License Plate', style: TextStyle(color: Colors.white))),
          Expanded(
              flex: 2,
              child: Text('Camera ID', style: TextStyle(color: Colors.white))),
          Expanded(
              flex: 2,
              child: Text('Timestamp', style: TextStyle(color: Colors.white))),
          Expanded(
              flex: 2,
              child: Text('Picture', style: TextStyle(color: Colors.white))),
        ],
      ),
    );
  }

  Widget _buildPagination() {
    final totalPages = (filteredData.length / rowsPerPage).ceil();

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: currentPage > 0
                ? () {
                    setState(() {
                      currentPage--;
                    });
                  }
                : null,
          ),
          Text("${currentPage + 1} / ${totalPages == 0 ? 1 : totalPages}"),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: currentPage < totalPages - 1
                ? () {
                    setState(() {
                      currentPage++;
                    });
                  }
                : null,
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    try {
      final raw = timestamp.toString();

      if (raw.contains('_')) {
        final parts = raw.split('_');
        final d = parts[0];
        final t = parts[1];

        return "${d.substring(0, 4)}-"
            "${d.substring(4, 6)}-"
            "${d.substring(6, 8)} "
            "${t.substring(0, 2)}:"
            "${t.substring(2, 4)}:"
            "${t.substring(4, 6)}";
      }

      final date = DateTime.parse(raw);
      return DateFormat('yyyy-MM-dd HH:mm:ss').format(date);
    } catch (e) {
      return '-';
    }
  }
}
