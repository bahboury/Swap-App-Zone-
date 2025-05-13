// lib/features/profile/domain/usecases/get_my_posts_usecase.dart

import 'package:dartz/dartz.dart';
import 'package:swap_app/core/error/failurs.dart';
import 'package:swap_app/core/usecases/usecase.dart';
import 'package:swap_app/features/home/domain/entities/post_entity.dart';
import 'package:swap_app/features/home/domain/repo/post_repository.dart'; // Corrected dependency import

// This Use Case fetches posts belonging to the currently authenticated user.
// It depends on the PostRepository to get post data.
class GetMyPostsUseCase implements UseCase<List<PostEntity>, NoParams> {
  // Corrected dependency type to PostRepository
  final PostRepository repository;

  // Corrected constructor to accept PostRepository
  GetMyPostsUseCase(this.repository);

  @override
  Future<Either<Failure, List<PostEntity>>> call(NoParams params) async {
    return await repository.getMyPosts();
  }
}

// NoParams is used because this use case doesn't require specific input parameters
// other than implicitly using the current user ID (which should be handled internally
// by the repository or data source with the help of AuthRepository).
