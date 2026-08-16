import 'package:i_cant_cook/api/api_helper.dart';
import 'package:i_cant_cook/models/home_feed/home_feed.dart';
import 'package:i_cant_cook/models/mood/mood.dart';

class HomeApi {
  final ApiHelper _apiHelper = ApiHelper();

  /// Fetches the home feed for the given local time, weekday, and optional mood.
  /// Computes daypart and weekend flag from local DateTime.now() on device.
  /// Weekday conversion: Dart weekday is 1=Mon..7=Sun → 0..6 for API.
  Future<HomeFeed?> fetchHomeFeed({Mood? mood, double? lat, double? lng}) async {
    try {
      final now = DateTime.now();
      final hour = now.hour;
      final dartWeekday = now.weekday; // 1=Mon, 7=Sun
      final apiWeekday = (dartWeekday - 1) % 7; // 0=Mon, 6=Sun

      final queryParams = <String, String>{
        'local_hour': hour.toString(),
        'weekday': apiWeekday.toString(),
        if (mood != null) 'mood': mood.wireValue,
        // Device location powers the "deals near you" module (auto, no prompt).
        if (lat != null && lng != null) 'lat': lat.toString(),
        if (lat != null && lng != null) 'lng': lng.toString(),
      };

      final response = await _apiHelper.getRequest(
        'home/feed/',
        queryParams: queryParams,
      );

      if (response == null) return null;

      return HomeFeed.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      print('HomeFeed fetch error: $e');
      return null;
    }
  }
}
