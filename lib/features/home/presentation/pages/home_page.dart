// lib/features/home/data/datasources/post_remote_datasource.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'; // For kDebugMode
// import 'package:geoflutterfire2/geoflutterfire2.dart'; // For geo-queries (if using)
import 'package:swap_app/core/error/exceptions.dart';
import 'package:swap_app/core/location/location_service.dart'; // For LatLng
import 'package:swap_app/features/home/data/models/post_model.dart';
import 'package:swap_app/core/utils/geohash_util.dart'; // Import our utility
import 'package:swap_app/features/home/data/models/swap_request_model.dart'; // Import SwapRequestModel
import 'package:swap_app/features/home/domain/entities/swap_request_entity.dart'; // Import SwapRequestStatus

abstract class PostRemoteDataSource {
  Future<List<PostModel>> getNearbyPosts({
    required LatLng centerLocation,
    required double radiusKm,
  });

  Future<PostModel> createPost({required PostModel post});

  Future<PostModel> getPostDetails(String postId);

  Future<void> deletePost(String postId);

  // Interaction methods for Data Source
  Future<void> likePost(String postId, String userId);
  Future<void> unlikePost(String postId, String userId);
  Future<SwapRequestModel> createSwapRequest({
    required String requestingUserId,
    required String requestedPostId,
    required String requestedPostOwnerId,
    String? offeringPostId,
  });
  // Method to check if a user has liked a post (needed for UI state)
  Future<bool> isPostLiked(String postId, String userId);
}

class PostRemoteDataSourceImpl implements PostRemoteDataSource {
  final FirebaseFirestore firestore;
  // Remove GeoFlutterFire instance if not using it for queries
  // final GeoFlutterFire geo;

  PostRemoteDataSourceImpl({
    required this.firestore,
  }); // No longer need geo in constructor if not used

  static const String _postsCollection = 'posts';
  static const String _likesSubcollection = 'likes'; // Subcollection for likes
  static const String _swapRequestsCollection =
      'swapRequests'; // Top-level collection for swap requests

  @override
  Future<List<PostModel>> getNearbyPosts({
    required LatLng centerLocation,
    required double radiusKm,
  }) async {
    try {
      // Using manual geohash approach based on previous conversation context
      final geohashPrefixes = GeoHashUtil.getGeohashNeighbors(
        centerLocation,
        radiusKm,
      );

      List<QuerySnapshot> snapshots = [];
      for (String prefix in geohashPrefixes) {
        final query = firestore
            .collection(_postsCollection)
            .orderBy('location.geohash')
            .startAt([prefix])
            .endAt(['$prefix~']);

        final snapshot = await query.get();
        snapshots.add(snapshot);
      }

      final allDocs = snapshots.expand((snapshot) => snapshot.docs).toList();

      final List<PostModel> nearbyPosts =
          allDocs
              .map((doc) {
                final data = doc.data() as Map<String, dynamic>?;
                if (data == null) {
                  if (kDebugMode) {
                    print(
                      'Warning: Document data is null for post ID: ${doc.id}',
                    );
                  }
                  return null;
                }
                return PostModel.fromDocumentSnapshot(doc.id, data);
              })
              .whereType<PostModel>()
              .where((post) {
                // Perform a precise distance check using the actual LatLng
                final distance = GeoHashUtil.calculateDistance(
                  centerLocation,
                  post.location,
                );
                return distance <= radiusKm;
              })
              .toList();

      return nearbyPosts;
    } catch (e) {
      throw ServerException(
        message: 'Failed to fetch nearby posts: ${e.toString()}',
      );
    }
  }

  @override
  Future<PostModel> createPost({required PostModel post}) async {
    try {
      // Add the post data to Firestore
      final docRef = await firestore
          .collection(_postsCollection)
          .add(post.toMap());

      // Fetch the created document to get the server-generated ID and timestamp
      final docSnapshot = await docRef.get();
      final data = docSnapshot.data();
      if (data == null) {
        throw ServerException(
          message:
              'Failed to retrieve created post data for ID: ${docSnapshot.id}',
        );
      }

      // Return the PostModel with the correct ID and server timestamp
      return PostModel.fromDocumentSnapshot(docSnapshot.id, data);
    } catch (e) {
      throw ServerException(message: 'Failed to create post: ${e.toString()}');
    }
  }

