import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:injectable/injectable.dart';

/// Thin wrapper over connectivity_plus so the rest of the app can ask
/// "are we online?" without pulling the connectivity API directly.
///
/// The `onConnected` stream filters down to "went from no-network to
/// has-network" transitions — what `SyncManager` cares about. Cellular,
/// wifi, and Ethernet all count as "connected" — VPN does too (we don't
/// need to inspect the bearer).
@lazySingleton
class NetworkInfo {
  NetworkInfo(this._connectivity);

  final Connectivity _connectivity;

  Future<bool> get isConnected async {
    final results = await _connectivity.checkConnectivity();
    return _hasNetwork(results);
  }

  /// Stream of connectivity state changes. Each event is a boolean —
  /// `true` when at least one transport is connected.
  Stream<bool> get connectivityChanges =>
      _connectivity.onConnectivityChanged.map(_hasNetwork);

  /// Filtered stream that only fires when the device transitions from
  /// no-network to has-network. Useful for "we just came back online,
  /// drain the sync queue" hooks.
  Stream<void> get onConnected {
    var wasOnline = false;
    return connectivityChanges
        .where((online) {
          final justCame = online && !wasOnline;
          wasOnline = online;
          return justCame;
        })
        .map((_) {});
  }

  bool _hasNetwork(List<ConnectivityResult> results) {
    return results.any(
      (r) => r != ConnectivityResult.none && r != ConnectivityResult.bluetooth,
    );
  }
}
