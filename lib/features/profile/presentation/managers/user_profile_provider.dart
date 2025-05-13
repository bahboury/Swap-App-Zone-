// lib/features/profile/presentation/managers/user_profile_provider.dart

import 'package:flutter/foundation.dart'; // For ChangeNotifier and kDebugMode
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:swap_app/core/error/failurs.dart';
import 'package:swap_app/core/usecases/usecase.dart'; // For NoParams
import 'package:swap_app/features/profile/domain/entities/user_profile_entity.dart';
import 'package:swap_app/features/home/domain/entities/post_entity.dart';
import 'package:swap_app/features/profile/domain/entities/swap_history_entity.dart'; // NEW: Import SwapHistoryEntity
import 'package:swap_app/features/profile/domain/usecases/get_my_profile.dart';
import 'package:swap_app/features/profile/domain/usecases/get_user_profile_usecase.dart';
import 'package:swap_app/features/profile/domain/usecases/get_my_posts_usecase.dart';
import 'package:swap_app/features/profile/domain/usecases/get_user_posts_usecase.dart';
import 'package:swap_app/features/profile/domain/usecases/get_swap_history_usecase.dart'; // NEW: Import GetSwapHistoryUseCase
// You might need to import UserEntity and PostEntity from their respective domain layers
// if you plan to populate them in the provider for SwapHistoryEntity.
// import 'package:swap_app/features/auth/domain/entities/user_entity.dart';
// import 'package:swap_app/features/home/domain/entities/post_entity.dart';

enum UserProfileStatus {
  initial,
  loading,
  loaded,
  error,
  loadingPosts,
  loadedPosts,
  errorLoadingPosts,
  emptyPosts,
  loadingSwapHistory, // NEW: Status for loading swap history
  loadedSwapHistory, // NEW: Status for loaded swap history
  errorLoadingSwapHistory, // NEW: Status for error loading swap history
  emptySwapHistory, // NEW: Status for empty swap history
}

class UserProfileProvider extends ChangeNotifier {
  final GetMyProfileUseCase _getMyProfileUseCase;
  final GetUserProfileUseCase _getUserProfileUseCase;
  final GetMyPostsUseCase _getMyPostsUseCase;
  final GetUserPostsUseCase _getUserPostsUseCase;
  final GetSwapHistoryUseCase _getSwapHistoryUseCase;

  UserProfileStatus _status = UserProfileStatus.initial;
  UserProfileEntity? _userProfile;
  List<PostEntity> _userPosts = [];
  List<SwapHistoryEntity> _swapHistory = [];
  String? _errorMessage;
  String? _postsErrorMessage;
  String? _swapHistoryErrorMessage;
  UserProfileStatus _swapHistoryStatus = UserProfileStatus.initial;

  UserProfileProvider({
    required GetMyProfileUseCase getMyProfileUseCase,
    required GetUserProfileUseCase getUserProfileUseCase,
    required GetMyPostsUseCase getMyPostsUseCase,
    required GetUserPostsUseCase getUserPostsUseCase,
    required GetSwapHistoryUseCase getSwapHistoryUseCase,
  }) : _getMyProfileUseCase = getMyProfileUseCase,
       _getUserProfileUseCase = getUserProfileUseCase,
       _getMyPostsUseCase = getMyPostsUseCase,
       _getUserPostsUseCase = getUserPostsUseCase,
       _getSwapHistoryUseCase = getSwapHistoryUseCase;

  // Getters
  UserProfileStatus get status => _status;
  UserProfileEntity? get userProfile => _userProfile;
  List<PostEntity> get userPosts => _userPosts;
  List<SwapHistoryEntity> get swapHistory => _swapHistory;
  String? get errorMessage => _errorMessage;
  String? get postsErrorMessage => _postsErrorMessage;
  String? get swapHistoryErrorMessage => _swapHistoryErrorMessage;
  UserProfileStatus get swapHistoryStatus => _swapHistoryStatus;

  /// Fetches the profile of the currently logged-in user.
  Future<void> fetchMyProfile() async {
    try {
      _status = UserProfileStatus.loading;
      _errorMessage = null;
      _userProfile = null;
      notifyListeners();

      final result = await _getMyProfileUseCase(NoParams());

      result.fold(
        (failure) {
          _status = UserProfileStatus.error;
          _errorMessage = _mapFailureToMessage(failure);
        },
        (profile) {
          _userProfile = profile;
          _status = UserProfileStatus.loaded;
        },
      );
      notifyListeners();
    } catch (e, stack) {
      if (kDebugMode) {
        print('Error in fetchMyProfile: $e\n$stack');
      }
      _status = UserProfileStatus.error;
      _errorMessage = 'Unexpected error: $e';
      notifyListeners();
    }
  }

