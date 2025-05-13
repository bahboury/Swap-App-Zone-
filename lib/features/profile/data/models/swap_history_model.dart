// lib/features/profile/data/models/swap_history_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:swap_app/features/home/domain/entities/swap_request_entity.dart';
import 'package:swap_app/features/profile/domain/entities/swap_history_entity.dart'; // Import SwapHistoryEntity

class SwapHistoryModel extends SwapHistoryEntity {
  const SwapHistoryModel({
    required super.id,
    required super.requestingUserId,
    required super.requestedPostId,
    required super.requestedPostOwnerId,
    super.offeringPostId,
    required super.completedAt,
    super.status = SwapRequestStatus.completed,
    // Note: requestingUser, requestedPostOwner, requestedPost, offeringPost
    // are typically NOT included in the model or stored directly in the document.
    // They are populated in the presentation layer by fetching related data.
  });

  // Factory constructor to create a SwapHistoryModel from a Firestore DocumentSnapshot
  factory SwapHistoryModel.fromDocumentSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Swap history document data is null for ID: ${doc.id}');
    }

    // Ensure status is completed for history
    SwapRequestStatus status = SwapRequestStatus.values.firstWhere(
      (e) => e.toString().split('.').last == data['status'],
      orElse:
          () => SwapRequestStatus.pending, // Should be 'completed' for history
    );

    // Use createdAt from the document as completedAt for history
    final completedAt =
        (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();

    return SwapHistoryModel(
      id: doc.id,
      requestingUserId: data['requestingUserId'] as String? ?? '',
      requestedPostId: data['requestedPostId'] as String? ?? '',
      requestedPostOwnerId: data['requestedPostOwnerId'] as String? ?? '',
      offeringPostId: data['offeringPostId'] as String?, // This can be null
      completedAt: completedAt,
      status: status, // Should be SwapRequestStatus.completed
    );
  }

  // Method to convert a SwapHistoryModel (or SwapHistoryEntity) to a Map for Firestore
  // This might not be needed if history is only read, not written to directly.
  // If needed, it would map to the structure of the completed swap request document.
  // Map<String, dynamic> toMap() { ... }

  // Helper to convert SwapHistoryEntity to SwapHistoryModel
  factory SwapHistoryModel.fromEntity(SwapHistoryEntity entity) {
    return SwapHistoryModel(
      id: entity.id,
      requestingUserId: entity.requestingUserId,
      requestedPostId: entity.requestedPostId,
      requestedPostOwnerId: entity.requestedPostOwnerId,
      offeringPostId: entity.offeringPostId,
      completedAt: entity.completedAt,
      status: entity.status,
    );
  }
}
