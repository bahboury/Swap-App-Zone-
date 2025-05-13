// lib/features/home/domain/repo/post_repository.dart

import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:swap_app/core/error/failurs.dart';
import 'package:swap_app/core/location/location_service.dart';
import 'package:swap_app/features/home/domain/entities/post_entity.dart';
import 'package:swap_app/features/home/domain/entities/swap_request_entity.dart';

abstract class PostRepository {
  // region Post CRUD Operations

  /// Fetches posts near the specified location within the given radius
  Future<Either<Failure, List<PostEntity>>> getNearbyPosts({
    required LatLng centerLocation,
    required double radiusKm,
  });

  /// Creates a new post with the provided data and images
  Future<Either<Failure, PostEntity>> createPost({
    required PostEntity post,
    required List<File> images,
  });

  /// Retrieves detailed information about a specific post
  Future<Either<Failure, PostEntity>> getPostDetails(String postId);

  /// Deletes a post with the given ID
  Future<Either<Failure, void>> deletePost(String postId);

  /// Gets all posts created by the currently authenticated user
  Future<Either<Failure, List<PostEntity>>> getMyPosts();

  // endregion

  // region Post Interaction Methods

  /// Likes a post for the specified user
  Future<Either<Failure, void>> likePost(String postId, String userId);

  /// Removes a like from a post for the specified user
  Future<Either<Failure, void>> unlikePost(String postId, String userId);

  /// Checks if a post is liked by the specified user
  Future<Either<Failure, bool>> isPostLiked(String postId, String userId);

  // endregion

  // region Swap Request Management

  /// Creates a new swap request between users
  Future<Either<Failure, SwapRequestEntity>> createSwapRequest({
    required String requestingUserId,
    required String requestedPostId,
    required String requestedPostOwnerId,
    String? offeringPostId,
  });

  /// Gets all swap requests sent by the user
  Future<Either<Failure, List<SwapRequestEntity>>> getSentSwapRequests(
    String userId,
  );

  /// Gets all swap requests received by the user
  Future<Either<Failure, List<SwapRequestEntity>>> getReceivedSwapRequests(
    String userId,
  );

  /// Updates the status of a swap request
  Future<Either<Failure, void>> updateSwapRequestStatus(
    String requestId,
    SwapRequestStatus status,
  );

  // endregion
}