  /// Fetches the profile of a specific user by ID.
  Future<void> fetchUserProfile(String userId) async {
    _status = UserProfileStatus.loading;
    _errorMessage = null;
    _userProfile = null;
    notifyListeners();

    final params = GetUserProfileParams(userId: userId);
    final result = await _getUserProfileUseCase(params);

    result.fold(
      (failure) {
        _status = UserProfileStatus.error;
        _errorMessage = _mapFailureToMessage(failure);
      },
      (profile) {
        _userProfile = profile;
        _status = UserProfileStatus.loaded;
      },
    );
    notifyListeners();
  }

  /// Fetches the posts of the currently logged-in user.
  Future<void> fetchMyPosts() async {
    _status = UserProfileStatus.loadingPosts;
    _postsErrorMessage = null;
    _userPosts = [];
    notifyListeners();

    final result = await _getMyPostsUseCase(NoParams());

    result.fold(
      (failure) {
        _status = UserProfileStatus.errorLoadingPosts;
        _postsErrorMessage = _mapFailureToMessage(failure);
      },
      (posts) {
        _userPosts = posts;
        _status =
            posts.isEmpty
                ? UserProfileStatus.emptyPosts
                : UserProfileStatus.loadedPosts;
      },
    );
    notifyListeners();
  }

  /// Fetches the posts of a specific user by ID.
  Future<void> fetchUserPosts(String userId) async {
    _status = UserProfileStatus.loadingPosts;
    _postsErrorMessage = null;
    _userPosts = [];
    notifyListeners();

    final params = GetUserPostsParams(userId: userId);
    final result = await _getUserPostsUseCase(params);

    result.fold(
      (failure) {
        _status = UserProfileStatus.errorLoadingPosts;
        _postsErrorMessage = _mapFailureToMessage(failure);
      },
      (posts) {
        _userPosts = posts;
        _status =
            posts.isEmpty
                ? UserProfileStatus.emptyPosts
                : UserProfileStatus.loadedPosts;
      },
    );
    notifyListeners();
  }

  /// Fetches the completed swap history for the current user.
  Future<void> fetchSwapHistory() async {
    _swapHistoryStatus = UserProfileStatus.loadingSwapHistory;
    _swapHistoryErrorMessage = null;
    _swapHistory = [];
    notifyListeners();

    final result = await _getSwapHistoryUseCase(NoParams());

    result.fold(
      (failure) {
        _swapHistoryStatus = UserProfileStatus.errorLoadingSwapHistory;
        _swapHistoryErrorMessage = _mapFailureToMessage(failure);
        if (kDebugMode) {
          print('Error fetching swap history: $_swapHistoryErrorMessage');
        }
      },
      (history) {
        _swapHistory = history;
        _swapHistoryStatus =
            history.isEmpty
                ? UserProfileStatus.emptySwapHistory
                : UserProfileStatus.loadedSwapHistory;
        if (kDebugMode) {
          print('Swap history loaded: ${_swapHistory.length} items');
        }
      },
    );
    notifyListeners();
  }

  /// Helper function to map failures to user-friendly messages.
  String _mapFailureToMessage(Failure failure) {
    if (failure is ServerFailure) {
      return failure.message;
    } else if (failure is NetworkFailure) {
      return 'No internet connection. Please check your network settings.';
    } else if (failure is UserNotFoundFailure) {
      return 'User or profile not found.';
    } else if (failure is LocationPermissionDeniedFailure) {
      return failure.message;
    } else if (failure is LocationServiceDisabledFailure) {
      return failure.message;
    } else if (failure is LocationFetchFailure) {
      return failure.message;
    } else {
      return 'An unexpected error occurred. Please try again.';
    }
  }

  /// Refreshes all profile-related data.
  Future<void> refreshAllData() async {
    await fetchMyProfile();
    await fetchMyPosts();
    await fetchSwapHistory();
  }
}

final userProfileProvider =
    AsyncNotifierProvider<UserProfileNotifier, UserProfileEntity?>(() {
      return UserProfileNotifier();
    });

class UserProfileNotifier extends AsyncNotifier<UserProfileEntity?> {
  @override
  Future<UserProfileEntity?> build() async {
    return null; // Return null as initial state
    // Fetch profile logic here
  }
}
