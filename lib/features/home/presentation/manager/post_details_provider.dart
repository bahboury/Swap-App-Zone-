// lib/features/home/presentation/managers/post_details_provider.dart

import 'package:flutter/foundation.dart'; // For ChangeNotifier and kDebugMode
import 'package:swap_app/core/error/failurs.dart';
import 'package:swap_app/features/auth/domain/repo/auth_repository.dart';
import 'package:swap_app/features/home/domain/entities/post_entity.dart';
import 'package:swap_app/features/home/domain/repo/post_repository.dart';
import 'package:swap_app/features/home/domain/usecases/get_post_details_usecase.dart';
import 'package:swap_app/features/home/domain/usecases/like_post_usecase.dart'; // Import LikePostUseCase
import 'package:swap_app/features/home/domain/usecases/create_swap_request_usecase.dart';
import 'package:swap_app/features/profile/domain/usecases/get_my_posts_usecase.dart'; // Import GetMyPostsUseCase (still present)

enum PostDetailsStatus {
  initial,
  loading,
  loaded,
  error,
  liking, // New status
  unliking, // New status
  swapRequesting, // New status
  swapRequestSuccess, // New status
  swapRequestError, // New status
}

class PostDetailsProvider extends ChangeNotifier {
  final GetPostDetailsUseCase _getPostDetailsUseCase;
  final LikePostUseCase _likePostUseCase;
  final CreateSwapRequestUseCase _createSwapRequestUseCase;
  final AuthRepository _authRepository; // To get current user ID
  final PostRepository _postRepository; // To check if post is liked
  // final GetMyPostsUseCase _getMyPostsUseCase; // GetMyPostsUseCase seems unused here currently

  PostDetailsStatus _status = PostDetailsStatus.initial;
  PostEntity? _post;
  String? _errorMessage;
  bool _isLiked = false; // New state variable
  String? _currentUserId;

  // ignore: prefer_typing_uninitialized_variables
  var userPosts;

  PostDetailsProvider({
    required GetPostDetailsUseCase getPostDetailsUseCase,
    required LikePostUseCase likePostUseCase, // NEW: Require UnlikePostUseCase
    required CreateSwapRequestUseCase createSwapRequestUseCase,
    required AuthRepository authRepository,
    required PostRepository postRepository,
    required GetMyPostsUseCase
    getMyPostsUseCase, // GetMyPostsUseCase is still required by the constructor
  }) : _getPostDetailsUseCase = getPostDetailsUseCase,
       _likePostUseCase = likePostUseCase,
       _createSwapRequestUseCase = createSwapRequestUseCase,
       _authRepository = authRepository,
       _postRepository = postRepository
  // _getMyPostsUseCase = getMyPostsUseCase // Initialize if used
  {
    _getCurrentUserId(); // Get current user ID on initialization
  }

  PostDetailsStatus get status => _status;
  PostEntity? get post => _post;
  String? get errorMessage => _errorMessage;
  bool get isLiked => _isLiked;
  String? get currentUserId => _currentUserId;

  Future<void> _getCurrentUserId() async {
    final result = await _authRepository.getCurrentUser();
    result.fold(
      (failure) {
        _currentUserId = null; // User not logged in
        if (kDebugMode) {
          print(
            'Failed to get current user for PostDetailsProvider: ${failure.message}',
          );
        }
      },
      (user) {
        _currentUserId = user.uid;
      },
    );
    notifyListeners(); // Notify listeners after getting user ID
  }

  Future<void> fetchPostDetails(String postId) async {
    _status = PostDetailsStatus.loading;
    _errorMessage = null;
    _post = null;
    _isLiked = false; // Reset like status
    notifyListeners();

    final params = GetPostDetailsParams(postId: postId);
    final result = await _getPostDetailsUseCase(params);

    await result.fold(
      (failure) async {
        _status = PostDetailsStatus.error;
        _errorMessage = _mapFailureToMessage(failure);
      },
      (postEntity) async {
        _post = postEntity;

        // Check if the current user has liked this post
        await _checkIfLiked();

        _status = PostDetailsStatus.loaded;
      },
    );
    notifyListeners();
  }

  /// Checks if the current user has liked the post.
  Future<void> _checkIfLiked() async {
    if (_currentUserId == null || _post == null) {
      _isLiked = false; // Cannot be liked if no user or post
      return;
    }

    final result = await _postRepository.isPostLiked(
      _post!.id,
      _currentUserId!,
    );

    result.fold(
      (failure) {
        if (kDebugMode) {
          print('Warning: Failed to check like status: ${failure.message}');
        }
        _isLiked = false; // Default to not liked on error
      },
      (liked) {
        _isLiked = liked;
      },
    );
    notifyListeners(); // Notify after checking like status
  }

