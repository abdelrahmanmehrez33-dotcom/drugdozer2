/// Pharmacy entity representing a nearby pharmacy
class Pharmacy {
  final String id;
  final String name;
  final String nameAr;
  final String address;
  final double latitude;
  final double longitude;
  final double distance; // in km
  final String? phoneNumber;
  final String? website;
  final double? rating;
  final int? totalRatings;
  final bool? isOpen;
  final List<String>? openingHours;
  final String? photoReference;
  final String? placeId;

  const Pharmacy({
    required this.id,
    required this.name,
    required this.nameAr,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.distance,
    this.phoneNumber,
    this.website,
    this.rating,
    this.totalRatings,
    this.isOpen,
    this.openingHours,
    this.photoReference,
    this.placeId,
  });

  /// Get formatted distance string
  String get formattedDistance {
    if (distance < 1) {
      return '${(distance * 1000).round()} م';
    }
    return '${distance.toStringAsFixed(1)} كم';
  }

  /// Get formatted distance string in English
  String get formattedDistanceEn {
    if (distance < 1) {
      return '${(distance * 1000).round()} m';
    }
    return '${distance.toStringAsFixed(1)} km';
  }

  /// Get open/closed status text
  String getStatusText(bool isEnglish) {
    if (isOpen == null) {
      return isEnglish ? 'Hours unknown' : 'ساعات العمل غير معروفة';
    }
    return isOpen! 
        ? (isEnglish ? 'Open now' : 'مفتوح الآن')
        : (isEnglish ? 'Closed' : 'مغلق');
  }

  /// Check if phone number is available
  bool get hasPhoneNumber => phoneNumber != null && phoneNumber!.isNotEmpty;

  /// Get rating stars (1-5)
  int get ratingStars => rating != null ? rating!.round().clamp(1, 5) : 0;

  /// Copy with method for immutability
  Pharmacy copyWith({
    String? id,
    String? name,
    String? nameAr,
    String? address,
    double? latitude,
    double? longitude,
    double? distance,
    String? phoneNumber,
    String? website,
    double? rating,
    int? totalRatings,
    bool? isOpen,
    List<String>? openingHours,
    String? photoReference,
    String? placeId,
  }) {
    return Pharmacy(
      id: id ?? this.id,
      name: name ?? this.name,
      nameAr: nameAr ?? this.nameAr,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      distance: distance ?? this.distance,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      website: website ?? this.website,
      rating: rating ?? this.rating,
      totalRatings: totalRatings ?? this.totalRatings,
      isOpen: isOpen ?? this.isOpen,
      openingHours: openingHours ?? this.openingHours,
      photoReference: photoReference ?? this.photoReference,
      placeId: placeId ?? this.placeId,
    );
  }

  @override
  String toString() {
    return 'Pharmacy(name: $name, distance: $formattedDistance, isOpen: $isOpen, phone: $phoneNumber)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Pharmacy && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
