// lib/features/auth/data/datasources/auth_remote_datasource.dart

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:swap_app/core/error/exceptions.dart';
import 'package:swap_app/features/auth/data/models/user_model.dart'; // Assuming you have a UserModel

abstract class AuthRemoteDataSource {
  Future<UserModel> signInWithGoogle();
  Future<UserModel> signInWithEmailPassword({
    required String email,
    required String password,
  });
  Future<UserModel> signUpWithEmailPassword({
    required String email,
    required String password,
    String? displayName, // Add optional display name
    String? photoUrl, // Add optional photo URL
  });
  Future<void> signOut();
  firebase_auth.User? getCurrentFirebaseUser(); // Get raw Firebase User
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final firebase_auth.FirebaseAuth firebaseAuth;
  final GoogleSignIn googleSignIn;
  final FirebaseFirestore firestore; // Inject Firestore

  AuthRemoteDataSourceImpl({
    required this.firebaseAuth,
    required this.googleSignIn,
    required this.firestore, // Require Firestore in constructor
  });

  static const String _usersCollection = 'users'; // Firestore collection name

  @override
  Future<UserModel> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        // User cancelled the sign-in
        throw ServerException(message: 'Google Sign-In cancelled.');
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final firebase_auth.AuthCredential credential = firebase_auth
          .GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final firebase_auth.UserCredential userCredential = await firebaseAuth
          .signInWithCredential(credential);
      final firebase_auth.User? firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        throw ServerException(
          message: 'Google Sign-In failed, no user returned.',
        );
      }

      // --- Save/Update user data in Firestore ---
      await _saveUserToFirestore(firebaseUser);
      // --- End Save/Update ---

      return UserModel.fromFirebaseUser(firebaseUser);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw ServerException(message: e.message);
    } catch (e) {
      throw ServerException(message: 'Google Sign-In failed: ${e.toString()}');
    }
  }

  @override
  Future<UserModel> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      final firebase_auth.UserCredential userCredential = await firebaseAuth
          .signInWithEmailAndPassword(email: email, password: password);
      final firebase_auth.User? firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        throw ServerException(message: 'Sign-In failed, no user returned.');
      }

      // --- Optional: Ensure user data exists in Firestore on sign-in if not already there ---
      // This is a fallback in case signUp didn't run or for users created differently.
      // await _saveUserToFirestore(firebaseUser);
      // --- End Optional ---

      return UserModel.fromFirebaseUser(firebaseUser);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw ServerException(message: e.message);
    } catch (e) {
      throw ServerException(message: 'Sign-In failed: ${e.toString()}');
    }
  }

  @override
  Future<UserModel> signUpWithEmailPassword({
    required String email,
    required String password,
    String? displayName,
    String? photoUrl,
  }) async {
    try {
      final firebase_auth.UserCredential userCredential = await firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password);
      final firebase_auth.User? firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        throw ServerException(message: 'Sign-Up failed, no user returned.');
      }

      // Optional: Update display name and photo URL if provided during sign-up
      if (displayName != null || photoUrl != null) {
        await firebaseUser.updateDisplayName(displayName);
        await firebaseUser.updatePhotoURL(photoUrl);
        // Reload the user to get the updated profile info
        await firebaseUser.reload();
        final updatedFirebaseUser = firebaseAuth.currentUser;
        if (updatedFirebaseUser != null) {
          // Use the reloaded user for saving to Firestore and returning
          // This ensures the UserModel has the latest display name/photoUrl
          // Note: updateDisplayName and updatePhotoURL might not immediately
          // update the user object returned by createUserWithEmailAndPassword.
          // Reloading and getting currentUser ensures you have the latest.
          await _saveUserToFirestore(updatedFirebaseUser);
          return UserModel.fromFirebaseUser(updatedFirebaseUser);
        }
      }

      // --- Save user data to Firestore ---
      await _saveUserToFirestore(firebaseUser);
      // --- End Save ---

      return UserModel.fromFirebaseUser(firebaseUser);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw ServerException(message: e.message);
    } catch (e) {
      throw ServerException(message: 'Sign-Up failed: ${e.toString()}');
    }
  }

  // Helper method to save user data to Firestore
  Future<void> _saveUserToFirestore(firebase_auth.User firebaseUser) async {
    try {
      final userDocRef = firestore
          .collection(_usersCollection)
          .doc(firebaseUser.uid);

      // Prepare data to save - only include non-null values
      final userData = <String, dynamic>{};
      if (firebaseUser.email != null) userData['email'] = firebaseUser.email;
      if (firebaseUser.displayName != null) {
        userData['displayName'] = firebaseUser.displayName;
      }
      if (firebaseUser.photoURL != null) {
        userData['photoUrl'] = firebaseUser.photoURL;
      }
      if (firebaseUser.phoneNumber != null) {
        userData['phoneNumber'] = firebaseUser.phoneNumber;
      }
      // Add a timestamp for when the profile was created or last updated
      userData['lastActive'] = FieldValue.serverTimestamp();

      // Use set with merge: true to create the document if it doesn't exist
      // or merge new data if it does (useful for updates or subsequent sign-ins)
      await userDocRef.set(userData, SetOptions(merge: true));
    } catch (e) {
      // Log the error, but don't necessarily fail the sign-up/in process
      // as the user is still authenticated with Firebase Auth.
      if (kDebugMode) {
        if (kDebugMode) {
          print('Error saving user data to Firestore: ${e.toString()}');
        }
      }
      // You might want to add this user to a queue to retry saving later.
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await firebaseAuth.signOut();
      await googleSignIn.signOut(); // Also sign out from Google
    } catch (e) {
      throw ServerException(message: 'Sign-Out failed: ${e.toString()}');
    }
  }

  @override
  firebase_auth.User? getCurrentFirebaseUser() {
    return firebaseAuth.currentUser;
  }
}
