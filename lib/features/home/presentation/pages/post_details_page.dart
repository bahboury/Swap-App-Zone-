// lib/features/home/presentation/pages/post_details_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:swap_app/features/home/presentation/manager/post_details_provider.dart';
// You might need a map package here later, e.g., google_maps_flutter or flutter_map

class PostDetailsPage extends StatefulWidget {
  final String postId; // The ID of the post to display

  const PostDetailsPage({super.key, required this.postId});

  @override
  State<PostDetailsPage> createState() => _PostDetailsPageState();
}

class _PostDetailsPageState extends State<PostDetailsPage> {
  @override
  void initState() {
    super.initState();
    // Fetch post details when the page is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PostDetailsProvider>(
        context,
        listen: false,
      ).fetchPostDetails(widget.postId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Post Details')),
      body: Consumer<PostDetailsProvider>(
        builder: (context, postDetailsProvider, child) {
          // Handle different states (loading, loaded, error)
          if (postDetailsProvider.status == PostDetailsStatus.loading ||
              postDetailsProvider.status ==
                  PostDetailsStatus
                      .liking || // Show loading during liking/unliking
              postDetailsProvider.status == PostDetailsStatus.unliking ||
              postDetailsProvider.status == PostDetailsStatus.swapRequesting) {
            // Show loading during swap request
            return const Center(child: CircularProgressIndicator());
          } else if (postDetailsProvider.status == PostDetailsStatus.error ||
              postDetailsProvider.status ==
                  PostDetailsStatus.swapRequestError) {
            // Handle general and swap request errors
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 50, color: Colors.grey[600]),
                  const SizedBox(height: 16),
                  Text(
                    postDetailsProvider.errorMessage ??
                        'Failed to load post details.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    onPressed: () {
                      postDetailsProvider.fetchPostDetails(
                        widget.postId,
                      ); // Retry fetching
                    },
                  ),
                ],
              ),
            );
          } else if (postDetailsProvider.status == PostDetailsStatus.loaded &&
              postDetailsProvider.post != null) {
            final post = postDetailsProvider.post!;
            // Display the loaded post details
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (post.imageUrls.isNotEmpty)
                    SizedBox(
                      height: 250, // Adjust height for larger images
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: post.imageUrls.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Image.network(
                              post.imageUrls[index],
                              width:
                                  MediaQuery.of(context).size.width *
                                  0.8, // Take 80% of screen width
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (context, error, stackTrace) =>
                                      const Icon(Icons.broken_image, size: 100),
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 16),
                  Text(
                    'Description:',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(post.description, style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 16),
                  Text(
                    'Location:',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 20,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        // Use Expanded to prevent overflow
                        child: Text(
                          post.address,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 200,
                    color: Colors.grey[300],
                    child: const Center(child: Text('Map Widget Placeholder')),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Posted:',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    post.createdAt.toLocal().toString(),
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  // Interactions Section
                  const Text(
                    'Interactions:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // Like Button
                      IconButton(
                        icon: Icon(
                          postDetailsProvider.isLiked
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color:
                              postDetailsProvider.isLiked
                                  ? Colors.red
                                  : Colors.grey,
                          size: 24,
                        ),
                        onPressed:
                            postDetailsProvider.currentUserId ==
                                    null // Disable if user not logged in
                                ? null
                                : () {
                                  postDetailsProvider.toggleLike();
                                },
                      ),
                      Text('${post.likesCount} Likes'),
                      const SizedBox(width: 16),
                      // Icon(Icons.comment_outlined, size: 24, color: Colors.blue),
                      // SizedBox(width: 4),
                      // Text('${post.commentsCount} Comments'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Swap Request Button
                  if (postDetailsProvider.currentUserId != null &&
                      post.userId !=
                          postDetailsProvider
                              .currentUserId) // Only show if logged in and not own post
                    ElevatedButton(
                      onPressed:
                          postDetailsProvider.status ==
                                  PostDetailsStatus.swapRequesting
                              ? null // Disable if swap request is in progress
                              : () async {
                                // For demonstration, show a dialog to select an offering post (if user has posts)
                                final offeringPostId = await showDialog<String>(
                                  context: context,
                                  builder: (context) {
                                    final userPosts =
                                        postDetailsProvider.userPosts;
                                    if (userPosts == null ||
                                        userPosts.isEmpty) {
                                      return AlertDialog(
                                        title: const Text('No Posts Available'),
                                        content: const Text(
                                          'You have no posts to offer for swap.',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed:
                                                () => Navigator.pop(
                                                  context,
                                                  null,
                                                ),
                                            child: const Text('OK'),
                                          ),
                                        ],
                                      );
                                    }
                                    return SimpleDialog(
                                      title: const Text(
                                        'Select a Post to Offer',
                                      ),
                                      children:
                                          userPosts.map((userPost) {
                                            return SimpleDialogOption(
                                              onPressed:
                                                  () => Navigator.pop(
                                                    context,
                                                    userPost.id,
                                                  ),
                                              child: Text(userPost.title),
                                            );
                                          }).toList(),
                                    );
                                  },
                                );
                                if (offeringPostId != null) {
                                  postDetailsProvider.createSwapRequest(
                                    offeringPostId: offeringPostId,
                                  );
                                }
                                // For now, create a request without an offering post
                                postDetailsProvider.createSwapRequest(
                                  offeringPostId: null,
                                );
                              },
                      child:
                          postDetailsProvider.status ==
                                  PostDetailsStatus.swapRequesting
                              ? const CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.0,
                              )
                              : const Text('Send Swap Request'),
                    ),
                  // Show success message after swap request
                  if (postDetailsProvider.status ==
                      PostDetailsStatus.swapRequestSuccess)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Swap request sent successfully!',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            );
          }
          // Handle swap request success state (show message briefly)
          else if (postDetailsProvider.status ==
              PostDetailsStatus.swapRequestSuccess) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Swap request sent successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
              // After showing success, maybe fetch post details again to update UI (e.g., if swap request status affects post)
              // Or simply reset status to loaded if no UI change on the post itself
              postDetailsProvider.fetchPostDetails(
                widget.postId,
              ); // Re-fetch to update state
            });
            return const SizedBox.shrink(); // Hide content while navigating or re-fetching
          }

          return const SizedBox.shrink(); // Fallback
        },
      ),
    );
  }
}
