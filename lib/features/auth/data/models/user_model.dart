// lib/features/auth/data/models/user_model.dart

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:swap_app/features/auth/domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.uid,
    super.email,
    super.displayName,
    super.photoUrl,
    super.phoneNumber,
  });

  // Factory constructor to create a UserModel from a Firebase User object
  factory UserModel.fromFirebaseUser(firebase_auth.User? firebaseUser) {
    if (firebaseUser == null) {
      return UserEntity.empty
          as UserModel; // Return an empty UserModel if Firebase User is null
    }
    return UserModel(
      uid: firebaseUser.uid,
      email: firebaseUser.email,
      displayName: firebaseUser.displayName,
      photoUrl: firebaseUser.photoURL,
      phoneNumber: firebaseUser.phoneNumber,
    );
  }

  // Optional: For converting UserModel to a map for Firestore (if you plan to store more user details)
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'phoneNumber': phoneNumber,
      // Add other user-specific fields here
    };
  }

  // Optional: For creating a UserModel from a Firestore snapshot (if you store more user details)
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] as String,
      email: map['email'] as String?,
      displayName: map['displayName'] as String?,
      photoUrl: map['photoUrl'] as String?,
      phoneNumber: map['phoneNumber'] as String?,
    );
  }
}
