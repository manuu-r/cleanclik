import 'package:latlong2/latlong.dart';

class Bin {
  final String name;
  final String type;
  final int fillLevel;
  final LatLng location;

  Bin({
    required this.name,
    required this.type,
    required this.fillLevel,
    required this.location,
  });
}

class Hotspot {
  final String name;
  final String priority;
  final LatLng location;

  Hotspot({required this.name, required this.priority, required this.location});
}

class Mission {
  final String name;
  final String items;
  final String timeLeft;
  final LatLng location;

  Mission({
    required this.name,
    required this.items,
    required this.timeLeft,
    required this.location,
  });
}

class Friend {
  final String username;
  final String level;
  final String status;
  final LatLng location;

  Friend({
    required this.username,
    required this.level,
    required this.status,
    required this.location,
  });
}

class MapDataService {
  static List<Bin> getBins() {
    return [
      Bin(
        name: 'Koramangala Bin',
        type: 'Recycling',
        fillLevel: 85,
        location: LatLng(12.9750, 77.5920),
      ),
      Bin(
        name: 'Indiranagar Bin',
        type: 'Organic',
        fillLevel: 60,
        location: LatLng(12.9680, 77.5850),
      ),
      Bin(
        name: 'Electronic City Bin',
        type: 'E-waste',
        fillLevel: 30,
        location: LatLng(12.9830, 77.6050),
      ),
      Bin(
        name: 'Whitefield Bin',
        type: 'Hazardous',
        fillLevel: 15,
        location: LatLng(12.9620, 77.5990),
      ),
      Bin(
        name: 'MG Road Bin',
        type: 'General',
        fillLevel: 70,
        location: LatLng(12.9780, 77.6080),
      ),
    ];
  }

  static List<Hotspot> getHotspots() {
    return [
      Hotspot(
        name: 'Cubbon Park',
        priority: 'High Priority',
        location: LatLng(12.9650, 77.6100),
      ),
      Hotspot(
        name: 'Lalbagh Botanical Garden',
        priority: 'Medium Priority',
        location: LatLng(12.9550, 77.5870),
      ),
    ];
  }

  static List<Mission> getMissions() {
    return [
      Mission(
        name: 'Ulsoor Lake Cleanup',
        items: '10 items',
        timeLeft: '2 hours left',
        location: LatLng(12.9710, 77.6020),
      ),
    ];
  }

  static List<Friend> getFriends() {
    return [
      Friend(
        username: 'BangaloreGreen',
        level: 'Level 15',
        status: 'Online',
        location: LatLng(12.9800, 77.5930),
      ),
      Friend(
        username: 'SiliconValleyCleanup',
        level: 'Level 12',
        status: 'Recently active',
        location: LatLng(12.9730, 77.5860),
      ),
    ];
  }
}
