import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/tank_model.dart';

// TODO: add all data persistence operations
class DataPersistService {
  // SharedPreferences keys
  static const String _tanksKey = 'tanks_data';
  static const String _tankCountKey = 'tank_count';
  static const String _tankStatesKey = 'tank_states';
  static const String _postcodeKey = 'selected_postcode';
  static const String _yearKey = 'selected_year';
  static const String _timePeriodKey = 'selected_time_period';

  // Singleton pattern
  static final DataPersistService _instance = DataPersistService._internal();
  factory DataPersistService() => _instance;
  DataPersistService._internal();

  // Tank data operations

  Future<void> saveTankData({
    required int tankCount,
    required List<Tank> tanks,
    required List<Map<String, bool>> tankStates,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt(_tankCountKey, tankCount);

    final tankDataList = tanks.map((tank) => tank.toJson()).toList();
    await prefs.setString(_tanksKey, json.encode(tankDataList));

    await prefs.setString(_tankStatesKey, json.encode(tankStates));
  }

  Future<Map<String, dynamic>> loadTankData() async {
    final prefs = await SharedPreferences.getInstance();

    final int tankCount = prefs.getInt(_tankCountKey) ?? 1;
    final String? savedTanksData = prefs.getString(_tanksKey);
    final String? savedStatesData = prefs.getString(_tankStatesKey);

    List<Tank> tanks = [];
    List<Map<String, bool>> tankStates = [];

    if (savedTanksData != null) {
      final List<dynamic> tankDataList = json.decode(savedTanksData);
      tanks = tankDataList.map((tankData) => Tank.fromJson(tankData)).toList();
    }

    if (savedStatesData != null) {
      final List<dynamic> statesDataList = json.decode(savedStatesData);
      tankStates =
          statesDataList
              .cast<Map<String, bool>>()
              .map(
                (state) => {
                  'knowTankCapacity': state['knowTankCapacity'] ?? false,
                  'knowTankWaterLevel': state['knowTankWaterLevel'] ?? false,
                },
              )
              .toList();
    }

    return {'tankCount': tankCount, 'tanks': tanks, 'tankStates': tankStates};
  }

  // Location data operations
  Future<void> saveLocationData({
    String? postcode,
    required double year,
    required String timePeriod,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    if (postcode != null) {
      await prefs.setString(_postcodeKey, postcode);
    }
    await prefs.setDouble(_yearKey, year);
    await prefs.setString(_timePeriodKey, timePeriod);
  }

  Future<Map<String, dynamic>> loadLocationData() async {
    final prefs = await SharedPreferences.getInstance();

    return {
      'postcode': prefs.getString(_postcodeKey),
      'year': prefs.getDouble(_yearKey) ?? DateTime.now().year.toDouble(),
      'timePeriod': prefs.getString(_timePeriodKey) ?? "Monthly",
    };
  }

  // Clear all data
  Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tanksKey);
    await prefs.remove(_tankCountKey);
    await prefs.remove(_tankStatesKey);
    await prefs.remove(_postcodeKey);
    await prefs.remove(_yearKey);
    await prefs.remove(_timePeriodKey);
  }

  // Export data as JSON string (for backup/sharing)
  Future<String> exportData() async {
    final tankData = await loadTankData();
    final locationData = await loadLocationData();

    final exportData = {
      'tankData': tankData,
      'locationData': locationData,
      'exportDate': DateTime.now().toIso8601String(),
    };

    return json.encode(exportData);
  }

  // Import data from JSON string (for restore/sharing)
  Future<bool> importData(String jsonData) async {
    try {
      final Map<String, dynamic> importData = json.decode(jsonData);

      if (importData.containsKey('tankData')) {
        final tankData = importData['tankData'];
        await saveTankData(
          tankCount: tankData['tankCount'] ?? 1,
          tanks:
              (tankData['tanks'] as List<dynamic>? ?? [])
                  .map((tankJson) => Tank.fromJson(tankJson))
                  .toList(),
          tankStates:
              (tankData['tankStates'] as List<dynamic>? ?? [])
                  .cast<Map<String, bool>>()
                  .map(
                    (state) => {
                      'knowTankCapacity': state['knowTankCapacity'] ?? false,
                      'knowTankWaterLevel':
                          state['knowTankWaterLevel'] ?? false,
                    },
                  )
                  .toList(),
        );
      }

      if (importData.containsKey('locationData')) {
        final locationData = importData['locationData'];
        await saveLocationData(
          postcode: locationData['postcode'],
          year: locationData['year'] ?? DateTime.now().year.toDouble(),
          timePeriod: locationData['timePeriod'] ?? "Monthly",
        );
      }

      return true;
    } catch (e) {
      return false;
    }
  }
}
