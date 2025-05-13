// lib/features/home/domain/usecases/get_nearby_posts_usecase.dart

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:swap_app/core/error/failurs.dart';
import 'package:swap_app/core/location/location_service.dart'; // For LatLng
import 'package:swap_app/core/usecases/usecase.dart';
import 'package:swap_app/features/home/domain/entities/post_entity.dart';
import 'package:swap_app/features/home/domain/repo/post_repository.dart';

class GetNearbyPostsUseCase
    implements UseCase<List<PostEntity>, GetNearbyPostsParams> {
  final PostRepository repository;

  GetNearbyPostsUseCase(this.repository);

  @override
  Future<Either<Failure, List<PostEntity>>> call(
    GetNearbyPostsParams params,
  ) async {
    return await repository.getNearbyPosts(
      centerLocation: params.centerLocation,
      radiusKm: params.radiusKm,
    );
  }
}

class GetNearbyPostsParams extends Equatable {
  final LatLng centerLocation;
  final double radiusKm;

  const GetNearbyPostsParams({
    required this.centerLocation,
    required this.radiusKm,
  });

  @override
  List<Object?> get props => [centerLocation, radiusKm];
}