  /// Toggles the like status of the post.
  Future<void> toggleLike() async {
    if (_post == null || _currentUserId == null) {
      if (kDebugMode) {
        print('Cannot toggle like: post or current user is null.');
      }
      return; // Cannot like if post or user is null
    }

    final currentLikeStatus = _isLiked;
    _status =
        currentLikeStatus
            ? PostDetailsStatus.unliking
            : PostDetailsStatus.liking;
    _isLiked = !currentLikeStatus; // Optimistically update UI
    // Optimistically update likes count - handle potential null post
    _post = _post?.copyWith(
      likesCount:
          currentLikeStatus ? (_post!.likesCount) - 1 : (_post!.likesCount) + 1,
    );
    notifyListeners();

    final params = LikePostParams(postId: _post!.id, userId: _currentUserId!);

    final result =
        currentLikeStatus
            ? await _likePostUseCase(
              params,
            ) // Use UnlikePostUseCase when unliking
            : null; // Use LikePostUseCase when liking

    result?.fold(
      (failure) {
        // Revert UI on error
        _isLiked = currentLikeStatus;
        // Revert likes count - handle potential null post
        _post = _post?.copyWith(
          likesCount:
              currentLikeStatus
                  ? (_post!.likesCount) + 1
                  : (_post!.likesCount) - 1,
        );
        _status =
            PostDetailsStatus
                .error; // Use a general error status or a specific one
        _errorMessage = _mapFailureToMessage(failure);
        if (kDebugMode) {
          print('Failed to toggle like: ${failure.message}');
        }
      },
      (_) {
        // Success - status remains liking/unliking briefly, then can go back to loaded
        _status = PostDetailsStatus.loaded; // Go back to loaded on success
        if (kDebugMode) {
          print('Like toggled successfully.');
        }
      },
    );
    notifyListeners();
  }

  /// Creates a swap request for the current post.
  Future<void> createSwapRequest({String? offeringPostId}) async {
    if (_post == null ||
        _currentUserId == null ||
        _post!.userId == _currentUserId) {
      // Cannot request swap if post or user is null, or if it's the user's own post
      _status = PostDetailsStatus.error;
      _errorMessage = 'Cannot create swap request for this post.';
      if (kDebugMode) {
        print('Cannot create swap request: invalid state.');
      }
      notifyListeners();
      return;
    }

    _status = PostDetailsStatus.swapRequesting;
    _errorMessage = null;
    notifyListeners();

    final params = CreateSwapRequestParams(
      requestingUserId: _currentUserId!,
      requestedPostId: _post!.id,
      requestedPostOwnerId: _post!.userId,
      offeringPostId: offeringPostId, // Pass the optional offering post ID
    );

    final result = await _createSwapRequestUseCase(params);

    result.fold(
      (failure) {
        _status = PostDetailsStatus.swapRequestError;
        _errorMessage = _mapFailureToMessage(failure);
        if (kDebugMode) {
          print('Failed to create swap request: ${failure.message}');
        }
      },
      (swapRequest) {
        _status = PostDetailsStatus.swapRequestSuccess;
        // Optionally store the created swap request entity
        // _createdSwapRequest = swapRequest;
        if (kDebugMode) {
          print('Swap request created successfully: ${swapRequest.id}');
        }
      },
    );
    notifyListeners();
  }

  // Helper function to map failures to user-friendly messages
  String _mapFailureToMessage(Failure failure) {
    if (failure is ServerFailure) {
      return failure.message; // Added fallback
    } else if (failure is NetworkFailure) {
      return 'No internet connection. Please check your network settings.';
    } else if (failure is UserNotFoundFailure) {
      return 'User not found or not logged in.';
    } else if (failure is InvalidCredentialsFailure) {
      return failure.message; // Added fallback
    } else if (failure is EmailAlreadyInUseFailure) {
      return failure.message; // Added fallback
    } else if (failure is WeakPasswordFailure) {
      return failure.message; // Added fallback
    } else if (failure is OperationNotAllowedFailure) {
      return failure.message; // Added fallback
    } else if (failure is TooManyRequestsFailure) {
      return failure.message; // Added fallback
    } else if (failure is LocationPermissionDeniedFailure) {
      return failure.message; // Added fallback
    } else if (failure is LocationServiceDisabledFailure) {
      return failure.message; // Added fallback
    } else if (failure is LocationFetchFailure) {
      return failure.message; // Added fallback
    } else {
      return 'An unexpected error occurred. Please try again.';
    }
  }
}
