import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/incident.dart';
import '../services/api_client.dart';
import '../services/location_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ai_badges.dart';
import '../widgets/floating_tab_bar.dart';
import '../widgets/glass.dart';
import '../widgets/server_dialog.dart';
import '../widgets/urgency_labels.dart';

/// Map is home: full-bleed live map under a floating glass top bar
/// (search/status pill + backend server button), a draggable glass bottom
/// sheet with nearby incidents, a locate/recenter button and a floating
/// SOS button. Read APIs are unchanged: [ApiClient.fetchIncidents].
class MapScreen extends StatefulWidget {
  final VoidCallback? onSosPressed;

  const MapScreen({super.key, this.onSosPressed});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _api = ApiClient();
  final _location = LocationService();
  final _mapController = MapController();
  final _sheetController = DraggableScrollableController();
  final _searchCtrl = TextEditingController();
  List<Incident> _incidents = [];
  LatLng _center = const LatLng(-6.2, 106.8); // Jakarta default
  LatLng? _myPosition;
  bool _loading = true;
  String _query = '';
  String? _clusterFilter;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _api.dispose();
    _mapController.dispose();
    _sheetController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final pos = await _location.currentPosition();
      if (pos != null) {
        _center = LatLng(pos.latitude, pos.longitude);
        _myPosition = _center;
        _mapController.move(_center, 14);
      }
      final incidents = await _api.fetchIncidents();
      if (mounted) setState(() => _incidents = incidents);
    } catch (_) {
      // Offline: keep map centered, show empty state in the sheet.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _recenter() async {
    final pos = await _location.currentPosition();
    if (pos == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Location unavailable — enable GPS.')),
      );
      return;
    }
    _center = LatLng(pos.latitude, pos.longitude);
    _myPosition = _center;
    _mapController.move(_center, 14.5);
    if (mounted) setState(() {});
  }

  void _showIncident(Incident i) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Padding(
        // layout.md › Guides and safe areas: sheet content clears the
        // system bottom inset, not just a fixed margin.
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          24 + MediaQuery.of(sheetContext).padding.bottom,
        ),
        child: LiquidGlass(
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
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Pill(
                        label: UrgencyLabels.forUrgency(i.urgency),
                        bg: UrgencyLabels.urgencyBg(i.urgency),
                        fg: UrgencyLabels.urgencyFg(i.urgency),
                        icon: Icons.bolt_rounded,
                      ),
                      const SizedBox(height: 6),
                      Pill(
                        label:
                            UrgencyLabels.forSeverity(i.severity.name),
                        bg: AppColors.severitySoftFor(i.severity.name),
                        fg: AppColors.severityFor(i.severity.name),
                      ),
                    ],
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
              AiTriageBadges(
                incident: i,
                clusterSize: _clusterSize(i.clusterId),
                onClusterTap: i.clusterId == null
                    ? null
                    : () {
                        Navigator.pop(context);
                        setState(() => _clusterFilter = i.clusterId);
                      },
              ),
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

  List<Incident> get _filtered {
    Iterable<Incident> items = _incidents;
    if (_clusterFilter != null) {
      items = items.where((i) => i.clusterId == _clusterFilter);
    }
    if (_query.isEmpty) return items.toList();
    final q = _query.toLowerCase();
    return items
        .where((i) =>
            i.title.toLowerCase().contains(q) ||
            i.category.toLowerCase().contains(q) ||
            i.description.toLowerCase().contains(q))
        .toList();
  }

  int _clusterSize(String? cid) {
    if (cid == null) return 0;
    return _incidents.where((e) => e.clusterId == cid).length;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final urgent = _incidents
        .where((e) =>
            e.severity == IncidentSeverity.critical ||
            e.severity == IncidentSeverity.high)
        .length;
    final top = MediaQuery.of(context).padding.top;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    // layout.md › Guides and safe areas + tab-bars.md › Best practices:
    // the tab bar floats above content, so the nearby-incidents list must
    // reserve the bar's own clearance *plus* the system bottom inset.
    // scroll-views.md: the resting (collapsed-sheet) state must already
    // show scrollable content — hence the extra overscroll pad.
    final listClearance = kFloatingTabBarClearance + bottomInset + 24.0;

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Full-bleed map behind everything.
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
                markers: [
                  if (_myPosition != null)
                    Marker(
                      point: _myPosition!,
                      width: 48,
                      height: 48,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.info.withValues(alpha: 0.2),
                          border: Border.all(
                            color: AppColors.info,
                            width: 2,
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.person_pin_circle_rounded,
                            color: AppColors.info,
                            size: 26,
                          ),
                        ),
                      ),
                    ),
                  ..._incidents.map(
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
                  ),
                ],
              ),
            ],
          ),

          // Floating glass top bar: search + status pill + server button.
          Positioned(
            top: top + 8,
            left: 16,
            right: 16,
            child: LiquidGlass(
              radius: 26,
              blur: 28,
              padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _loading
                              ? AppColors.warning
                              : _incidents.isEmpty
                                  ? AppColors.success
                                  : AppColors.accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _loading
                              ? 'Locating incidents…'
                              : _incidents.isEmpty
                                  ? 'All clear near you'
                                  : '${_incidents.length} incident${_incidents.length == 1 ? '' : 's'} near you',
                          style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                      if (!_loading && urgent > 0)
                        Pill(
                          label: '$urgent need help NOW',
                          bg: AppColors.accentSoft,
                          fg: AppColors.accentDeep,
                          icon: Icons.bolt_rounded,
                        ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.refresh_rounded, size: 20),
                        color: AppColors.secondary,
                        tooltip: 'Refresh',
                        onPressed: _load,
                      ),
                      GlassIconButton(
                        icon: Icons.dns_outlined,
                        size: 38,
                        tooltip: 'Backend server',
                        onPressed: () => showServerDialog(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Search incidents…',
                      prefixIcon: const Icon(Icons.search_rounded,
                          size: 19),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.clear_rounded,
                                  size: 18),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _query = '');
                              },
                            ),
                      filled: true,
                      fillColor:
                          Colors.white.withValues(alpha: 0.65),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (v) =>
                        setState(() => _query = v.trim()),
                  ),
                ],
              ),
            ),
          ),

          // Draggable glass bottom sheet with nearby incidents.
          DraggableScrollableSheet(
            controller: _sheetController,
            initialChildSize: 0.28,
            minChildSize: 0.16,
            maxChildSize: 0.62,
            builder: (context, scrollController) {
              return LiquidGlass(
                radius: 28,
                blur: 30,
                highlight: true,
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    Padding(
                      padding:
                          const EdgeInsets.only(top: 10, bottom: 4),
                      child: Container(
                        width: 42,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.black
                              .withValues(alpha: 0.18),
                          borderRadius:
                              BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                          18, 2, 18, 8),
                      child: Row(
                        children: [
                          const Text(
                            'Nearby',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (_clusterFilter != null)
                            GestureDetector(
                              onTap: () =>
                                  setState(() => _clusterFilter = null),
                              child: Pill(
                                label:
                                    'cluster ${_clusterFilter!.length > 6 ? _clusterFilter!.substring(0, 6) : _clusterFilter!} ✕',
                                bg: AppColors.successSoft,
                                fg: AppColors.success,
                              ),
                            )
                          else if (_loading)
                            const SizedBox(
                              width: 15,
                              height: 15,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2),
                            )
                          else
                            Pill(
                              label: '${filtered.length}',
                              bg: AppColors.infoSoft,
                              fg: AppColors.info,
                            ),
                          const Spacer(),
                          TextButton(
                            onPressed: _load,
                            child: const Text('Refresh'),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _loading
                          ? const Center(
                              child: CircularProgressIndicator())
                          : filtered.isEmpty
                              ? SingleChildScrollView(
                                  controller:
                                      scrollController,
                                  child: Padding(
                                    padding:
                                        EdgeInsets.fromLTRB(
                                            18, 4, 18, listClearance),
                                    child: const EmptyState(
                                      icon:
                                          Icons.map_outlined,
                                      title:
                                          'Nothing to show yet',
                                      hint:
                                          'Incidents nearby will appear as pins here.',
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  controller:
                                      scrollController,
                                  padding: EdgeInsets
                                      .fromLTRB(
                                          14, 0, 14, listClearance),
                                  itemCount:
                                      filtered.length,
                                  separatorBuilder:
                                      (_, __) => const SizedBox(
                                          height: 8),
                                  itemBuilder:
                                      (context, idx) {
                                    final i =
                                        filtered[idx];
                                    final sev = AppColors
                                        .severityFor(i
                                            .severity
                                            .name);
                                    return LiquidGlass(
                                      radius: 22,
                                      blur: 24,
                                      padding:
                                          const EdgeInsets
                                              .all(12),
                                      onTap: () =>
                                          _showIncident(
                                              i),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 40,
                                            height: 40,
                                            decoration:
                                                BoxDecoration(
                                              color: AppColors
                                                  .severitySoftFor(i
                                                      .severity
                                                      .name),
                                              borderRadius:
                                                  BorderRadius
                                                      .circular(
                                                          13),
                                            ),
                                            child: Icon(
                                              Icons
                                                  .location_pin,
                                              color: sev,
                                              size: 21,
                                            ),
                                          ),
                                          const SizedBox(
                                              width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment
                                                      .start,
                                              children: [
                                                Text(
                                                  i.title,
                                                  maxLines:
                                                      1,
                                                  overflow:
                                                      TextOverflow
                                                          .ellipsis,
                                                  style: const TextStyle(
                                                      fontSize:
                                                          14,
                                                      fontWeight:
                                                          FontWeight
                                                              .w800),
                                                ),
                                                const SizedBox(
                                                    height:
                                                        2),
                                                Text(
                                                  '${i.category} • ${i.status.name}',
                                                  style: const TextStyle(
                                                      color: AppColors
                                                          .secondary,
                                                      fontSize:
                                                          12),
                                                ),
                                                const SizedBox(height: 4),
                                                AiTriageBadges(
                                                  incident: i,
                                                  clusterSize:
                                                      _clusterSize(
                                                          i.clusterId),
                                                  onClusterTap: i.clusterId ==
                                                          null
                                                      ? null
                                                      : () => setState(() =>
                                                          _clusterFilter =
                                                              i.clusterId),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(
                                              width: 8),
                                          Pill(
                                            label: i
                                                .severity
                                                .name
                                                .toUpperCase(),
                                            bg: AppColors
                                                .severitySoftFor(i
                                                    .severity
                                                    .name),
                                            fg: sev,
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                    ),
                  ],
                ),
              );
            },
          ),

          // Locate / recenter: floats above the sheet's resting position and
          // the floating tab bar zone (tab-bars.md: bar stays visible).
          Positioned(
            right: 16,
            bottom: kFloatingTabBarClearance + 112,
            child: Semantics(
              button: true,
              label: 'Re-center on my location',
              child: GlassIconButton(
              icon: Icons.my_location_rounded,
              tooltip: 'Re-center on me',
              color: AppColors.info,
              onPressed: _recenter,
              ),
            ),
          ),

          // Floating SOS above the floating tab bar zone. 62pt circle beats
          // the 44pt minimum (accessibility.md › Mobility) with room for
          // one-handed reach (designing-for-ios.md).
          Positioned(
            right: 16,
            bottom: kFloatingTabBarClearance + 48,
            child: Semantics(
              button: true,
              label: 'Send SOS',
              child: GestureDetector(
              onTap: widget.onSosPressed,
              child: Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.sosStart,
                      AppColors.sosEnd
                    ],
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.8),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent
                          .withValues(alpha: 0.5),
                      blurRadius: 22,
                      spreadRadius: 1,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: const Text(
                  'SOS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
