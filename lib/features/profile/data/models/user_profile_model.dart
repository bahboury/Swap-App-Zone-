// lib/features/profile/data/models/user_profile_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:swap_app/features/profile/domain/entities/user_profile_entity.dart';
// Import UserModel

class UserProfileModel extends UserProfileEntity {
  // Add fields that are specific to the Firestore document if any,
  // beyond what's in UserProfileEntity (which extends UserEntity)
  // For example:
  // final String? bio;
  // final String? locationPreference;
  // final List<String>? interests;
  // final DateTime? lastActive; // Example of a Firestore-specific field

  const UserProfileModel({
    required super.uid,
    super.email,
    super.displayName,
    super.photoUrl,
    super.phoneNumber,
    // Include additional fields here
    // this.bio,
    // this.locationPreference,
    // this.interests,
    // this.lastActive,
  });

  // Factory constructor to create a UserProfileModel from a Firestore DocumentSnapshot
  factory UserProfileModel.fromDocumentSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;

    // Read fields from the Firestore document
    return UserProfileModel(
      uid: doc.id, // Document ID is the UID
      email: data?['email'] as String?,
      displayName: data?['displayName'] as String?,
      photoUrl: data?['photoUrl'] as String?,
      phoneNumber: data?['phoneNumber'] as String?,
      // Read additional fields from Firestore data if they exist
      // bio: data?['bio'] as String?,
      // locationPreference: data?['locationPreference'] as String?,
      // interests: List<String>.from(data?['interests'] as List? ?? []),
      // lastActive: (data?['lastActive'] as Timestamp?)?.toDate(),
    );
  }

  // Method to convert a UserProfileModel (or UserProfileEntity) to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      // UID is the document ID, not stored as a field typically
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'phoneNumber': phoneNumber,
      // Include additional fields here
      // 'bio': bio,
      // 'locationPreference': locationPreference,
      // 'interests': interests,
      // 'lastActive': FieldValue.serverTimestamp(), // Update timestamp on save
    };
  }

  // Helper to create a UserProfileModel from a basic UserEntity
  factory UserProfileModel.fromEntity(UserProfileEntity entity) {
    return UserProfileModel(
      uid: entity.uid,
      email: entity.email,
      displayName: entity.displayName,
      photoUrl: entity.photoUrl,
      phoneNumber: entity.phoneNumber,
      // Map additional fields from entity if they exist
      // bio: entity.bio,
      // locationPreference: entity.locationPreference,
      // interests: entity.interests,
    );
  }

  @override
  List<Object?> get props => [
    uid,
    email,
    displayName,
    photoUrl,
    phoneNumber,
    // Include additional fields here
    // bio,
    // locationPreference,
    // interests,
    // lastActive,
  ];
}
