import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// A widget that displays an offline indicator banner when there's no internet connection
///
/// This widget listens to connectivity changes and shows a persistent banner
/// at the top of the screen when the device is offline.
class OfflineIndicator extends StatefulWidget {
  final Widget child;

  const OfflineIndicator({
    super.key,
    required this.child,
  });

  @override
  State<OfflineIndicator> createState() => _OfflineIndicatorState();
}

class _OfflineIndicatorState extends State<OfflineIndicator> {
  bool _isOnline = true;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _checkInitialConnectivity();
    _listenToConnectivityChanges();
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  /// Check initial connectivity status
  Future<void> _checkInitialConnectivity() async {
    try {
      final result = await Connectivity().checkConnectivity();
      if (mounted) {
        setState(() {
          _isOnline = result.isNotEmpty && result.first != ConnectivityResult.none;
        });
      }
    } catch (e) {
      // Conservatively assume offline if connectivity check fails
      if (mounted) {
        setState(() {
          _isOnline = false;
        });
      }
    }
  }

  /// Listen to connectivity changes
  void _listenToConnectivityChanges() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      if (mounted) {
        setState(() {
          _isOnline = results.isNotEmpty && results.first != ConnectivityResult.none;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Show offline banner when offline
        if (!_isOnline)
          Material(
            color: Colors.red.shade700,
            elevation: 4,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.cloud_off,
                    color: Colors.white,
                    size: 16,
                    semanticLabel: 'Offline',
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'No internet connection',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Main content
        Expanded(child: widget.child),
      ],
    );
  }
}
