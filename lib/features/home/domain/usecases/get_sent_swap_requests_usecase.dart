// lib/features/home/domain/usecases/get_sent_swap_requests_usecase.dart

import 'package:dartz/dartz.dart';
import 'package:swap_app/core/error/failurs.dart';
import 'package:swap_app/core/usecases/usecase.dart'; // For UseCase and NoParams
import 'package:swap_app/features/auth/domain/repo/auth_repository.dart';
import 'package:swap_app/features/home/domain/entities/swap_request_entity.dart'; // Import SwapRequestEntity
import 'package:swap_app/features/home/domain/repo/post_repository.dart';

/// Use case to get swap requests sent by the currently authenticated user.
class GetSentSwapRequestsUseCase
    implements UseCase<List<SwapRequestEntity>, NoParams> {
  final PostRepository postRepository;
  final AuthRepository authRepository; // To get the current user's ID

  GetSentSwapRequestsUseCase({
    required this.postRepository,
    required this.authRepository,
  });

  @override
  Future<Either<Failure, List<SwapRequestEntity>>> call(NoParams params) async {
    // First, get the current user's ID
    final currentUserResult = await authRepository.getCurrentUser();

    return currentUserResult.fold(
      (failure) {
        // If getting the current user fails, return a Failure
        return Left(failure);
      },
      (user) async {
        // If user is found, use their ID to fetch sent swap requests
        if (user.uid.isEmpty) {
          return Left(
            UserNotFoundFailure(
              message: 'Current user not found or not logged in.',
            ),
          );
        }
        return await postRepository.getSentSwapRequests(user.uid);
      },
    );
  }
}
