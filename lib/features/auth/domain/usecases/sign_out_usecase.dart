// lib/features/auth/domain/usecases/sign_out_usecase.dart

import 'package:dartz/dartz.dart';
import 'package:swap_app/core/error/failurs.dart';
import 'package:swap_app/core/usecases/usecase.dart';
import 'package:swap_app/features/auth/domain/repo/auth_repository.dart';

class SignOutUseCase implements UseCase<void, NoParams> {
  final AuthRepository repository;

  SignOutUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(NoParams params) async {
    return await repository.signOut();
  }
}
