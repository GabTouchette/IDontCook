import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class NetworkService {
  static const String _cachedIpKey = 'cached_local_ip';
  static const String _prodBaseUrl =
      'https://api.idontcook.app';
  static const bool _useProd = false; // Set to true for production
  static const int _defaultPort = 8000;

  static String? _cachedLocalIp;

  /// Gets the appropriate base URL based on environment
  static Future<String> getBaseUrl() async {
    if (_useProd) {
      return _prodBaseUrl;
    }

    final localIp = await getLocalIpAddress();
    return 'http://$localIp:$_defaultPort';
  }

  /// Discovers and returns the local IP address
  static Future<String> getLocalIpAddress() async {
    // Return cached IP if available
    if (_cachedLocalIp != null) {
      return _cachedLocalIp!;
    }

    // Try to get from SharedPreferences cache
    final cachedIp = await _getCachedIp();
    if (cachedIp != null && await _isIpReachable(cachedIp)) {
      _cachedLocalIp = cachedIp;
      return cachedIp;
    }

    // Discover new IP address
    final discoveredIp = await _discoverLocalIp();
    if (discoveredIp != null) {
      _cachedLocalIp = discoveredIp;
      await _setCachedIp(discoveredIp);
      return discoveredIp;
    }

    // Fallback to localhost (dev default)
    _cachedLocalIp = 'localhost';
    return 'localhost';
  }

  /// Discovers local IP by checking network interfaces
  static Future<String?> _discoverLocalIp() async {
    try {
      // Get all network interfaces (device IPs)
      final interfaces = await NetworkInterface.list(
        includeLoopback: false,
        type: InternetAddressType.IPv4,
      );

      // Build candidate list from subnets around device IPs
      final Set<String> candidateIps = {};
      
      // Add specific known IP address first
      candidateIps.add('192.168.0.21');
      
      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          final ip = addr.address;
          print('Found network interface IP: $ip'); // Debug logging
          if (!_isPrivateIp(ip)) continue;
          final parts = ip.split('.');
          if (parts.length != 4) continue;
          final prefix = '${parts[0]}.${parts[1]}.${parts[2]}.';
          final host = int.tryParse(parts[3]) ?? 0;
          // Prioritize nearby hosts
          final nearby = <int>{
            host,
            host - 1,
            host - 2,
            host - 3,
            host - 4,
            host - 5,
            host + 1,
            host + 2,
            host + 3,
            host + 4,
            host + 5
          }.where((h) => h > 0 && h < 255);
          for (final h in nearby) {
            candidateIps.add('$prefix$h');
          }
          // Common host candidates
          for (final h in const [
            2,
            10,
            20,
            21, // Added for 192.168.0.21
            30,
            40,
            50,
            60,
            70,
            80,
            90,
            100,
            101,
            110,
            120,
            150,
            200
          ]) {
            candidateIps.add('$prefix$h');
          }
        }
      }

      // Try cached IP first if present
      final cachedIp = await _getCachedIp();
      if (cachedIp != null) candidateIps.add(cachedIp);

      // Attempt HTTP reachability (fast)
      final httpHit =
          await resolveLocalIp(candidateIps.toList(), port: _defaultPort);
      if (httpHit != null && httpHit.isNotEmpty) {
        print('Discovered local server via HTTP: $httpHit');
        return httpHit;
      }

      // Fallback: quick socket probe of nearby hosts
      for (final ip in candidateIps) {
        if (await _isIpReachable(ip)) {
          print('Discovered local server via TCP: $ip');
          return ip;
        }
      }
    } catch (e) {
      print('Error discovering local IP: $e');
    }

    return null;
  }

  /// Checks if an IP address is reachable on the expected port
  static Future<bool> _isIpReachable(String ip) async {
    try {
      final socket = await Socket.connect(
        ip,
        _defaultPort,
        timeout: const Duration(seconds: 2),
      );
      socket.destroy();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Checks if an IP is in private range
  static bool _isPrivateIp(String ip) {
    if (ip.startsWith('10.')) return true;
    if (ip.startsWith('192.168.')) return true;
    if (ip.startsWith('172.')) {
      final parts = ip.split('.');
      if (parts.length > 1) {
        final second = int.tryParse(parts[1]) ?? -1;
        return second >= 16 && second <= 31;
      }
    }
    return false;
  }

  /// Try a list of candidate IPs with a quick HTTP GET on the given port.
  /// Returns the first reachable IP or null.
  static Future<String?> resolveLocalIp(List<String> candidateIps,
      {int? port}) async {
    final p = port ?? _defaultPort;
    for (final ip in candidateIps) {
      final url = Uri.parse('http://$ip:$p');
      try {
        await http.get(url).timeout(const Duration(seconds: 1));
        print('✅ Reachable IP: $ip');
        return ip;
      } catch (_) {
        print('❌ IP $ip is not reachable.');
      }
    }
    print('⚠️ No reachable IP found. Defaulting to localhost.');
    return null;
  }

  /// Gets cached IP from SharedPreferences
  static Future<String?> _getCachedIp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_cachedIpKey);
    } catch (e) {
      print('Error getting cached IP: $e');
      return null;
    }
  }

  /// Saves IP to SharedPreferences cache
  static Future<void> _setCachedIp(String ip) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cachedIpKey, ip);
    } catch (e) {
      print('Error caching IP: $e');
    }
  }

  /// Forces a refresh of the local IP address
  static Future<String> refreshLocalIp() async {
    _cachedLocalIp = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cachedIpKey);
    return await getLocalIpAddress();
  }

  /// Manually set a local IP (useful for debugging)
  static Future<void> setManualIp(String ip) async {
    _cachedLocalIp = ip;
    await _setCachedIp(ip);
  }

  /// Clear cached IP and force rediscovery
  static Future<void> clearCache() async {
    _cachedLocalIp = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cachedIpKey);
  }
  
  /// Force set the correct IP address (for debugging network issues)
  static Future<void> forceSetCorrectIp() async {
    const correctIp = '192.168.0.21';
    print('🔧 Forcing IP to: $correctIp');
    await setManualIp(correctIp);
  }
}
