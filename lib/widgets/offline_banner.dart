import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../theme.dart';

/// A small banner at the top of the home screen that appears when the device
/// loses network connectivity and disappears when it comes back.
///
/// Uses `connectivity_plus` to listen for connectivity changes.
class OfflineBanner extends StatefulWidget {
  const OfflineBanner({super.key});

  @override
  State<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends State<OfflineBanner> {
  final _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _sub;
  bool _offline = false;

  @override
  void initState() {
    super.initState();
    _connectivity.checkConnectivity().then(_apply);
    _sub = _connectivity.onConnectivityChanged.listen(_apply);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _apply(List<ConnectivityResult> result) {
    final offline = result.every((r) => r == ConnectivityResult.none);
    if (mounted && offline != _offline) setState(() => _offline = offline);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      child: !_offline
          ? const SizedBox.shrink()
          : Container(
              width: double.infinity,
              color: MomentoTheme.deepPlum,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.cloud_off, size: 16, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    l.commonYouAreOffline,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ],
              ),
            ),
    );
  }
}
