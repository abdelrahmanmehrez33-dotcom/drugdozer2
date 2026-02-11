import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../../services/pharmacy_service.dart';
import '../../core/providers/language_provider.dart';

class NearbyPharmaciesScreen extends StatefulWidget {
  const NearbyPharmaciesScreen({super.key});

  @override
  State<NearbyPharmaciesScreen> createState() => _NearbyPharmaciesScreenState();
}

class _NearbyPharmaciesScreenState extends State<NearbyPharmaciesScreen> {
  final PharmacyService _pharmacyService = PharmacyService();
  GoogleMapController? _mapController;
  List<Pharmacy> _pharmacies = [];
  Set<Marker> _markers = {};
  bool _isLoading = true;
  String? _errorMessage;
  LatLng? _userLocation;
  Pharmacy? _selectedPharmacy;

  @override
  void initState() {
    super.initState();
    _loadPharmacies();
  }

  Future<void> _loadPharmacies() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final position = await _pharmacyService.getCurrentLocation();
      _userLocation = LatLng(position.latitude, position.longitude);

      final pharmacies = await _pharmacyService.getNearbyPharmacies(
        userPosition: position,
        radiusInMeters: 5000,
      );

      setState(() {
        _pharmacies = pharmacies;
        _isLoading = false;
        _createMarkers();
      });

      if (_mapController != null && _userLocation != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(_userLocation!, 14),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  void _createMarkers() {
    Set<Marker> markers = {};

    // User location marker
    if (_userLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('user_location'),
          position: _userLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(title: 'موقعك الحالي'),
        ),
      );
    }

    // Pharmacy markers
    for (var pharmacy in _pharmacies) {
      markers.add(
        Marker(
          markerId: MarkerId(pharmacy.id),
          position: LatLng(pharmacy.latitude, pharmacy.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(
            title: pharmacy.name,
            snippet: pharmacy.address,
          ),
          onTap: () {
            setState(() {
              _selectedPharmacy = pharmacy;
            });
          },
        ),
      );
    }

    setState(() {
      _markers = markers;
    });
  }

  Future<void> _callPharmacy(String phoneNumber) async {
    final uri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openDirections(Pharmacy pharmacy) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${pharmacy.latitude},${pharmacy.longitude}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEnglish = Provider.of<LanguageProvider>(context).isEnglish;
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.primaryColor.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Premium Header
              _buildPremiumHeader(isEnglish, theme),
              
              // Content
              Expanded(
                child: _isLoading
                    ? _buildLoadingState(isEnglish)
                    : _errorMessage != null
                        ? _buildErrorState(isEnglish)
                        : _buildContent(isEnglish, theme),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumHeader(bool isEnglish, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              isEnglish ? Icons.arrow_back : Icons.arrow_forward,
              color: theme.primaryColor,
            ),
            style: IconButton.styleFrom(
              backgroundColor: theme.primaryColor.withOpacity(0.1),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEnglish ? 'Nearby Pharmacies' : 'الصيدليات القريبة',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                Text(
                  isEnglish 
                      ? '${_pharmacies.length} pharmacies found' 
                      : 'تم العثور على ${_pharmacies.length} صيدلية',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _loadPharmacies,
            icon: const Icon(Icons.refresh),
            style: IconButton.styleFrom(
              backgroundColor: theme.primaryColor.withOpacity(0.1),
              foregroundColor: theme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(bool isEnglish) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                ),
              ],
            ),
            child: const CircularProgressIndicator(
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            isEnglish ? 'Finding nearby pharmacies...' : 'جاري البحث عن الصيدليات القريبة...',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(bool isEnglish) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.location_off,
                size: 48,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isEnglish ? 'Unable to find pharmacies' : 'تعذر العثور على الصيدليات',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isEnglish 
                  ? 'Please enable location services and try again'
                  : 'يرجى تفعيل خدمات الموقع والمحاولة مرة أخرى',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadPharmacies,
              icon: const Icon(Icons.refresh),
              label: Text(isEnglish ? 'Try Again' : 'حاول مرة أخرى'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(bool isEnglish, ThemeData theme) {
    return Column(
      children: [
        // Map
        Expanded(
          flex: 2,
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _userLocation ?? const LatLng(24.7136, 46.6753),
                zoom: 14,
              ),
              markers: _markers,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              onMapCreated: (controller) {
                _mapController = controller;
              },
            ),
          ),
        ),

        // Pharmacy List
        Expanded(
          flex: 3,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                
                // List
                Expanded(
                  child: _pharmacies.isEmpty
                      ? Center(
                          child: Text(
                            isEnglish 
                                ? 'No pharmacies found nearby'
                                : 'لا توجد صيدليات قريبة',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _pharmacies.length,
                          itemBuilder: (context, index) {
                            return _buildPharmacyCard(_pharmacies[index], isEnglish, theme);
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPharmacyCard(Pharmacy pharmacy, bool isEnglish, ThemeData theme) {
    final isSelected = _selectedPharmacy?.id == pharmacy.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected ? theme.primaryColor.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? theme.primaryColor : Colors.grey.withOpacity(0.2),
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            setState(() {
              _selectedPharmacy = pharmacy;
            });
            _mapController?.animateCamera(
              CameraUpdate.newLatLng(LatLng(pharmacy.latitude, pharmacy.longitude)),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Pharmacy Icon
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00BFA5).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.local_pharmacy,
                        color: Color(0xFF00BFA5),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Name and Rating
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pharmacy.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A2E),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              if (pharmacy.rating != null) ...[
                                Icon(Icons.star, size: 16, color: Colors.amber[700]),
                                const SizedBox(width: 4),
                                Text(
                                  pharmacy.rating!.toStringAsFixed(1),
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 12),
                              ],
                              Icon(
                                pharmacy.isOpenNow == true ? Icons.check_circle : Icons.access_time,
                                size: 16,
                                color: pharmacy.isOpenNow == true ? Colors.green : Colors.orange,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                pharmacy.isOpenNow == true
                                    ? (isEnglish ? 'Open' : 'مفتوح')
                                    : (isEnglish ? 'Closed' : 'مغلق'),
                                style: TextStyle(
                                  color: pharmacy.isOpenNow == true ? Colors.green : Colors.orange,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Distance
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${pharmacy.distanceInKm.toStringAsFixed(1)} ${isEnglish ? 'km' : 'كم'}',
                        style: TextStyle(
                          color: theme.primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Address
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.grey[500]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        pharmacy.address,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                // Phone number if available
                if (pharmacy.phoneNumber != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.phone, size: 16, color: Colors.grey[500]),
                      const SizedBox(width: 8),
                      Text(
                        pharmacy.phoneNumber!,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 16),

                // Action Buttons
                Row(
                  children: [
                    // Call Button
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: pharmacy.phoneNumber != null
                            ? () => _callPharmacy(pharmacy.phoneNumber!)
                            : null,
                        icon: const Icon(Icons.call, size: 18),
                        label: Text(isEnglish ? 'Call' : 'اتصال'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00BFA5),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Directions Button
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _openDirections(pharmacy),
                        icon: const Icon(Icons.directions, size: 18),
                        label: Text(isEnglish ? 'Directions' : 'الاتجاهات'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: theme.primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(color: theme.primaryColor),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
