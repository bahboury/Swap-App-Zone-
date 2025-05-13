// lib/features/home/presentation/managers/swap_requests_provider.dart

import 'package:flutter/foundation.dart'; // For ChangeNotifier and kDebugMode
import 'package:swap_app/features/home/domain/entities/swap_request_entity.dart'; // <-- Use this import
import 'package:swap_app/features/home/domain/usecases/get_received_swap_requests_usecase.dart';
import 'package:swap_app/features/home/domain/usecases/get_sent_swap_requests_usecase.dart';
import 'package:swap_app/features/home/domain/usecases/update_swap_request_status_usecase.dart';
import 'package:swap_app/core/error/failurs.dart';
import 'package:swap_app/core/usecases/usecase.dart';

enum SwapRequestsStatus {
  initial,
  loadingSent,
  loadedSent,
  errorSent,
  emptySent,
  loadingReceived,
  loadedReceived,
  errorReceived,
  emptyReceived,
  updatingStatus, // NEW: Status for status update in progress
  statusUpdated, // NEW: Status for successful status update
  statusUpdateError, // NEW: Status for status update failure
}

class SwapRequestsProvider extends ChangeNotifier {
  final GetSentSwapRequestsUseCase _getSentSwapRequestsUseCase;
  final GetReceivedSwapRequestsUseCase _getReceivedSwapRequestsUseCase;
  final UpdateSwapRequestStatusUseCase
  _updateSwapRequestStatusUseCase; // NEW: Update use case

  SwapRequestsStatus _sentStatus = SwapRequestsStatus.initial;
  SwapRequestsStatus _receivedStatus = SwapRequestsStatus.initial;
  SwapRequestsStatus _updateStatus =
      SwapRequestsStatus.initial; // NEW: Status for update operations

  List<SwapRequestEntity> _sentRequests = [];
  List<SwapRequestEntity> _receivedRequests = [];

  String? _sentErrorMessage;
  String? _receivedErrorMessage;
  String? _updateErrorMessage; // NEW: Error message for update operations

  SwapRequestsProvider({
    required GetSentSwapRequestsUseCase getSentSwapRequestsUseCase,
    required GetReceivedSwapRequestsUseCase getReceivedSwapRequestsUseCase,
    required UpdateSwapRequestStatusUseCase
    updateSwapRequestStatusUseCase, // NEW: Inject update use case
  }) : _getSentSwapRequestsUseCase = getSentSwapRequestsUseCase,
       _getReceivedSwapRequestsUseCase = getReceivedSwapRequestsUseCase,
       _updateSwapRequestStatusUseCase =
           updateSwapRequestStatusUseCase; // NEW: Assign update use case

  // Getters
  SwapRequestsStatus get sentStatus => _sentStatus;
  SwapRequestsStatus get receivedStatus => _receivedStatus;
  SwapRequestsStatus get updateStatus =>
      _updateStatus; // NEW: Getter for update status

  List<SwapRequestEntity> get sentRequests => _sentRequests;
  List<SwapRequestEntity> get receivedRequests => _receivedRequests;

  String? get sentErrorMessage => _sentErrorMessage;
  String? get receivedErrorMessage => _receivedErrorMessage;
  String? get updateErrorMessage =>
      _updateErrorMessage; // NEW: Getter for update error message

  // Fetch sent swap requests
  Future<void> fetchSentSwapRequests(String userId) async {
    _sentStatus = SwapRequestsStatus.loadingSent;
    _sentErrorMessage = null;
    notifyListeners();

    if (userId.isEmpty) {
      _sentStatus = SwapRequestsStatus.errorSent;
      _sentErrorMessage = 'User not authenticated. Cannot fetch sent requests.';
      if (kDebugMode) {
        print('Error fetching sent requests: User ID is empty.');
      }
      notifyListeners();
      return;
    }

    final result = await _getSentSwapRequestsUseCase(NoParams());

    result.fold(
      (failure) {
        _sentStatus = SwapRequestsStatus.errorSent;
        _sentErrorMessage = _mapFailureToMessage(failure);
        if (kDebugMode) {
          print('Failed to fetch sent requests: ${failure.message}');
        }
      },
      (requests) {
        _sentRequests = requests.cast<SwapRequestEntity>();
        _sentStatus =
            requests.isEmpty
                ? SwapRequestsStatus.emptySent
                : SwapRequestsStatus.loadedSent;
        if (kDebugMode) {
          print('Fetched ${requests.length} sent requests.');
        }
      },
    );
    notifyListeners();
  }

