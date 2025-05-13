// lib/features/home/domain/usecases/like_post_usecase.dart

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:swap_app/core/error/failurs.dart';
import 'package:swap_app/core/usecases/usecase.dart';
import 'package:swap_app/features/home/domain/repo/post_repository.dart';

class LikePostUseCase implements UseCase<void, LikePostParams> {
  final PostRepository repository;

  LikePostUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(LikePostParams params) async {
    return await repository.likePost(params.postId, params.userId);
  }
}

class LikePostParams extends Equatable {
  final String postId;
  final String userId;

  const LikePostParams({required this.postId, required this.userId});

  @override
  List<Object?> get props => [postId, userId];
}
