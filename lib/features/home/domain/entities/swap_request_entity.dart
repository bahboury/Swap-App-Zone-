// lib/features/home/domain/entities/swap_request_entity.dart

import 'package:equatable/equatable.dart';
import 'package:swap_app/features/home/domain/entities/post_entity.dart'; // To link to the involved posts
import 'package:swap_app/features/auth/domain/entities/user_entity.dart'; // To link to the involved users

enum SwapRequestStatus {
  pending,
  accepted,
  rejected,
  cancelled,
  completed,
  declined,
}

class SwapRequestEntity extends Equatable {
  final String id;
  final String requestingUserId; // User initiating the request
  final String requestedPostId; // The post the requesting user is interested in
  final String requestedPostOwnerId; // The owner of the requested post
  final String?
  offeringPostId; // Optional: The post the requesting user is offering
  final DateTime createdAt;
  final SwapRequestStatus status;

  // Optional: Entities for the involved users and posts (populated by presentation layer)
  final UserEntity? requestingUser;
  final UserEntity? requestedPostOwner;
  final PostEntity? requestedPost;
  final PostEntity? offeringPost;

  const SwapRequestEntity({
    required this.id,
    required this.requestingUserId,
    required this.requestedPostId,
    required this.requestedPostOwnerId,
    this.offeringPostId,
    required this.createdAt,
    this.status = SwapRequestStatus.pending,
    this.requestingUser,
    this.requestedPostOwner,
    this.requestedPost,
    this.offeringPost,
  });

  @override
  List<Object?> get props => [
    id,
    requestingUserId,
    requestedPostId,
    requestedPostOwnerId,
    offeringPostId,
    createdAt,
    status,
    requestingUser,
    requestedPostOwner,
    requestedPost,
    offeringPost,
  ];

  SwapRequestEntity copyWith({
    String? id,
    String? requestingUserId,
    String? requestedPostId,
    String? requestedPostOwnerId,
    String? offeringPostId,
    DateTime? createdAt,
    SwapRequestStatus? status,
    UserEntity? requestingUser,
    UserEntity? requestedPostOwner,
    PostEntity? requestedPost,
    PostEntity? offeringPost,
  }) {
    return SwapRequestEntity(
      id: id ?? this.id,
      requestingUserId: requestingUserId ?? this.requestingUserId,
      requestedPostId: requestedPostId ?? this.requestedPostId,
      requestedPostOwnerId: requestedPostOwnerId ?? this.requestedPostOwnerId,
      offeringPostId: offeringPostId ?? this.offeringPostId,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      requestingUser: requestingUser ?? this.requestingUser,
      requestedPostOwner: requestedPostOwner ?? this.requestedPostOwner,
      requestedPost: requestedPost ?? this.requestedPost,
      offeringPost: offeringPost ?? this.offeringPost,
    );
  }
}
