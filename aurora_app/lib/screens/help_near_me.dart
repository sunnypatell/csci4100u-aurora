import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

/// HelpNearMePage
/// Now uses an interactive map (flutter_map + OpenStreetMap)
/// with user location and a marker layer, instead of a static image.
class HelpNearMePage extends StatelessWidget {
  const HelpNearMePage({super.key});

  // Default fallback (Toronto) if location is unavailable/denied.
  static const LatLng _fallbackCenter = LatLng(43.6532, -79.3832);

  // Fetch user location with permission handling, but gracefully fall back.
  Future<LatLng> _getInitialCenter() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Location services off → fallback
        return _fallbackCenter;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        // Permissions denied → fallback
        return _fallbackCenter;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      return LatLng(position.latitude, position.longitude);
    } catch (_) {
      // Any error → fallback
      return _fallbackCenter;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF5EFE7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5EFE7),
        elevation: 0,
        title: const Text(
          'Help Near Me',
          style: TextStyle(color: Color(0xFF2F2E2C)),
        ),
      ),
      body: Column(
        children: [
          // 🔍 Interactive Map Region
          FutureBuilder<LatLng>(
            future: _getInitialCenter(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Container(
                  margin: const EdgeInsets.all(16),
                  height: 240,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.grey.shade300,
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final center = snapshot.data ?? _fallbackCenter;

              return Container(
                margin: const EdgeInsets.all(16),
                height: 240,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.grey.shade300,
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    FlutterMap(
                      options: MapOptions(
                        center: center,
                        zoom: 13,
                        interactiveFlags: InteractiveFlag.all &
                            ~InteractiveFlag.rotate, // disable rotation
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.aurora',
                        ),

                        // 🧿 Marker layer – currently just user location.
                        // Future: add hospital/support markers here.
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: center,
                              width: 40,
                              height: 40,
                              builder: (ctx) => const Icon(
                                Icons.person_pin_circle,
                                size: 36,
                                color: Colors.redAccent,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Overlay label at top
                    Align(
                      alignment: Alignment.topCenter,
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
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
              );
            },
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Align(
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
          ),

          const SizedBox(height: 12),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              children: [
                _HelplineTile(
                  title: 'Emergency (Canada)',
                  subtitle:
                      'If you or someone is in immediate danger, call 911.',
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
                  subtitle:
                      'Young people: Call 1-800-668-6868 • Text CONNECT to 686868.',
                  actionLabel: 'Call 1-800-668-6868',
                  color: Colors.teal.shade200,
                  onPressed: () => launchUrl(Uri.parse('tel:+18006686868')),
                ),
                _HelplineTile(
                  title: 'Talk Suicide Canada',
                  subtitle:
                      '1-833-456-4566 (24/7) • Text 45645 (4pm–midnight ET).',
                  actionLabel: 'Call 1-833-456-4566',
                  color: Colors.amber.shade200,
                  onPressed: () => launchUrl(Uri.parse('tel:+18334564566')),
                ),
                _HelplineTile(
                  title: 'Hope for Wellness (Indigenous Peoples)',
                  subtitle: '1-855-242-3310 • Chat at hopeforwellness.ca',
                  actionLabel: 'Open Website',
                  color: Colors.indigo.shade200,
                  onPressed: () =>
                      launchUrl(Uri.parse('https://hopeforwellness.ca')),
                ),
                _HelplineTile(
                  title: 'ConnexOntario (Mental Health & Addiction)',
                  subtitle: '1-866-531-2600 (24/7 information & referral)',
                  actionLabel: 'Call 1-866-531-2600',
                  color: Colors.greenAccent.shade100,
                  onPressed: () => launchUrl(Uri.parse('tel:+18665312600')),
                ),
                const SizedBox(height: 20),
                Text(
                  '💙 Remember, reaching out is a sign of strength. You are not alone.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
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

/// Reusable helpline tile widget
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
