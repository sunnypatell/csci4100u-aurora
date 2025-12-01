import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_map/flutter_map.dart';
import 'aurora_shell.dart';
import '../widgets/small_glowing_candle.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'dart:math' as math;

/// HelpNearMePage
/// Interactive map with clustering, nearby POIs and a search bar.
class HelpNearMePage extends StatefulWidget {
  const HelpNearMePage({super.key});

  @override
  State<HelpNearMePage> createState() => _HelpNearMePageState();
}

class _HelpNearMePageState extends State<HelpNearMePage> {
  final MapController _mapController = MapController();
  LatLng? _center;
  bool _loading = true;
  // map drag is handled manually (via gestures); keep flutter_map drag disabled
  // (old pointer tracking removed; using scale gesture handling)
  List<Map<String, dynamic>> _nearbyPois = [];
  List<Marker> _poiMarkers = [];
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  // For manual two-finger pan handling
  Offset? _lastFocalPoint;
  // Allow panning after a double-tap (second tap) — user taps twice then drags to pan.
  bool _doubleTapPanEnabled = false;
  // legacy field removed; using _lastFocalPoint for tracking

  // Default fallback (Toronto) if location is unavailable/denied.
  static const LatLng _fallbackCenter = LatLng(43.6532, -79.3832);

  // Sample POIs (small list for demo)
  static const List<Map<String, dynamic>> _samplePois = [
    {
      'name': 'Toronto General Hospital',
      'lat': 43.6577,
      'lng': -79.3865,
    },
    {
      'name': 'Mississauga Hospital',
      'lat': 43.5904,
      'lng': -79.6406,
    },
    {
      'name': "St. Michael's Hospital",
      'lat': 43.6531,
      'lng': -79.3754,
    },
  ];

