// lib/features/home/domain/usecases/create_post_usecase.dart

import 'dart:io'; // Import for File
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:swap_app/core/error/failurs.dart';
import 'package:swap_app/core/usecases/usecase.dart';
import 'package:swap_app/features/home/domain/entities/post_entity.dart';
import 'package:swap_app/features/home/domain/repo/post_repository.dart';

class CreatePostUseCase implements UseCase<PostEntity, CreatePostParams> {
  final PostRepository repository;

  CreatePostUseCase(this.repository);

  @override
  Future<Either<Failure, PostEntity>> call(CreatePostParams params) async {
    // Pass the post entity AND the list of image files to the repository
    return await repository.createPost(
      post: params.post,
      images: params.images,
    );
  }
}

// CORRECTED: Simplified parameters to only include the PostEntity and the list of image Files
class CreatePostParams extends Equatable {
  final PostEntity
  post; // The PostEntity containing title, description, location, etc.
  final List<File> images; // The list of image files to upload

  const CreatePostParams({required this.post, required this.images});

  @override
  List<Object?> get props => [post, images]; // Updated props
}
