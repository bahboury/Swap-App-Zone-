// lib/features/home/data/datasources/post_remote_datasource.dart

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:swap_app/core/error/exceptions.dart';
import 'package:swap_app/core/location/location_service.dart';
import 'package:swap_app/features/home/data/models/post_model.dart';
import 'package:swap_app/core/utils/geohash_util.dart';
import 'package:swap_app/features/home/data/models/swap_request_model.dart';
import 'package:swap_app/features/home/domain/entities/post_entity.dart';
import 'package:swap_app/features/home/domain/entities/swap_request_entity.dart';

// ignore: depend_on_referenced_packages
import 'package:path/path.dart' as path;

enum PostStatus { active, swapped, archived }

abstract class PostRemoteDataSource {
  Future<List<PostModel>> getNearbyPosts({
    required LatLng centerLocation,
    required double radiusKm,
  });

  Future<PostModel> createPost({
    required PostModel post,
    required List<File> images,
  });

  Future<PostModel> getPostDetails(String postId);

  Future<void> deletePost(String postId);

  Future<void> likePost(String postId, String userId);
  Future<void> unlikePost(String postId, String userId);

  Future<SwapRequestModel> createSwapRequest({
    required String requestingUserId,
    required String requestedPostId,
    required String requestedPostOwnerId,
    String? offeringPostId,
  });

  Future<bool> isPostLiked(String postId, String userId);

  Future<List<SwapRequestModel>> getSentSwapRequests(String userId);
  Future<List<SwapRequestModel>> getReceivedSwapRequests(String userId);

  Future<void> updateSwapRequestStatus(
    String requestId,
    SwapRequestStatus status,
  );

  Future<List<PostModel>> getPostsByUserId(String userId);
  Future<List<PostEntity>> getMyPosts(String userId);
}

class PostRemoteDataSourceImpl implements PostRemoteDataSource {
  final FirebaseFirestore firestore;
  final FirebaseStorage firebaseStorage;

  PostRemoteDataSourceImpl({
    required this.firestore,
    required this.firebaseStorage,
  });

  static const String _postsCollection = 'posts';
  static const String _likesSubcollection = 'likes';
  static const String _swapRequestsCollection = 'swapRequests';
  static const String _postImagesStoragePath = 'post_images';