  @override
  void initState() {
    super.initState();
    _initLocationAndPois();
    _searchController.addListener(() => _onSearchChanged(_searchController.text));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initLocationAndPois() async {
    final LatLng center = await _getInitialCenter();
    _computeNearbyPois(center);
    setState(() {
      _center = center;
      _loading = false;
    });
  }

  Future<LatLng> _getInitialCenter() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return _fallbackCenter;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        return _fallbackCenter;
      }

      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      return LatLng(position.latitude, position.longitude);
    } catch (_) {
      return _fallbackCenter;
    }
  }

  void _computeNearbyPois(LatLng center) {
    final List<Map<String, dynamic>> nearby = [];
    final List<Marker> markers = [];

    for (final poi in _samplePois) {
      final double poiLat = poi['lat'] as double;
      final double poiLng = poi['lng'] as double;
      final double distanceMeters = Geolocator.distanceBetween(
        center.latitude,
        center.longitude,
        poiLat,
        poiLng,
      );
      if (distanceMeters <= 50000) {
        nearby.add(poi);
        markers.add(
          Marker(
            point: LatLng(poiLat, poiLng),
            width: 36,
            height: 36,
            builder: (ctx) => GestureDetector(
              onTap: () => _showPoiDialog(ctx, poi, distanceMeters),
              child: const Icon(
                Icons.local_hospital,
                size: 28,
                color: Colors.blue,
              ),
            ),
          ),
        );
      }
    }

    setState(() {
      _nearbyPois = nearby;
      _poiMarkers = markers;
      _searchResults = List<Map<String, dynamic>>.from(nearby);
    });
  }

  void _showPoiDialog(BuildContext ctx, Map<String, dynamic> poi, double distanceMeters) {
    showDialog(
      context: ctx,
      builder: (dctx) => AlertDialog(
        title: Text(poi['name'] as String),
        content: Text('Distance: ${(distanceMeters / 1000).toStringAsFixed(1)} km'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _onSearchChanged(String q) {
    final query = q.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _searchResults = List<Map<String, dynamic>>.from(_nearbyPois);
      } else {
        _searchResults = _nearbyPois.where((p) => (p['name'] as String).toLowerCase().contains(query)).toList();
      }
    });
  }

  void _onSelectSearchResult(Map<String, dynamic> poi) {
    final LatLng target = LatLng(poi['lat'] as double, poi['lng'] as double);
    _mapController.move(target, 15);
    setState(() {
      _searchController.text = poi['name'] as String;
      _searchResults = [poi];
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bool inShell = context.findAncestorWidgetOfExactType<AuroraShell>() != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF5EFE7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5EFE7),
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        leading: const Padding(
          padding: EdgeInsets.only(left: 12.0),
          child: SizedBox(
            width: 44,
            height: 44,
            child: Center(child: SmallGlowingCandle()),
          ),
        ),
        title: const Text(
          'Help Near Me',
          style: TextStyle(color: Color(0xFF2F2E2C)),
        ),
      ),
      bottomNavigationBar: inShell
          ? null
          : NavigationBar(
              // When opened directly (outside the shell), provide a
              // consistent navbar and route back into the shell.
              selectedIndex: 3,
              onDestinationSelected: (i) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (_) => AuroraShell(initialIndex: i),
                  ),
                  (route) => false,
                );
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard_rounded),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.menu_book_outlined),
                  selectedIcon: Icon(Icons.menu_book_rounded),
                  label: 'Journal',
                ),
                NavigationDestination(
                  icon: Icon(Icons.library_books_outlined),
                  selectedIcon: Icon(Icons.library_books_rounded),
                  label: 'Resources',
                ),
                NavigationDestination(
                  icon: Icon(Icons.place_outlined),
                  selectedIcon: Icon(Icons.place_rounded),
                  label: 'Help Nearby',
                ),
                NavigationDestination(
                  icon: Icon(Icons.psychology_alt_outlined),
                  selectedIcon: Icon(Icons.psychology_alt_rounded),
                  label: 'Chat',
                ),
                NavigationDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings_rounded),
                  label: 'Settings',
                ),
              ],
            ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Search nearby hospitals & support centres',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  if (_searchController.text.isNotEmpty && _searchResults.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListView.builder(
                        itemCount: _searchResults.length,
                        itemBuilder: (context, idx) {
                          final poi = _searchResults[idx];
                          return ListTile(
                            title: Text(poi['name'] as String),
                            onTap: () => _onSelectSearchResult(poi),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: _loading
                ? Container(
                    margin: const EdgeInsets.all(16),
                    height: 240,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.grey.shade300,
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  )
                : Container(
                    margin: const EdgeInsets.all(16),
                    height: 360,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.grey.shade300,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onScaleStart: (details) {
                        _lastFocalPoint = details.focalPoint;
                      },
                      onDoubleTapDown: (details) {
                        _doubleTapPanEnabled = true;
                        _lastFocalPoint = details.globalPosition;
                      },
                      onScaleUpdate: (details) {
                        if ((details.pointerCount >= 2 || _doubleTapPanEnabled) && _center != null) {
                          final Offset focal = details.focalPoint;
                          final Offset last = _lastFocalPoint ?? focal;
                          final dx = focal.dx - last.dx;
                          final dy = focal.dy - last.dy;

                          final double latRad = _center!.latitude * (3.1415926535897932 / 180.0);
                          double currentZoom = 13.0;
                          try {
                            currentZoom = _mapController.zoom;
                          } catch (_) {}

                          final double metersPerPixel =
                              156543.03392 * (math.cos(latRad)) / (math.pow(2, currentZoom) as double);

                          final double deltaLonMeters = -dx * metersPerPixel;
                          final double deltaLatMeters = dy * metersPerPixel;

                          final double deltaLatDeg = deltaLatMeters / 111320.0;
                          final double deltaLonDeg =
                              deltaLonMeters / (111320.0 * math.cos(latRad).abs().clamp(0.000001, 1.0));

                          final LatLng newCenter = LatLng(
                            _center!.latitude + deltaLatDeg,
                            _center!.longitude + deltaLonDeg,
                          );

                          _mapController.move(newCenter, currentZoom);
                          setState(() => _center = newCenter);
                          _lastFocalPoint = focal;
                        }
                      },
                      onScaleEnd: (details) {
                        _doubleTapPanEnabled = false;
                        _lastFocalPoint = null;
                      },
                      child: Stack(
                        children: [
                          FlutterMap(
                            mapController: _mapController,
                            options: MapOptions(
                              center: _center,
                              zoom: 13,
                              interactiveFlags:
                                  (InteractiveFlag.all & ~InteractiveFlag.rotate & ~InteractiveFlag.drag),
                            ),
                            children: [
                              TileLayer(
                                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.example.aurora',
                              ),

                              MarkerLayer(
                                markers: [
                                  if (_center != null)
                                    Marker(
                                      point: _center!,
                                      width: 44,
                                      height: 44,
                                      builder: (ctx) => const Icon(
                                        Icons.my_location,
                                        size: 36,
                                        color: Colors.redAccent,
                                      ),
                                    ),
                                ],
                              ),

                              MarkerClusterLayerWidget(
                                options: MarkerClusterLayerOptions(
                                  maxClusterRadius: 45,
                                  size: const Size(40, 40),
                                  fitBoundsOptions: const FitBoundsOptions(padding: EdgeInsets.all(50)),
                                  markers: _poiMarkers,
                                  builder: (context, markers) {
                                    return Container(
                                      alignment: Alignment.center,
                                      decoration: const BoxDecoration(
                                        color: Colors.blue,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Text(
                                        markers.length.toString(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),

                          Align(
                            alignment: Alignment.topCenter,
                            child: Container(
                              margin: const EdgeInsets.all(8),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Nearby Hospitals & Support Centres',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                [
                  const SizedBox(height: 8),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Helplines & Support',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2F2E2C),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _HelplineTile(
                    title: 'Emergency (Canada)',
                    subtitle: 'If you or someone is in immediate danger, call 911.',
                    actionLabel: 'Call 911',
                    color: Colors.redAccent.shade100,
                    onPressed: () => launchUrl(Uri.parse('tel:911')),
                  ),
                  _HelplineTile(
                    title: '9-8-8 Suicide Crisis Helpline',
                    subtitle: 'Call or text 9-8-8 (24/7, Canada-wide).',
                    actionLabel: 'Call 9-8-8',
                    color: Colors.purple.shade200,
                    onPressed: () => launchUrl(Uri.parse('tel:988')),
                  ),
                  _HelplineTile(
                    title: 'Kids Help Phone',
                    subtitle: 'Young people: Call 1-800-668-6868 • Text CONNECT to 686868.',
                    actionLabel: 'Call 1-800-668-6868',
                    color: Colors.teal.shade200,
                    onPressed: () => launchUrl(Uri.parse('tel:+18006686868')),
                  ),
                  _HelplineTile(
                    title: 'Talk Suicide Canada',
                    subtitle: '1-833-456-4566 (24/7) • Text 45645 (4pm–midnight ET).',
                    actionLabel: 'Call 1-833-456-4566',
                    color: Colors.amber.shade200,
                    onPressed: () => launchUrl(Uri.parse('tel:+18334564566')),
                  ),
                  _HelplineTile(
                    title: 'Hope for Wellness (Indigenous Peoples)',
                    subtitle: '1-855-242-3310 • Chat at hopeforwellness.ca',
                    actionLabel: 'Open Website',
                    color: Colors.indigo.shade200,
                    onPressed: () => launchUrl(Uri.parse('https://hopeforwellness.ca')),
                  ),
                  _HelplineTile(
                    title: 'ConnexOntario (Mental Health & Addiction)',
                    subtitle: '1-866-531-2600 (24/7 information & referral)',
                    actionLabel: 'Call 1-866-531-2600',
                    color: Colors.greenAccent.shade100,
                    onPressed: () => launchUrl(Uri.parse('tel:+18665312600')),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Text(
                      '💙 Remember, reaching out is a sign of strength. You are not alone.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
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


class _HelplineTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String actionLabel;
  final Color color;
  final VoidCallback onPressed;

  const _HelplineTile({
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: color.withValues(alpha: 0.35),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2F2E2C),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(color: Color(0xFF2F2E2C)),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF2F2E2C),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                onPressed: onPressed,
                child: Text(
                  actionLabel,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
