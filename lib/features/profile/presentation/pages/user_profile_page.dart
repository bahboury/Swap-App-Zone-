// lib/features/profile/presentation/pages/user_profile_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:swap_app/features/home/presentation/widgets/post_card.dart';
import 'package:swap_app/features/profile/presentation/managers/user_profile_provider.dart';
import 'package:swap_app/features/profile/presentation/widgets/swap_history_list_item.dart'; // Import SwapHistoryListItem

class UserProfilePage extends StatefulWidget {
  final String? userId; // Optional: If null, show the current user's profile

  const UserProfilePage({super.key, this.userId});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  @override
  void initState() {
    super.initState();
    // Fetch profile, posts, AND swap history based on whether a userId is provided
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<UserProfileProvider>(context, listen: false);
      if (widget.userId == null) {
        provider.fetchMyProfile();
        provider.fetchMyPosts();
        provider.fetchSwapHistory(); // Fetch swap history for the current user
      } else {
        provider.fetchUserProfile(widget.userId!);
        provider.fetchUserPosts(widget.userId!);
        // Note: We only fetch swap history for the *current* user's profile page.
        // If you want to see another user's completed swaps, you would need
        // to modify the backend and frontend to support that.
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.userId == null ? 'My Profile' : 'User Profile'),
      ),
      body: Consumer<UserProfileProvider>(
        builder: (context, userProfileProvider, child) {
          // Handle loading and error states for the main profile data
          if (userProfileProvider.status == UserProfileStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          } else if (userProfileProvider.status == UserProfileStatus.error) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 50, color: Colors.grey[600]),
                  const SizedBox(height: 16),
                  Text(
                    userProfileProvider.errorMessage ??
                        'Failed to load profile.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    onPressed: () {
                      if (widget.userId == null) {
                        userProfileProvider.fetchMyProfile();
                      } else {
                        userProfileProvider.fetchUserProfile(widget.userId!);
                      }
                    },
                  ),
                ],
              ),
            );
          } else if (userProfileProvider.status == UserProfileStatus.loaded &&
              userProfileProvider.userProfile != null) {
            final userProfile = userProfileProvider.userProfile!;
            // Display the loaded profile and then the posts and swap history
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User Profile Information
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundImage:
                              userProfile.photoUrl != null
                                  ? NetworkImage(userProfile.photoUrl!)
                                  : null,
                          child:
                              userProfile.photoUrl == null
                                  ? Icon(Icons.person, size: 50)
                                  : null,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          userProfile.displayName ?? 'No Name',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          userProfile.email ?? 'No Email',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                        // Add other profile fields here (e.g., bio, location)
                        if (userProfile.phoneNumber != null &&
                            userProfile.phoneNumber!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              'Phone: ${userProfile.phoneNumber!}',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Posts:',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  // Display user's posts
                  _buildUserPostsSection(userProfileProvider),
                  const SizedBox(height: 24), // Separator
                  // Swap History Section (only for current user's profile)
                  if (widget.userId == null) ...[
                    const Text(
                      'Swap History:',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSwapHistorySection(
                      userProfileProvider,
                    ), // Call the builder method
                  ],
                ],
              ),
            );
          }
          // If status is initial or any other unhandled state, show nothing
          return const SizedBox.shrink(); // Fallback for other states
        },
      ),
    );
  }

  Widget _buildUserPostsSection(UserProfileProvider userProfileProvider) {
    // Handle loading, error, and empty states for posts
    if (userProfileProvider.status == UserProfileStatus.loadingPosts) {
      return const Center(child: CircularProgressIndicator());
    } else if (userProfileProvider.status ==
        UserProfileStatus.errorLoadingPosts) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 40, color: Colors.grey[600]),
            const SizedBox(height: 8),
            Text(
              userProfileProvider.postsErrorMessage ?? 'Failed to load posts.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Retry Posts'),
              onPressed: () {
                if (widget.userId == null) {
                  userProfileProvider.fetchMyPosts();
                } else {
                  userProfileProvider.fetchUserPosts(widget.userId!);
                }
              },
            ),
          ],
        ),
      );
    } else if (userProfileProvider.status == UserProfileStatus.emptyPosts) {
      return const Center(
        child: Text(
          'No posts found for this user.',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    } else if (userProfileProvider.status == UserProfileStatus.loadedPosts) {
      // Display the list of posts
      return ListView.builder(
        shrinkWrap: true, // Important for ListView inside SingleChildScrollView
        physics:
            const NeverScrollableScrollPhysics(), // Disable ListView's own scrolling
        itemCount: userProfileProvider.userPosts.length,
        itemBuilder: (context, index) {
          final post = userProfileProvider.userPosts[index];
          // Reuse the PostCard widget from the home feed
          return InkWell(
            onTap: () {
              // Navigate to Post Details page
              Navigator.of(
                context,
              ).pushNamed('/post_details', arguments: post.id);
            },
            child: PostCard(
              title: post.title,
              description: post.description,
              imageUrls: post.imageUrls,
            ),
          );
        },
      );
    }
    return const SizedBox.shrink(); // Fallback
  }

  // Widget to build the Swap History section
  Widget _buildSwapHistorySection(UserProfileProvider userProfileProvider) {
    // Handle loading, error, and empty states for swap history
    // NOTE: This section uses swapHistoryStatus, ensure your provider has this state variable
    if (userProfileProvider.swapHistoryStatus ==
        UserProfileStatus.loadingSwapHistory) {
      return const Center(child: CircularProgressIndicator());
    } else if (userProfileProvider.swapHistoryStatus ==
        UserProfileStatus.errorLoadingSwapHistory) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 40, color: Colors.grey[600]),
            const SizedBox(height: 8),
            Text(
              userProfileProvider.swapHistoryErrorMessage ??
                  'Failed to load swap history.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Retry Swap History'),
              onPressed: () {
                userProfileProvider
                    .fetchSwapHistory(); // Retry fetching swap history
              },
            ),
          ],
        ),
      );
    } else if (userProfileProvider.swapHistoryStatus ==
        UserProfileStatus.emptySwapHistory) {
      return const Center(
        child: Text(
          'You have no completed swaps yet.',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    } else if (userProfileProvider.swapHistoryStatus ==
        UserProfileStatus.loadedSwapHistory) {
      // Display the list of swap history items
      return ListView.builder(
        shrinkWrap: true, // Important for ListView inside SingleChildScrollView
        physics:
            const NeverScrollableScrollPhysics(), // Disable ListView's own scrolling
        itemCount: userProfileProvider.swapHistory.length,
        itemBuilder: (context, index) {
          final historyItem = userProfileProvider.swapHistory[index];
          // Use the new SwapHistoryListItem widget
          return SwapHistoryListItem(
            historyItem: historyItem,
          ); // Use SwapHistoryListItem
        },
      );
    }
    return const SizedBox.shrink(); // Fallback
  }
}

