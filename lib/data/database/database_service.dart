// lib/logic/services/database_service.dart
// Updated to use API instead of Supabase

import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../../logic/services/postcode_service.dart';
import '../api/rainfall_api.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  // Cache for storing data locally
  static final Map<String, CacheEntry> _cache = {};
  static const Duration _cacheTimeout = Duration(
    hours: 1,
  ); // Shorter cache for API data

  // Cache management
  static bool _isCacheValid(String key) {
    final entry = _cache[key];
    if (entry == null) return false;
    return DateTime.now().difference(entry.timestamp) < _cacheTimeout;
  }

  static void _setCache(String key, dynamic data) {
    _cache[key] = CacheEntry(data: data, timestamp: DateTime.now());
  }

  static T? _getCache<T>(String key) {
    if (_isCacheValid(key)) {
      return _cache[key]?.data as T?;
    }
    return null;
  }

  // Get weather data using API
  Future<List<WeatherData>> getWeatherByPostcode({
    required String postcode,
    required DateTime startDate,
    required DateTime endDate,
    int? limit,
    bool useCache = true,
  }) async {
    final cacheKey =
        'weather_api_${postcode}_${startDate.year}_${endDate.year}';

    // Check cache first
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
      final List<WeatherData> allWeatherData = [];

      // Get data year by year to avoid overwhelming the API
      for (int year = startDate.year; year <= endDate.year; year++) {
        try {
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
          print('Failed to get data for $postcode year $year: $e');
          // Continue with next year
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

    final cacheKey = 'monthly_rainfall_api_${postcode}_$year';

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

      if (useCache) {
        _setCache(cacheKey, monthlyData);
      }

      return monthlyData;
    } catch (e) {
      print('Failed to get monthly rainfall from API: $e');
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
      final monthlyData = await getMonthlyRainfall(
        postcode: postcode,
        year: year,
        useCache: useCache,
      );

      return monthlyData.map((d) => d.totalRainfall).reduce((a, b) => a + b);
    } catch (e) {
      print('Failed to get annual rainfall: $e');
      return 0.0;
    }
  }

  // Get available postcodes (now using hardcoded + API fallback)
  Future<List<PostcodeInfo>> getAvailablePostcodes({
    bool useCache = true,
  }) async {
    try {
      // Try to get from API first
      final apiPostcodes = await RainfallApiService.getAvailablePostcodes();
      return apiPostcodes.map((pc) => PostcodeInfo(postcode: pc)).toList();
    } catch (e) {
      // Fallback to hardcoded postcodes
      print('API postcodes failed, using hardcoded: $e');
      return PostcodesService.getAvailablePostcodeInfos();
    }
  }

  // Calculate water depletion forecast using API data
  Future<List<WaterForecast>> calculateWaterDepletion({
    required String postcode,
    required double currentInventory,
    required double dailyUsage,
    required double roofCatchmentArea,
    required double otherDailyIntake,
    required int forecastDays,
    String rainfallPattern = '10-year average',
    bool useCache = true,
  }) async {
    final cacheKey =
        'water_forecast_api_${postcode}_${rainfallPattern}_${forecastDays}';

    if (useCache) {
      final cached = _getCache<List<WaterForecast>>(cacheKey);
      if (cached != null) return cached;
    }

    try {
      final now = DateTime.now();
      List<WaterForecast> forecast = [];
      double waterLevel = currentInventory;

      // Get historical data for pattern calculation
      Map<int, double> dailyAverages = {};

      if (rainfallPattern != 'No rain') {
        try {
          // Get last 3 years of data for pattern calculation
          final historicalData = await getWeatherByPostcode(
            postcode: postcode,
            startDate: DateTime(now.year - 3, 1, 1),
            endDate: now,
            useCache: useCache,
          );

          if (historicalData.isNotEmpty) {
            // Calculate daily averages
            Map<int, List<double>> dailyRainfalls = {};

            for (var data in historicalData) {
              final dayOfYear =
                  data.date.difference(DateTime(data.date.year, 1, 1)).inDays;
              dailyRainfalls[dayOfYear] ??= [];
              dailyRainfalls[dayOfYear]!.add(data.rainfall);
            }

            dailyRainfalls.forEach((day, rainfalls) {
              dailyAverages[day] =
                  rainfalls.reduce((a, b) => a + b) / rainfalls.length;
            });
          }
        } catch (e) {
          print('Failed to get historical data for forecast: $e');
        }
      }

      // Generate forecast
      for (int day = 0; day <= forecastDays; day++) {
        final currentDate = now.add(Duration(days: day));
        final dayOfYear =
            currentDate.difference(DateTime(currentDate.year, 1, 1)).inDays;

        double expectedRainfall = 0;
        if (rainfallPattern != 'No rain' && dailyAverages.isNotEmpty) {
          expectedRainfall = dailyAverages[dayOfYear % 365] ?? 0;
        }

        double rainwaterCollected = expectedRainfall * roofCatchmentArea * 0.8;
        double dailyIntake = rainwaterCollected + otherDailyIntake;
        double netChange = dailyIntake - dailyUsage;

        waterLevel = (waterLevel + netChange).clamp(0, double.infinity);

        forecast.add(
          WaterForecast(
            date: currentDate,
            waterLevel: waterLevel,
            rainfall: expectedRainfall,
            intake: dailyIntake,
            usage: dailyUsage,
          ),
        );

        if (waterLevel <= 0) break;
      }

      if (useCache) {
        _setCache(cacheKey, forecast);
      }

      return forecast;
    } catch (e) {
      throw Exception('Failed to calculate water depletion: $e');
    }
  }

  // Get weather statistics using API data
  Future<WeatherStats> getWeatherStats({
    required String postcode,
    required DateTime startDate,
    required DateTime endDate,
    bool useCache = true,
  }) async {
    try {
      final weatherData = await getWeatherByPostcode(
        postcode: postcode,
        startDate: startDate,
        endDate: endDate,
        useCache: useCache,
      );

      if (weatherData.isEmpty) {
        return WeatherStats(
          avgRainfall: 0,
          maxRainfall: 0,
          minRainfall: 0,
          totalRainfall: 0,
          avgTemperature: 0,
          maxTemperature: 0,
          minTemperature: 0,
          dataPoints: 0,
        );
      }

      final rainfalls = weatherData.map((d) => d.rainfall).toList();
      final temperatures = weatherData.map((d) => d.temperature).toList();

      return WeatherStats(
        avgRainfall: rainfalls.reduce((a, b) => a + b) / rainfalls.length,
        maxRainfall: rainfalls.reduce((a, b) => a > b ? a : b),
        minRainfall: rainfalls.reduce((a, b) => a < b ? a : b),
        totalRainfall: rainfalls.reduce((a, b) => a + b),
        avgTemperature:
            temperatures.reduce((a, b) => a + b) / temperatures.length,
        maxTemperature: temperatures.reduce((a, b) => a > b ? a : b),
        minTemperature: temperatures.reduce((a, b) => a < b ? a : b),
        dataPoints: weatherData.length,
      );
    } catch (e) {
      throw Exception('Failed to fetch weather statistics: $e');
    }
  }

  // Cache management
  static void clearCache() {
    _cache.clear();
  }

  static void clearExpiredCache() {
    final now = DateTime.now();
    _cache.removeWhere(
      (key, entry) => now.difference(entry.timestamp) > _cacheTimeout,
    );
  }
}

// Cache entry class
class CacheEntry {
  final dynamic data;
  final DateTime timestamp;

  CacheEntry({required this.data, required this.timestamp});
}

// Keep the existing model classes but ensure they're here
class WeatherData {
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
}

class WaterForecast {
  final DateTime date;
  final double waterLevel;
  final double rainfall;
  final double intake;
  final double usage;

  WaterForecast({
    required this.date,
    required this.waterLevel,
    required this.rainfall,
    required this.intake,
    required this.usage,
  });
}

class WeatherStats {
  final double avgRainfall;
  final double maxRainfall;
  final double minRainfall;
  final double totalRainfall;
  final double avgTemperature;
  final double maxTemperature;
  final double minTemperature;
  final int dataPoints;

  WeatherStats({
    required this.avgRainfall,
    required this.maxRainfall,
    required this.minRainfall,
    required this.totalRainfall,
    required this.avgTemperature,
    required this.maxTemperature,
    required this.minTemperature,
    required this.dataPoints,
  });
}
