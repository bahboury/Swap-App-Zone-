// lib/features/home/presentation/pages/swap_requests_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:swap_app/features/home/domain/entities/swap_request_entity.dart';
import 'package:swap_app/features/home/presentation/manager/swap_requests_provider.dart';
import 'package:swap_app/features/home/presentation/widgets/swap_request_list_item.dart'; // Import the list item widget
import 'package:firebase_auth/firebase_auth.dart';

class SwapRequestsPage extends StatefulWidget {
  const SwapRequestsPage({super.key});

  @override
  State<SwapRequestsPage> createState() => _SwapRequestsPageState();
}

class _SwapRequestsPageState extends State<SwapRequestsPage>
    with SingleTickerProviderStateMixin {
  // Tab controller for Sent and Received requests
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<SwapRequestsProvider>(
        context,
        listen: false,
      );
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        provider.refreshSwapRequests(userId);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Swap Requests'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Received'), Tab(text: 'Sent')],
        ),
      ),
      body: Consumer<SwapRequestsProvider>(
        builder: (context, provider, child) {
          // Display feedback for update operations (like accepting/declining)
          if (provider.updateStatus == SwapRequestsStatus.updatingStatus) {
            // Show a loading indicator or a subtle message
            // Consider using an overlay or a snackbar for less intrusive feedback
            return const Center(
              child: CircularProgressIndicator(),
            ); // Example: Full screen loading
          } else if (provider.updateStatus ==
              SwapRequestsStatus.statusUpdateError) {
            // Show an error message, maybe in a snackbar or a dialog
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Error updating request: ${provider.updateErrorMessage ?? "Unknown error"}',
                  ),
                  backgroundColor: Colors.red,
                ),
              );
              provider
                  .resetUpdateStatus(); // Reset status after showing message
            });
          } else if (provider.updateStatus ==
              SwapRequestsStatus.statusUpdated) {
            // Show a success message
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Swap request updated successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
              provider
                  .resetUpdateStatus(); // Reset status after showing message
              // Optionally refresh the lists after a successful update
              final userId = FirebaseAuth.instance.currentUser?.uid;
              if (userId != null) {
                provider.refreshSwapRequests(userId);
              }
            });
          }

          // Main content based on selected tab and data loading status
          return TabBarView(
            controller: _tabController,
            children: [
              // Received Requests Tab
              _buildRequestList(
                status: provider.receivedStatus,
                errorMessage: provider.receivedErrorMessage,
                requests: provider.receivedRequests,
                isReceived: true, // Indicate this is the received list
                onRefresh: () {
                  final userId = FirebaseAuth.instance.currentUser?.uid;
                  if (userId != null) {
                    return provider.fetchReceivedSwapRequests(userId);
                  }
                  return Future.value();
                }, // Pass refresh function
              ),
              // Sent Requests Tab
              _buildRequestList(
                status: provider.sentStatus,
                errorMessage: provider.sentErrorMessage,
                requests: provider.sentRequests,
                isReceived: false, // Indicate this is the sent list
                onRefresh: () {
                  final userId = FirebaseAuth.instance.currentUser?.uid;
                  if (userId != null) {
                    return provider.fetchSentSwapRequests(userId);
                  }
                  return Future.value();
                }, // Pass refresh function
              ),
            ],
          );
        },
      ),
    );
  }

  // Helper method to build the list view for requests
  Widget _buildRequestList({
    required SwapRequestsStatus status,
    required String? errorMessage,
    required List<SwapRequestEntity> requests,
    required bool isReceived,
    required Future<void> Function() onRefresh, // Refresh function
  }) {
    if (status == SwapRequestsStatus.loadingSent ||
        status == SwapRequestsStatus.loadingReceived) {
      return const Center(child: CircularProgressIndicator());
    } else if (status == SwapRequestsStatus.errorSent ||
        status == SwapRequestsStatus.errorReceived) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 50, color: Colors.grey[600]),
            const SizedBox(height: 16),
            Text(
              errorMessage ?? 'Failed to load requests.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              onPressed: onRefresh, // Use the passed refresh function
            ),
          ],
        ),
      );
    } else if (status == SwapRequestsStatus.emptySent ||
        status == SwapRequestsStatus.emptyReceived) {
      return Center(
        child: Text(
          isReceived ? 'No received swap requests.' : 'No sent swap requests.',
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    } else if (status == SwapRequestsStatus.loadedSent ||
        status == SwapRequestsStatus.loadedReceived) {
      return ListView.builder(
        itemCount: requests.length,
        itemBuilder: (context, index) {
          final request = requests[index];
          return SwapRequestListItem(
            request: request,
            isSentRequest: !isReceived, // Pass whether it's a sent request
          );
        },
      );
    }
    return const SizedBox.shrink(); // Fallback for initial state
  }
}
