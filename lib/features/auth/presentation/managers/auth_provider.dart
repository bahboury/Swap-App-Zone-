// lib/features/auth/presentation/managers/auth_provider.dart

import 'dart:async'; // For StreamSubscription

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'; // For ChangeNotifier

import 'package:swap_app/core/error/failurs.dart';
import 'package:swap_app/core/usecases/usecase.dart';
import 'package:swap_app/features/auth/domain/entities/user_entity.dart';
import 'package:swap_app/features/auth/domain/repo/auth_repository.dart';
import 'package:swap_app/features/auth/domain/usecases/get_current_user_usecase.dart'; // For initial user check
import 'package:swap_app/features/auth/domain/usecases/sign_in_usecase.dart';
import 'package:swap_app/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:swap_app/features/auth/domain/usecases/sign_up_usecase.dart';
// Add 'as firebase_auth'

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final SignInUseCase _signInUseCase;
  final SignUpUseCase _signUpUseCase;
  final SignOutUseCase _signOutUseCase;
  final GetCurrentUserUseCase _getCurrentUserUseCase;
  final AuthRepository _authRepository; // To listen to the user stream

  AuthStatus _status = AuthStatus.initial;
  UserEntity _currentUser = UserEntity.empty;
  String? _errorMessage;
  StreamSubscription<UserEntity>? _userSubscription;

  AuthProvider({
    required SignInUseCase signInUseCase,
    required SignUpUseCase signUpUseCase,
    required SignOutUseCase signOutUseCase,
    required GetCurrentUserUseCase getCurrentUserUseCase,
    required AuthRepository authRepository,
  }) : _signInUseCase = signInUseCase,
       _signUpUseCase = signUpUseCase,
       _signOutUseCase = signOutUseCase,
       _getCurrentUserUseCase = getCurrentUserUseCase,
       _authRepository = authRepository {
    // Initialize user state on startup
    _checkCurrentUser();
    // Listen to authentication state changes
    _userSubscription = _authRepository.user.listen((user) {
      _currentUser = user;
      _status =
          user.isNotEmpty
              ? AuthStatus.authenticated
              : AuthStatus.unauthenticated;
      notifyListeners();
    });
  }

  AuthStatus get status => _status;
  UserEntity get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;

  // Initial check for authenticated user on app startup
  Future<void> _checkCurrentUser() async {
    _status = AuthStatus.loading;
    notifyListeners();
    final result = await _getCurrentUserUseCase(NoParams());
    result.fold(
      (failure) {
        _currentUser = UserEntity.empty;
        _status = AuthStatus.unauthenticated;
        _errorMessage = _mapFailureToMessage(failure);
      },
      (user) {
        _currentUser = user;
        _status = AuthStatus.authenticated;
      },
    );
    notifyListeners();
  }

  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    final params = SignInParams(email: email, password: password);
    final result = await _signInUseCase(params);

    result.fold(
      (failure) {
        _status = AuthStatus.error;
        _errorMessage = _mapFailureToMessage(failure);
        _currentUser = UserEntity.empty; // Ensure user is empty on failed login
      },
      (user) {
        _currentUser = user;
        _status = AuthStatus.authenticated;
      },
    );
    notifyListeners();
  }

  Future<void> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String fullName, // <-- Add this
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    final params = SignUpParams(email: email, password: password);
    final result = await _signUpUseCase(params);

    result.fold(
      (failure) {
        _status = AuthStatus.error;
        _errorMessage = _mapFailureToMessage(failure);
        _currentUser =
            UserEntity.empty; // Ensure user is empty on failed signup
      },
      (user) async {
        _currentUser = user;
        _status = AuthStatus.authenticated;

        // Save full name in Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({
          'email': email,
          'fullName': fullName, // <-- Save full name
          // ...other fields...
        });
      },
    );
    notifyListeners();
  }

  Future<void> signOut() async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    final result = await _signOutUseCase(NoParams());

    result.fold(
      (failure) {
        _status = AuthStatus.error;
        _errorMessage = _mapFailureToMessage(failure);
      },
      (_) {
        _status = AuthStatus.unauthenticated;
        _currentUser = UserEntity.empty;
      },
    );
    notifyListeners();
  }

  // Helper function to map failures to user-friendly messages
  String _mapFailureToMessage(Failure failure) {
    if (failure is ServerFailure) {
      return failure.message;
    } else if (failure is NetworkFailure) {
      return 'Please check your internet connection.';
    } else if (failure is InvalidCredentialsFailure) {
      return 'Invalid email or password.';
    } else if (failure is EmailAlreadyInUseFailure) {
      return 'This email is already registered.';
    } else if (failure is WeakPasswordFailure) {
      return 'Password is too weak.';
    } else if (failure is UserDisabledFailure) {
      return 'Your account has been disabled.';
    } else {
      return 'An unexpected error occurred. Please try again.';
    }
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    super.dispose();
  }
}
