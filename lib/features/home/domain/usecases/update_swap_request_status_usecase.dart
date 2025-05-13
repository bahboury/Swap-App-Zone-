// lib/features/home/domain/usecases/update_swap_request_status_usecase.dart

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:swap_app/core/error/failurs.dart';
import 'package:swap_app/core/usecases/usecase.dart'; // For UseCase
import 'package:swap_app/features/home/domain/entities/swap_request_entity.dart';
import 'package:swap_app/features/home/domain/repo/post_repository.dart';

/// Use case to update the status of a specific swap request.
class UpdateSwapRequestStatusUseCase
    implements UseCase<void, UpdateSwapRequestStatusParams> {
  final PostRepository postRepository;

  UpdateSwapRequestStatusUseCase({required this.postRepository});

  @override
  Future<Either<Failure, void>> call(
    UpdateSwapRequestStatusParams params,
  ) async {
    return await postRepository.updateSwapRequestStatus(
      params.requestId,
      params.status,
    );
  }
}

/// Parameters for the UpdateSwapRequestStatusUseCase.
class UpdateSwapRequestStatusParams extends Equatable {
  final String requestId;
  final SwapRequestStatus status;

  const UpdateSwapRequestStatusParams({
    required this.requestId,
    required this.status,
  });

  @override
  List<Object?> get props => [requestId, status];
}