// Assuming PostCard is defined elsewhere or imported correctly
// If not, you'll need to provide the PostCard widget definition.
// Example placeholder if needed:
/*
class PostCard extends StatelessWidget {
  final PostEntity post;
  const PostCard({Key? key, required this.post}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(post.title), // Simple representation
      ),
    );
  }
}
*/

// ignore: unused_element
class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;

  const _ProfileMenuItem({
    required this.icon,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // Navigate to edit profile
            },
          ),
        ],
      ),
      body: Consumer<UserProfileProvider>(
        builder: (context, userProfileProvider, child) {
          if (userProfileProvider.status == UserProfileStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          } else if (userProfileProvider.status == UserProfileStatus.error) {
            return Center(
              child: SelectableText.rich(
                TextSpan(
                  text: 'Unknown error',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            );
          } else if (userProfileProvider.status == UserProfileStatus.loaded &&
              userProfileProvider.userProfile != null) {
            final user = userProfileProvider.userProfile!;
            return SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  CircleAvatar(
                    radius: 40,
                    backgroundImage:
                        user.photoUrl != null
                            ? NetworkImage(user.photoUrl!)
                            : null,
                    child:
                        user.photoUrl == null
                            ? const Icon(Icons.person, size: 40)
                            : null,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user.displayName ?? '',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    user.email ?? '',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Bio',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        user.bio ?? 'No bio provided.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Menu items
                  _ProfileMenuItem(
                    icon: Icons.list,
                    text: 'My Items',
                    onTap: () {
                      /* Navigate to My Items */
                    },
                  ),
                  _ProfileMenuItem(
                    icon: Icons.swap_horiz,
                    text: 'My Swaps',
                    onTap: () {
                      /* Navigate to My Swaps */
                    },
                  ),
                  _ProfileMenuItem(
                    icon: Icons.thumb_up,
                    text: 'Liked Swaps',
                    onTap: () {
                      /* Navigate to Liked Swaps */
                    },
                  ),
                  _ProfileMenuItem(
                    icon: Icons.settings,
                    text: 'Settings / Preferences',
                    onTap: () {
                      /* Navigate to Settings */
                    },
                  ),
                  _ProfileMenuItem(
                    icon: Icons.help,
                    text: 'Help & Support',
                    onTap: () {
                      /* Navigate to Help */
                    },
                  ),
                  _ProfileMenuItem(
                    icon: Icons.logout,
                    text: 'Logout',
                    onTap: () {
                      /* Handle logout */
                    },
                  ),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 4,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view),
            label: 'Categories',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.add), label: 'Add'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chats'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        onTap: (index) {
          // Handle navigation
        },
      ),
    );
  }
}
