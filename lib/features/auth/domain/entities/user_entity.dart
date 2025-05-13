// lib/features/auth/domain/entities/user_entity.dart

import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String uid;
  final String? email;
  final String? displayName;
  final String? photoUrl; // Optional: For profile picture
  final String? phoneNumber; // Optional

  const UserEntity({
    required this.uid,
    this.email,
    this.displayName,
    this.photoUrl,
    this.phoneNumber,
  });

  @override
  List<Object?> get props => [uid, email, displayName, photoUrl, phoneNumber];

  // Optional: Factory constructor for creating an empty or unauthenticated user
  static const UserEntity empty = UserEntity(uid: '');

  /// Convenience getter to determine whether the current user is empty.
  bool get isEmpty => this == UserEntity.empty;

  /// Convenience getter to determine whether the current user is not empty.
  bool get isNotEmpty => this != UserEntity.empty;
}
