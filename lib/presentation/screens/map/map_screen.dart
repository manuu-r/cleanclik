import 'dart:async';
import 'package:cleanclik/presentation/widgets/map/holographic_marker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:maps_launcher/maps_launcher.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'dart:io' show Platform;
import 'package:cleanclik/core/theme/neon_colors.dart';
import 'package:cleanclik/core/services/location/location_service.dart';
import 'package:cleanclik/core/services/location/bin_location_service.dart';
import 'package:cleanclik/core/models/bin_location.dart';

import 'package:cleanclik/presentation/widgets/map/bin_marker.dart';
import 'package:cleanclik/presentation/widgets/map/mission_marker.dart';
import 'package:cleanclik/presentation/widgets/map/friend_marker.dart';
import 'package:cleanclik/presentation/widgets/inventory/detail_card.dart';
import 'package:cleanclik/core/services/location/map_data_service.dart';

import 'package:cleanclik/presentation/widgets/map/ping_animation.dart';
import 'package:cleanclik/presentation/widgets/map/map_control_column.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen>
    with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  late AnimationController _pingAnimationController;

  // Default location (Bangalore, India)
  static const LatLng _initialCenter = LatLng(12.971599, 77.594566);
  static const double _initialZoom = 14.0;

  // Map layers visibility
  bool _showBins = true;
  bool _showHotspots = true;
  bool _showMissions = false;
  bool _showFriends = false;
  bool _showUserLocation = true;

  List<Marker> _markers = [];
  List<BinLocation> _localBins = [];
  LocationData? _currentLocation;
  final bool _isModalOpen = false;
  bool _followUserLocation = false;

  // Performance optimization
  double _currentZoom = _initialZoom;
  Timer? _markerUpdateTimer;

  // Detail card state
  DetailType? _selectedDetailType;
  String? _selectedDetailTitle;
  Map<String, dynamic>? _selectedDetailData;
  List<ActionButton>? _selectedDetailActions;

  @override
  void initState() {
    super.initState();
    _pingAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _loadLocalBins();
    _createMarkers();

    // Set up periodic refresh to catch newly scanned bins
    Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        _loadLocalBins();
      } else {
        timer.cancel();
      }
    });
  }

  /// Load local bins from storage
  Future<void> _loadLocalBins() async {
    final binService = ref.read(binLocationServiceProvider);
    try {
      _localBins = await binService.getAllBins();
      print(
        '📦 [MAP_SCREEN] Loaded ${_localBins.length} local bins from storage',
      );
      if (_localBins.isNotEmpty) {
        for (final bin in _localBins) {
          print('  - ${bin.name} (${bin.category}) at ${bin.coordinates}');
        }
      }
      if (mounted) {
        setState(() {
          _createMarkers();
        });
      }
    } catch (e) {
      print('❌ [MAP_SCREEN] Error loading local bins: $e');
    }
  }

  void _createMarkers() {
    // Debounce marker updates for performance
    _markerUpdateTimer?.cancel();
    _markerUpdateTimer = Timer(const Duration(milliseconds: 100), () {
      _createMarkersOptimized();
    });
  }

  void _createMarkersOptimized() {
    final markers = <Marker>[];

    // Calculate viewport bounds for culling
    final viewportBounds = _calculateViewportBounds();
    final shouldShowDetailedMarkers = _currentZoom >= 12.0;
    final maxMarkersToShow = _getMaxMarkersForZoom(_currentZoom);

    // Local bins from storage with viewport culling
    if (_showBins) {
      final visibleLocalBins = _localBins
          .where((bin) => _isPointInViewport(bin.coordinates, viewportBounds))
          .take(maxMarkersToShow ~/ 2)
          .toList();

      print(
        '🗺️ [MAP_SCREEN] Creating markers for ${visibleLocalBins.length} visible local bins (total: ${_localBins.length})',
      );

      markers.addAll(
        visibleLocalBins.map(
          (bin) => Marker(
            point: bin.coordinates,
            width: shouldShowDetailedMarkers ? 50 : 35,
            height: shouldShowDetailedMarkers ? 50 : 35,
            child: shouldShowDetailedMarkers
                ? _buildEnhancedBinMarker(bin)
                : _buildSimpleBinMarker(bin),
          ),
        ),
      );

      // Add default bins from service with viewport culling
      final bins = MapDataService.getBins();
      final visibleBins = bins
          .where((bin) => _isPointInViewport(bin.location, viewportBounds))
          .take(maxMarkersToShow ~/ 2)
          .toList();

      markers.addAll(
        visibleBins.map(
          (bin) => Marker(
            point: bin.location,
            width: shouldShowDetailedMarkers ? 40 : 30,
            height: shouldShowDetailedMarkers ? 40 : 30,
            child: shouldShowDetailedMarkers
                ? BinMarker(
                    bin: BinData(
                      name: bin.name,
                      type: bin.type,
                      fillLevel: bin.fillLevel,
                      lat: bin.location.latitude,
                      lng: bin.location.longitude,
                    ),
                    onTap: (b) => _showBinDetails(
                      b.name,
                      b.type,
                      b.fillLevel,
                      bin.location,
                    ),
                  )
                : _buildSimpleBinMarkerFromBin(bin),
          ),
        ),
      );
    }

    // User location marker (always show)
    if (_showUserLocation && _currentLocation != null) {
      markers.add(
        Marker(
          point: _currentLocation!.position,
          width: 60,
          height: 60,
          child: _buildUserLocationMarker(),
        ),
      );
    }

    // Heat zones (replacing hotspot fire icons)
    if (_showHotspots) {
      final hotspots = MapDataService.getHotspots();
      markers.addAll(
        hotspots.map(
          (hotspot) => Marker(
            point: hotspot.location,
            width: 80,
            height: 80,
            child: _buildHeatZoneMarker(hotspot),
          ),
        ),
      );
    }

    // Missions
    if (_showMissions) {
      final missions = MapDataService.getMissions();
      markers.addAll(
        missions.map(
          (mission) => Marker(
            point: mission.location,
            width: 45,
            height: 45,
            child: MissionMarker(
              mission: MissionData(
                name: mission.name,
                items: mission.items,
                timeLeft: mission.timeLeft,
                lat: mission.location.latitude,
                lng: mission.location.longitude,
              ),
              onTap: (m) => _showMissionDetails(m.name, m.items, m.timeLeft),
            ),
          ),
        ),
      );
    }

    // Friends
    if (_showFriends) {
      final friends = MapDataService.getFriends();
      markers.addAll(
        friends.map(
          (friend) => Marker(
            point: friend.location,
            width: 40,
            height: 40,
            child: FriendMarker(
              friend: FriendData(
                username: friend.username,
                level: friend.level,
                status: friend.status,
                lat: friend.location.latitude,
                lng: friend.location.longitude,
              ),
              onTap: (f) => _showFriendDetails(f.username, f.level, f.status),
            ),
          ),
        ),
      );
    }

    setState(() {
      _markers = markers;
    });
  }

  /// Build enhanced bin marker with distance and category info
  Widget _buildEnhancedBinMarker(BinLocation bin) {
    final distance = _currentLocation != null
        ? GeohashUtils.distanceBetween(
            _currentLocation!.position,
            bin.coordinates,
          )
        : null;

    return GestureDetector(
      onTap: () => _showEnhancedBinDetails(bin, distance),
      child: HolographicMarker(category: bin.category, distance: distance),
    );
  }

  /// Build user location marker with accuracy circle
  Widget _buildUserLocationMarker() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Accuracy circle
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.blue.withOpacity(0.5), width: 1),
          ),
        ),
        // User location dot
        Container(
          width: 20,
          height: 20,
          decoration: const BoxDecoration(
            color: Colors.blue,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: Colors.white, blurRadius: 4, spreadRadius: 2),
            ],
          ),
        ),
        // Heading indicator
        if (_currentLocation?.heading != null)
          Transform.rotate(
            angle: (_currentLocation!.heading! * 3.14159) / 180,
            child: Container(
              width: 3,
              height: 15,
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
      ],
    );
  }

  void _showBinDetails(
    String name,
    String type,
    int fillLevel,
    LatLng location,
  ) {
    final distance = _currentLocation != null
        ? GeohashUtils.distanceBetween(_currentLocation!.position, location)
        : null;

    setState(() {
      _selectedDetailType = DetailType.bin;
      _selectedDetailTitle = name;
      _selectedDetailData = {
        'type': type,
        'fillLevel': fillLevel,
        'distance': distance != null
            ? '${distance.round()}m away'
            : 'Distance unknown',
      };
      _selectedDetailActions = [
        ActionButton(
          icon: Icons.directions,
          label: 'Navigate',
          onPressed: () => _navigateToLocation(location),
          color: Colors.blue,
        ),
      ];
    });
  }

  void _showEnhancedBinDetails(BinLocation bin, double? distance) {
    setState(() {
      _selectedDetailType = DetailType.bin;
      _selectedDetailTitle = bin.name;
      _selectedDetailData = {
        'Category': bin.category,
        'Distance': distance != null
            ? '${distance.round()}m away'
            : 'Distance unknown',
        'Last Scanned': _formatTimestamp(bin.timestamp),
        'Fill Level': bin.fillLevel != null
            ? '${(bin.fillLevel! * 100).round()}%'
            : 'Unknown',
      };
      _selectedDetailActions = [
        ActionButton(
          icon: Icons.directions,
          label: 'Navigate',
          onPressed: () => _navigateToLocation(bin.coordinates),
          color: Colors.blue,
        ),
        ActionButton(
          icon: Icons.info,
          label: 'Details',
          onPressed: () => _showBinInfo(bin),
          color: NeonColors.oceanBlue,
        ),
      ];
    });
  }

  void _showMissionDetails(String name, String items, String timeLeft) {
    setState(() {
      _selectedDetailType = DetailType.mission;
      _selectedDetailTitle = name;
      _selectedDetailData = {
        'Items': items,
        'Time Left': timeLeft,
        'XP Reward': '150 XP',
        'Description': 'Help clean up this area and earn rewards!',
      };
      _selectedDetailActions = [
        ActionButton(
          icon: Icons.check_circle_outline,
          label: 'Accept Mission',
          onPressed: _acceptMission,
          color: NeonColors.oceanBlue,
        ),
      ];
    });
  }

  void _showFriendDetails(String name, String level, String status) {
    setState(() {
      _selectedDetailType = DetailType.friend;
      _selectedDetailTitle = name;
      _selectedDetailData = {
        'Level': level,
        'Status': status,
        'Points': '1,250',
        'Eco-Rank': 'Green Warrior',
      };
      _selectedDetailActions = [
        ActionButton(
          icon: Icons.person,
          label: 'View Profile',
          onPressed: _viewFriendProfile,
          color: NeonColors.earthOrange,
        ),
        ActionButton(
          icon: Icons.group_add,
          label: 'Invite',
          onPressed: _inviteToCleanup,
          color: Colors.white,
        ),
      ];
    });
  }

  /// Navigate to a specific location using external maps
  Future<void> _navigateToLocation(LatLng location) async {
    setState(() => _selectedDetailType = null);

    try {
      print(
        '🗺️ [MAP_SCREEN] Starting navigation to ${location.latitude}, ${location.longitude}',
      );

      // Method 1: Try maps_launcher package (most reliable)
      try {
        print('🗺️ [MAP_SCREEN] Trying maps_launcher package...');

        await MapsLauncher.launchCoordinates(
          location.latitude,
          location.longitude,
          'Bin Location',
        );
        print('✅ [MAP_SCREEN] Successfully launched with maps_launcher');
        return;
      } catch (e) {
        print('⚠️ [MAP_SCREEN] maps_launcher failed: $e');
      }

      // Method 2: Try Android Intent (Android only)
      if (Platform.isAndroid) {
        try {
          print('🗺️ [MAP_SCREEN] Trying Android Intent...');
          final intent = AndroidIntent(
            action: 'android.intent.action.VIEW',
            data:
                'google.navigation:q=${location.latitude},${location.longitude}&mode=w',
          );
          await intent.launch();
          print('✅ [MAP_SCREEN] Successfully launched with Android Intent');
          return;
        } catch (e) {
          print('⚠️ [MAP_SCREEN] Android Intent failed: $e');
        }

        // Try geo intent as fallback
        try {
          print('🗺️ [MAP_SCREEN] Trying geo intent...');
          final geoIntent = AndroidIntent(
            action: 'android.intent.action.VIEW',
            data:
                'geo:${location.latitude},${location.longitude}?q=${location.latitude},${location.longitude}(Bin Location)',
          );
          await geoIntent.launch();
          print('✅ [MAP_SCREEN] Successfully launched with geo intent');
          return;
        } catch (e) {
          print('⚠️ [MAP_SCREEN] Geo intent failed: $e');
        }
      }

      // Method 3: Try URL launcher with different URLs
      final urls = [
        'https://www.google.com/maps/dir/?api=1&destination=${location.latitude},${location.longitude}&travelmode=walking',
        'https://maps.apple.com/?daddr=${location.latitude},${location.longitude}&dirflg=w',
        'https://www.openstreetmap.org/directions?to=${location.latitude},${location.longitude}',
      ];

      for (final urlString in urls) {
        try {
          final url = Uri.parse(urlString);
          print('🗺️ [MAP_SCREEN] Trying URL: $urlString');

          if (await canLaunchUrl(url)) {
            final launched = await launchUrl(
              url,
              mode: LaunchMode.externalApplication,
            );
            if (launched) {
              print('✅ [MAP_SCREEN] Successfully launched URL: $urlString');
              return;
            }
          }
        } catch (e) {
          print('⚠️ [MAP_SCREEN] URL failed: $urlString - $e');
          continue;
        }
      }

      // If all methods fail, show helpful message
      print('❌ [MAP_SCREEN] All navigation methods failed');
      if (mounted) {
        _showNavigationFailedDialog(location);
      }
    } catch (e) {
      print('❌ [MAP_SCREEN] Navigation error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Navigation error: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Show dialog when navigation fails with helpful options
  void _showNavigationFailedDialog(LatLng location) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Navigation Not Available'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('No maps app found on this device.'),
            const SizedBox(height: 16),
            const Text('Bin Location:'),
            SelectableText(
              '${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}',
              style: const TextStyle(fontFamily: 'monospace'),
            ),
            const SizedBox(height: 16),
            const Text('You can:'),
            const Text('• Copy coordinates above'),
            const Text('• Install Google Maps or another maps app'),
            const Text(
              '• Use the coordinates in your preferred navigation app',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _openPlayStore();
            },
            child: const Text('Get Maps App'),
          ),
        ],
      ),
    );
  }

  /// Open Play Store to install Google Maps
  Future<void> _openPlayStore() async {
    try {
      const playStoreUrl =
          'https://play.google.com/store/apps/details?id=com.google.android.apps.maps';
      final url = Uri.parse(playStoreUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      print('⚠️ [MAP_SCREEN] Could not open Play Store: $e');
    }
  }

  /// Test navigation to a known location (Bangalore City Center)
  Future<void> _testNavigation() async {
    const testLocation = LatLng(12.9716, 77.5946); // Bangalore city center
    print('🧪 [MAP_SCREEN] Testing navigation to Bangalore city center');

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Testing navigation to Bangalore city center...'),
        duration: Duration(seconds: 2),
      ),
    );

    await _navigateToLocation(testLocation);
  }

  /// Add a test bin near current location for debugging
  Future<void> _addTestBin() async {
    if (_currentLocation == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Location not available')));
      return;
    }

    final binService = ref.read(binLocationServiceProvider);

    // Create a test bin 100m away from current location
    final testLocation = LatLng(
      _currentLocation!.position.latitude + 0.001, // ~100m north
      _currentLocation!.position.longitude + 0.001, // ~100m east
    );

    final testBin = BinLocation(
      id: 'test_bin_${DateTime.now().millisecondsSinceEpoch}',
      geohash: GeohashUtils.encode(
        testLocation.latitude,
        testLocation.longitude,
      ),
      coordinates: testLocation,
      category: 'recycle',
      name: 'Test Recycle Bin',
      timestamp: DateTime.now(),
      metadata: {'source': 'test', 'description': 'Test bin for debugging'},
    );

    final added = await binService.addBin(testBin);
    if (added) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Test bin added successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      print(
        '✅ [MAP_SCREEN] Test bin added: ${testBin.name} at ${testBin.coordinates}',
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Test bin already exists nearby'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  /// Show detailed bin information
  void _showBinInfo(BinLocation bin) {
    setState(() => _selectedDetailType = null);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(bin.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Category: ${bin.category}'),
            Text(
              'Coordinates: ${bin.coordinates.latitude.toStringAsFixed(6)}, ${bin.coordinates.longitude.toStringAsFixed(6)}',
            ),
            Text('Geohash: ${bin.geohash}'),
            Text('Added: ${_formatTimestamp(bin.timestamp)}'),
            if (bin.metadata != null) ...[
              const SizedBox(height: 8),
              const Text(
                'Additional Info:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ...bin.metadata!.entries.map((e) => Text('${e.key}: ${e.value}')),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _joinCleanup() {
    setState(() => _selectedDetailType = null);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Joined cleanup event!')));
  }

  void _acceptMission() {
    setState(() => _selectedDetailType = null);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Mission accepted!')));
  }

  void _viewFriendProfile() {
    setState(() => _selectedDetailType = null);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Opening friend profile...')));
  }

  void _inviteToCleanup() {
    setState(() => _selectedDetailType = null);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Invitation sent!')));
  }

  void _toggleLayer(String layer) {
    setState(() {
      switch (layer) {
        case 'bins':
          _showBins = !_showBins;
          break;
        case 'hotspots':
          _showHotspots = !_showHotspots;
          break;
        case 'missions':
          _showMissions = !_showMissions;
          break;
        case 'friends':
          _showFriends = !_showFriends;
          break;
        case 'location':
          _showUserLocation = !_showUserLocation;
          break;
      }
      _createMarkers();
    });
  }

  void _goToCurrentLocation() {
    if (_currentLocation != null) {
      _mapController.move(_currentLocation!.position, 16.0);
      setState(() {
        _followUserLocation = true;
      });
    } else {
      _mapController.move(_initialCenter, _initialZoom);
    }
  }

  /// Find and show the nearest bin to current location
  Future<void> _showNearestBin() async {
    if (_currentLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Location not available. Please enable location services.',
          ),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    print(
      '🔍 [MAP_SCREEN] Searching for nearest bin from location: ${_currentLocation!.position}',
    );

    // Find nearest bin from local storage
    final binService = ref.read(binLocationServiceProvider);
    final nearestBin = await binService.findNearestBin(
      _currentLocation!.position,
      maxDistanceMeters: 5000, // 5km radius
    );

    if (nearestBin != null) {
      // Move map to show both user location and nearest bin
      final distance = GeohashUtils.distanceBetween(
        _currentLocation!.position,
        nearestBin.coordinates,
      );

      print(
        '✅ [MAP_SCREEN] Found nearest local bin: ${nearestBin.name} at ${distance.round()}m',
      );

      // Calculate appropriate zoom level based on distance
      double zoom = 16.0;
      if (distance > 1000) zoom = 14.0;
      if (distance > 2000) zoom = 13.0;
      if (distance > 5000) zoom = 12.0;

      _mapController.move(nearestBin.coordinates, zoom);

      // Show bin details
      _showEnhancedBinDetails(nearestBin, distance);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Nearest ${nearestBin.category} bin: ${distance.round()}m away',
          ),
          backgroundColor: _getCategoryColor(nearestBin.category),
          action: SnackBarAction(
            label: 'Navigate',
            textColor: Colors.white,
            onPressed: () => _navigateToLocation(nearestBin.coordinates),
          ),
        ),
      );
    } else {
      // Check default bins from service
      final bins = MapDataService.getBins();
      print(
        '🔍 [MAP_SCREEN] No local bins found, checking ${bins.length} default bins',
      );

      if (bins.isNotEmpty) {
        Bin? nearestDefaultBin;
        double nearestDistance = double.infinity;

        for (final bin in bins) {
          final distance = GeohashUtils.distanceBetween(
            _currentLocation!.position,
            bin.location,
          );
          if (distance < nearestDistance) {
            nearestDistance = distance;
            nearestDefaultBin = bin;
          }
        }

        if (nearestDefaultBin != null && nearestDistance <= 5000) {
          final bin = nearestDefaultBin; // Create non-nullable reference

          print(
            '✅ [MAP_SCREEN] Found nearest default bin: ${bin.name} at ${nearestDistance.round()}m',
          );

          double zoom = 16.0;
          if (nearestDistance > 1000) zoom = 14.0;
          if (nearestDistance > 2000) zoom = 13.0;

          _mapController.move(bin.location, zoom);
          _showBinDetails(bin.name, bin.type, bin.fillLevel, bin.location);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Nearest ${bin.type} bin: ${nearestDistance.round()}m away',
              ),
              backgroundColor: _getCategoryColor(bin.type),
              action: SnackBarAction(
                label: 'Navigate',
                textColor: Colors.white,
                onPressed: () => _navigateToLocation(bin.location),
              ),
            ),
          );
        } else {
          print('⚠️ [MAP_SCREEN] No bins found within 5km radius');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No bins found within 5km radius'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else {
        print('⚠️ [MAP_SCREEN] No bins available at all');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No bins available. Scan QR codes to add bin locations.',
            ),
            duration: Duration(seconds: 4),
          ),
        );
      }
    }
  }

  /// Get category color for bin markers
  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'recycle':
        return NeonColors.electricGreen;
      case 'organic':
        return NeonColors.earthOrange;
      case 'ewaste':
        return NeonColors.oceanBlue;
      case 'hazardous':
        return NeonColors.toxicPurple;
      case 'landfill':
      default:
        return Colors.grey;
    }
  }

  /// Get category icon for bin markers
  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'recycle':
        return Icons.recycling;
      case 'organic':
        return Icons.eco;
      case 'ewaste':
        return Icons.electrical_services;
      case 'hazardous':
        return Icons.warning;
      case 'landfill':
      default:
        return Icons.delete;
    }
  }

  /// Format timestamp for display
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

  /// Calculate viewport bounds for marker culling
  Map<String, double> _calculateViewportBounds() {
    final camera = _mapController.camera;
    final bounds = camera.visibleBounds;

    return {
      'north': bounds.north,
      'south': bounds.south,
      'east': bounds.east,
      'west': bounds.west,
    };
  }

  /// Check if a point is within the viewport bounds
  bool _isPointInViewport(LatLng point, Map<String, double> bounds) {
    return point.latitude >= bounds['south']! &&
        point.latitude <= bounds['north']! &&
        point.longitude >= bounds['west']! &&
        point.longitude <= bounds['east']!;
  }

  /// Get maximum markers to show based on zoom level
  int _getMaxMarkersForZoom(double zoom) {
    if (zoom >= 16) return 100;
    if (zoom >= 14) return 50;
    if (zoom >= 12) return 25;
    return 10;
  }

  /// Build simple bin marker for performance at low zoom levels
  Widget _buildSimpleBinMarker(BinLocation bin) {
    return GestureDetector(
      onTap: () => _showEnhancedBinDetails(bin, null),
      child: HolographicMarker(category: bin.category, isSimple: true),
    );
  }

  /// Build simple bin marker from Bin object
  Widget _buildSimpleBinMarkerFromBin(Bin bin) {
    return GestureDetector(
      onTap: () =>
          _showBinDetails(bin.name, bin.type, bin.fillLevel, bin.location),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: _getCategoryColor(bin.type),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 1),
        ),
        child: Icon(_getCategoryIcon(bin.type), color: Colors.white, size: 14),
      ),
    );
  }

  /// Handle map events for performance optimization
  void _onMapEvent(MapEvent event) {
    if (event is MapEventMove || event is MapEventRotate) {
      _currentZoom = event.camera.zoom;

      // Disable user location following when user manually moves map
      if (event.source == MapEventSource.onDrag ||
          event.source == MapEventSource.doubleTap) {
        _followUserLocation = false;
      }

      // Update markers with debouncing for performance
      _createMarkers();
    }
  }

  @override
  void dispose() {
    _markerUpdateTimer?.cancel();
    _pingAnimationController.dispose();
    super.dispose();
  }

  /// Build heat zone marker with gradient colors
  Widget _buildHeatZoneMarker(Hotspot hotspot) {
    final isHighPriority = hotspot.priority.toLowerCase() == 'high priority';
    final colors = isHighPriority
        ? [
            Colors.red.withOpacity(0.7),
            Colors.orange.withOpacity(0.4),
            Colors.yellow.withOpacity(0.2),
          ]
        : [
            Colors.orange.withOpacity(0.6),
            Colors.yellow.withOpacity(0.3),
            Colors.green.withOpacity(0.1),
          ];

    return GestureDetector(
      onTap: () => _showHeatZoneDetails(hotspot),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer heat zone
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: colors,
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
          // Middle heat zone
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [colors[0], colors[1]],
                stops: const [0.0, 1.0],
              ),
            ),
          ),
          // Inner heat zone
          Container(
            width: 25,
            height: 25,
            decoration: BoxDecoration(shape: BoxShape.circle, color: colors[0]),
            child: Icon(Icons.warning, color: Colors.white, size: 16),
          ),
        ],
      ),
    );
  }

  void _showHeatZoneDetails(Hotspot hotspot) {
    final distance = _currentLocation != null
        ? GeohashUtils.distanceBetween(
            _currentLocation!.position,
            hotspot.location,
          )
        : null;

    setState(() {
      _selectedDetailType = DetailType.hotspot;
      _selectedDetailTitle = hotspot.name;
      _selectedDetailData = {
        'Priority': hotspot.priority,
        'Status': 'Active cleanup needed',
        'Distance': distance != null
            ? '${distance.round()}m away'
            : 'Distance unknown',
        'Estimated Items': '15-25 items',
        'Category Mix': 'Mixed waste types',
        'Description':
            'This area needs community attention. Join other eco-warriors to clean up this hotspot!',
      };
      _selectedDetailActions = [
        ActionButton(
          icon: Icons.directions,
          label: 'Navigate',
          onPressed: () => _navigateToLocation(hotspot.location),
          color: Colors.blue,
        ),
        ActionButton(
          icon: Icons.people,
          label: 'Join Cleanup',
          onPressed: _joinCleanup,
          color: NeonColors.toxicPurple,
        ),
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    // Listen to location updates
    ref.listen<AsyncValue<LocationData?>>(locationStreamProvider, (
      previous,
      next,
    ) {
      next.whenData((locationData) {
        if (locationData != null && mounted) {
          setState(() {
            _currentLocation = locationData;
            _createMarkers();
          });

          // Follow user location if enabled
          if (_followUserLocation) {
            _mapController.move(
              locationData.position,
              _mapController.camera.zoom,
            );
          }
        }
      });
    });

    // Listen to bin location updates for real-time map updates
    ref.listen<AsyncValue<List<BinLocation>>>(binLocationsStreamProvider, (
      previous,
      next,
    ) {
      next.whenData((bins) {
        if (mounted) {
          setState(() {
            _localBins = bins;
            _createMarkers();
          });
          print(
            '🗺️ [MAP_SCREEN] Updated map with ${bins.length} bin locations',
          );
        }
      });
    });

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _initialCenter,
              initialZoom: _initialZoom,
              maxZoom: 18.0,
              minZoom: 3.0,
              onMapEvent: _onMapEvent,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.vibesweep',
                tileBuilder: (context, tileWidget, tile) {
                  return ColorFiltered(
                    colorFilter: const ColorFilter.matrix([
                      0.2,
                      0.2,
                      0.2,
                      0,
                      0,
                      0.2,
                      0.2,
                      0.2,
                      0,
                      0,
                      0.2,
                      0.2,
                      0.2,
                      0,
                      0,
                      0,
                      0,
                      0,
                      1,
                      0,
                    ]),
                    child: tileWidget,
                  );
                },
              ),
              if (_currentLocation != null)
                AnimatedBuilder(
                  animation: _pingAnimationController,
                  builder: (context, child) {
                    return PingAnimation(
                      center: _currentLocation!.position,
                      controller: _pingAnimationController,
                    );
                  },
                ),
              MarkerLayer(markers: _markers),
            ],
          ),
          // Left column - Map actions
          Positioned(
            top: 60,
            left: 16,
            child: SafeArea(
              child: MapControlColumn(
                items: [
                  MapControlItem(
                    icon: Icons.navigation,
                    color: const Color(0xFFFFD700), // Bright gold
                    onTap: _testNavigation,
                    tooltip: 'Test Navigation',
                  ),
                  MapControlItem(
                    icon: Icons.add_location,
                    color: const Color(0xFFFF6B6B), // Bright red
                    onTap: _addTestBin,
                    tooltip: 'Add Test Bin',
                  ),
                  MapControlItem(
                    icon: Icons.near_me,
                    color: const Color(0xFF4ECDC4), // Bright teal
                    onTap: _showNearestBin,
                    tooltip: 'Nearest Bin',
                  ),
                  MapControlItem(
                    icon: Icons.my_location,
                    color: const Color(0xFF45B7D1), // Bright blue
                    onTap: _goToCurrentLocation,
                    tooltip: 'My Location',
                  ),
                ],
              ),
            ),
          ),
          // Right column - Layer toggles
          Positioned(
            top: 60,
            right: 16,
            child: SafeArea(
              child: IgnorePointer(
                ignoring: _isModalOpen,
                child: MapControlColumn(
                  items: [
                    MapControlItem(
                      icon: Icons.delete_outline,
                      color: const Color(0xFF00FF7F), // Bright green
                      onTap: () => _toggleLayer('bins'),
                      tooltip: 'Toggle Bins',
                      isActive: _showBins,
                      count:
                          MapDataService.getBins().length + _localBins.length,
                    ),
                    MapControlItem(
                      icon: Icons.whatshot,
                      color: const Color(0xFFFF4500), // Bright orange-red
                      onTap: () => _toggleLayer('hotspots'),
                      tooltip: 'Toggle Hotspots',
                      isActive: _showHotspots,
                      count: MapDataService.getHotspots().length,
                    ),
                    MapControlItem(
                      icon: Icons.flag,
                      color: const Color(0xFF1E90FF), // Bright blue
                      onTap: () => _toggleLayer('missions'),
                      tooltip: 'Toggle Missions',
                      isActive: _showMissions,
                      count: MapDataService.getMissions().length,
                    ),
                    MapControlItem(
                      icon: Icons.people,
                      color: const Color(0xFFFF8C00), // Bright orange
                      onTap: () => _toggleLayer('friends'),
                      tooltip: 'Toggle Friends',
                      isActive: _showFriends,
                      count: MapDataService.getFriends().length,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_selectedDetailType != null)
            Positioned(
              top:
                  MediaQuery.of(context).size.height *
                  0.3, // Center vertically (40% from top)
              left: 16,
              right: 16,
              child: DetailCard(
                type: _selectedDetailType!,
                title: _selectedDetailTitle!,
                details: _selectedDetailData!,
                actions: _selectedDetailActions!,
                onClose: () => setState(() => _selectedDetailType = null),
              ),
            ),
        ],
      ),
    );
  }
}
