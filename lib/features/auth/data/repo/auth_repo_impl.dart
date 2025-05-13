// lib/features/auth/data/datasources/auth_remote_datasource.dart

import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:swap_app/core/error/exceptions.dart';
import 'package:swap_app/core/error/failurs.dart';
import 'package:swap_app/features/auth/data/models/user_model.dart';
import 'package:swap_app/features/auth/domain/entities/user_entity.dart';
import 'package:swap_app/features/auth/domain/repo/auth_repository.dart'; // Assuming you have a UserModel

abstract class AuthRemoteDataSource {
  // Add the missing method and getter declarations
  Future<UserModel> signInWithEmailPassword({
    required String email,
    required String password,
  });
  Future<UserModel> signUpWithEmailPassword({
    required String email,
    required String password,
    String? displayName,
    String? photoUrl,
  });
  Future<UserModel> signInWithGoogle();
  Future<void> signOut();
  firebase_auth.User? getCurrentFirebaseUser();
  Stream<firebase_auth.User?> get user; // Add the missing getter declaration
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final firebase_auth.FirebaseAuth firebaseAuth;
  final GoogleSignIn googleSignIn;
  final FirebaseFirestore firestore;

  AuthRemoteDataSourceImpl({
    required this.firebaseAuth,
    required this.googleSignIn,
    required this.firestore,
    Object? remoteDataSource,
  });

  static const String _usersCollection = 'users';

  @override
  Future<UserModel> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        throw ServerException(message: 'Google Sign-In cancelled.');
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final firebase_auth.AuthCredential credential = firebase_auth
          .GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final firebase_auth.UserCredential userCredential = await firebaseAuth
          .signInWithCredential(credential);
      final firebase_auth.User? firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        throw ServerException(
          message: 'Google Sign-In failed, no user returned.',
        );
      }

      await _saveUserToFirestore(firebaseUser);

      return UserModel.fromFirebaseUser(firebaseUser);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw ServerException(message: e.message, code: e.code); // Include code
    } catch (e) {
      throw ServerException(message: 'Google Sign-In failed: ${e.toString()}');
    }
  }

  @override
  Future<UserModel> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      final firebase_auth.UserCredential userCredential = await firebaseAuth
          .signInWithEmailAndPassword(email: email, password: password);
      final firebase_auth.User? firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        throw ServerException(message: 'Sign-In failed, no user returned.');
      }

      // Optional: Ensure user data exists in Firestore on sign-in if not already there
      // await _saveUserToFirestore(firebaseUser);

      return UserModel.fromFirebaseUser(firebaseUser);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw ServerException(message: e.message, code: e.code); // Include code
    } catch (e) {
      throw ServerException(message: 'Sign-In failed: ${e.toString()}');
    }
  }

  @override
  Future<UserModel> signUpWithEmailPassword({
    required String email,
    required String password,
    String? displayName,
    String? photoUrl,
  }) async {
    try {
      final firebase_auth.UserCredential userCredential = await firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password);
      firebase_auth.User? firebaseUser =
          userCredential.user; // Use mutable variable

      if (firebaseUser == null) {
        throw ServerException(message: 'Sign-Up failed, no user returned.');
      }

      // Optional: Update display name and photo URL if provided during sign-up
      if (displayName != null || photoUrl != null) {
        await firebaseUser.updateDisplayName(displayName);
        await firebaseUser.updatePhotoURL(photoUrl);
        // Reload the user to get the updated profile info
        await firebaseUser.reload();
        // Get the reloaded user instance
        firebaseUser = firebaseAuth.currentUser;
        if (firebaseUser == null) {
          // Handle case where user becomes null after reload (unlikely but safe)
          throw ServerException(
            message: 'Sign-Up failed after updating profile.',
          );
        }
      }

      await _saveUserToFirestore(firebaseUser);

      return UserModel.fromFirebaseUser(firebaseUser);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw ServerException(message: e.message, code: e.code); // Include code
    } catch (e) {
      throw ServerException(message: 'Sign-Up failed: ${e.toString()}');
    }
  }

  Future<void> _saveUserToFirestore(firebase_auth.User firebaseUser) async {
    try {
      final userDocRef = firestore
          .collection(_usersCollection)
          .doc(firebaseUser.uid);

      final userData = <String, dynamic>{};
      if (firebaseUser.email != null) userData['email'] = firebaseUser.email;
      if (firebaseUser.displayName != null) {
        userData['displayName'] = firebaseUser.displayName;
      }
      if (firebaseUser.photoURL != null) {
        userData['photoUrl'] = firebaseUser.photoURL;
      }
      if (firebaseUser.phoneNumber != null) {
        userData['phoneNumber'] = firebaseUser.phoneNumber;
      }
      userData['lastActive'] = FieldValue.serverTimestamp();

      await userDocRef.set(userData, SetOptions(merge: true));
    } catch (e) {
      if (kDebugMode) {
        print('Error saving user data to Firestore: ${e.toString()}');
      }
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await firebaseAuth.signOut();
      await googleSignIn.signOut();
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw ServerException(message: e.message, code: e.code); // Include code
    } catch (e) {
      throw ServerException(message: 'Sign-Out failed: ${e.toString()}');
    }
  }

  @override
  firebase_auth.User? getCurrentFirebaseUser() {
    return firebaseAuth.currentUser;
  }

  @override
  Stream<firebase_auth.User?> get user {
    return firebaseAuth.authStateChanges(); // Use authStateChanges stream
  }
}

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, UserEntity>> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final user = await remoteDataSource.signInWithEmailPassword(
        email: email,
        password: password,
      );
      return Right(user);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> signUpWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final user = await remoteDataSource.signUpWithEmailPassword(
        email: email,
        password: password,
      );
      return Right(user);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await remoteDataSource.signOut();
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> signInWithGoogle() async {
    try {
      final user = await remoteDataSource.signInWithGoogle();
      return Right(user);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> getCurrentUser() async {
    try {
      final firebaseUser = remoteDataSource.getCurrentFirebaseUser();
      if (firebaseUser == null) {
        return Left(ServerFailure(message: 'No user logged in.'));
      }
      final user = UserModel.fromFirebaseUser(firebaseUser);
      return Right(user);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Stream<UserEntity> get user => remoteDataSource.user.map(
    (firebaseUser) =>
        firebaseUser != null
            ? UserModel.fromFirebaseUser(firebaseUser)
            : UserEntity.empty,
  );
}
