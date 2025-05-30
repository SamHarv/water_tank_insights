// lib/logic/services/rainfall_api_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:math';

import '../../logic/services/postcode_service.dart';
import '../database/database_service.dart';

class RainfallApiService {
  static const String _baseUrl = 'https://rainfall-api-3mlh.onrender.com';
  static const Duration _timeout = Duration(seconds: 30);

  // Get rainfall data for a specific postcode
  static Future<List<RainfallRecord>> getRainfallData({
    required String postcode,
    int? year,
    int? month,
  }) async {
    try {
      if (kIsWeb) {
        return await _getRainfallDataWeb(
          postcode: postcode,
          year: year,
          month: month,
        );
      } else {
        return await _getRainfallDataNative(
          postcode: postcode,
          year: year,
          month: month,
        );
      }
    } catch (e) {
      print('Error fetching rainfall data: $e');
      throw RainfallApiException('Failed to fetch rainfall data: $e');
    }
  }

  // Native app version (no CORS issues)
  static Future<List<RainfallRecord>> _getRainfallDataNative({
    required String postcode,
    int? year,
    int? month,
  }) async {
    final client = http.Client();

    try {
      // Build query parameters
      final queryParams = <String, String>{'postcode': postcode};
      if (year != null) queryParams['year'] = year.toString();
      if (month != null) queryParams['month'] = month.toString();

      final uri = Uri.parse(
        '$_baseUrl/get_rainfall',
      ).replace(queryParameters: queryParams);

      print('Making API request to: $uri');

      final response = await client.get(uri).timeout(_timeout);

      print('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData
            .map((item) => RainfallRecord.fromJson(item, postcode))
            .toList();
      } else {
        throw RainfallApiException(
          'API returned status ${response.statusCode}: ${response.body}',
        );
      }
    } finally {
      client.close();
    }
  }

  // Web version with CORS workaround
  static Future<List<RainfallRecord>> _getRainfallDataWeb({
    required String postcode,
    int? year,
    int? month,
  }) async {
    final client = http.Client();

    try {
      // Build query parameters
      final queryParams = <String, String>{'postcode': postcode};
      if (year != null) queryParams['year'] = year.toString();
      if (month != null) queryParams['month'] = month.toString();

      final targetUrl =
          Uri.parse(
            '$_baseUrl/get_rainfall',
          ).replace(queryParameters: queryParams).toString();

      // Try multiple CORS proxy services
      final proxies = [
        'https://api.allorigins.win/get?url=',
        'https://corsproxy.io/?',
        'https://cors-anywhere.herokuapp.com/',
      ];

      for (int i = 0; i < proxies.length; i++) {
        try {
          final proxyUrl = '${proxies[i]}${Uri.encodeComponent(targetUrl)}';
          final uri = Uri.parse(proxyUrl);

          print('Trying proxy ${i + 1}: $uri');

          final response = await client.get(uri).timeout(_timeout);

          if (response.statusCode == 200) {
            dynamic responseData;

            // Handle different proxy response formats
            if (proxies[i].contains('allorigins')) {
              final proxyResponse = json.decode(response.body);
              responseData = json.decode(proxyResponse['contents']);
            } else {
              responseData = json.decode(response.body);
            }

            if (responseData is List) {
              return responseData
                  .map((item) => RainfallRecord.fromJson(item, postcode))
                  .toList();
            } else {
              throw RainfallApiException('Unexpected response format');
            }
          }
        } catch (e) {
          print('Proxy ${i + 1} failed: $e');
          if (i == proxies.length - 1) rethrow; // Last proxy failed
          continue; // Try next proxy
        }
      }

      throw RainfallApiException('All proxy services failed');
    } finally {
      client.close();
    }
  }

