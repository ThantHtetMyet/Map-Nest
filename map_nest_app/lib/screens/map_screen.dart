import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../providers/post_provider.dart';
import '../providers/theme_provider.dart';
import '../models/post_model.dart';
import '../services/location_service.dart';
import '../widgets/post_marker.dart';
import '../widgets/current_location_marker.dart';
import '../widgets/glass_card.dart';
import 'create_post_screen.dart';
import 'post_detail_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final LocationService _locationService = LocationService();
  Position? _currentPosition;
  bool _isLoadingLocation = true;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    final position = await _locationService.getCurrentLocation();
    
    if (position != null) {
      setState(() {
        _currentPosition = position;
        _isLoadingLocation = false;
      });
      
      // Move map to current location
      _mapController.move(
        LatLng(position.latitude, position.longitude),
        15.0,
      );
    } else {
      setState(() {
        _isLoadingLocation = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permission denied. Please enable location services.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Consumer<PostProvider>(
        builder: (context, postProvider, child) {
          // Debug: Print posts count
          debugPrint('🗺️ MapScreen: Posts count: ${postProvider.posts.length}');
          if (postProvider.posts.isNotEmpty) {
            debugPrint('🗺️ First post location: ${postProvider.posts.first.latitude}, ${postProvider.posts.first.longitude}');
          }
          if (postProvider.lastError != null) {
            debugPrint('🗺️ Error: ${postProvider.lastError}');
          }
          
          return Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _currentPosition != null
                      ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
                      : const LatLng(16.8661, 96.1951), // Default to Yangon, Myanmar
                  initialZoom: _currentPosition != null ? 15.0 : 10.0,
                  onLongPress: (tapPosition, point) {
                    _showLocationOptions(context, point);
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate: isDark
                        ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
                        : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    subdomains: isDark ? const ['a', 'b', 'c', 'd'] : const [],
                    userAgentPackageName: 'com.mapnest.app',
                  ),
                  MarkerLayer(
                    markers: [
                      // Current location marker
                      if (_currentPosition != null)
                        Marker(
                          point: LatLng(
                            _currentPosition!.latitude,
                            _currentPosition!.longitude,
                          ),
                          width: 40,
                          height: 40,
                          child: const CurrentLocationMarker(),
                        ),
                      // Post markers
                      ...postProvider.posts.map((post) {
                        debugPrint('Creating marker for post ${post.id} at ${post.latitude}, ${post.longitude}');
                        return Marker(
                          point: LatLng(post.latitude, post.longitude),
                          width: 40,
                          height: 40,
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PostDetailScreen(post: post),
                                ),
                              );
                            },
                            child: PostMarker(
                              propertyType: post.propertyType,
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ],
              ),
              if (_isLoadingLocation)
                const Center(
                  child: CircularProgressIndicator(),
                ),
              // Refresh location button
              Positioned(
                top: 50,
                right: 16,
                child: Column(
                  children: [
                    GlassCard(
                      padding: EdgeInsets.zero,
                      borderRadius: 12,
                      child: IconButton(
                        onPressed: _getCurrentLocation,
                        icon: Icon(
                          Icons.my_location,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Show all posts button
                    if (postProvider.posts.isNotEmpty)
                      GlassCard(
                        padding: EdgeInsets.zero,
                        borderRadius: 12,
                        child: IconButton(
                          onPressed: () {
                            if (postProvider.posts.isNotEmpty) {
                              // Calculate bounds to show all posts
                              double minLat = postProvider.posts.first.latitude;
                              double maxLat = postProvider.posts.first.latitude;
                              double minLng = postProvider.posts.first.longitude;
                              double maxLng = postProvider.posts.first.longitude;
                              
                              for (var post in postProvider.posts) {
                                if (post.latitude < minLat) minLat = post.latitude;
                                if (post.latitude > maxLat) maxLat = post.latitude;
                                if (post.longitude < minLng) minLng = post.longitude;
                                if (post.longitude > maxLng) maxLng = post.longitude;
                              }
                              
                              // Center on all posts
                              final centerLat = (minLat + maxLat) / 2;
                              final centerLng = (minLng + maxLng) / 2;
                              
                              _mapController.move(
                                LatLng(centerLat, centerLng),
                                12.0,
                              );
                            }
                          },
                          icon: Icon(
                            Icons.map,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Theme toggle button at top right corner
              Positioned(
                top: 50,
                left: 16,
                child: GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  borderRadius: 25,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.light_mode,
                        color: isDark ? Colors.grey[400] : Colors.amber[700],
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Switch(
                        value: isDark,
                        onChanged: (value) {
                          themeProvider.setTheme(value);
                        },
                        activeColor: Colors.white,
                        activeTrackColor: Colors.grey[700],
                        inactiveThumbColor: Colors.white,
                        inactiveTrackColor: Colors.grey[400],
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.dark_mode,
                        color: isDark ? Colors.indigo[300] : Colors.grey[600],
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: GlassCard(
        padding: EdgeInsets.zero,
        borderRadius: 30,
        child: FloatingActionButton.extended(
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CreatePostScreen(
                  initialLocation: _currentPosition != null
                      ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
                      : null,
                ),
              ),
            );
            
            if (result == true) {
              // Post created successfully - refresh posts
              final postProvider = Provider.of<PostProvider>(context, listen: false);
              await postProvider.refreshPosts();
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Post created successfully!'),
                  backgroundColor: Colors.green.withOpacity(0.9),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            }
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          label: Text(
            'Create Post',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          icon: Icon(
            Icons.add,
            color: isDark ? Colors.white : Colors.black87,
            size: 24,
          ),
        ),
      ),
    );
  }

  void _showLocationOptions(BuildContext context, LatLng point) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add_location),
              title: const Text('Create post at this location'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CreatePostScreen(
                      initialLocation: point,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

