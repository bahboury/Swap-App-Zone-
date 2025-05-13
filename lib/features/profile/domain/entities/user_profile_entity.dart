// lib/features/profile/domain/entities/user_profile_entity.dart

import 'package:swap_app/features/auth/domain/entities/user_entity.dart'; // Extend UserEntity

// UserProfileEntity represents the full profile information of a user.
// It extends UserEntity and can include additional profile-specific fields.
class UserProfileEntity extends UserEntity {
  // Add additional profile fields here if needed, e.g.:
  final String? bio;
  // final String locationPreference; // e.g., 'local', 'regional'
  // final List<String> interests;

  const UserProfileEntity({
    required super.uid,
    super.email,
    super.displayName,
    super.photoUrl,
    super.phoneNumber,
    this.bio,
    // Include additional fields here
    // this.locationPreference,
    // this.interests,
  });

  // Override props to include new fields if added
  @override
  List<Object?> get props => [
    uid,
    email,
    displayName,
    photoUrl,
    phoneNumber,
    bio,
    // Include additional fields here
    // locationPreference,
    // interests,
  ];

  // Factory constructor to create UserProfileEntity from UserEntity
  factory UserProfileEntity.fromUserEntity(UserEntity user) {
    return UserProfileEntity(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      photoUrl: user.photoUrl,
      phoneNumber: user.phoneNumber,
      // bio: user.bio, // Uncomment if UserEntity has bio
      // Map additional fields from UserEntity if they exist there
    );
  }

  // Optional: copyWith method if you add more fields
  // UserProfileEntity copyWith({
  //   String? uid,
  //   String? email,
  //   String? displayName,
  //   String? photoUrl,
  //   String? phoneNumber,
  //   String? bio,
  //   String? locationPreference,
  //   List<String>? interests,
  // }) {
  //   return UserProfileEntity(
  //     uid: uid ?? this.uid,
  //     email: email ?? this.email,
  //     displayName: displayName ?? this.displayName,
  //     photoUrl: photoUrl ?? this.photoUrl,
  //     phoneNumber: phoneNumber ?? this.phoneNumber,
  //     bio: bio ?? this.bio,
  //     locationPreference: locationPreference ?? this.locationPreference,
  //     interests: interests ?? this.interests,
  //   );
  // }
}
