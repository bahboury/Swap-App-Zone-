// lib/features/profile/domain/usecases/get_user_profile_usecase.dart

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:swap_app/core/error/failurs.dart';
import 'package:swap_app/core/usecases/usecase.dart';
import 'package:swap_app/features/profile/domain/entities/user_profile_entity.dart';
import 'package:swap_app/features/profile/domain/repo/user_profile_repository.dart';

class GetUserProfileUseCase
    implements UseCase<UserProfileEntity, GetUserProfileParams> {
  final UserProfileRepository repository;

  GetUserProfileUseCase(this.repository);

  @override
  Future<Either<Failure, UserProfileEntity>> call(
    GetUserProfileParams params,
  ) async {
    return await repository.getUserProfile(params.userId);
  }
}

class GetUserProfileParams extends Equatable {
  final String userId;

  const GetUserProfileParams({required this.userId});

  @override
  List<Object?> get props => [userId];
}
