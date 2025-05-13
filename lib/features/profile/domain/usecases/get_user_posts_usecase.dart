// lib/features/profile/domain/usecases/get_user_posts_usecase.dart

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:swap_app/core/error/failurs.dart';
import 'package:swap_app/core/usecases/usecase.dart';
import 'package:swap_app/features/home/domain/entities/post_entity.dart';
import 'package:swap_app/features/home/domain/repo/post_repository.dart'; // Corrected dependency import

// This Use Case fetches posts belonging to a specific user ID.
// It depends on the PostRepository to get post data.
class GetUserPostsUseCase
    implements UseCase<List<PostEntity>, GetUserPostsParams> {
  // Corrected dependency type to PostRepository
  final PostRepository repository;

  // Corrected constructor to accept PostRepository
  GetUserPostsUseCase(this.repository);

  @override
  Future<Either<Failure, List<PostEntity>>> call(
    GetUserPostsParams params,
  ) async {
    // Assuming PostRepository has a method to get posts by user ID
    // Example: return await repository.getPostsByUserId(params.userId);
    throw UnimplementedError('GetUserPostsUseCase.call is not implemented');
  }
}

class GetUserPostsParams extends Equatable {
  final String userId;

  const GetUserPostsParams({required this.userId});

  @override
  List<Object?> get props => [userId];
}
