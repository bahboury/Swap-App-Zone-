// lib/features/home/data/datasources/post_remote_datasource.dart

import 'dart:io'; // Import for File
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart'; // NEW: Import Firebase Storage
import 'package:flutter/foundation.dart'; // For kDebugMode
import 'package:swap_app/core/error/exceptions.dart';
import 'package:swap_app/core/location/location_service.dart'; // For LatLng
import 'package:swap_app/features/home/data/models/post_model.dart';
import 'package:swap_app/core/utils/geohash_util.dart'; // Import our utility
import 'package:swap_app/features/home/data/models/swap_request_model.dart'; // Import SwapRequestModel
import 'package:swap_app/features/home/domain/entities/swap_request_entity.dart'; // Import SwapRequestStatus
// ignore: depend_on_referenced_packages
import 'package:path/path.dart'
    as path; // NEW: Import path package for file name

abstract class PostRemoteDataSource {
  Future<List<PostModel>> getNearbyPosts({
    required LatLng centerLocation,
    required double radiusKm,
  });

  // Modified createPost to accept List<File> for images
  Future<PostModel> createPost({
    required PostModel post,
    required List<File> images,
  });

  Future<PostModel> getPostDetails(String postId);

  Future<void> deletePost(String postId);

  // Interaction methods
  Future<void> likePost(String postId, String userId);
  Future<void> unlikePost(String postId, String userId);
  Future<SwapRequestModel> createSwapRequest({
    required String requestingUserId,
    required String requestedPostId,
    required String requestedPostOwnerId,
    String? offeringPostId,
  });
  Future<bool> isPostLiked(String postId, String userId);

  // Swap Request Management Methods
  Future<List<SwapRequestModel>> getSentSwapRequests(String userId);
  Future<List<SwapRequestModel>> getReceivedSwapRequests(String userId);
  Future<void> updateSwapRequestStatus(
    String requestId,
    SwapRequestStatus status,
  );
}

class PostRemoteDataSourceImpl implements PostRemoteDataSource {
  final FirebaseFirestore firestore;
  final FirebaseStorage firebaseStorage; // NEW: Add Firebase Storage dependency

  // NEW: Constructor now requires FirebaseStorage
  PostRemoteDataSourceImpl({
    required this.firestore,
    required this.firebaseStorage,
  });

  static const String _postsCollection = 'posts';
  static const String _likesSubcollection = 'likes'; // Subcollection for likes
  static const String _swapRequestsCollection =
      'swapRequests'; // Top-level collection for swap requests
  static const String _postImagesStoragePath =
      'post_images'; // Storage path for post images

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

  // NEW: Method to upload a single image file to Firebase Storage
  Future<String> _uploadImageToStorage(File imageFile, String postId) async {
    try {
      // Create a reference to the location you want to upload to in Firebase Storage
      // Use a unique name for the file, e.g., postId/imageFileName
      final fileName = path.basename(imageFile.path);
      final storageRef = firebaseStorage
          .ref()
          .child(_postImagesStoragePath)
          .child(postId) // Organize images by post ID
          .child(fileName);

      // Upload the file
      final uploadTask = storageRef.putFile(imageFile);

      // Wait for the upload to complete and get the download URL
      final snapshot = await uploadTask.whenComplete(() => null);
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } on FirebaseException catch (e) {
      throw ServerException(
        message:
            'Firebase Storage error during image upload: ${e.code} - ${e.message}',
      );
    } catch (e) {
      throw ServerException(
        message: 'Failed to upload image to storage: ${e.toString()}',
      );
    }
  }

