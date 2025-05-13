// lib/features/profile/domain/usecases/get_swap_history_usecase.dart

import 'package:dartz/dartz.dart';
import 'package:swap_app/core/error/failurs.dart';
import 'package:swap_app/core/usecases/usecase.dart'; // For NoParams
import 'package:swap_app/features/profile/domain/entities/swap_history_entity.dart'; // Import SwapHistoryEntity
import 'package:swap_app/features/profile/domain/repo/user_profile_repository.dart';

/// Use case to fetch the completed swap history for the current user.
class GetSwapHistoryUseCase
    implements UseCase<List<SwapHistoryEntity>, NoParams> {
  final UserProfileRepository repository;

  GetSwapHistoryUseCase(this.repository);

  @override
  Future<Either<Failure, List<SwapHistoryEntity>>> call(NoParams params) async {
    // The repository handles getting the current user's ID internally for this use case.
    return await repository.getSwapHistory();
  }
}
