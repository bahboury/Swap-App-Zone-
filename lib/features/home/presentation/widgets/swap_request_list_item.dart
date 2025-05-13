// lib/features/home/presentation/widgets/swap_request_list_item.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:swap_app/features/home/domain/entities/swap_request_entity.dart'; // Import SwapRequestEntity
import 'package:swap_app/features/home/domain/entities/post_entity.dart'; // Import PostEntity (for displaying item details)
import 'package:swap_app/features/auth/domain/entities/user_entity.dart'; // Import UserEntity (for displaying user details)

/// A widget to display a single swap request item in a list.
class SwapRequestListItem extends StatefulWidget {
  final SwapRequestEntity request;
  final bool
  isSentRequest; // True if this item represents a request sent by the current user
  // Callbacks for actions - these will trigger the provider methods
  final ValueChanged<String>? onAccept;
  final ValueChanged<String>? onReject;
  final ValueChanged<String>? onCancel;

  const SwapRequestListItem({
    super.key,
    required this.request,
    required this.isSentRequest,
    this.onAccept,
    this.onReject,
    this.onCancel,
  });

  @override
  State<SwapRequestListItem> createState() => _SwapRequestListItemState();
}

class _SwapRequestListItemState extends State<SwapRequestListItem> {
  bool _isUpdatingStatus =
      false; // State to track if this specific item is being updated

  // Helper function to handle status updates and manage local loading state
  Future<void> _handleStatusUpdate(SwapRequestStatus status) async {
    if (_isUpdatingStatus) return; // Prevent multiple taps

    setState(() {
      _isUpdatingStatus = true;
    });

    // Call the appropriate callback based on the status
    if (status == SwapRequestStatus.accepted && widget.onAccept != null) {
      widget.onAccept!(widget.request.id);
    } else if (status == SwapRequestStatus.rejected &&
        widget.onReject != null) {
      widget.onReject!(widget.request.id);
    } else if (status == SwapRequestStatus.cancelled &&
        widget.onCancel != null) {
      widget.onCancel!(widget.request.id);
    }

    // Note: The provider will handle the actual status update and refreshing the list.
    // We don't need to reset _isUpdatingStatus here immediately because the provider
    // will notify listeners, causing the parent page to rebuild, which will
    // create new SwapRequestListItem widgets with _isUpdatingStatus = false.
    // If the provider didn't refresh the list, we would need a mechanism
    // to listen for the provider's status change and reset _isUpdatingStatus.
  }

