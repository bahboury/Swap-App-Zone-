// lib/features/auth/domain/repositories/auth_repository.dart

import 'package:dartz/dartz.dart';
import 'package:swap_app/core/error/failurs.dart';
import 'package:swap_app/features/auth/domain/entities/user_entity.dart';

abstract class AuthRepository {
  Future<Either<Failure, UserEntity>> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  Future<Either<Failure, UserEntity>> signUpWithEmailAndPassword({
    required String email,
    required String password,
  });

  Future<Either<Failure, void>> signOut();

  // Potentially add Google/Facebook sign-in
  Future<Either<Failure, UserEntity>> signInWithGoogle();

  // Get the current logged-in user (can be null if not logged in)
  Future<Either<Failure, UserEntity>> getCurrentUser();

  // Listen to authentication state changes (optional, for streams)
  Stream<UserEntity> get user;
}
