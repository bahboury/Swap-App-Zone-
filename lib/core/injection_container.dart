// lib/core/injection_container.dart

import 'package:get_it/get_it.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

// Core
import 'package:swap_app/core/utils/input_converter.dart';
import 'package:swap_app/core/location/location_service.dart';
import 'package:swap_app/core/location/geocoding_service.dart';
import 'package:swap_app/features/auth/data/repo/auth_repo_impl.dart';
import 'package:swap_app/features/auth/domain/repo/auth_repository.dart';

// Auth Feature
// Domain
import 'package:swap_app/features/auth/domain/usecases/sign_in_usecase.dart';
import 'package:swap_app/features/auth/domain/usecases/sign_up_usecase.dart';
import 'package:swap_app/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:swap_app/features/auth/domain/usecases/get_current_user_usecase.dart';
// Presentation
import 'package:swap_app/features/auth/presentation/managers/auth_provider.dart';
import 'package:swap_app/features/home/data/sources/post_remote_datasource.dart';
import 'package:swap_app/features/home/domain/repo/post_repository.dart';
import 'package:swap_app/features/home/domain/repo/post_repository_impl.dart';

// Home Feature
// Domain
import 'package:swap_app/features/home/domain/usecases/get_nearby_posts_usecase.dart';
import 'package:swap_app/features/home/domain/usecases/create_post_usecase.dart';
import 'package:swap_app/features/home/domain/usecases/get_post_details_usecase.dart';
// Import interaction use cases
import 'package:swap_app/features/home/domain/usecases/like_post_usecase.dart';
import 'package:swap_app/features/home/domain/usecases/create_swap_request_usecase.dart';
// Import swap request management use cases
import 'package:swap_app/features/home/domain/usecases/get_sent_swap_requests_usecase.dart';
import 'package:swap_app/features/home/domain/usecases/get_received_swap_requests_usecase.dart';
import 'package:swap_app/features/home/domain/usecases/update_swap_request_status_usecase.dart';

import 'package:swap_app/features/home/presentation/manager/create_post_provider.dart';
import 'package:swap_app/features/home/presentation/manager/home_feed_provider.dart';
import 'package:swap_app/features/home/presentation/manager/post_details_provider.dart';
import 'package:swap_app/features/home/presentation/manager/swap_requests_provider.dart';
import 'package:swap_app/features/profile/data/sources/user_profile_remote_datasource.dart';
import 'package:swap_app/features/profile/data/repo/user_profile_repository_impl.dart'; // Corrected import path for UserProfileRepositoryImpl
import 'package:swap_app/features/profile/domain/repo/user_profile_repository.dart';
import 'package:swap_app/features/profile/domain/usecases/get_my_profile.dart';
import 'package:swap_app/features/profile/domain/usecases/get_swap_history_usecase.dart';

// Profile Feature
// Domain
import 'package:swap_app/features/profile/domain/usecases/get_user_profile_usecase.dart';
import 'package:swap_app/features/profile/domain/usecases/get_my_posts_usecase.dart';
import 'package:swap_app/features/profile/domain/usecases/get_user_posts_usecase.dart';
// Presentation
import 'package:swap_app/features/profile/presentation/managers/user_profile_provider.dart';

final sl = GetIt.instance; // Service Locator