  @override
  // Modified createPost to accept List<File> for images
  Future<PostModel> createPost({
    required PostModel post,
    required List<File> images,
  }) async {
    try {
      // First, add the post data to Firestore to get a document ID
      // We do this first so we can use the document ID in the storage path
      final docRef = await firestore
          .collection(_postsCollection)
          .add(post.toMap());

      final postId = docRef.id;

      // Upload images to Firebase Storage using the generated postId
      List<String> imageUrls = [];
      for (File imageFile in images) {
        final downloadUrl = await _uploadImageToStorage(imageFile, postId);
        imageUrls.add(downloadUrl);
      }

      // Update the Firestore document with the image URLs
      await docRef.update({'imageUrls': imageUrls});

      // Fetch the updated document to get the server-generated ID and timestamp
      final docSnapshot = await docRef.get();
      final data = docSnapshot.data();
      if (data == null) {
        throw ServerException(
          message:
              'Failed to retrieve created post data for ID: ${docSnapshot.id}',
        );
      }

      // Return the PostModel with the correct ID, server timestamp, and image URLs
      return PostModel.fromDocumentSnapshot(docSnapshot.id, data);
    } catch (e) {
      // If any part of the process fails, you might want to clean up
      // the partially created document and uploaded images.
      // This requires more complex error handling (e.g., using transactions or cloud functions).
      // For now, we'll just throw the exception.
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
      // This is important to avoid orphaned files in storage.
      // You would fetch the post document, get the imageUrls, and delete each file from storage.
      // Consider using a Cloud Function for this to ensure it happens reliably.

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
      // Re-throw as ServerException for consistency in the data layer
      throw ServerException(
        message: 'Failed to check like status: ${e.toString()}',
      );
    }
  }

  // Implementation to get swap requests sent by a user
  @override
  Future<List<SwapRequestModel>> getSentSwapRequests(String userId) async {
    try {
      final querySnapshot =
          await firestore
              .collection(_swapRequestsCollection)
              .where('requestingUserId', isEqualTo: userId)
              .orderBy('createdAt', descending: true) // Order by creation date
              .get();

      final List<SwapRequestModel> sentRequests =
          querySnapshot.docs
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
                return SwapRequestModel.fromDocumentSnapshot(doc);
              })
              .whereType<SwapRequestModel>()
              .toList();

      return sentRequests;
    } catch (e) {
      throw ServerException(
        message: 'Failed to get sent swap requests: ${e.toString()}',
      );
    }
  }

  // Implementation to get swap requests received by a user
  @override
  Future<List<SwapRequestModel>> getReceivedSwapRequests(String userId) async {
    try {
      final querySnapshot =
          await firestore
              .collection(_swapRequestsCollection)
              .where('requestedPostOwnerId', isEqualTo: userId)
              .orderBy('createdAt', descending: true) // Order by creation date
              .get();

      final List<SwapRequestModel> receivedRequests =
          querySnapshot.docs
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
                return SwapRequestModel.fromDocumentSnapshot(doc);
              })
              .whereType<SwapRequestModel>()
              .toList();

      return receivedRequests;
    } catch (e) {
      throw ServerException(
        message: 'Failed to get received swap requests: ${e.toString()}',
      );
    }
  }

  // Implementation to update the status of a swap request
  @override
  Future<void> updateSwapRequestStatus(
    String requestId,
    SwapRequestStatus status,
  ) async {
    try {
      final requestRef = firestore
          .collection(_swapRequestsCollection)
          .doc(requestId);

      // Get the current swap request data
      final requestSnapshot = await requestRef.get();
      if (!requestSnapshot.exists) {
        throw ServerException(message: 'Swap request not found.');
      }
      final requestData = requestSnapshot.data() as Map<String, dynamic>;
      final requestedPostId = requestData['requestedPostId'] as String?;
      final offeringPostId = requestData['offeringPostId'] as String?;

      // Update the status field
      await requestRef.update({
        'status': status.toString().split('.').last, // Convert enum to string
        // Optionally add an update timestamp
        // 'updatedAt': FieldValue.serverTimestamp(),
      });

      // If accepted, update involved post(s) status to 'swapped'
      if (status == SwapRequestStatus.accepted) {
        await firestore.runTransaction((transaction) async {
          if (requestedPostId != null) {
            final requestedPostRef = firestore
                .collection(_postsCollection)
                .doc(requestedPostId);
            transaction.update(requestedPostRef, {'status': 'swapped'});
          }
          if (offeringPostId != null && offeringPostId.isNotEmpty) {
            final offeringPostRef = firestore
                .collection(_postsCollection)
                .doc(offeringPostId);
            transaction.update(offeringPostRef, {'status': 'swapped'});
          }
        });
      }
    } catch (e) {
      throw ServerException(
        message: 'Failed to update swap request status: ${e.toString()}',
      );
    }
  }

  // Methods for commenting are excluded as per your request.
}
