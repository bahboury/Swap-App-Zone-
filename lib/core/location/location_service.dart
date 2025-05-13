// lib/core/location/location_service.dart

import 'package:dartz/dartz.dart';
import 'package:geolocator/geolocator.dart';
import 'package:swap_app/core/error/exceptions.dart'; // Import the exceptions you defined
import 'package:swap_app/core/error/failurs.dart'; // Import the failures you defined

// Represents a geographical point
class LatLng {
  final double latitude;
  final double longitude;

  const LatLng({required this.latitude, required this.longitude});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LatLng &&
          runtimeType == other.runtimeType &&
          latitude == other.latitude &&
          longitude == other.longitude;

  @override
  int get hashCode => latitude.hashCode ^ longitude.hashCode;
}

abstract class LocationService {
  Future<Either<Failure, LatLng>> getCurrentLocation();
  Future<Either<Failure, bool>> requestPermission();
  Future<Either<Failure, bool>> checkPermission();
  Future<Either<Failure, bool>> isLocationServiceEnabled();
}

class LocationServiceImpl implements LocationService {
  @override
  Future<Either<Failure, LatLng>> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Location services are not enabled don't continue
        // accessing the position and request users to enable the services.
        throw LocationException(message: 'Location services are disabled.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          // Permissions are denied, next time you could ask for permissions again
          throw LocationException(message: 'Location permissions are denied.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        // Permissions are denied forever, handle appropriately.
        throw LocationException(
          message:
              'Location permissions are permanently denied, we cannot request permissions.',
        );
      }

      // When we reach here, permissions are granted and we can
      // continue accessing the position of the device.
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      return Right(
        LatLng(latitude: position.latitude, longitude: position.longitude),
      );
    } on LocationException catch (e) {
      return Left(
        LocationFetchFailure(message: e.message ?? 'Unknown location error.'),
      );
    } catch (e) {
      return Left(
        LocationFetchFailure(
          message: 'Failed to get location: ${e.toString()}',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, bool>> requestPermission() async {
    try {
      LocationPermission permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return Left(LocationPermissionDeniedFailure());
      }
      return const Right(true);
    } catch (e) {
      return Left(LocationPermissionDeniedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> checkPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return const Right(false);
      }
      return const Right(true);
    } catch (e) {
      return Left(LocationPermissionDeniedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> isLocationServiceEnabled() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      return Right(serviceEnabled);
    } catch (e) {
      return Left(LocationServiceDisabledFailure(message: e.toString()));
    }
  }
}
