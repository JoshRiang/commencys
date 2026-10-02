import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/incident.dart';
import '../services/api_client.dart';
import '../services/location_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass.dart';

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

  void _showIncident(Incident i) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: GlassCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      i.title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                  ),
                  Pill(
                    label: i.severity.name.toUpperCase(),
                    bg: AppColors.severitySoftFor(i.severity.name),
                    fg: AppColors.severityFor(i.severity.name),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${i.category} • ${i.status.name}',
                style: const TextStyle(
                    color: AppColors.secondary, fontSize: 13),
              ),
              if (i.description.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(i.description,
                    style: const TextStyle(fontSize: 14, height: 1.4)),
              ],
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('Close'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live map'),
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _load),
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
                        width: 44,
                        height: 44,
                        child: GestureDetector(
                          onTap: () => _showIncident(i),
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.severitySoftFor(
                                  i.severity.name),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.severityFor(
                                    i.severity.name),
                                width: 2,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x22000000),
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.location_pin,
                              color: AppColors.severityFor(
                                  i.severity.name),
                              size: 24,
                            ),
                          ),
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
          if (!_loading)
            Positioned(
              top: 12,
              left: 16,
              right: 16,
              child: GlassCard(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _incidents.isEmpty
                            ? 'All clear near you'
                            : '${_incidents.length} active incident${_incidents.length == 1 ? '' : 's'} near you',
                        style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                    if (_incidents.isNotEmpty)
                      Pill(
                        label:
                            '${_incidents.where((e) => e.severity == IncidentSeverity.critical || e.severity == IncidentSeverity.high).length} urgent',
                        bg: AppColors.accentSoft,
                        fg: AppColors.accentDeep,
                      ),
                  ],
                ),
              ),
            ),
          if (!_loading && _incidents.isEmpty)
            const Positioned(
              bottom: 24,
              left: 16,
              right: 16,
              child: EmptyState(
                icon: Icons.map_outlined,
                title: 'Nothing to show yet',
                hint: 'Incidents nearby will appear as pins here.',
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/report'),
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Report',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }
}
