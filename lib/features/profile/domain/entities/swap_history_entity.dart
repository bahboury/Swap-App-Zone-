// lib/features/profile/domain/entities/swap_history_entity.dart

import 'package:equatable/equatable.dart';
import 'package:swap_app/features/home/domain/entities/post_entity.dart'; // To link to the involved posts
import 'package:swap_app/features/auth/domain/entities/user_entity.dart'; // To link to the involved users
import 'package:swap_app/features/home/domain/entities/swap_request_entity.dart';

/// Represents a completed swap transaction in a user's history.
/// This entity is derived from a completed SwapRequest.
class SwapHistoryEntity extends Equatable {
  final String id; // The ID of the original swap request
  final String requestingUserId; // User who initiated the request
  final String requestedPostId; // The post that was requested
  final String requestedPostOwnerId; // The owner of the requested post
  final String? offeringPostId; // Optional: The post that was offered
  final DateTime completedAt; // The date/time the swap was completed
  final SwapRequestStatus
  status; // Should be SwapRequestStatus.completed for history

  // Optional: Entities for the involved users and posts (populated by presentation layer)
  final UserEntity? requestingUser;
  final UserEntity? requestedPostOwner;
  final PostEntity? requestedPost;
  final PostEntity? offeringPost;

  const SwapHistoryEntity({
    required this.id,
    required this.requestingUserId,
    required this.requestedPostId,
    required this.requestedPostOwnerId,
    this.offeringPostId,
    required this.completedAt,
    this.status = SwapRequestStatus.completed, // History should be completed
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
    completedAt,
    status,
    requestingUser,
    requestedPostOwner,
    requestedPost,
    offeringPost,
  ];
}
