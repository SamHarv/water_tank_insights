import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math' as math;
import '../data/database/database_service.dart';

class ResultsCalculator {
  /// [ResultsCalculator] calculates water balance and days remaining

  static const String _numOfPeopleKey = 'num_of_people';
  static const String _personWaterUsageListKey = 'person_water_usage_list';
  static const String _tanksKey = 'tanks_data';
  static const String _postcodeKey = 'selected_postcode';
  static const String _roofCatchmentAreaKey = 'roof_catchment_area';
  static const String _otherIntakeKey = 'other_intake';

  /// Calculate days remaining based on current scenario
  static Future<Map<String, dynamic>> calculateDaysRemaining({
    String rainfallScenario = "10-year median",
    double perPersonUsage = 200.0,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get current inventory from tanks
      final currentInventory = await _getCurrentInventory();

      // Get water usage per day
      final dailyUsage = await _getDailyWaterUsage();

      // Get water intake per month based on scenario
      final monthlyIntake = await _getMonthlyWaterIntake(rainfallScenario);

      // Calculate net position and days remaining
      final results = _calculateWaterBalance(
        currentInventory: currentInventory,
        dailyUsage: dailyUsage,
        monthlyIntake: monthlyIntake,
        perPersonUsage: perPersonUsage,
      );

      return results;
    } catch (e) {
      throw Exception('Failed to calculate days remaining: $e');
    }
  }

  /// Get current water inventory from all tanks
  static Future<int> _getCurrentInventory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? savedTanksData = prefs.getString(_tanksKey);

      if (savedTanksData == null) return 0;

      final List<dynamic> tankDataList = json.decode(savedTanksData);
      int totalInventory = 0;

      for (var tankData in tankDataList) {
        final waterLevel = tankData['waterLevel'] ?? 0;
        totalInventory += waterLevel as int;
      }