  // Get available postcodes (if your API supports this)
  static Future<List<String>> getAvailablePostcodes() async {
    // If your colleague's API has an endpoint for this
    try {
      if (kIsWeb) {
        // Web implementation with proxy
        final client = http.Client();
        final targetUrl = '$_baseUrl/get_postcodes';
        final proxyUrl =
            'https://api.allorigins.win/get?url=${Uri.encodeComponent(targetUrl)}';

        final response = await client
            .get(Uri.parse(proxyUrl))
            .timeout(_timeout);

        if (response.statusCode == 200) {
          final proxyResponse = json.decode(response.body);
          final List<dynamic> postcodes = json.decode(
            proxyResponse['contents'],
          );
          return postcodes.map((e) => e.toString()).toList();
        }
        client.close();
      } else {
        // Native implementation
        final response = await http
            .get(Uri.parse('$_baseUrl/get_postcodes'))
            .timeout(_timeout);
        if (response.statusCode == 200) {
          final List<dynamic> postcodes = json.decode(response.body);
          return postcodes.map((e) => e.toString()).toList();
        }
      }
    } catch (e) {
      print('Failed to get postcodes from API: $e');
    }

    // Fallback to hardcoded postcodes
    return PostcodesService.getAvailablePostcodes();
  }
}

// Improved data model
class RainfallRecord {
  final String postcode;
  final String stationId;
  final String monthYear;
  final int year;
  final int month;
  final double rainfall;
  final String quality;

  RainfallRecord({
    required this.postcode,
    required this.stationId,
    required this.monthYear,
    required this.year,
    required this.month,
    required this.rainfall,
    required this.quality,
  });

  factory RainfallRecord.fromJson(Map<String, dynamic> json, String postcode) {
    return RainfallRecord(
      postcode: postcode,
      stationId: json['station_id'] ?? '',
      monthYear: json['month_year'] ?? '',
      year: _parseYear(json['month_year'] ?? ''),
      month: _parseMonth(json['month_year'] ?? ''),
      rainfall: (json['precpt'] ?? 0).toDouble(),
      quality: json['quality'] ?? 'N',
    );
  }

  static int _parseYear(String monthYear) {
    try {
      // Handle different formats: "2024-01", "01.2024", etc.
      if (monthYear.contains('-')) {
        return int.parse(monthYear.split('-')[0]);
      } else if (monthYear.contains('.')) {
        return int.parse(monthYear.split('.')[1]);
      }
      return DateTime.now().year; // Fallback
    } catch (e) {
      return DateTime.now().year;
    }
  }

  static int _parseMonth(String monthYear) {
    try {
      // Handle different formats: "2024-01", "01.2024", etc.
      if (monthYear.contains('-')) {
        return int.parse(monthYear.split('-')[1]);
      } else if (monthYear.contains('.')) {
        return int.parse(monthYear.split('.')[0]);
      }
      return 1; // Fallback
    } catch (e) {
      return 1;
    }
  }

  // Convert to daily weather data for your app
  List<WeatherData> toDailyWeatherData() {
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final List<WeatherData> dailyData = [];

    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(year, month, day);

      // Distribute monthly rainfall across random days
      final double dailyRainfall =
          rainfall > 0
              ? (Random().nextDouble() < 0.2
                  ? rainfall / 6
                  : 0) // 20% chance of rain
              : 0;

      // Seasonal temperature estimates
      final temperature = _getSeasonalTemperature(month);

      dailyData.add(
        WeatherData(
          postcode: postcode,
          date: date,
          rainfall: dailyRainfall,
          temperature: temperature,
        ),
      );
    }

    return dailyData;
  }

  double _getSeasonalTemperature(int month) {
    // South Australian seasonal temperatures
    switch (month) {
      case 12:
      case 1:
      case 2: // Summer
        return 28 + (Random().nextDouble() * 12); // 28-40°C
      case 6:
      case 7:
      case 8: // Winter
        return 8 + (Random().nextDouble() * 10); // 8-18°C
      case 3:
      case 4:
      case 5: // Autumn
        return 18 + (Random().nextDouble() * 10); // 18-28°C
      default: // Spring
        return 20 + (Random().nextDouble() * 12); // 20-32°C
    }
  }
}

// Custom exception for API errors
class RainfallApiException implements Exception {
  final String message;
  RainfallApiException(this.message);

  @override
  String toString() => 'RainfallApiException: $message';
}