Future<void> init() async {
  // --------------------------------------------------------------------------
  // Feature: Auth
  // --------------------------------------------------------------------------

  // Use Cases
  sl.registerFactory(() => SignInUseCase(sl<AuthRepository>()));
  sl.registerFactory(() => SignUpUseCase(sl<AuthRepository>()));
  sl.registerFactory(() => SignOutUseCase(sl<AuthRepository>()));
  sl.registerFactory(() => GetCurrentUserUseCase(sl<AuthRepository>()));

  // Repository
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(remoteDataSource: sl<AuthRemoteDataSource>()),
  );

  // Data Sources
  // NOTE: Corrected datasource import based on typical naming convention
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(
      firebaseAuth: sl<firebase_auth.FirebaseAuth>(),
      googleSignIn: sl<GoogleSignIn>(),
      firestore: sl<FirebaseFirestore>(),
    ),
  );

  // Presentation (AuthProvider)
  sl.registerLazySingleton(
    () => AuthProvider(
      signInUseCase: sl<SignInUseCase>(),
      signUpUseCase: sl<SignUpUseCase>(),
      signOutUseCase: sl<SignOutUseCase>(),
      getCurrentUserUseCase: sl<GetCurrentUserUseCase>(),
      authRepository: sl<AuthRepository>(),
    ),
  );

  // --------------------------------------------------------------------------
  // Feature: Home
  // --------------------------------------------------------------------------

  // Use Cases
  sl.registerFactory(() => GetNearbyPostsUseCase(sl<PostRepository>()));
  sl.registerFactory(() => CreatePostUseCase(sl<PostRepository>()));
  sl.registerFactory(() => GetPostDetailsUseCase(sl<PostRepository>()));
  // Register interaction use cases
  sl.registerFactory(() => LikePostUseCase(sl<PostRepository>()));
  sl.registerFactory(() => CreateSwapRequestUseCase(sl<PostRepository>()));
  // Register swap request management use cases
  sl.registerFactory(
    () => GetSentSwapRequestsUseCase(
      postRepository: sl<PostRepository>(),
      authRepository: sl<AuthRepository>(),
    ),
  );
  sl.registerFactory(
    () => GetReceivedSwapRequestsUseCase(
      postRepository: sl<PostRepository>(),
      authRepository: sl<AuthRepository>(),
    ),
  );
  sl.registerFactory(
    () => UpdateSwapRequestStatusUseCase(postRepository: sl<PostRepository>()),
  );
  // Register GetSwapHistoryUseCase - Assuming it depends on PostRepository
  // REMOVED the incorrect type cast 'as UserProfileRepository'
  sl.registerFactory(() => GetSwapHistoryUseCase(sl<UserProfileRepository>()));

  // Repository
  sl.registerLazySingleton<PostRepository>(
    () => PostRepositoryImpl(
      remoteDataSource: sl<PostRemoteDataSource>(),
      authRepository: sl<AuthRepository>(),
    ),
  );

  // Data Sources
  sl.registerLazySingleton<PostRemoteDataSource>(
    () => PostRemoteDataSourceImpl(
      firestore: sl<FirebaseFirestore>(),
      firebaseStorage: sl<FirebaseStorage>(),
    ),
  );

  // Presentation (HomeFeedProvider)
  sl.registerLazySingleton(
    () => HomeFeedProvider(
      getNearbyPostsUseCase: sl<GetNearbyPostsUseCase>(),
      locationService: sl<LocationService>(),
      geocodingService: sl<GeocodingService>(),
      authRepository: sl<AuthRepository>(),
    ),
  );

  // Presentation (CreatePostProvider)
  sl.registerFactory(
    () => CreatePostProvider(
      createPostUseCase: sl<CreatePostUseCase>(),
      locationService: sl<LocationService>(),
      geocodingService: sl<GeocodingService>(),
      authRepository: sl<AuthRepository>(),
    ),
  );

  // Presentation (PostDetailsProvider)
  sl.registerFactory(
    () => PostDetailsProvider(
      getPostDetailsUseCase: sl<GetPostDetailsUseCase>(),
      likePostUseCase: sl<LikePostUseCase>(),
      createSwapRequestUseCase: sl<CreateSwapRequestUseCase>(),
      authRepository: sl<AuthRepository>(),
      postRepository: sl<PostRepository>(),
      // NOTE: getMyPostsUseCase dependency might be unnecessary here,
      // depending on PostDetailsProvider's responsibilities.
      getMyPostsUseCase: sl<GetMyPostsUseCase>(),
    ),
  );

  // Register Swap Requests Provider
  sl.registerLazySingleton(
    () => SwapRequestsProvider(
      getSentSwapRequestsUseCase: sl<GetSentSwapRequestsUseCase>(),
      getReceivedSwapRequestsUseCase: sl<GetReceivedSwapRequestsUseCase>(),
      updateSwapRequestStatusUseCase: sl<UpdateSwapRequestStatusUseCase>(),
    ),
  );

  // --------------------------------------------------------------------------
  // Feature: Profile
  // --------------------------------------------------------------------------

  // Use Cases
  sl.registerFactory(() => GetMyProfileUseCase(sl<UserProfileRepository>()));
  sl.registerFactory(() => GetUserProfileUseCase(sl<UserProfileRepository>()));
  // Corrected dependencies for GetMyPostsUseCase and GetUserPostsUseCase
  sl.registerFactory(
    () => GetMyPostsUseCase(sl<PostRepository>()),
  ); // Depends on PostRepository
  sl.registerFactory(
    () => GetUserPostsUseCase(sl<PostRepository>()),
  ); // Depends on PostRepository
  // GetSwapHistoryUseCase is registered in the Home section

  // Repository
  sl.registerLazySingleton<UserProfileRepository>(
    () => UserProfileRepositoryImpl(
      remoteDataSource: sl<UserProfileRemoteDataSource>(),
      authRepository: sl<AuthRepository>(),
    ),
  );

  // Data Sources
  sl.registerLazySingleton<UserProfileRemoteDataSource>(
    () => UserProfileRemoteDataSourceImpl(
      firestore: sl<FirebaseFirestore>(),
      firebaseAuth: sl<firebase_auth.FirebaseAuth>(),
    ),
  );

  // Presentation (UserProfileProvider)
  sl.registerFactory(
    () => UserProfileProvider(
      getMyProfileUseCase: sl<GetMyProfileUseCase>(),
      getUserProfileUseCase: sl<GetUserProfileUseCase>(),
      getMyPostsUseCase: sl<GetMyPostsUseCase>(),
      getUserPostsUseCase: sl<GetUserPostsUseCase>(),
      getSwapHistoryUseCase: sl<GetSwapHistoryUseCase>(),
    ),
  );

  // --------------------------------------------------------------------------
  // Core
  // --------------------------------------------------------------------------

  // Utils
  sl.registerLazySingleton(() => InputConverter());

  // Location Services
  sl.registerLazySingleton<LocationService>(() => LocationServiceImpl());
  sl.registerLazySingleton<GeocodingService>(() => GeocodingServiceImpl());

  // --------------------------------------------------------------------------
  // External Dependencies
  // --------------------------------------------------------------------------

  // Firebase Auth
  final firebaseAuth = firebase_auth.FirebaseAuth.instance;
  sl.registerLazySingleton(() => firebaseAuth);

  // Google Sign-In
  final googleSignIn = GoogleSignIn();
  sl.registerLazySingleton(() => googleSignIn);

  // Firebase Firestore
  final firebaseFirestore = FirebaseFirestore.instance;
  sl.registerLazySingleton(() => firebaseFirestore);

  // Firebase Storage
  final firebaseStorage = FirebaseStorage.instance;
  sl.registerLazySingleton(() => firebaseStorage);
}
