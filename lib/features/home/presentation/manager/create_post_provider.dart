// lib/features/home/presentation/managers/create_post_provider.dart

import 'dart:io'; // For File
import 'package:flutter/foundation.dart'; // For ChangeNotifier
import 'package:image_picker/image_picker.dart';
import 'package:swap_app/core/error/failurs.dart';
import 'package:swap_app/core/location/location_service.dart'; // For LocationService
import 'package:swap_app/core/location/geocoding_service.dart'; // For GeocodingService
import 'package:swap_app/features/auth/domain/repo/auth_repository.dart'; // To get the current user ID
import 'package:swap_app/features/home/domain/entities/post_entity.dart';
import 'package:swap_app/features/home/domain/usecases/create_post_usecase.dart'; // For CreatePostUseCase and CreatePostParams
// CORRECTED: Import LatLng from geolocator (assuming)

enum CreatePostStatus {
  initial,
  loadingLocation,
  locationLoaded,
  locationError,
  pickingImage,
  imagePicked,
  saving,
  success,
  error,
}

enum LocationStatus {
  initial,
  loading,
  loaded,
  error,
  permissionDenied,
  serviceDisabled,
}

class CreatePostProvider extends ChangeNotifier {
  final CreatePostUseCase _createPostUseCase;
  final LocationService _locationService;
  final GeocodingService _geocodingService;
  final AuthRepository _authRepository; // To get the current user ID
  final ImagePicker _imagePicker; // For picking images

  CreatePostStatus _status = CreatePostStatus.initial;
  final List<File> _selectedImages = [];
  String? _errorMessage;
  LatLng? _currentLocation;
  String? _currentAddress;
  LocationStatus _currentLocationStatus = LocationStatus.initial;
  String? _locationErrorMessage;

  CreatePostProvider({
    required CreatePostUseCase createPostUseCase,
    required LocationService locationService,
    required GeocodingService geocodingService,
    required AuthRepository authRepository,
  }) : _createPostUseCase = createPostUseCase,
       _locationService = locationService,
       _geocodingService = geocodingService,
       _authRepository = authRepository,
       _imagePicker = ImagePicker() {
    // Fetch location immediately when the provider is created
    _fetchCurrentLocation();
  }

  CreatePostStatus get status => _status;
  List<File> get selectedImages => _selectedImages;
  String? get errorMessage => _errorMessage;
  LatLng? get currentLocation => _currentLocation;
  String? get currentAddress => _currentAddress;
  LocationStatus get currentLocationStatus => _currentLocationStatus;
  String? get locationErrorMessage => _locationErrorMessage;

  void resetStatus() {
    _status = CreatePostStatus.initial;
    _errorMessage = null;
    // Keep selected images and location data unless explicitly cleared
    notifyListeners();
  }

  // Method to clear selected images
  void clearSelectedImages() {
    _selectedImages.clear();
    notifyListeners();
  }

  Future<void> _fetchCurrentLocation() async {
    _currentLocationStatus = LocationStatus.loading;
    _locationErrorMessage = null;
    notifyListeners();

    final locationResult = await _locationService.getCurrentLocation();
    await locationResult.fold(
      (failure) async {
        _currentLocation = null;
        _currentAddress = null;
        _currentLocationStatus = LocationStatus.error; // Default to error
        _locationErrorMessage = _mapFailureToMessage(failure);

        if (failure is LocationPermissionDeniedFailure) {
          _currentLocationStatus = LocationStatus.permissionDenied;
        } else if (failure is LocationServiceDisabledFailure) {
          _currentLocationStatus = LocationStatus.serviceDisabled;
        }
      },
      (latLng) async {
        _currentLocation = latLng;
        // Pass both latitude and longitude as required by the method signature
        final addressResult = await _geocodingService.getAddressFromLatLng(
          latLng, // LatLng object
          latLng.longitude, // double
        );
        addressResult.fold((failure) {
          _currentAddress = 'Address not found';
          _locationErrorMessage = _mapFailureToMessage(failure);
        }, (address) => _currentAddress = address);
        _currentLocationStatus = LocationStatus.loaded;
      },
    );
    notifyListeners();
  }

  Future<void> pickImage(ImageSource source) async {
    _status = CreatePostStatus.pickingImage;
    _errorMessage = null;
    notifyListeners();

    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 80, // Adjust imageQuality as needed
      );

