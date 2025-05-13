// lib/features/home/domain/usecases/get_post_details_usecase.dart

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:swap_app/core/error/failurs.dart';
import 'package:swap_app/core/usecases/usecase.dart';
import 'package:swap_app/features/home/domain/entities/post_entity.dart';
import 'package:swap_app/features/home/domain/repo/post_repository.dart';

class GetPostDetailsUseCase
    implements UseCase<PostEntity, GetPostDetailsParams> {
  final PostRepository repository;

  GetPostDetailsUseCase(this.repository);

  @override
  Future<Either<Failure, PostEntity>> call(GetPostDetailsParams params) async {
    return await repository.getPostDetails(params.postId);
  }
}

class GetPostDetailsParams extends Equatable {
  final String postId;

  const GetPostDetailsParams({required this.postId});

  @override
  List<Object?> get props => [postId];
}
