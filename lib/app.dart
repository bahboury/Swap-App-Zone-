// lib/app.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:swap_app/core/injection_container.dart';
import 'package:swap_app/features/auth/presentation/managers/auth_provider.dart';
import 'package:swap_app/features/auth/presentation/pages/login_page.dart';
import 'package:swap_app/features/auth/presentation/pages/register_page.dart';
import 'package:swap_app/features/home/presentation/manager/create_post_provider.dart';
import 'package:swap_app/features/home/presentation/manager/home_feed_provider.dart';
import 'package:swap_app/features/home/presentation/manager/post_details_provider.dart';
import 'package:swap_app/features/home/presentation/manager/swap_requests_provider.dart';
import 'package:swap_app/features/home/presentation/pages/create_post_page.dart';
import 'package:swap_app/features/home/presentation/pages/post_details_page.dart';
import 'package:swap_app/features/home/presentation/widgets/post_card.dart';
import 'package:swap_app/features/home/presentation/widgets/sample_post_card.dart';
import 'package:swap_app/features/profile/presentation/pages/user_profile_page.dart';
import 'package:swap_app/features/profile/presentation/managers/user_profile_provider.dart';
import 'package:swap_app/features/home/presentation/pages/swap_requests_page.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(create: (_) => sl<AuthProvider>()),
        ChangeNotifierProvider<HomeFeedProvider>(
          create: (_) => sl<HomeFeedProvider>(),
        ),
        ChangeNotifierProvider<CreatePostProvider>(
          create: (_) => sl<CreatePostProvider>(),
        ),
        ChangeNotifierProvider<PostDetailsProvider>(
          create: (_) => sl<PostDetailsProvider>(),
        ),
        ChangeNotifierProvider<UserProfileProvider>(
          create: (_) => sl<UserProfileProvider>(),
        ),
        ChangeNotifierProvider<SwapRequestsProvider>(
          create: (_) => sl<SwapRequestsProvider>(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Swap App',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        routes: {
          '/': (context) => const AuthChecker(),
          '/login': (context) => const LoginPage(),
          '/register': (context) => const RegisterPage(),
          '/home': (context) => const HomePage(),
          '/create_post': (context) => const CreatePostPage(),
          '/post_details': (context) {
            final postId =
                ModalRoute.of(context)?.settings.arguments as String?;
            if (postId == null) {
              return const Scaffold(
                body: Center(child: Text('Error: Post ID not provided.')),
              );
            }
            return PostDetailsPage(postId: postId);
          },
          '/my_profile':
              (context) => ChangeNotifierProvider(
                create: (_) => sl<UserProfileProvider>(),
                child: const UserProfilePage(),
              ),
          '/user_profile': (context) {
            final userId =
                ModalRoute.of(context)?.settings.arguments as String?;
            if (userId == null) {
              return const Scaffold(
                body: Center(child: Text('Error: User ID not provided.')),
              );
            }
            return UserProfilePage(userId: userId);
          },
          '/swap_requests': (context) => const SwapRequestsPage(),
        },
        initialRoute: '/',
      ),
    );
  }
}

class AuthChecker extends StatelessWidget {
  const AuthChecker({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        switch (authProvider.status) {
          case AuthStatus.initial:
          case AuthStatus.loading:
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          case AuthStatus.authenticated:
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.of(context).pushReplacementNamed('/home');
            });
            return const SizedBox.shrink();
          case AuthStatus.unauthenticated:
          case AuthStatus.error:
            return const LoginPage();
        }
      },
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'SwapZone',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.pink),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: Consumer<HomeFeedProvider>(
        builder: (context, homeProvider, child) {
          return RefreshIndicator(
            onRefresh: () async => homeProvider.refreshFeed(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Location Row
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: Colors.pink,
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            homeProvider.currentAddress ??
                                'Fetching location...',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Search Bar
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F8F8),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.pink, width: 1.5),
                      ),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search items, categories, or users...',
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Colors.pink,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 14,
                          ),
                        ),
                        onSubmitted: (value) {
                          // TODO: Implement search logic
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Location-Based Swaps Section
                    const Text(
                      'Location-Based Swaps',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.8,
                      children: const [
                        SamplePostCard(
                          imageUrl:
                              'https://images.unsplash.com/photo-1519125323398-675f0ddb6308',
                          title: 'Vintage Radio',
                        ),
                        SamplePostCard(
                          imageUrl:
                              'https://images.unsplash.com/photo-1503736334956-4c8f8e92946d',
                          title: 'Classic Car',
                        ),
                        SamplePostCard(
                          imageUrl:
                              'https://images.unsplash.com/photo-1524985069026-dd778a71c7b4',
                          title: 'Book',
                        ),
                        SamplePostCard(
                          imageUrl:
                              'https://images.unsplash.com/photo-1516979187457-637abb4f9353',
                          title: 'Chess Game',
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    // Recent Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text(
                          'Recent',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          'See More',
                          style: TextStyle(fontSize: 14, color: Colors.black87),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Dynamic Recent Posts
                    if (homeProvider.status == HomeFeedStatus.loading)
                      const Center(child: CircularProgressIndicator())
                    else if (homeProvider.posts.isEmpty)
                      const Center(child: Text('No recent posts.'))
                    else
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: homeProvider.posts.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 16,
                              childAspectRatio: 0.8,
                            ),
                        itemBuilder: (context, index) {
                          final post = homeProvider.posts[index];
                          return GestureDetector(
                            onTap: () {
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
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: Colors.pink,
        unselectedItemColor: Colors.black38,
        onTap: (index) {
          if (index == 0) return;
          if (index == 1) {
            // TODO: Navigate to Categories
          } else if (index == 2) {
            Navigator.of(context).pushNamed('/create_post');
          } else if (index == 3) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Chats feature coming soon!'),
                duration: Duration(seconds: 2),
              ),
            );
          } else if (index == 4) {
            Navigator.of(context).pushNamed('/my_profile');
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view),
            label: 'Categories',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.add), label: 'Add'),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Chats',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
