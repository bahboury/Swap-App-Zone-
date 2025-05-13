// lib/features/home/domain/usecases/create_swap_request_usecase.dart

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:swap_app/core/error/failurs.dart';
import 'package:swap_app/core/usecases/usecase.dart';
import 'package:swap_app/features/home/domain/entities/swap_request_entity.dart';
import 'package:swap_app/features/home/domain/repo/post_repository.dart';

class CreateSwapRequestUseCase
    implements UseCase<SwapRequestEntity, CreateSwapRequestParams> {
  final PostRepository repository;

  CreateSwapRequestUseCase(this.repository);

  @override
  Future<Either<Failure, SwapRequestEntity>> call(
    CreateSwapRequestParams params,
  ) async {
    return await repository.createSwapRequest(
      requestingUserId: params.requestingUserId,
      requestedPostId: params.requestedPostId,
      requestedPostOwnerId: params.requestedPostOwnerId,
      offeringPostId: params.offeringPostId,
    );
  }
}

class CreateSwapRequestParams extends Equatable {
  final String requestingUserId;
  final String requestedPostId;
  final String requestedPostOwnerId;
  final String? offeringPostId; // Optional

  const CreateSwapRequestParams({
    required this.requestingUserId,
    required this.requestedPostId,
    required this.requestedPostOwnerId,
    this.offeringPostId,
  });

  @override
  List<Object?> get props => [
    requestingUserId,
    requestedPostId,
    requestedPostOwnerId,
    offeringPostId,
  ];
}
