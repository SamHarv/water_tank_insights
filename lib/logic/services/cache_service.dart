import '../../data/models/monthly_rainfall_model.dart';
import '../../data/models/weather_data_model.dart';

class CacheService {
  // Private cache storage
  static final Map<String, CacheEntry> _cache = {};
  static const Duration _defaultTimeout = Duration(hours: 1);

  // Generic cache operations
  static bool isValid(String key, {Duration? timeout}) {
    final entry = _cache[key];
    if (entry == null) return false;
    final actualTimeout = timeout ?? _defaultTimeout;
    return DateTime.now().difference(entry.timestamp) < actualTimeout;
  }

  static void set(String key, dynamic data, {Duration? timeout}) {
    _cache[key] = CacheEntry(
      data: data,
      timestamp: DateTime.now(),
      timeout: timeout ?? _defaultTimeout,
    );
  }

  static T? get<T>(String key, {Duration? timeout}) {
    if (isValid(key, timeout: timeout)) {
      return _cache[key]?.data as T?;
    }
    return null;
  }

  static void remove(String key) {
    _cache.remove(key);
  }

  static void clear() {
    _cache.clear();
  }

  // Rainfall-specific cache keys
  static String weatherCacheKey(String postcode, int startYear, int endYear) {
    return 'weather_api_${postcode}_${startYear}_${endYear}';
  }

  static String monthlyRainfallCacheKey(String postcode, int year) {
    return 'monthly_rainfall_api_${postcode}_$year';
  }

  // Cache management for rainfall data
  static void cacheWeatherData(
    String postcode,
    int startYear,
    int endYear,
    List<WeatherData> data,
  ) {
    final key = weatherCacheKey(postcode, startYear, endYear);
    set(
      key,
      data,
      timeout: Duration(hours: 2),
    ); // Weather data can be cached longer
  }

  static List<WeatherData>? getCachedWeatherData(
    String postcode,
    int startYear,
    int endYear,
  ) {
    final key = weatherCacheKey(postcode, startYear, endYear);
    return get<List<WeatherData>>(key, timeout: Duration(hours: 2));
  }

  static void cacheMonthlyRainfall(
    String postcode,
    int year,
    List<MonthlyRainfall> data,
  ) {
    final key = monthlyRainfallCacheKey(postcode, year);
    set(
      key,
      data,
      timeout: Duration(hours: 6),
    ); // Monthly data can be cached even longer
  }

  static List<MonthlyRainfall>? getCachedMonthlyRainfall(
    String postcode,
    int year,
  ) {
    final key = monthlyRainfallCacheKey(postcode, year);
    return get<List<MonthlyRainfall>>(key, timeout: Duration(hours: 6));
  }
}

class CacheEntry {
  final dynamic data;
  final DateTime timestamp;
  final Duration timeout;

  CacheEntry({
    required this.data,
    required this.timestamp,
    required this.timeout,
  });
}