  @override
  Future<List<PostModel>> getNearbyPosts({
    required LatLng centerLocation,
    required double radiusKm,
  }) async {
    try {
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

  Future<String> _uploadImageToStorage(File imageFile, String postId) async {
    try {
      final fileName = path.basename(imageFile.path);
      final fullPath = '$_postImagesStoragePath/$postId/$fileName';

      if (kDebugMode) {
        print('Attempting to upload image to Storage path: $fullPath');
      }

      final storageRef = firebaseStorage
          .ref()
          .child(_postImagesStoragePath)
          .child(postId)
          .child(fileName);

      final uploadTask = storageRef.putFile(imageFile);

      final snapshot = await uploadTask.whenComplete(() => null);
      final downloadUrl = await snapshot.ref.getDownloadURL();

      if (kDebugMode) {
        print('Image uploaded successfully. Download URL: $downloadUrl');
      }

      return downloadUrl;
    } on FirebaseException catch (e) {
      if (kDebugMode) {
        print(
          'Firebase Storage error during image upload: ${e.code} - ${e.message}',
        );
        print(
          'Storage path attempted: $_postImagesStoragePath/$postId/${path.basename(imageFile.path)}',
        );
      }
      throw ServerException(
        message:
            'Firebase Storage error during image upload: ${e.code} - ${e.message}',
      );
    } catch (e) {
      if (kDebugMode) {
        print('Failed to upload image to storage: ${e.toString()}');
      }
      throw ServerException(
        message: 'Failed to upload image to storage: ${e.toString()}',
      );
    }
  }

  @override
  Future<PostModel> createPost({
    required PostModel post,
    required List<File> images,
  }) async {
    try {
      final docRef = await firestore
          .collection(_postsCollection)
          .add(post.toMap());

      final postId = docRef.id;

      List<String> imageUrls = [];
      if (images.isNotEmpty) {
        try {
          for (File imageFile in images) {
            final downloadUrl = await _uploadImageToStorage(imageFile, postId);
            imageUrls.add(downloadUrl);
          }
          await docRef.update({'imageUrls': imageUrls});
        } on ServerException catch (e) {
          if (kDebugMode) {
            print(
              'Image upload failed, proceeding without images: ${e.message}',
            );
          }
        } catch (e) {
          if (kDebugMode) {
            print(
              'Unexpected error during image upload: ${e.toString()}, proceeding without images.',
            );
          }
        }
      }

      final docSnapshot = await docRef.get();
      final data = docSnapshot.data();
      if (data == null) {
        throw ServerException(
          message:
              'Failed to retrieve created post data for ID: ${docSnapshot.id}',
        );
      }

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

  @override
  Future<void> likePost(String postId, String userId) async {
    try {
      await firestore.runTransaction((transaction) async {
        final postRef = firestore.collection(_postsCollection).doc(postId);
        final likeRef = postRef.collection(_likesSubcollection).doc(userId);

        final postSnapshot = await transaction.get(postRef);
        if (!postSnapshot.exists) {
          throw ServerException(message: 'Post not found when trying to like.');
        }

        final likeSnapshot = await transaction.get(likeRef);

        if (!likeSnapshot.exists) {
          transaction.set(likeRef, {
            'userId': userId,
            'timestamp': FieldValue.serverTimestamp(),
          });
          final currentLikes = postSnapshot.data()?['likesCount'] as int? ?? 0;
          transaction.update(postRef, {'likesCount': currentLikes + 1});
        }
      });
    } catch (e) {
      throw ServerException(message: 'Failed to like post: ${e.toString()}');
    }
  }

  @override
  Future<void> unlikePost(String postId, String userId) async {
    try {
      await firestore.runTransaction((transaction) async {
        final postRef = firestore.collection(_postsCollection).doc(postId);
        final likeRef = postRef.collection(_likesSubcollection).doc(userId);

        final postSnapshot = await transaction.get(postRef);
        if (!postSnapshot.exists) {
          throw ServerException(
            message: 'Post not found when trying to unlike.',
          );
        }

        final likeSnapshot = await transaction.get(likeRef);

        if (likeSnapshot.exists) {
          transaction.delete(likeRef);
          final currentLikes = postSnapshot.data()?['likesCount'] as int? ?? 0;
          if (currentLikes > 0) {
            transaction.update(postRef, {'likesCount': currentLikes - 1});
          }
        }
      });
    } catch (e) {
      throw ServerException(message: 'Failed to unlike post: ${e.toString()}');
    }
  }

  @override
  Future<SwapRequestModel> createSwapRequest({
    required String requestingUserId,
    required String requestedPostId,
    required String requestedPostOwnerId,
    String? offeringPostId,
  }) async {
    try {
      final newSwapRequest = SwapRequestModel(
        id: '',
        requestingUserId: requestingUserId,
        requestedPostId: requestedPostId,
        requestedPostOwnerId: requestedPostOwnerId,
        offeringPostId: offeringPostId,
        createdAt: DateTime.now(),
        status: SwapRequestStatus.pending,
      );

      final docRef = await firestore
          .collection(_swapRequestsCollection)
          .add(newSwapRequest.toMap());

      final docSnapshot = await docRef.get();
      final data = docSnapshot.data();
      if (data == null) {
        throw ServerException(
          message:
              'Failed to retrieve created swap request data for ID: ${docSnapshot.id}',
        );
      }

      return SwapRequestModel.fromDocumentSnapshot(docSnapshot);
    } catch (e) {
      throw ServerException(
        message: 'Failed to create swap request: ${e.toString()}',
      );
    }
  }

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

      return likeDocSnapshot.exists;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking if post is liked: ${e.toString()}');
      }
      throw ServerException(
        message: 'Failed to check like status: ${e.toString()}',
      );
    }
  }

  @override
  Future<List<SwapRequestModel>> getSentSwapRequests(String userId) async {
    try {
      final querySnapshot =
          await firestore
              .collection(_swapRequestsCollection)
              .where('requestingUserId', isEqualTo: userId)
              .orderBy('createdAt', descending: true)
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

  @override
  Future<List<SwapRequestModel>> getReceivedSwapRequests(String userId) async {
    try {
      final querySnapshot =
          await firestore
              .collection(_swapRequestsCollection)
              .where('requestedPostOwnerId', isEqualTo: userId)
              .orderBy('createdAt', descending: true)
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

  @override
  Future<void> updateSwapRequestStatus(
    String requestId,
    SwapRequestStatus status,
  ) async {
    try {
      await firestore.runTransaction((transaction) async {
        final requestRef = firestore
            .collection(_swapRequestsCollection)
            .doc(requestId);
        final requestSnapshot = await transaction.get(requestRef);

        if (!requestSnapshot.exists) {
          throw ServerException(
            message: 'Swap request with ID $requestId not found.',
          );
        }

        final requestData = requestSnapshot.data();
        if (requestData == null) {
          throw ServerException(
            message: 'Swap request data is null for ID $requestId.',
          );
        }

        final SwapRequestModel swapRequest =
            SwapRequestModel.fromDocumentSnapshot(requestSnapshot);

        // Update the swap request status
        transaction.update(requestRef, {
          'status': status.toString().split('.').last,
        });

        // --- Logic for when a swap request is ACCEPTED ---
        if (status == SwapRequestStatus.accepted) {
          final requestedPostId = swapRequest.requestedPostId;
          final offeringPostId = swapRequest.offeringPostId;

          // Fetch the involved posts
          final requestedPostRef = firestore
              .collection(_postsCollection)
              .doc(requestedPostId);
          final requestedPostSnapshot = await transaction.get(requestedPostRef);

          if (!requestedPostSnapshot.exists) {
            throw ServerException(
              message: 'Requested post not found for swap request $requestId.',
            );
          }

          // Update the status of the requested post
          transaction.update(requestedPostRef, {
            'status': PostStatus.swapped.toString().split('.').last,
          });

          // If an offering post exists, fetch and update its status
          if (offeringPostId != null && offeringPostId.isNotEmpty) {
            final offeringPostRef = firestore
                .collection(_postsCollection)
                .doc(offeringPostId);
            final offeringPostSnapshot = await transaction.get(offeringPostRef);

            if (!offeringPostSnapshot.exists) {
              if (kDebugMode) {
                print(
                  'Warning: Offering post not found for swap request $requestId. Proceeding with requested post update.',
                );
              }
            } else {
              transaction.update(offeringPostRef, {
                'status': PostStatus.swapped.toString().split('.').last,
              });
            }
          }
        }
        // For declined or cancelled, only the swap request status is updated, which is already done above.
      });
    } on FirebaseException catch (e) {
      if (kDebugMode) {
        print(
          'Firebase error updating swap request status: ${e.code} - ${e.message}',
        );
      }
      throw ServerException(
        message:
            'Firebase error updating swap request status: ${e.code} - ${e.message}',
      );
    } catch (e) {
      if (kDebugMode) {
        print('Failed to update swap request status: ${e.toString()}');
      }
      throw ServerException(
        message: 'Failed to update swap request status: ${e.toString()}',
      );
    }
  }

  @override
  Future<List<PostModel>> getPostsByUserId(String userId) async {
    try {
      final querySnapshot =
          await firestore
              .collection(_postsCollection)
              .where('userId', isEqualTo: userId)
              .orderBy('createdAt', descending: true)
              .get();

      final List<PostModel> userPosts =
          querySnapshot.docs
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
              .toList();

      return userPosts;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching posts by user ID: ${e.toString()}');
      }
      throw ServerException(
        message: 'Failed to fetch user posts: ${e.toString()}',
      );
    }
  }

  @override
  Future<List<PostEntity>> getMyPosts(String userId) async {
    try {
      final posts = await getPostsByUserId(userId);
      return posts;
    } on ServerException catch (e) {
      throw ServerException(
        message: e.message ?? 'Failed to get my posts from server.',
      );
    } catch (e) {
      throw ServerException(
        message:
            'An unexpected error occurred while getting my posts: ${e.toString()}',
      );
    }
  }
}
