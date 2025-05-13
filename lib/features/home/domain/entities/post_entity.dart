// lib/features/home/domain/entities/post_entity.dart

import 'package:equatable/equatable.dart';
import 'package:swap_app/core/location/location_service.dart'; // For LatLng
import 'package:swap_app/features/auth/domain/entities/user_entity.dart'; // For UserEntity

class PostEntity extends Equatable {
  final String id;
  final String userId; // ID of the user who posted
  final String title;
  final String description;
  final List<String> imageUrls;
  final LatLng location; // Geo-location of the item
  final String address; // Readable address of the item
  final DateTime createdAt;
  final int likesCount; // Number of likes
  final int commentsCount; // Number of comments
  final String? status; // e.g., 'available', 'swapped', 'pending'
  final UserEntity?
  postedByUser; // Optional: User details (populated by presentation layer)

  const PostEntity({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.imageUrls,
    required this.location,
    required this.address,
    required this.createdAt,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.status = 'available',
    this.postedByUser,
  });

  // Used for creating a new post where 'id' is not yet assigned by the backend
  PostEntity copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    List<String>? imageUrls,
    LatLng? location,
    String? address,
    DateTime? createdAt,
    int? likesCount,
    int? commentsCount,
    String? status,
    UserEntity? postedByUser,
  }) {
    return PostEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrls: imageUrls ?? this.imageUrls,
      location: location ?? this.location,
      address: address ?? this.address,
      createdAt: createdAt ?? this.createdAt,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      status: status ?? this.status,
      postedByUser: postedByUser ?? this.postedByUser,
    );
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    title,
    description,
    imageUrls,
    location,
    address,
    createdAt,
    likesCount,
    commentsCount,
    status,
    postedByUser,
  ];
}
