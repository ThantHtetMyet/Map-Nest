import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../providers/post_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';
import '../models/post_model.dart';
import '../services/location_service.dart';
import '../widgets/post_marker.dart';
import '../widgets/current_location_marker.dart';
import '../widgets/glass_card.dart';
import 'create_post_screen.dart';
import 'post_detail_screen.dart';
import 'sign_in_screen.dart';

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
            ],
          );
        },
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[900] : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Theme Toggle - Left
              Expanded(
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[800] : Colors.white,
                    border: Border(
                      right: BorderSide(
                        color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                        width: 1,
                      ),
                    ),
                  ),
                  child: IconButton(
                    onPressed: () {
                      themeProvider.setTheme(!isDark);
                    },
                    icon: Icon(
                      isDark ? Icons.dark_mode : Icons.light_mode,
                      size: 20,
                      color: isDark ? Colors.blue.shade300 : Colors.orange,
                    ),
                    tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
                  ),
                ),
              ),
              // Create Post - Second
              Expanded(
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[800] : Colors.white,
                    border: Border(
                      right: BorderSide(
                        color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                        width: 1,
                      ),
                    ),
                  ),
                  child: IconButton(
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
                      
                      if (result == true && mounted) {
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
                    icon: Icon(
                      Icons.add_circle_outline,
                      size: 20,
                      color: isDark ? Colors.white : Colors.grey[800],
                    ),
                    tooltip: 'Create Post',
                  ),
                ),
              ),
              // Language Selection - Third
              Expanded(
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[800] : Colors.white,
                    border: Border(
                      right: BorderSide(
                        color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Consumer<LanguageProvider>(
                    builder: (context, languageProvider, child) {
                      return IconButton(
                        onPressed: () {
                          languageProvider.toggleLanguage();
                        },
                        icon: Text(
                          languageProvider.currentLanguage == 'my' ? '🇲🇲' : '🇬🇧',
                          style: const TextStyle(fontSize: 20),
                        ),
                        tooltip: languageProvider.displayLanguage,
                      );
                    },
                  ),
                ),
              ),
              // Sign Out - Right
              Expanded(
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[800] : Colors.white,
                  ),
                  child: Consumer<AuthProvider>(
                    builder: (context, authProvider, child) {
                      return IconButton(
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) {
                              final themeProvider = Provider.of<ThemeProvider>(context);
                              final isDarkDialog = themeProvider.isDarkMode;
                              return AlertDialog(
                                backgroundColor: isDarkDialog ? Colors.grey[800] : Colors.white,
                                title: Text(
                                  'Sign Out',
                                  style: TextStyle(
                                    color: isDarkDialog ? Colors.white : Colors.grey[900],
                                  ),
                                ),
                                content: Text(
                                  'Are you sure you want to sign out?',
                                  style: TextStyle(
                                    color: isDarkDialog ? Colors.grey[300] : Colors.grey[700],
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: Text(
                                      'Cancel',
                                      style: TextStyle(
                                        color: isDarkDialog ? Colors.grey[400] : Colors.grey[600],
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    child: const Text(
                                      'Sign Out',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              );
                            },
                          );
                          
                          if (confirm == true && mounted) {
                            await authProvider.signOut();
                            if (mounted) {
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(
                                  builder: (context) => const SignInScreen(),
                                ),
                                (route) => false,
                              );
                            }
                          }
                        },
                        icon: Icon(
                          Icons.logout,
                          size: 20,
                          color: isDark ? Colors.white : Colors.grey[800],
                        ),
                        tooltip: 'Sign Out',
                      );
                    },
                  ),
                ),
              ),
            ],
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

