// lib/features/home/data/models/post_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:swap_app/core/location/location_service.dart'; // For LatLng
import 'package:swap_app/core/utils/geohash_util.dart';
import 'package:swap_app/features/home/domain/entities/post_entity.dart';

class PostModel extends PostEntity {
  // Add geohash field
  final String geohash;

  const PostModel({
    required super.id,
    required super.userId,
    required super.title,
    required super.description,
    required super.imageUrls,
    required super.location,
    required super.address,
    required super.createdAt,
    super.likesCount,
    super.commentsCount,
    super.status,
    super.postedByUser,
    required this.geohash, // Require geohash
  });

  // Factory constructor to create a PostModel from a Firestore DocumentSnapshot
  factory PostModel.fromDocumentSnapshot(String id, Map<String, dynamic> data) {
    final locationData = data['location'] as Map<String, dynamic>?;
    GeoPoint? geoPoint;
    if (locationData != null && locationData['geopoint'] is GeoPoint) {
      geoPoint = locationData['geopoint'] as GeoPoint;
    }

    return PostModel(
      id: id,
      userId: data['userId'] as String? ?? '',
      title: data['title'] as String? ?? 'No Title',
      description: data['description'] as String? ?? 'No Description',
      imageUrls: List<String>.from(data['imageUrls'] as List? ?? []),
      location:
          geoPoint != null
              ? LatLng(
                latitude: geoPoint.latitude,
                longitude: geoPoint.longitude,
              )
              : const LatLng(latitude: 0.0, longitude: 0.0),
      address: data['address'] as String? ?? 'Unknown Location',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      likesCount: data['likesCount'] as int? ?? 0,
      commentsCount: data['commentsCount'] as int? ?? 0,
      status: data['status'] as String? ?? 'available',
      geohash: data['geohash'] as String? ?? '', // Get geohash from data
    );
  }

  // Method to convert a PostModel (or PostEntity) to a Map for Firestore
  // Override to include geohash
  Map<String, dynamic> toMap() {
    // No longer using GeoFlutterFire's data structure directly
    return {
      'userId': userId,
      'title': title,
      'description': description,
      'imageUrls': imageUrls,
      'location': {
        // Store location as a map with geopoint
        'geopoint': GeoPoint(location.latitude, location.longitude),
        'geohash': geohash, // Store the calculated geohash
      },
      'address': address,
      'createdAt': Timestamp.fromDate(createdAt),
      'likesCount': likesCount,
      'commentsCount': commentsCount,
      'status': status,
    };
  }

  // Helper to convert PostEntity to PostModel (useful when creating a new post)
  factory PostModel.fromEntity(PostEntity entity) {
    // Calculate geohash when converting from entity to model for creation
    final geohash = GeoHashUtil.encode(entity.location); // Use our utility

    return PostModel(
      id: entity.id,
      userId: entity.userId,
      title: entity.title,
      description: entity.description,
      imageUrls: entity.imageUrls,
      location: entity.location,
      address: entity.address,
      createdAt: entity.createdAt,
      likesCount: entity.likesCount,
      commentsCount: entity.commentsCount,
      status: entity.status,
      geohash: geohash, // Set the calculated geohash
    );
  }

  @override // Override to include geohash in props for Equatable
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
    geohash, // Include geohash
  ];
}