      if (pickedFile != null) {
        _selectedImages.add(File(pickedFile.path));
        _status =
            CreatePostStatus.imagePicked; // Status indicates image was picked
      } else {
        // User cancelled picking, reset status if it was pickingImage
        if (_status == CreatePostStatus.pickingImage) {
          _status = CreatePostStatus.initial;
        }
      }
    } catch (e) {
      _status = CreatePostStatus.error;
      _errorMessage = 'Failed to pick image: ${e.toString()}';
    } finally {
      notifyListeners();
    }
  }

  void removeImage(int index) {
    if (index >= 0 && index < _selectedImages.length) {
      _selectedImages.removeAt(index);
      // Optionally update status if the last image was removed
      if (_selectedImages.isEmpty && _status == CreatePostStatus.imagePicked) {
        _status = CreatePostStatus.initial;
      }
      notifyListeners();
    }
  }

  Future<void> createPost({
    required String title,
    required String description,
    String? manualLocation, // new: manual location from user input
    String? swapMethod, // new: swap method from dropdown
    String? exchange, // new: what user wants in exchange
  }) async {
    _status = CreatePostStatus.saving;
    _errorMessage = null;
    notifyListeners();

    // Use manual location if provided, otherwise use detected location
    String? addressToSave =
        manualLocation?.isNotEmpty == true ? manualLocation : _currentAddress;

    // Ensure location/address is available
    if ((_currentLocation == null &&
            (manualLocation == null || manualLocation.isEmpty)) ||
        addressToSave == null) {
      _status = CreatePostStatus.error;
      _errorMessage = 'Location is not available. Cannot create post.';
      notifyListeners();
      return;
    }

    // Ensure user is authenticated and get their ID
    final currentUserResult = await _authRepository.getCurrentUser();
    String? userId;
    bool authError = false;
    currentUserResult.fold(
      (failure) {
        authError = true;
        _status = CreatePostStatus.error;
        _errorMessage = 'User not authenticated. Cannot create post.';
      },
      (user) {
        if (user.isEmpty) {
          authError = true;
          _status = CreatePostStatus.error;
          _errorMessage = 'User not authenticated. Cannot create post.';
        } else {
          userId = user.uid;
        }
      },
    );

    if (authError || userId == null) {
      notifyListeners();
      return;
    }

    try {
      final newPost = PostEntity(
        id: '',
        userId: userId!,
        title: title,
        description: description,
        imageUrls: [],
        location:
            _currentLocation ??
            LatLng(
              latitude: 0,
              longitude: 0,
            ), // Provide a default LatLng if null
        address: addressToSave,
        createdAt: DateTime.now(),
        // swapMethod and exchange removed; ensure PostEntity supports these if needed
      );

      final params = CreatePostParams(post: newPost, images: _selectedImages);

      final result = await _createPostUseCase(params);

      result.fold(
        (failure) {
          _status = CreatePostStatus.error;
          _errorMessage = _mapFailureToMessage(failure);
        },
        (post) {
          _status = CreatePostStatus.success;
          clearSelectedImages();
        },
      );
    } catch (e) {
      _status = CreatePostStatus.error;
      _errorMessage =
          'An unexpected error occurred during post creation: ${e.toString()}';
    }
    notifyListeners();
  }

  // Helper function to map failures to user-friendly messages
  String _mapFailureToMessage(Failure failure) {
    if (failure is ServerFailure) {
      // Assuming ServerFailure has a message property
      return failure.message;
    } else if (failure is NetworkFailure) {
      return 'No internet connection. Please check your network settings.';
    } else if (failure is LocationPermissionDeniedFailure) {
      return 'Location permission denied. Please enable location permissions in app settings.';
    } else if (failure is LocationServiceDisabledFailure) {
      return 'Location services are disabled. Please enable location services on your device.';
    } else if (failure is LocationFetchFailure) {
      // Assuming LocationFetchFailure has a message property
      return failure.message;
    } else if (failure is UserNotFoundFailure) {
      return 'User not found or not logged in.';
    } else {
      return 'An unexpected error occurred. Please try again.';
    }
  }

  @override
  void dispose() {
    // Dispose controllers if they were managed here (they are in the page widget now)
    super.dispose();
  }
}
