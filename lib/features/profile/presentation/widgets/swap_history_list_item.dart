// lib/features/profile/presentation/widgets/swap_history_list_item.dart

import 'package:flutter/material.dart';
import 'package:swap_app/features/profile/domain/entities/swap_history_entity.dart'; // Import SwapHistoryEntity

/// A widget to display a single completed swap history item.
class SwapHistoryListItem extends StatelessWidget {
  final SwapHistoryEntity historyItem;

  const SwapHistoryListItem({super.key, required this.historyItem});

  @override
  Widget build(BuildContext context) {
    // Determine the other user involved in the swap
    // Note: We don't have the full UserEntity or PostEntity objects directly
    // in the SwapHistoryEntity fetched from Firestore. We would need to
    // fetch these separately or rely on data already available in the provider
    // or pass them down from the parent page if they were fetched there.
    // For now, we'll display basic info from the history item itself.
    // A more complete implementation would fetch/provide the full entities.

    // Example: Determine which post was yours and which was theirs based on user IDs
    // This requires knowing the current user's ID, which is not available in this widget.
    // A better approach is to fetch/provide the PostEntity objects in the provider
    // and pass them down to this widget.

    // Placeholder for displaying items and other user:
    // This is simplified. A real implementation would display actual item titles/images
    // and the other user's name/photo if those entities were populated.
    final String requestedItemTitle =
        historyItem.requestedPost?.title ?? 'Requested Item';
    final String offeredItemTitle =
        historyItem.offeringPost?.title ?? 'Offered Item';
    final String otherUserName =
        historyItem.requestingUserId == historyItem.requestedPostOwnerId
            ? 'Self Swap (Unlikely)' // Should not happen in a typical swap
            : (historyItem.requestingUser?.displayName ??
                historyItem.requestedPostOwner?.displayName ??
                'Another User');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      elevation: 1.0,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display the other user involved
            Text(
              'Swapped with: $otherUserName',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // Display the items involved
            Text(
              'Items:',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            const SizedBox(height: 4),
            // You could add InkWell here to navigate to PostDetailsPage for each item
            Text(
              '- Requested: ${requestedItemTitle.isNotEmpty ? requestedItemTitle : 'N/A'}',
            ),
            if (historyItem.offeringPostId != null)
              Text(
                '- Offered: ${offeredItemTitle.isNotEmpty ? offeredItemTitle : 'N/A'}',
              ),

            const SizedBox(height: 8),

            // Display completion date
            Text(
              'Completed On: ${historyItem.completedAt.toLocal().toString().split(' ')[0]}',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),

            // Add navigation to Post Details for involved items if entities are populated
            Row(
              children: [
                if (historyItem.requestedPost != null &&
                    historyItem.requestedPost!.id.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pushNamed(
                        '/post_details',
                        arguments: historyItem.requestedPost!.id,
                      );
                    },
                    child: const Text('View Requested Item'),
                  ),
                if (historyItem.offeringPost != null &&
                    historyItem.offeringPost!.id.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pushNamed(
                        '/post_details',
                        arguments: historyItem.offeringPost!.id,
                      );
                    },
                    child: const Text('View Offered Item'),
                  ),
              ],
            ),
            if (historyItem.requestedPost != null &&
                historyItem.requestedPost!.id.isNotEmpty)
              Align(
                alignment: Alignment.bottomRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).pushNamed(
                      '/post_details',
                      arguments: historyItem.requestedPost!.id,
                    );
                  },
                  child: const Text('View Requested Item'),
                ),
              ),
            if (historyItem.offeringPost != null &&
                historyItem.offeringPost!.id.isNotEmpty)
              Align(
                alignment: Alignment.bottomRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).pushNamed(
                      '/post_details',
                      arguments: historyItem.offeringPost!.id,
                    );
                  },
                  child: const Text('View Offered Item'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
