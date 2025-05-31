import '../api/rainfall_api.dart';

class DatabaseService {
  /// [DatabaseService] to access API data

  // Singleton
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  // Cache for storing weather data locally
  static final Map<String, CacheEntry> _cache = {};
  static const Duration _cacheTimeout = Duration(hours: 1);

  // Check whether cache is still valid
  static bool _isCacheValid(String key) {
    final entry = _cache[key];
    if (entry == null) return false;
    return DateTime.now().difference(entry.timestamp) < _cacheTimeout;
  }

  // Set cache
  static void _setCache(String key, dynamic data) {
    _cache[key] = CacheEntry(data: data, timestamp: DateTime.now());
  }

  // Get cache
  static T? _getCache<T>(String key) {
    if (_isCacheValid(key)) {
      return _cache[key]?.data as T?;
    }
    return null;
  }

  // Get weather data using Rainfall API
  Future<List<WeatherData>> getWeatherByPostcode({
    required String postcode,
    required DateTime startDate,
    required DateTime endDate,
    int? limit, // Optional - limit number of data points
    bool useCache = true,
  }) async {
    // Cache key for weather data
    final cacheKey =
        'weather_api_${postcode}_${startDate.year}_${endDate.year}';

    // Check cache
    if (useCache) {
      final cached = _getCache<List<WeatherData>>(cacheKey);
      if (cached != null) {
        // Filter cached data by date range
        return cached
            .where(
              (data) =>
                  data.date.isAfter(startDate.subtract(Duration(days: 1))) &&
                  data.date.isBefore(endDate.add(Duration(days: 1))),
            )
            .toList();
      }
    }

    try {
      // Initialise list to hold all weather data
      final List<WeatherData> allWeatherData = [];

      // Get data year by year to avoid overwhelming the API
      for (int year = startDate.year; year <= endDate.year; year++) {
        try {
          // Get rainfall data using API
          final rainfallRecords = await RainfallApiService.getRainfallData(
            postcode: postcode,
            year: year,
          );

          // Convert rainfall records to daily weather data
          for (final record in rainfallRecords) {
            allWeatherData.addAll(record.toDailyWeatherData());
          }

          // Add small delay to avoid overwhelming the API
          await Future.delayed(Duration(milliseconds: 100));
        } catch (e) {
          throw Exception('Failed to fetch weather data from API: $e');
        }
      }

      // Filter by actual date range
      final filteredData =
          allWeatherData
              .where(
                (data) =>
                    data.date.isAfter(startDate.subtract(Duration(days: 1))) &&
                    data.date.isBefore(endDate.add(Duration(days: 1))),
              )
              .toList();

      // Sort by date
      filteredData.sort((a, b) => a.date.compareTo(b.date));

      // Apply limit if specified
      final limitedData =
          limit != null && filteredData.length > limit
              ? filteredData.take(limit).toList()
              : filteredData;

      // Cache the result
      if (useCache && allWeatherData.isNotEmpty) {
        _setCache(cacheKey, allWeatherData);
      }

      return limitedData;
    } catch (e) {
      throw Exception('Failed to fetch weather data from API: $e');
    }
  }

  // Get monthly rainfall using API data
  Future<List<MonthlyRainfall>> getMonthlyRainfall({
    required String postcode,
    required int year,
    bool useCache = true,
  }) async {
    // Enforce 50-year limit
    if (year < 1975 || year > 2025) {
      return List.generate(
        12,
        (index) => MonthlyRainfall(month: index + 1, totalRainfall: 0),
      );
    }

    // Cache key
    final cacheKey = 'monthly_rainfall_api_${postcode}_$year';

    // Check cache
    if (useCache) {
      final cached = _getCache<List<MonthlyRainfall>>(cacheKey);
      if (cached != null) return cached;
    }

    try {
      // Get rainfall data from API
      final rainfallRecords = await RainfallApiService.getRainfallData(
        postcode: postcode,
        year: year,
      );

      // Group by month
      Map<int, double> monthlyTotals = {};
      for (final record in rainfallRecords) {
        if (record.year == year) {
          monthlyTotals[record.month] =
              (monthlyTotals[record.month] ?? 0) + record.rainfall;
        }
      }

      // Convert to list for all 12 months
      final monthlyData = List.generate(12, (index) {
        final month = index + 1;
        return MonthlyRainfall(
          month: month,
          totalRainfall: monthlyTotals[month] ?? 0,
        );
      });

      // Cache the result
      if (useCache) {
        _setCache(cacheKey, monthlyData);
      }

      return monthlyData;
    } catch (e) {
      // Return empty data on error
      return List.generate(
        12,
        (index) => MonthlyRainfall(month: index + 1, totalRainfall: 0),
      );
    }
  }

  // Get annual rainfall using API data
  Future<double> getAnnualRainfall({
    required String postcode,
    required int year,
    bool useCache = true,
  }) async {
    try {
      // Get monthly data using API
      final monthlyData = await getMonthlyRainfall(
        postcode: postcode,
        year: year,
        useCache: useCache,
      );

      // Sum total rainfall for year
      return monthlyData.map((d) => d.totalRainfall).reduce((a, b) => a + b);
    } catch (e) {
      return 0.0;
    }
  }

  // TODO: delete this if all is working
  // // Get available postcodes (now using hardcoded + API fallback)
  // Future<List<PostcodeInfo>> getAvailablePostcodes({
  //   bool useCache = true,
  // }) async {
  //   try {
  //     // Try to get from API first
  //     final apiPostcodes = await RainfallApiService.getAvailablePostcodes();
  //     print("Success!");
  //     return apiPostcodes.map((pc) => PostcodeInfo(postcode: pc)).toList();
  //   } catch (e) {
  //     // Fallback to hardcoded postcodes
  //     print('API postcodes failed, using hardcoded: $e');
  //     return PostcodesService.getAvailablePostcodeInfos();
  //   }
  // }
}

class CacheEntry {
  /// [CacheEntry] class to hold data and timestamp
  final dynamic data;
  final DateTime timestamp;

  CacheEntry({required this.data, required this.timestamp});
}

class WeatherData {
  /// [WeatherData] class to hold data for a single day
  final String postcode;
  final DateTime date;
  final double rainfall;
  final double temperature;

  WeatherData({
    required this.postcode,
    required this.date,
    required this.rainfall,
    required this.temperature,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      postcode: json['postcode'],
      date: DateTime.parse(json['date']),
      rainfall: (json['rainfall'] as num).toDouble(),
      temperature: (json['temperature'] as num).toDouble(),
    );
  }
}

class MonthlyRainfall {
  /// [MonthlyRainfall] class to hold data for a single month
  final int month;
  final double totalRainfall;

  MonthlyRainfall({required this.month, required this.totalRainfall});

  String get monthName {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  @override
  String toString() =>
      'MonthlyRainfall(month: $month, totalRainfall: $totalRainfall)';
}
