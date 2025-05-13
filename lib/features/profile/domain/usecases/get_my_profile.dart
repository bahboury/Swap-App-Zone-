// lib/features/profile/domain/usecases/get_my_profile_usecase.dart

import 'package:dartz/dartz.dart';
import 'package:swap_app/core/error/failurs.dart';
import 'package:swap_app/core/usecases/usecase.dart'; // For NoParams
import 'package:swap_app/features/profile/domain/entities/user_profile_entity.dart';
import 'package:swap_app/features/profile/domain/repo/user_profile_repository.dart';

class GetMyProfileUseCase implements UseCase<UserProfileEntity, NoParams> {
  final UserProfileRepository repository;

  GetMyProfileUseCase(this.repository);

  @override
  Future<Either<Failure, UserProfileEntity>> call(NoParams params) async {
    return await repository.getMyProfile();
  }
}