  @override
  Future<PostModel> getPostDetails(String postId) async {
    try {
      final docSnapshot =
          await firestore.collection(_postsCollection).doc(postId).get();

      if (!docSnapshot.exists) {
        throw ServerException(message: 'Post with ID $postId not found.');
      }

      final data = docSnapshot.data();
      if (data == null) {
        throw ServerException(
          message: 'Document data is null for post ID: ${docSnapshot.id}',
        );
      }

      return PostModel.fromDocumentSnapshot(docSnapshot.id, data);
    } catch (e) {
      throw ServerException(
        message: 'Failed to get post details: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> deletePost(String postId) async {
    try {
      await firestore.collection(_postsCollection).doc(postId).delete();
    } catch (e) {
      throw ServerException(message: 'Failed to delete post: ${e.toString()}');
    }
  }

  // Implementation for liking a post
  @override
  Future<void> likePost(String postId, String userId) async {
    try {
      // Use a transaction to ensure atomicity for updating the likes count
      await firestore.runTransaction((transaction) async {
        final postRef = firestore.collection(_postsCollection).doc(postId);
        final likeRef = postRef
            .collection(_likesSubcollection)
            .doc(userId); // Use userId as like document ID

        final postSnapshot = await transaction.get(postRef);
        if (!postSnapshot.exists) {
          throw ServerException(message: 'Post not found when trying to like.');
        }

        final likeSnapshot = await transaction.get(likeRef);

        if (!likeSnapshot.exists) {
          // If the user hasn't liked it yet, add the like and increment count
          transaction.set(likeRef, {
            'userId': userId,
            'timestamp': FieldValue.serverTimestamp(),
          });
          final currentLikes = postSnapshot.data()?['likesCount'] as int? ?? 0;
          transaction.update(postRef, {'likesCount': currentLikes + 1});
        }
        // If likeSnapshot exists, the user has already liked it, do nothing.
      });
    } catch (e) {
      throw ServerException(message: 'Failed to like post: ${e.toString()}');
    }
  }

  // Implementation for unliking a post
  @override
  Future<void> unlikePost(String postId, String userId) async {
    try {
      // Use a transaction to ensure atomicity for updating the likes count
      await firestore.runTransaction((transaction) async {
        final postRef = firestore.collection(_postsCollection).doc(postId);
        final likeRef = postRef
            .collection(_likesSubcollection)
            .doc(userId); // Use userId as like document ID

        final postSnapshot = await transaction.get(postRef);
        if (!postSnapshot.exists) {
          throw ServerException(
            message: 'Post not found when trying to unlike.',
          );
        }

        final likeSnapshot = await transaction.get(likeRef);

        if (likeSnapshot.exists) {
          // If the user has liked it, remove the like and decrement count
          transaction.delete(likeRef);
          final currentLikes = postSnapshot.data()?['likesCount'] as int? ?? 0;
          if (currentLikes > 0) {
            // Prevent negative likes count
            transaction.update(postRef, {'likesCount': currentLikes - 1});
          }
        }
        // If likeSnapshot doesn't exist, the user hasn't liked it, do nothing.
      });
    } catch (e) {
      throw ServerException(message: 'Failed to unlike post: ${e.toString()}');
    }
  }

  // Implementation for creating a swap request
  @override
  Future<SwapRequestModel> createSwapRequest({
    required String requestingUserId,
    required String requestedPostId,
    required String requestedPostOwnerId,
    String? offeringPostId,
  }) async {
    try {
      // Create a SwapRequestModel instance
      final newSwapRequest = SwapRequestModel(
        id: '', // ID will be assigned by Firestore
        requestingUserId: requestingUserId,
        requestedPostId: requestedPostId,
        requestedPostOwnerId: requestedPostOwnerId,
        offeringPostId: offeringPostId,
        createdAt:
            DateTime.now(), // Set creation time (will be overwritten by server timestamp)
        status: SwapRequestStatus.pending, // Default status is pending
      );

      // Add the swap request data to the top-level swapRequests collection
      final docRef = await firestore
          .collection(_swapRequestsCollection)
          .add(newSwapRequest.toMap());

      // Fetch the created document to get the server-generated ID and timestamp
      final docSnapshot = await docRef.get();
      final data = docSnapshot.data();
      if (data == null) {
        throw ServerException(
          message:
              'Failed to retrieve created swap request data for ID: ${docSnapshot.id}',
        );
      }

      // Return the SwapRequestModel with the correct ID and server timestamp
      return SwapRequestModel.fromDocumentSnapshot(docSnapshot);
    } catch (e) {
      throw ServerException(
        message: 'Failed to create swap request: ${e.toString()}',
      );
    }
  }

  // Implementation to check if a post is liked by a user
  @override
  Future<bool> isPostLiked(String postId, String userId) async {
    try {
      final likeDocSnapshot =
          await firestore
              .collection(_postsCollection)
              .doc(postId)
              .collection(_likesSubcollection)
              .doc(userId)
              .get();

      return likeDocSnapshot.exists; // Returns true if the like document exists
    } catch (e) {
      if (kDebugMode) {
        print('Error checking if post is liked: ${e.toString()}');
      }
      // Return false or re-throw based on desired error handling
      throw ServerException(
        message: 'Failed to check like status: ${e.toString()}',
      );
    }
  }
}