  @override
  Widget build(BuildContext context) {
    // Determine the status text and color
    Color statusColor = Colors.grey;
    String statusText = 'Status: ';
    switch (widget.request.status) {
      case SwapRequestStatus.pending:
        statusText += 'Pending';
        statusColor = Colors.orange;
        break;
      case SwapRequestStatus.accepted:
        statusText += 'Accepted';
        statusColor = Colors.green;
        break;
      case SwapRequestStatus.rejected:
        statusText += 'Rejected';
        statusColor = Colors.red;
        break;
      case SwapRequestStatus.cancelled:
        statusText += 'Cancelled';
        statusColor = Colors.blueGrey;
        break;
      case SwapRequestStatus.completed:
        statusText += 'Completed';
        statusColor = Colors.teal;
        break;
      case SwapRequestStatus.declined:
        statusText += 'Declined';
        statusColor = Colors.purple;
        break;
    }

    // Determine which item is "yours" and which is "theirs" based on isSentRequest
    final PostEntity? _ =
        widget.isSentRequest
            ? widget.request.offeringPost
            : widget.request.requestedPost;
    final PostEntity? _ =
        widget.isSentRequest
            ? widget.request.requestedPost
            : widget.request.offeringPost;

    // Determine which user is "yours" and which is "theirs"
    final UserEntity? _ =
        widget.isSentRequest
            ? widget.request.requestingUser
            : widget.request.requestedPostOwner;
    final UserEntity? theirUser =
        widget.isSentRequest
            ? widget.request.requestedPostOwner
            : widget.request.requestingUser;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 2.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display who the request is with
            Text(
              widget.isSentRequest
                  ? 'Request Sent to:'
                  : 'Request Received from:',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            const SizedBox(height: 4),
            // Display the other user's name (if available)
            Text(
              theirUser?.displayName ?? 'Unknown User',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Display the requested item
            Text(
              widget.isSentRequest ? 'Item Requested:' : 'Your Item:',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            const SizedBox(height: 4),
            _buildItemDetails(
              context,
              widget.request.requestedPost,
              'Requested Item',
            ), // Always show details of the requested post
            const SizedBox(height: 12),

            // Display the offered item (if any)
            if (widget.request.offeringPost != null) ...[
              Text(
                widget.isSentRequest
                    ? 'Item Offered:'
                    : 'Item Offered by Them:',
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
              const SizedBox(height: 4),
              _buildItemDetails(
                context,
                widget.request.offeringPost,
                'Offered Item',
              ), // Show details of the offered post
              const SizedBox(height: 12),
            ],

            // Display Status and Date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
                Text(
                  'on ${widget.request.createdAt.toLocal().toString().split(' ')[0]}',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Action Buttons based on request type and status
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  /// Helper widget to display item details with image and title.
  Widget _buildItemDetails(
    BuildContext context,
    PostEntity? item,
    String fallbackTitle,
  ) {
    if (item == null) {
      return Text(
        'Item details not available for $fallbackTitle.',
        style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
      );
    }
    return InkWell(
      onTap: () {
        // Navigate to the Post Details page for this item
        if (item.id.isNotEmpty) {
          Navigator.of(context).pushNamed('/post_details', arguments: item.id);
        } else {
          // Handle case where item ID is missing (shouldn't happen if data is structured correctly)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Item details not available.')),
          );
        }
      },
      child: Row(
        children: [
          // Display item image (or placeholder)
          Container(
            width: 60,
            height: 60,
            margin: const EdgeInsets.only(right: 12.0),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(8.0),
              image:
                  item.imageUrls.isNotEmpty
                      ? DecorationImage(
                        image: NetworkImage(item.imageUrls.first),
                        fit: BoxFit.cover,
                        onError: (exception, stackTrace) {
                          // Handle image loading errors
                          if (kDebugMode) {
                            print('Error loading image: $exception');
                          }
                        },
                      )
                      : null,
            ),
            child:
                item.imageUrls.isEmpty
                    ? const Icon(
                      Icons.image_not_supported,
                      size: 30,
                      color: Colors.grey,
                    )
                    : null,
          ),
          // Display item title
          Expanded(
            child: Text(
              item.title.isNotEmpty ? item.title : fallbackTitle,
              style: const TextStyle(fontSize: 16),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds action buttons based on request type and status.
  Widget _buildActionButtons(BuildContext context) {
    // Only show buttons if the status is pending
    if (widget.request.status == SwapRequestStatus.pending) {
      if (widget.isSentRequest) {
        // Buttons for a request sent by the current user
        return Align(
          alignment: Alignment.bottomRight,
          child: ElevatedButton(
            // Disable button while updating or if onCancel is null
            onPressed:
                (_isUpdatingStatus || widget.onCancel == null)
                    ? null
                    : () => _handleStatusUpdate(SwapRequestStatus.cancelled),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child:
                _isUpdatingStatus
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                    : const Text(
                      'Cancel Request',
                      style: TextStyle(color: Colors.white),
                    ),
          ),
        );
      } else {
        // Buttons for a request received by the current user
        return Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            OutlinedButton(
              // Disable button while updating or if onReject is null
              onPressed:
                  (_isUpdatingStatus || widget.onReject == null)
                      ? null
                      : () => _handleStatusUpdate(SwapRequestStatus.rejected),
              style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
              child:
                  _isUpdatingStatus &&
                          widget.request.status ==
                              SwapRequestStatus
                                  .rejected // Only show loading for the specific action being taken
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.red,
                        ),
                      )
                      : const Text('Reject'),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              // Disable button while updating or if onAccept is null
              onPressed:
                  (_isUpdatingStatus || widget.onAccept == null)
                      ? null
                      : () => _handleStatusUpdate(SwapRequestStatus.accepted),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child:
                  _isUpdatingStatus &&
                          widget.request.status ==
                              SwapRequestStatus
                                  .accepted // Only show loading for the specific action being taken
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                      : const Text(
                        'Accept',
                        style: TextStyle(color: Colors.white),
                      ),
            ),
          ],
        );
      }
    } else {
      // No buttons needed for non-pending statuses
      return const SizedBox.shrink();
    }
  }
}
