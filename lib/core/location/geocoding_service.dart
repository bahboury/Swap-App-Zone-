// lib/core/location/geocoding_service.dart

import 'package:dartz/dartz.dart';
import 'package:geocoding/geocoding.dart' as geo_coding;
import 'package:swap_app/core/error/exceptions.dart';
import 'package:swap_app/core/error/failurs.dart';
import 'package:swap_app/core/location/location_service.dart'; // To use the LatLng entity

abstract class GeocodingService {
  Future<Either<Failure, String>> getAddressFromLatLng(
    LatLng latLng,
    double longitude,
  );
  Future<Either<Failure, LatLng>> getLatLngFromAddress(String address);
}

class GeocodingServiceImpl implements GeocodingService {
  @override
  Future<Either<Failure, String>> getAddressFromLatLng(
    LatLng latLng,
    double longitude,
  ) async {
    try {
      List<geo_coding.Placemark> placemarks = await geo_coding
          .placemarkFromCoordinates(latLng.latitude, latLng.longitude);
      if (placemarks.isEmpty) {
        return Left(
          LocationFetchFailure(
            message: 'No address found for these coordinates.',
          ),
        );
      }
      // You can customize how you want to format the address
      geo_coding.Placemark place = placemarks.first;
      String address =
          '${place.street}, ${place.subLocality}, ${place.locality}, ${place.administrativeArea}, ${place.country}';
      return Right(address);
    } on LocationException catch (e) {
      return Left(
        LocationFetchFailure(message: e.message ?? 'Unknown geocoding error.'),
      );
    } catch (e) {
      return Left(
        LocationFetchFailure(message: 'Failed to get address: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, LatLng>> getLatLngFromAddress(String address) async {
    try {
      List<geo_coding.Location> locations = await geo_coding
          .locationFromAddress(address);
      if (locations.isEmpty) {
        return Left(
          LocationFetchFailure(
            message: 'No coordinates found for this address.',
          ),
        );
      }
      geo_coding.Location location = locations.first;
      return Right(
        LatLng(latitude: location.latitude, longitude: location.longitude),
      );
    } on LocationException catch (e) {
      return Left(
        LocationFetchFailure(message: e.message ?? 'Unknown geocoding error.'),
      );
    } catch (e) {
      return Left(
        LocationFetchFailure(
          message: 'Failed to get coordinates: ${e.toString()}',
        ),
      );
    }
  }
}
