// lib/features/profile/data/datasources/user_profile_remote_datasource.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // To get current user UID
import 'package:flutter/foundation.dart';
import 'package:swap_app/core/error/exceptions.dart';
import 'package:swap_app/features/home/data/models/post_model.dart'; // Import PostModel
import 'package:swap_app/features/profile/data/models/swap_history_model.dart'; // NEW: Import SwapHistoryModel
import 'package:swap_app/features/profile/data/models/user_profile_model.dart'; // Import UserProfileModel

abstract class UserProfileRemoteDataSource {
  Future<UserProfileModel> getMyProfile();
  Future<UserProfileModel> getUserProfile(String userId);
  Future<List<PostModel>> getMyPosts(String userId); // Requires user ID
  Future<List<PostModel>> getUserPosts(String userId);
  // NEW: Method to get swap history - ADDED TO ABSTRACT CLASS
  Future<List<SwapHistoryModel>> getSwapHistory(String userId);
}

class UserProfileRemoteDataSourceImpl implements UserProfileRemoteDataSource {
  final FirebaseFirestore firestore;
  final FirebaseAuth firebaseAuth; // To get the current user's UID

  UserProfileRemoteDataSourceImpl({
    required this.firestore,
    required this.firebaseAuth,
  });

  static const String _usersCollection =
      'users'; // Collection for user profiles
  static const String _postsCollection = 'posts'; // Collection for posts
  static const String _swapRequestsCollection =
      'swapRequests'; // Collection for swap requests

  @override
  Future<UserProfileModel> getMyProfile() async {
    try {
      final currentUser = firebaseAuth.currentUser;
      if (currentUser == null) {
        throw ServerException(message: 'No authenticated user found.');
      }

      // Fetch the document using the current user's UID as the document ID
      final docSnapshot =
          await firestore
              .collection(_usersCollection)
              .doc(currentUser.uid)
              .get();

      if (!docSnapshot.exists) {
        // If the profile document doesn't exist, it might be a new user
        // or an issue with the save on sign-up. You might want to create a
        // basic profile here based on the Firebase Auth user data as a fallback.
        // For now, we'll throw an exception as the code expects a document.
        throw ServerException(
          message: 'User profile document not found for current user.',
        );
      }

      return UserProfileModel.fromDocumentSnapshot(docSnapshot);
    } catch (e) {
      throw ServerException(
        message: 'Failed to get my profile: ${e.toString()}',
      );
    }
  }

  @override
  Future<UserProfileModel> getUserProfile(String userId) async {
    try {
      // Fetch the document using the provided userId as the document ID
      final docSnapshot =
          await firestore.collection(_usersCollection).doc(userId).get();

      if (!docSnapshot.exists) {
        throw ServerException(
          message: 'User profile document not found for user ID: $userId.',
        );
      }

      return UserProfileModel.fromDocumentSnapshot(docSnapshot);
    } catch (e) {
      throw ServerException(
        message: 'Failed to get user profile: ${e.toString()}',
      );
    }
  }

  @override
  Future<List<PostModel>> getMyPosts(String userId) async {
    // This method is redundant if getUserPosts takes a userId.
    // We can just call getUserPosts(userId) from the repository.
    // Keeping it for now but will likely remove in the repository.
    return getUserPosts(userId);
  }

  @override
  Future<List<PostModel>> getUserPosts(String userId) async {
    try {
      // Query the posts collection for documents where 'userId' field matches the provided userId
      final querySnapshot =
          await firestore
              .collection(_postsCollection)
              .where('userId', isEqualTo: userId)
              .orderBy('createdAt', descending: true) // Order by creation date
              .get();

      final List<PostModel> userPosts =
          querySnapshot.docs
              .map((doc) {
                final data = doc.data();
                return PostModel.fromDocumentSnapshot(doc.id, data);
              })
              .whereType<PostModel>()
              .toList();

      return userPosts;
    } catch (e) {
      throw ServerException(
        message: 'Failed to get user posts: ${e.toString()}',
      );
    }
  }

  // NEW: Implementation for getting swap history
  @override // Added @override annotation
  Future<List<SwapHistoryModel>> getSwapHistory(String userId) async {
    try {
      // Query swap requests where status is 'completed' AND
      // the current user is either the requesting user OR the requested post owner.
      // Firestore doesn't directly support OR queries on different fields in a single query.
      // We need to perform two separate queries and merge the results.

      // Query 1: Requests where the user is the requesting user and status is completed
      final sentCompletedRequestsQuery = firestore
          .collection(_swapRequestsCollection)
          .where('requestingUserId', isEqualTo: userId)
          .where(
            'status',
            isEqualTo: 'completed',
          ) // Query by string representation of enum
          .orderBy('createdAt', descending: true); // Order by creation date

      // Query 2: Requests where the user is the requested post owner and status is completed
      final receivedCompletedRequestsQuery = firestore
          .collection(_swapRequestsCollection)
          .where('requestedPostOwnerId', isEqualTo: userId)
          .where(
            'status',
            isEqualTo: 'completed',
          ) // Query by string representation of enum
          .orderBy('createdAt', descending: true); // Order by creation date

      // Execute both queries
      final sentSnapshot = await sentCompletedRequestsQuery.get();
      final receivedSnapshot = await receivedCompletedRequestsQuery.get();

      // Combine documents from both snapshots
      final allDocs = [...sentSnapshot.docs, ...receivedSnapshot.docs];

      // Remove duplicates (a request might appear in both if a user requested their own post, though unlikely)
      // Use a Set to keep track of document IDs
      final uniqueDocs = <String, QueryDocumentSnapshot>{};
      for (var doc in allDocs) {
        uniqueDocs[doc.id] = doc;
      }

      // Map unique documents to SwapHistoryModels
      final List<SwapHistoryModel> swapHistory =
          uniqueDocs.values
              .map((doc) {
                final data = doc.data() as Map<String, dynamic>?;
                if (data == null) {
                  if (kDebugMode) {
                    print(
                      'Warning: Document data is null for swap request ID: ${doc.id}',
                    );
                  }
                  return null;
                }
                // Use SwapHistoryModel.fromDocumentSnapshot
                return SwapHistoryModel.fromDocumentSnapshot(doc);
              })
              .whereType<SwapHistoryModel>() // Filter out any nulls
              .toList();

      // Optional: Sort the combined list by completion date if needed (Firestore queries are already ordered by createdAt)
      // swapHistory.sort((a, b) => b.completedAt.compareTo(a.completedAt));

      return swapHistory;
    } catch (e) {
      throw ServerException(
        message: 'Failed to get swap history: ${e.toString()}',
      );
    }
  }
}
