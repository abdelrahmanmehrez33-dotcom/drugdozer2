import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class Pharmacy {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String? phoneNumber;
  final double? rating;
  final bool? isOpenNow;
  final String? photoReference;
  final double distanceInKm;

  Pharmacy({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.phoneNumber,
    this.rating,
    this.isOpenNow,
    this.photoReference,
    required this.distanceInKm,
  });

  factory Pharmacy.fromJson(Map<String, dynamic> json, Position userPosition) {
    final location = json['geometry']['location'];
    final lat = location['lat'] as double;
    final lng = location['lng'] as double;
    
    // Calculate distance
    final distanceInMeters = Geolocator.distanceBetween(
      userPosition.latitude,
      userPosition.longitude,
      lat,
      lng,
    );
    
    return Pharmacy(
      id: json['place_id'] ?? '',
      name: json['name'] ?? 'Unknown Pharmacy',
      address: json['vicinity'] ?? json['formatted_address'] ?? 'No address',
      latitude: lat,
      longitude: lng,
      phoneNumber: json['formatted_phone_number'],
      rating: json['rating']?.toDouble(),
      isOpenNow: json['opening_hours']?['open_now'],
      photoReference: json['photos']?[0]?['photo_reference'],
      distanceInKm: distanceInMeters / 1000,
    );
  }
}

class PharmacyService {
  static const String _apiKey = 'AIzaSyA-yx6UwxmhVkKlxJvyINZhO1lL1AWydnU';
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/place';

  // Get current user location
  Future<Position> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied');
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  // Search for nearby pharmacies using Google Places API
  Future<List<Pharmacy>> getNearbyPharmacies({
    Position? userPosition,
    int radiusInMeters = 5000,
  }) async {
    try {
      // Get user position if not provided
      final position = userPosition ?? await getCurrentLocation();

      // Make API request to Google Places
      final url = Uri.parse(
        '$_baseUrl/nearbysearch/json'
        '?location=${position.latitude},${position.longitude}'
        '&radius=$radiusInMeters'
        '&type=pharmacy'
        '&key=$_apiKey'
        '&language=ar',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK') {
          final results = data['results'] as List;
          
          List<Pharmacy> pharmacies = results.map((place) {
            return Pharmacy.fromJson(place, position);
          }).toList();

          // Sort by distance
          pharmacies.sort((a, b) => a.distanceInKm.compareTo(b.distanceInKm));

          // Get phone numbers for each pharmacy (details request)
          for (int i = 0; i < pharmacies.length && i < 20; i++) {
            final details = await getPharmacyDetails(pharmacies[i].id);
            if (details != null) {
              pharmacies[i] = Pharmacy(
                id: pharmacies[i].id,
                name: pharmacies[i].name,
                address: details['formatted_address'] ?? pharmacies[i].address,
                latitude: pharmacies[i].latitude,
                longitude: pharmacies[i].longitude,
                phoneNumber: details['formatted_phone_number'] ?? details['international_phone_number'],
                rating: pharmacies[i].rating,
                isOpenNow: details['opening_hours']?['open_now'] ?? pharmacies[i].isOpenNow,
                photoReference: pharmacies[i].photoReference,
                distanceInKm: pharmacies[i].distanceInKm,
              );
            }
          }

          return pharmacies;
        } else if (data['status'] == 'ZERO_RESULTS') {
          return [];
        } else {
          throw Exception('API Error: ${data['status']}');
        }
      } else {
        throw Exception('HTTP Error: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Get detailed information about a specific pharmacy
  Future<Map<String, dynamic>?> getPharmacyDetails(String placeId) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/details/json'
        '?place_id=$placeId'
        '&fields=formatted_phone_number,international_phone_number,formatted_address,opening_hours,website'
        '&key=$_apiKey'
        '&language=ar',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          return data['result'];
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Get photo URL for a pharmacy
  String getPhotoUrl(String photoReference, {int maxWidth = 400}) {
    return '$_baseUrl/photo?maxwidth=$maxWidth&photo_reference=$photoReference&key=$_apiKey';
  }
}
