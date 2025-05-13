// lib/features/profile/domain/repositories/user_profile_repository.dart

import 'package:dartz/dartz.dart';
import 'package:swap_app/core/error/failurs.dart';
import 'package:swap_app/features/profile/domain/entities/swap_history_entity.dart';
import 'package:swap_app/features/profile/domain/entities/user_profile_entity.dart'; // Import UserProfileEntity
import 'package:swap_app/features/home/domain/entities/post_entity.dart'; // Import PostEntity

abstract class UserProfileRepository {
  /// Get the profile of the currently logged-in user.
  Future<Either<Failure, UserProfileEntity>> getMyProfile();

  /// Get the profile of a specific user by their ID.
  Future<Either<Failure, UserProfileEntity>> getUserProfile(String userId);

  /// Get the posts created by the currently logged-in user.
  Future<Either<Failure, List<PostEntity>>> getMyPosts();

  /// Get the posts created by a specific user by their ID.
  Future<Either<Failure, List<PostEntity>>> getUserPosts(String userId);

  // NEW: Get the completed swap history for the current user.
  // This method was missing and caused the error.
  Future<Either<Failure, List<SwapHistoryEntity>>> getSwapHistory();

  // Potentially add methods for:
  // - Updating user profile
}
