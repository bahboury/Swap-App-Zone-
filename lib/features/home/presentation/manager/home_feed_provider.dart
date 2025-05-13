// lib/features/home/presentation/managers/home_feed_provider.dart

import 'package:flutter/material.dart'; // For ChangeNotifier, @required
import 'package:swap_app/core/error/failurs.dart';
import 'package:swap_app/core/location/location_service.dart'; // For LatLng
import 'package:swap_app/features/auth/domain/repo/auth_repository.dart';
import 'package:swap_app/features/home/domain/entities/post_entity.dart';
import 'package:swap_app/features/home/domain/usecases/get_nearby_posts_usecase.dart';
import 'package:swap_app/core/location/geocoding_service.dart'; // For getting address from LatLng

enum HomeFeedStatus {
  initial,
  loading,
  loaded,
  error,
  locationLoading,
  locationUnavailable,
  empty, // No posts found in the area
}

class HomeFeedProvider extends ChangeNotifier {
  final GetNearbyPostsUseCase _getNearbyPostsUseCase;
  final LocationService _locationService;
  final GeocodingService _geocodingService;
  // If you need the current user's ID for some logic

  HomeFeedStatus _status = HomeFeedStatus.initial;
  List<PostEntity> _posts = [];
  String? _errorMessage;
  LatLng? _currentLocation;
  String? _currentAddress;
  double _searchRadiusKm = 10.0; // Default search radius

  HomeFeedProvider({
    required GetNearbyPostsUseCase getNearbyPostsUseCase,
    required LocationService locationService,
    required GeocodingService geocodingService,
    required AuthRepository authRepository,
  }) : _getNearbyPostsUseCase = getNearbyPostsUseCase,
       _locationService = locationService,
       _geocodingService = geocodingService;

  HomeFeedStatus get status => _status;
  List<PostEntity> get posts => _posts;
  String? get errorMessage => _errorMessage;
  LatLng? get currentLocation => _currentLocation;
  String? get currentAddress => _currentAddress;
  double get searchRadiusKm => _searchRadiusKm;

  set searchRadiusKm(double value) {
    _searchRadiusKm = value;
    notifyListeners();
    fetchNearbyPosts(); // Refetch posts when radius changes
  }

  Future<void> initializeFeed() async {
    if (_status == HomeFeedStatus.initial) {
      await _getCurrentLocationAndFetchPosts();
    }
  }

  Future<void> _getCurrentLocationAndFetchPosts() async {
    _status = HomeFeedStatus.locationLoading;
    _errorMessage = null;
    notifyListeners();

    final locationResult = await _locationService.getCurrentLocation();
    await locationResult.fold(
      (failure) async {
        _status = HomeFeedStatus.locationUnavailable;
        _errorMessage = _mapFailureToMessage(failure);
        _currentLocation = null;
        _currentAddress = null;
      },
      (latLng) async {
        _currentLocation = latLng;
        final addressResult = await _geocodingService.getAddressFromLatLng(
          latLng,
          latLng.longitude,
        );
        addressResult.fold(
          (failure) => _currentAddress = 'Address not found',
          (address) => _currentAddress = address,
        );
        await fetchNearbyPosts(); // Fetch posts once location is available
      },
    );
    notifyListeners();
  }

  Future<void> fetchNearbyPosts() async {
    if (_currentLocation == null &&
        _status != HomeFeedStatus.locationUnavailable) {
      // If location isn't set and we're not already showing unavailable, try to get it
      await _getCurrentLocationAndFetchPosts();
      if (_currentLocation == null) return; // If still null after attempt, stop
    }

    if (_currentLocation == null &&
        _status == HomeFeedStatus.locationUnavailable) {
      // Don't proceed if location is permanently unavailable
      return;
    }

    _status = HomeFeedStatus.loading;
    _errorMessage = null;
    _posts = []; // Clear previous posts
    notifyListeners();

    final params = GetNearbyPostsParams(
      centerLocation: _currentLocation!,
      radiusKm: _searchRadiusKm,
    );
    final result = await _getNearbyPostsUseCase(params);

    result.fold(
      (failure) {
        _status = HomeFeedStatus.error;
        _errorMessage = _mapFailureToMessage(failure);
      },
      (posts) {
        _posts = posts;
        _status = posts.isEmpty ? HomeFeedStatus.empty : HomeFeedStatus.loaded;
      },
    );
    notifyListeners();
  }

  Future<void> refreshFeed() async {
    await _getCurrentLocationAndFetchPosts(); // Re-attempt getting location and then posts
  }

  // Helper function to map failures to user-friendly messages
  String _mapFailureToMessage(Failure failure) {
    if (failure is ServerFailure) {
      return failure.message;
    } else if (failure is NetworkFailure) {
      return 'No internet connection. Please check your network settings.';
    } else if (failure is LocationPermissionDeniedFailure) {
      return 'Location permission denied. Please enable location permissions in app settings.';
    } else if (failure is LocationServiceDisabledFailure) {
      return 'Location services are disabled. Please enable location services on your device.';
    } else if (failure is LocationFetchFailure) {
      return failure.message;
    } else {
      return 'An unexpected error occurred. Please try again.';
    }
  }
}
