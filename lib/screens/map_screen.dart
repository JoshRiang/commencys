import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/incident.dart';
import '../services/api_client.dart';
import '../services/location_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _api = ApiClient();
  final _location = LocationService();
  final _mapController = MapController();
  List<Incident> _incidents = [];
  LatLng _center = const LatLng(-6.2, 106.8); // Jakarta default
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _api.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final pos = await _location.currentPosition();
      if (pos != null) {
        _center = LatLng(pos.latitude, pos.longitude);
        _mapController.move(_center, 14);
      }
      final incidents = await _api.fetchIncidents();
      if (mounted) setState(() => _incidents = incidents);
    } catch (_) {
      // Offline demo fallback: keep map centered, show empty state.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Color _severityColor(IncidentSeverity s) {
    switch (s) {
      case IncidentSeverity.critical:
        return Colors.red;
      case IncidentSeverity.high:
        return Colors.orange;
      case IncidentSeverity.medium:
        return Colors.amber.shade700;
      case IncidentSeverity.low:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Incident Map'),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 13,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.commencys.app',
              ),
              MarkerLayer(
                markers: _incidents
                    .map(
                      (i) => Marker(
                        point: LatLng(i.latitude, i.longitude),
                        width: 40,
                        height: 40,
                        child: Icon(
                          Icons.location_pin,
                          color: _severityColor(i.severity),
                          size: 36,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
          if (_loading)
            const Positioned(
              top: 12,
              left: 0,
              right: 0,
              child: Center(child: CircularProgressIndicator()),
            ),
          if (!_loading && _incidents.isEmpty)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    'No active incidents. Backend: ${_api.baseUrl}',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
