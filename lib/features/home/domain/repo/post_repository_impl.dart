// lib/features/home/data/repositories/post_repository_impl.dart
import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:swap_app/core/error/exceptions.dart';
import 'package:swap_app/core/error/failurs.dart';
import 'package:swap_app/core/location/location_service.dart';
import 'package:swap_app/features/auth/domain/repo/auth_repository.dart';
import 'package:swap_app/features/home/data/models/post_model.dart';
import 'package:swap_app/features/home/data/sources/post_remote_datasource.dart';
import 'package:swap_app/features/home/domain/entities/post_entity.dart';
import 'package:swap_app/features/home/domain/entities/swap_request_entity.dart';
import 'package:swap_app/features/home/domain/repo/post_repository.dart';

class PostRepositoryImpl implements PostRepository {
  final PostRemoteDataSource remoteDataSource;
  final AuthRepository authRepository;

  PostRepositoryImpl({
    required this.remoteDataSource,
    required this.authRepository,
  });

  @override
  Future<Either<Failure, List<PostEntity>>> getNearbyPosts({
    required LatLng centerLocation,
    required double radiusKm,
  }) async {
    try {
      final posts = await remoteDataSource.getNearbyPosts(
        centerLocation: centerLocation,
        radiusKm: radiusKm,
      );
      return Right(posts);
    } on ServerException catch (e) {
      return Left(
        ServerFailure(message: e.message ?? 'Failed to fetch nearby posts.'),
      );
    } catch (e) {
      return Left(ServerFailure(message: 'Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, PostEntity>> createPost({
    required PostEntity post,
    required List<File> images,
  }) async {
    try {
      final postModel = PostModel.fromEntity(post);
      final createdPost = await remoteDataSource.createPost(
        post: postModel,
        images: images,
      );
      return Right(createdPost);
    } on ServerException catch (e) {
      return Left(
        ServerFailure(message: e.message ?? 'Failed to create post.'),
      );
    } catch (e) {
      return Left(ServerFailure(message: 'Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, PostEntity>> getPostDetails(String postId) async {
    try {
      final post = await remoteDataSource.getPostDetails(postId);
      return Right(post);
    } on ServerException catch (e) {
      return Left(
        ServerFailure(message: e.message ?? 'Failed to fetch post details.'),
      );
    } catch (e) {
      return Left(ServerFailure(message: 'Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deletePost(String postId) async {
    try {
      await remoteDataSource.deletePost(postId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(
        ServerFailure(message: e.message ?? 'Failed to delete post.'),
      );
    } catch (e) {
      return Left(ServerFailure(message: 'Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> likePost(String postId, String userId) async {
    try {
      await remoteDataSource.likePost(postId, userId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message ?? 'Failed to like post.'));
    } catch (e) {
      return Left(ServerFailure(message: 'Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> unlikePost(String postId, String userId) async {
    try {
      await remoteDataSource.unlikePost(postId, userId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(
        ServerFailure(message: e.message ?? 'Failed to unlike post.'),
      );
    } catch (e) {
      return Left(ServerFailure(message: 'Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, SwapRequestEntity>> createSwapRequest({
    required String requestingUserId,
    required String requestedPostId,
    required String requestedPostOwnerId,
    String? offeringPostId,
  }) async {
    try {
      final request = await remoteDataSource.createSwapRequest(
        requestingUserId: requestingUserId,
        requestedPostId: requestedPostId,
        requestedPostOwnerId: requestedPostOwnerId,
        offeringPostId: offeringPostId,
      );
      return Right(request);
    } on ServerException catch (e) {
      return Left(
        ServerFailure(message: e.message ?? 'Failed to create swap request.'),
      );
    } catch (e) {
      return Left(ServerFailure(message: 'Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> isPostLiked(
    String postId,
    String userId,
  ) async {
    try {
      final isLiked = await remoteDataSource.isPostLiked(postId, userId);
      return Right(isLiked);
    } on ServerException catch (e) {
      return Left(
        ServerFailure(message: e.message ?? 'Failed to check like status.'),
      );
    } catch (e) {
      return Left(ServerFailure(message: 'Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, List<SwapRequestEntity>>> getSentSwapRequests(
    String userId,
  ) async {
    try {
      final requests = await remoteDataSource.getSentSwapRequests(userId);
      return Right(requests);
    } on ServerException catch (e) {
      return Left(
        ServerFailure(message: e.message ?? 'Failed to fetch sent requests.'),
      );
    } catch (e) {
      return Left(ServerFailure(message: 'Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, List<SwapRequestEntity>>> getReceivedSwapRequests(
    String userId,
  ) async {
    try {
      final requests = await remoteDataSource.getReceivedSwapRequests(userId);
      return Right(requests);
    } on ServerException catch (e) {
      return Left(
        ServerFailure(
          message: e.message ?? 'Failed to fetch received requests.',
        ),
      );
    } catch (e) {
      return Left(ServerFailure(message: 'Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> updateSwapRequestStatus(
    String requestId,
    SwapRequestStatus status,
  ) async {
    try {
      await remoteDataSource.updateSwapRequestStatus(requestId, status);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(
        ServerFailure(message: e.message ?? 'Failed to update swap request.'),
      );
    } catch (e) {
      return Left(ServerFailure(message: 'Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, List<PostEntity>>> getMyPosts() async {
    try {
      final userResult = await authRepository.getCurrentUser();
      return await userResult.fold(
        (failure) => Left(failure),
        (user) async {
          final posts = await remoteDataSource.getPostsByUserId(user.uid);
          return Right(posts);
        },
      );
    } catch (e) {
      return Left(
        ServerFailure(message: 'Unexpected error fetching user posts: $e'),
      );
    }
  }
}
