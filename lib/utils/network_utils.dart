import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkUtils {
  static final Connectivity _connectivity = Connectivity();

  /// Check if device is connected to the internet
  static Future<bool> isConnected() async {
    final connectivityResult = await _connectivity.checkConnectivity();
    
    if (connectivityResult == ConnectivityResult.mobile ||
        connectivityResult == ConnectivityResult.wifi) {
      return true;
    }
    
    return false;
  }

  /// Listen to connectivity changes
  static Stream<ConnectivityResult> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged;
  }
}