      return totalInventory;
    } catch (e) {
      return 0;
    }
  }

  /// Get daily water usage for household
  static Future<double> _getDailyWaterUsage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? savedUsageList = prefs.getString(_personWaterUsageListKey);

      if (savedUsageList == null) return 200.0; // Default

      final List<dynamic> usageData = json.decode(savedUsageList);
      final List<int> personWaterUsageList = usageData.cast<int>();

      return personWaterUsageList
          .fold(0, (sum, usage) => sum + usage)
          .toDouble();
    } catch (e) {
      return 200.0; // Default fallback
    }
  }

  /// Calculate median from a list of numbers
  static double _calculateMedian(List<double> values) {
    if (values.isEmpty) return 0.0;

    final sortedValues = List<double>.from(values)..sort();
    final length = sortedValues.length;

    if (length % 2 == 0) {
      // Even number of values - average of two middle values
      return (sortedValues[length ~/ 2 - 1] + sortedValues[length ~/ 2]) / 2;
    } else {
      // Odd number of values - middle value
      return sortedValues[length ~/ 2];
    }
  }

  /// Get historical rainfall statistics (min, median, max) for each month
  static Future<Map<String, Map<String, double>>>
  _getHistoricalRainfallStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final postcode = prefs.getString(_postcodeKey) ?? "5000";

      // Get rainfall data directly from database service
      final dbService = DatabaseService();
      final currentYear = DateTime.now().year;

      // Initialize stats structure
      Map<String, Map<String, double>> monthlyStats = {
        'Jan': {'min': 0.0, 'median': 0.0, 'max': 0.0},
        'Feb': {'min': 0.0, 'median': 0.0, 'max': 0.0},
        'Mar': {'min': 0.0, 'median': 0.0, 'max': 0.0},
        'Apr': {'min': 0.0, 'median': 0.0, 'max': 0.0},
        'May': {'min': 0.0, 'median': 0.0, 'max': 0.0},
        'Jun': {'min': 0.0, 'median': 0.0, 'max': 0.0},
        'Jul': {'min': 0.0, 'median': 0.0, 'max': 0.0},
        'Aug': {'min': 0.0, 'median': 0.0, 'max': 0.0},
        'Sep': {'min': 0.0, 'median': 0.0, 'max': 0.0},
        'Oct': {'min': 0.0, 'median': 0.0, 'max': 0.0},
        'Nov': {'min': 0.0, 'median': 0.0, 'max': 0.0},
        'Dec': {'min': 0.0, 'median': 0.0, 'max': 0.0},
      };

      // Collect rainfall data by month across all years
      Map<String, List<double>> monthlyRainfallData = {
        'Jan': [],
        'Feb': [],
        'Mar': [],
        'Apr': [],
        'May': [],
        'Jun': [],
        'Jul': [],
        'Aug': [],
        'Sep': [],
        'Oct': [],
        'Nov': [],
        'Dec': [],
      };

      // Get 10 years of data
      for (int year = currentYear - 9; year <= currentYear; year++) {
        try {
          final monthlyData = await dbService.getMonthlyRainfall(
            postcode: postcode,
            year: year,
            useCache: true,
          );

          for (final monthData in monthlyData) {
            final monthName = _getMonthName(monthData.month);
            monthlyRainfallData[monthName]!.add(monthData.totalRainfall);
          }
        } catch (e) {
          print('Failed to get data for year $year: $e');
          // Continue with other years
        }
      }

      // Calculate statistics for each month
      monthlyRainfallData.forEach((month, rainfallValues) {
        if (rainfallValues.isNotEmpty) {
          rainfallValues.sort();
          monthlyStats[month] = {
            'min': rainfallValues.first,
            'median': _calculateMedian(rainfallValues),
            'max': rainfallValues.last,
          };
        }
      });

      return monthlyStats;
    } catch (e) {
      print('Error getting historical rainfall stats: $e');
      // Return empty stats if error occurs
      return {
        'Jan': {'min': 0.0, 'median': 0.0, 'max': 0.0},
        'Feb': {'min': 0.0, 'median': 0.0, 'max': 0.0},
        'Mar': {'min': 0.0, 'median': 0.0, 'max': 0.0},
        'Apr': {'min': 0.0, 'median': 0.0, 'max': 0.0},
        'May': {'min': 0.0, 'median': 0.0, 'max': 0.0},
        'Jun': {'min': 0.0, 'median': 0.0, 'max': 0.0},
        'Jul': {'min': 0.0, 'median': 0.0, 'max': 0.0},
        'Aug': {'min': 0.0, 'median': 0.0, 'max': 0.0},
        'Sep': {'min': 0.0, 'median': 0.0, 'max': 0.0},
        'Oct': {'min': 0.0, 'median': 0.0, 'max': 0.0},
        'Nov': {'min': 0.0, 'median': 0.0, 'max': 0.0},
        'Dec': {'min': 0.0, 'median': 0.0, 'max': 0.0},
      };
    }
  }

  /// Get monthly water intake based on rainfall scenario
  static Future<Map<String, double>> _getMonthlyWaterIntake(
    String scenario,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final roofCatchmentStr = prefs.getString(_roofCatchmentAreaKey) ?? "100";
      final otherIntakeStr = prefs.getString(_otherIntakeKey) ?? "0";

      // Parse roof catchment area
      final roofCatchmentArea = double.tryParse(roofCatchmentStr) ?? 100.0;
      final otherIntakeDailyL = double.tryParse(otherIntakeStr) ?? 0.0;

      // Get historical rainfall statistics
      final rainfallStats = await _getHistoricalRainfallStats();

      // Convert rainfall to water intake based on scenario
      Map<String, double> monthlyIntake = {};
      final currentYear = DateTime.now().year;

      rainfallStats.forEach((month, stats) {
        double rainfallMm;

        // Select rainfall value based on scenario
        switch (scenario) {
          case "No Rainfall":
            rainfallMm = 0.0;
            break;
          case "Lowest recorded":
            rainfallMm = stats['min']!;
            break;
          case "10-year median":
            rainfallMm = stats['median']!;
            break;
          case "Highest recorded":
            rainfallMm = stats['max']!;
            break;
          default:
            rainfallMm = stats['median']!; // Default to median
        }

        // Calculate water collection: rainfall (mm) * catchment area (m²) * collection efficiency (95%)
        // 1mm of rain on 1m² = 1 liter, so: mm * m² * 0.95 = liters
        final collectedWaterL = rainfallMm * roofCatchmentArea * 0.95;

        // Add other daily intake sources (converted to monthly)
        final daysInMonth = _getDaysInMonth(month, currentYear);
        final otherIntakeMonthlyL = otherIntakeDailyL * daysInMonth;

        monthlyIntake[month] = collectedWaterL + otherIntakeMonthlyL;
      });

      return monthlyIntake;
    } catch (e) {
      print('Error calculating monthly water intake: $e');
      // Return minimal intake from other sources only
      final prefs = await SharedPreferences.getInstance();
      final otherIntakeStr = prefs.getString(_otherIntakeKey) ?? "0";
      final otherIntakeDailyL = double.tryParse(otherIntakeStr) ?? 0.0;

      return {
        'Jan': otherIntakeDailyL * 31,
        'Feb': otherIntakeDailyL * 28,
        'Mar': otherIntakeDailyL * 31,
        'Apr': otherIntakeDailyL * 30,
        'May': otherIntakeDailyL * 31,
        'Jun': otherIntakeDailyL * 30,
        'Jul': otherIntakeDailyL * 31,
        'Aug': otherIntakeDailyL * 31,
        'Sep': otherIntakeDailyL * 30,
        'Oct': otherIntakeDailyL * 31,
        'Nov': otherIntakeDailyL * 30,
        'Dec': otherIntakeDailyL * 31,
      };
    }
  }

  /// Get month name from month number
  static String _getMonthName(int month) {
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

  /// Get number of days in a month
  static int _getDaysInMonth(String monthName, int year) {
    const monthDays = {
      'Jan': 31,
      'Feb': 28,
      'Mar': 31,
      'Apr': 30,
      'May': 31,
      'Jun': 30,
      'Jul': 31,
      'Aug': 31,
      'Sep': 30,
      'Oct': 31,
      'Nov': 30,
      'Dec': 31,
    };

    int days = monthDays[monthName] ?? 30;

    // Handle leap year for February
    if (monthName == 'Feb' && _isLeapYear(year)) {
      days = 29;
    }

    return days;
  }

  /// Check if year is a leap year
  static bool _isLeapYear(int year) {
    return (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
  }

  /// Calculate water balance and determine days remaining
  static Map<String, dynamic> _calculateWaterBalance({
    required int currentInventory,
    required double dailyUsage,
    required Map<String, double> monthlyIntake,
    required double perPersonUsage,
  }) {
    final currentMonth = DateTime.now().month;
    final monthNames = [
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

    // Get current month's daily intake (monthly / days in month)
    final currentMonthName = monthNames[currentMonth - 1];
    final daysInCurrentMonth =
        DateTime(DateTime.now().year, currentMonth + 1, 0).day;
    final dailyIntake = monthlyIntake[currentMonthName]! / daysInCurrentMonth;

    // Calculate net daily change (intake - usage)
    final netDailyChange = dailyIntake - dailyUsage;

    int daysRemaining;
    String message;
    bool isIncreasing = false;

    if (netDailyChange >= 0) {
      // Water level is stable or increasing
      daysRemaining = -1; // Infinite
      isIncreasing = true;
      message =
          "You are gaining ${netDailyChange.toStringAsFixed(1)} litres per day!";
    } else {
      // Water level is decreasing
      if (currentInventory <= 0) {
        daysRemaining = 0;
        message = "Tank is empty - immediate action required!";
      } else {
        daysRemaining = (currentInventory / netDailyChange.abs()).floor();
        message =
            "You are using ${netDailyChange.abs().toStringAsFixed(1)} litres more than you're collecting per day.";
      }
    }

    // Calculate projected inventory levels for chart
    final projectedData = _calculateProjectedLevels(
      currentInventory: currentInventory,
      dailyUsage: dailyUsage,
      monthlyIntake: monthlyIntake,
      daysToProject: 90, // Project 3 months ahead
    );

    return {
      'daysRemaining': daysRemaining,
      'currentInventory': currentInventory,
      'dailyUsage': dailyUsage,
      'dailyIntake': dailyIntake,
      'netDailyChange': netDailyChange,
      'isIncreasing': isIncreasing,
      'message': message,
      'projectedData': projectedData,
      'monthlyIntake': monthlyIntake,
    };
  }

  /// Calculate projected water levels for charting
  static List<Map<String, dynamic>> _calculateProjectedLevels({
    required int currentInventory,
    required double dailyUsage,
    required Map<String, double> monthlyIntake,
    required int daysToProject,
  }) {
    final List<Map<String, dynamic>> projectedData = [];
    final monthNames = [
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

    double currentLevel = currentInventory.toDouble();
    final startDate = DateTime.now();

    for (int day = 0; day <= daysToProject; day++) {
      final projectedDate = startDate.add(Duration(days: day));
      final monthIndex = projectedDate.month - 1;
      final monthName = monthNames[monthIndex];
      final daysInMonth =
          DateTime(projectedDate.year, projectedDate.month + 1, 0).day;

      // Calculate daily intake for this month
      final dailyIntake = monthlyIntake[monthName]! / daysInMonth;

      // Update water level
      currentLevel += (dailyIntake - dailyUsage);

      // Ensure level doesn't go below 0
      if (currentLevel < 0) currentLevel = 0;

      projectedData.add({
        'day': day,
        'date': projectedDate.toIso8601String().split('T')[0],
        'waterLevel': currentLevel.round(),
        'dailyIntake': dailyIntake,
        'dailyUsage': dailyUsage,
      });

      // Stop projecting if tank is empty
      if (currentLevel <= 0 && day > 0) break;
    }

    return projectedData;
  }

  /// Get total tank capacity
  static Future<int> getTotalTankCapacity() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? savedTanksData = prefs.getString(_tanksKey);

      if (savedTanksData == null) return 0;

      final List<dynamic> tankDataList = json.decode(savedTanksData);
      int totalCapacity = 0;

      for (var tankData in tankDataList) {
        final capacity = tankData['capacity'] ?? 0;
        totalCapacity += capacity as int;
      }

      return totalCapacity;
    } catch (e) {
      return 0;
    }
  }

  /// Get tank usage summary
  static Future<Map<String, dynamic>> getTankSummary() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? savedTanksData = prefs.getString(_tanksKey);

      if (savedTanksData == null) {
        return {
          'totalCapacity': 0,
          'currentInventory': 0,
          'availableSpace': 0,
          'fillPercentage': 0.0,
          'tankCount': 0,
        };
      }

      final List<dynamic> tankDataList = json.decode(savedTanksData);
      int totalCapacity = 0;
      int totalInventory = 0;

      for (var tankData in tankDataList) {
        totalCapacity += (tankData['capacity'] ?? 0) as int;
        totalInventory += (tankData['waterLevel'] ?? 0) as int;
      }

      final availableSpace = totalCapacity - totalInventory;
      final fillPercentage =
          totalCapacity > 0 ? (totalInventory / totalCapacity) * 100 : 0.0;

      return {
        'totalCapacity': totalCapacity,
        'currentInventory': totalInventory,
        'availableSpace': availableSpace,
        'fillPercentage': fillPercentage,
        'tankCount': tankDataList.length,
      };
    } catch (e) {
      return {
        'totalCapacity': 0,
        'currentInventory': 0,
        'availableSpace': 0,
        'fillPercentage': 0.0,
        'tankCount': 0,
      };
    }
  }

  /// Debug method to check rainfall calculations with enhanced statistics
  static Future<Map<String, dynamic>> debugRainfallCalculations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final postcode = prefs.getString(_postcodeKey) ?? "5000";
      final roofCatchmentStr = prefs.getString(_roofCatchmentAreaKey) ?? "100";
      final otherIntakeStr = prefs.getString(_otherIntakeKey) ?? "0";

      final roofCatchmentArea = double.tryParse(roofCatchmentStr) ?? 100.0;
      final otherIntakeDailyL = double.tryParse(otherIntakeStr) ?? 0.0;

      // Get historical rainfall statistics
      final rainfallStats = await _getHistoricalRainfallStats();

      Map<String, Map<String, double>> intakeDebug = {};

      rainfallStats.forEach((month, stats) {
        final medianRainfall = stats['median']!;
        final minRainfall = stats['min']!;
        final maxRainfall = stats['max']!;

        final medianIntakeL = medianRainfall * roofCatchmentArea * 0.95;
        final minIntakeL = minRainfall * roofCatchmentArea * 0.95;
        final maxIntakeL = maxRainfall * roofCatchmentArea * 0.95;

        intakeDebug[month] = {
          'median': medianIntakeL,
          'min': minIntakeL,
          'max': maxIntakeL,
        };
      });

      return {
        'postcode': postcode,
        'roofCatchmentArea': roofCatchmentArea,
        'otherIntakeDailyL': otherIntakeDailyL,
        'currentYear': DateTime.now().year,
        'rainfallStatsByMonth': rainfallStats,
        'waterIntakeStatsByMonth': intakeDebug,
        'hasRoofCatchmentData':
            roofCatchmentStr.isNotEmpty && roofCatchmentArea > 0,
        'hasRainfallData': rainfallStats.values.any(
          (stats) =>
              stats['median']! > 0 || stats['min']! > 0 || stats['max']! > 0,
        ),
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// Get available rainfall scenarios based on historical data
  static Future<List<String>> getAvailableScenarios() async {
    try {
      final rainfallStats = await _getHistoricalRainfallStats();

      // Check if we have any meaningful data
      final hasData = rainfallStats.values.any(
        (stats) =>
            stats['median']! > 0 || stats['min']! > 0 || stats['max']! > 0,
      );

      if (hasData) {
        return [
          "No Rainfall",
          "Lowest recorded",
          "10-year median",
          "Highest recorded",
        ];
      } else {
        // If no historical data, only offer basic scenarios
        return [
          "No Rainfall",
          "10-year median", // Will default to 0 if no data
        ];
      }
    } catch (e) {
      return ["No Rainfall", "10-year median"];
    }
  }
}