  // Fetch received swap requests
  Future<void> fetchReceivedSwapRequests(String userId) async {
    _receivedStatus = SwapRequestsStatus.loadingReceived;
    _receivedErrorMessage = null;
    notifyListeners();

    if (userId.isEmpty) {
      _receivedStatus = SwapRequestsStatus.errorReceived;
      _receivedErrorMessage =
          'User not authenticated. Cannot fetch received requests.';
      if (kDebugMode) {
        print('Error fetching received requests: User ID is empty.');
      }
      notifyListeners();
      return;
    }

    final result = await _getReceivedSwapRequestsUseCase(NoParams());
    result.fold(
      (failure) {
        _receivedStatus = SwapRequestsStatus.errorReceived;
        _receivedErrorMessage = _mapFailureToMessage(failure);
        if (kDebugMode) {
          print('Failed to fetch received requests: ${failure.message}');
        }
      },
      (requests) {
        _receivedRequests = requests.cast<SwapRequestEntity>();
        _receivedStatus =
            requests.isEmpty
                ? SwapRequestsStatus.emptyReceived
                : SwapRequestsStatus.loadedReceived;
        if (kDebugMode) {
          print('Fetched ${requests.length} received requests.');
        }
      },
    );
    notifyListeners();
  }

  // NEW: Method to accept a swap request
  Future<void> acceptSwapRequest(String requestId) async {
    _updateStatus = SwapRequestsStatus.updatingStatus;
    _updateErrorMessage = null;
    notifyListeners();

    final result = await _updateSwapRequestStatusUseCase(
      UpdateSwapRequestStatusParams(
        requestId: requestId,
        status: SwapRequestStatus.accepted,
      ),
    );

    result.fold(
      (failure) {
        _updateStatus = SwapRequestsStatus.statusUpdateError;
        _updateErrorMessage = _mapFailureToMessage(failure);
        if (kDebugMode) {
          print('Failed to accept swap request $requestId: ${failure.message}');
        }
      },
      (_) {
        _updateStatus = SwapRequestsStatus.statusUpdated;
        // Optionally update the local list to reflect the status change immediately
        // This might involve finding the request by ID and changing its status
        _updateRequestStatusLocally(requestId, SwapRequestStatus.accepted);
        if (kDebugMode) {
          print('Swap request $requestId accepted successfully.');
        }
      },
    );
    notifyListeners();
  }

  // NEW: Method to decline a swap request
  Future<void> declineSwapRequest(String requestId) async {
    _updateStatus = SwapRequestsStatus.updatingStatus;
    _updateErrorMessage = null;
    notifyListeners();

    final result = await _updateSwapRequestStatusUseCase(
      UpdateSwapRequestStatusParams(
        requestId: requestId,
        status: SwapRequestStatus.declined,
      ),
    );

    result.fold(
      (failure) {
        _updateStatus = SwapRequestsStatus.statusUpdateError;
        _updateErrorMessage = _mapFailureToMessage(failure);
        if (kDebugMode) {
          print(
            'Failed to decline swap request $requestId: ${failure.message}',
          );
        }
      },
      (_) {
        _updateStatus = SwapRequestsStatus.statusUpdated;
        // Optionally update the local list to reflect the status change immediately
        _updateRequestStatusLocally(requestId, SwapRequestStatus.declined);
        if (kDebugMode) {
          print('Swap request $requestId declined successfully.');
        }
      },
    );
    notifyListeners();
  }

  // NEW: Helper to update status in local lists
  void _updateRequestStatusLocally(String requestId, SwapRequestStatus status) {
    // Find and update in received requests
    final receivedIndex = _receivedRequests.indexWhere(
      (req) => req.id == requestId,
    );
    if (receivedIndex != -1) {
      final updatedRequest = _receivedRequests[receivedIndex].copyWith(
        status: status,
      );
      _receivedRequests[receivedIndex] = updatedRequest;
    }

    // Find and update in sent requests (less common to update sent status locally this way,
    // but included for completeness if your UI needs it)
    final sentIndex = _sentRequests.indexWhere((req) => req.id == requestId);
    if (sentIndex != -1) {
      final updatedRequest = _sentRequests[sentIndex].copyWith(status: status);
      _sentRequests[sentIndex] = updatedRequest;
    }

    notifyListeners(); // Notify after local list update
  }

  // Helper function to map failures to user-friendly messages
  String _mapFailureToMessage(Failure failure) {
    if (failure is ServerFailure) {
      return failure.message;
    } else if (failure is NetworkFailure) {
      return 'No internet connection. Please check your network settings.';
    }
    // Add other specific failure types if needed
    else {
      return 'An unexpected error occurred. Please try again.';
    }
  }

  // Method to reset the update status, useful after showing feedback
  void resetUpdateStatus() {
    _updateStatus = SwapRequestsStatus.initial;
    _updateErrorMessage = null;
    notifyListeners();
  }

  // Method to refresh both sent and received lists
  Future<void> refreshSwapRequests(String userId) async {
    await fetchSentSwapRequests(userId);
    await fetchReceivedSwapRequests(userId);
  }
}
