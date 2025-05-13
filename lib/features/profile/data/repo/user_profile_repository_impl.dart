// lib/features/profile/data/repositories/user_profile_repository_impl.dart

import 'package:dartz/dartz.dart';
import 'package:swap_app/core/error/exceptions.dart';
import 'package:swap_app/core/error/failurs.dart';
import 'package:swap_app/features/auth/domain/repo/auth_repository.dart';
import 'package:swap_app/features/profile/data/sources/user_profile_remote_datasource.dart';
import 'package:swap_app/features/profile/domain/entities/user_profile_entity.dart';
import 'package:swap_app/features/home/domain/entities/post_entity.dart';
import 'package:swap_app/features/profile/domain/repo/user_profile_repository.dart';
import 'package:swap_app/features/home/data/models/post_model.dart'; // Import PostModel
import 'package:swap_app/features/profile/domain/entities/swap_history_entity.dart'; // NEW: Import SwapHistoryEntity
import 'package:swap_app/features/profile/data/models/swap_history_model.dart'; // NEW: Import SwapHistoryModel

class UserProfileRepositoryImpl implements UserProfileRepository {
  // <--- This is the class definition
  final UserProfileRemoteDataSource remoteDataSource;
  final AuthRepository authRepository; // To get the current user's UID

  UserProfileRepositoryImpl({
    required this.remoteDataSource,
    required this.authRepository,
  });

  @override
  Future<Either<Failure, UserProfileEntity>> getMyProfile() async {
    try {
      final userProfileModel = await remoteDataSource.getMyProfile();
      return Right(
        userProfileModel,
      ); // UserProfileModel extends UserProfileEntity
    } on ServerException catch (e) {
      // FIX: Provide a fallback message if e.message is null
      return Left(
        ServerFailure(
          message:
              e.message ??
              'An unknown server error occurred during getMyProfile.',
        ),
      );
    } catch (e) {
      return Left(
        ServerFailure(
          message:
              'An unexpected error occurred during getMyProfile: ${e.toString()}',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, UserProfileEntity>> getUserProfile(
    String userId,
  ) async {
    try {
      final userProfileModel = await remoteDataSource.getUserProfile(userId);
      return Right(userProfileModel);
    } on ServerException catch (e) {
      // FIX: Provide a fallback message if e.message is null
      return Left(
        ServerFailure(
          message:
              e.message ??
              'An unknown server error occurred during getUserProfile.',
        ),
      );
    } catch (e) {
      return Left(
        ServerFailure(
          message:
              'An unexpected error occurred during getUserProfile: ${e.toString()}',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, List<PostEntity>>> getMyPosts() async {
    try {
      // Get the current user's UID from the AuthRepository
      final currentUserResult = await authRepository.getCurrentUser();
      String? userId;
      currentUserResult.fold(
        (failure) {
          // If we can't get the current user, return a Failure
          userId = null; // Ensure userId is null on failure
        },
        (user) {
          userId = user.uid;
        },
      );

      if (userId == null || userId!.isEmpty) {
        // Added check for empty userId
        return Left(
          UserNotFoundFailure(
            message: 'Current user not found or not logged in.',
          ),
        );
      }

      final List<PostModel> postModels = await remoteDataSource.getUserPosts(
        userId!,
      );
      return Right(postModels); // PostModel extends PostEntity
    } on ServerException catch (e) {
      // FIX: Provide a fallback message if e.message is null
      return Left(
        ServerFailure(
          message:
              e.message ??
              'An unknown server error occurred during getMyPosts.',
        ),
      );
    } catch (e) {
      return Left(
        ServerFailure(
          message:
              'An unexpected error occurred during getMyPosts: ${e.toString()}',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, List<PostEntity>>> getUserPosts(String userId) async {
    try {
      final List<PostModel> postModels = await remoteDataSource.getUserPosts(
        userId,
      );
      return Right(postModels); // PostModel extends PostEntity
    } on ServerException catch (e) {
      // FIX: Provide a fallback message if e.message is null
      return Left(
        ServerFailure(
          message:
              e.message ??
              'An unknown server error occurred during getUserPosts.',
        ),
      );
    } catch (e) {
      return Left(
        ServerFailure(
          message:
              'An unexpected error occurred during getUserPosts: ${e.toString()}',
        ),
      );
    }
  }

  // NEW: Implementation for getting swap history
  @override
  Future<Either<Failure, List<SwapHistoryEntity>>> getSwapHistory() async {
    try {
      final currentUserResult = await authRepository.getCurrentUser();
      String? userId;

      currentUserResult.fold(
        (failure) => userId = null,
        (user) => userId = user.uid,
      );

      if (userId == null || userId!.isEmpty) {
        // Added check for empty userId
        return Left(
          UserNotFoundFailure(
            message: 'Current user not found or not logged in.',
          ),
        );
      }

      // Call the getSwapHistory method on the remote data source
      final List<SwapHistoryModel> swapHistoryModels = await remoteDataSource
          .getSwapHistory(userId!);
      // Return the list of SwapHistoryModels (which extend SwapHistoryEntity)
      return Right(swapHistoryModels);
    } on ServerException catch (e) {
      return Left(
        ServerFailure(
          message:
              e.message ??
              'An unknown error occurred while fetching swap history.',
        ),
      );
    } catch (e) {
      return Left(
        ServerFailure(
          message:
              'An unexpected error occurred while fetching swap history: ${e.toString()}',
        ),
      );
    }
  }
}
