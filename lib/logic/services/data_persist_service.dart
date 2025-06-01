import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/tank_model.dart';

class DataPersistService {
  // SharedPreferences keys
  static const String _tanksKey = 'tanks_data';
  static const String _tankCountKey = 'tank_count';
  static const String _tankStatesKey = 'tank_states';
  static const String _postcodeKey = 'selected_postcode';
  static const String _yearKey = 'selected_year';
  static const String _timePeriodKey = 'selected_time_period';
  static const String _knowRoofCatchmentKey = 'know_roof_catchment';
  static const String _roofCatchmentAreaKey = 'roof_catchment_area';
  static const String _otherIntakeKey = 'other_intake';
  static const String _numOfPeopleKey = 'num_of_people';
  static const String _personWaterUsageListKey = 'person_water_usage_list';
  static const String _isManualInputListKey = 'is_manual_input_list';

  // Singleton pattern
  static final DataPersistService _instance = DataPersistService._internal();
  factory DataPersistService() => _instance;
  DataPersistService._internal();

  // Generic helper methods
  Future<SharedPreferences> _getPrefs() async {
    return await SharedPreferences.getInstance();
  }

  // ======================
  // TANK DATA OPERATIONS
  // ======================

  Future<void> saveTankData({
    required int tankCount,
    required List<Tank> tanks,
    required List<Map<String, bool>> tankStates,
  }) async {
    final prefs = await _getPrefs();

    await prefs.setInt(_tankCountKey, tankCount);

    final tankDataList = tanks.map((tank) => tank.toJson()).toList();
    await prefs.setString(_tanksKey, json.encode(tankDataList));

    await prefs.setString(_tankStatesKey, json.encode(tankStates));
  }

  Future<Map<String, dynamic>> loadTankData() async {
    final prefs = await _getPrefs();

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
          statesDataList.map((state) {
            final Map<String, dynamic> stateMap = state as Map<String, dynamic>;
            return {
              'knowTankCapacity':
                  stateMap['knowTankCapacity'] as bool? ?? false,
              'knowTankWaterLevel':
                  stateMap['knowTankWaterLevel'] as bool? ?? false,
            };
          }).toList();
    }

    return {'tankCount': tankCount, 'tanks': tanks, 'tankStates': tankStates};
  }

  Future<void> saveTankCount(int count) async {
    final prefs = await _getPrefs();
    await prefs.setInt(_tankCountKey, count);
  }

  Future<int> loadTankCount() async {
    final prefs = await _getPrefs();
    return prefs.getInt(_tankCountKey) ?? 1;
  }

  Future<void> saveTankStates(List<Map<String, bool>> tankStates) async {
    final prefs = await _getPrefs();
    await prefs.setString(_tankStatesKey, json.encode(tankStates));
  }

  Future<List<Map<String, bool>>> loadTankStates() async {
    final prefs = await _getPrefs();
    final String? savedStatesData = prefs.getString(_tankStatesKey);

    if (savedStatesData == null) return [];

    final List<dynamic> statesDataList = json.decode(savedStatesData);
    return statesDataList.map((state) {
      final Map<String, dynamic> stateMap = state as Map<String, dynamic>;
      return {
        'knowTankCapacity': stateMap['knowTankCapacity'] as bool? ?? false,
        'knowTankWaterLevel': stateMap['knowTankWaterLevel'] as bool? ?? false,
      };
    }).toList();
  }

  Future<void> saveTanks(List<Tank> tanks) async {
    final prefs = await _getPrefs();
    final tankDataList = tanks.map((tank) => tank.toJson()).toList();
    await prefs.setString(_tanksKey, json.encode(tankDataList));
  }

  Future<List<Tank>> loadTanks() async {
    final prefs = await _getPrefs();
    final String? savedTanksData = prefs.getString(_tanksKey);

    if (savedTanksData == null) return [];

    final List<dynamic> tankDataList = json.decode(savedTanksData);
    return tankDataList.map((tankData) => Tank.fromJson(tankData)).toList();
  }

  // ======================
  // LOCATION DATA OPERATIONS
  // ======================

  Future<void> saveLocationData({
    String? postcode,
    required double year,
    required String timePeriod,
  }) async {
    final prefs = await _getPrefs();

    if (postcode != null) {
      await prefs.setString(_postcodeKey, postcode);
    }
    await prefs.setDouble(_yearKey, year);
    await prefs.setString(_timePeriodKey, timePeriod);
  }

  Future<Map<String, dynamic>> loadLocationData() async {
    final prefs = await _getPrefs();

    return {
      'postcode': prefs.getString(_postcodeKey),
      'year': prefs.getDouble(_yearKey) ?? DateTime.now().year.toDouble(),
      'timePeriod': prefs.getString(_timePeriodKey) ?? "Monthly",
    };
  }

  Future<void> savePostcode(String postcode) async {
    final prefs = await _getPrefs();
    await prefs.setString(_postcodeKey, postcode);
  }

  Future<String?> loadPostcode() async {
    final prefs = await _getPrefs();
    return prefs.getString(_postcodeKey);
  }

  Future<void> saveYear(double year) async {
    final prefs = await _getPrefs();
    await prefs.setDouble(_yearKey, year);
  }

  Future<double> loadYear() async {
    final prefs = await _getPrefs();
    return prefs.getDouble(_yearKey) ?? DateTime.now().year.toDouble();
  }

  Future<void> saveTimePeriod(String timePeriod) async {
    final prefs = await _getPrefs();
    await prefs.setString(_timePeriodKey, timePeriod);
  }

  Future<String> loadTimePeriod() async {
    final prefs = await _getPrefs();
    return prefs.getString(_timePeriodKey) ?? "Monthly";
  }

  // ======================
  // ROOF CATCHMENT DATA OPERATIONS
  // ======================

  Future<void> saveRoofCatchmentData({
    required bool knowRoofCatchment,
    required String roofCatchmentArea,
    required String otherIntake,
  }) async {
    final prefs = await _getPrefs();

    await prefs.setBool(_knowRoofCatchmentKey, knowRoofCatchment);
    await prefs.setString(_roofCatchmentAreaKey, roofCatchmentArea);
    await prefs.setString(_otherIntakeKey, otherIntake);
  }

  Future<Map<String, dynamic>> loadRoofCatchmentData() async {
    final prefs = await _getPrefs();

    return {
      'knowRoofCatchment': prefs.getBool(_knowRoofCatchmentKey) ?? false,
      'roofCatchmentArea': prefs.getString(_roofCatchmentAreaKey) ?? '',
      'otherIntake': prefs.getString(_otherIntakeKey) ?? '',
    };
  }

  Future<void> saveKnowRoofCatchment(bool knowRoofCatchment) async {
    final prefs = await _getPrefs();
    await prefs.setBool(_knowRoofCatchmentKey, knowRoofCatchment);
  }

  Future<bool> loadKnowRoofCatchment() async {
    final prefs = await _getPrefs();
    return prefs.getBool(_knowRoofCatchmentKey) ?? false;
  }

  Future<void> saveRoofCatchmentArea(String area) async {
    final prefs = await _getPrefs();
    await prefs.setString(_roofCatchmentAreaKey, area);
  }

  Future<String> loadRoofCatchmentArea() async {
    final prefs = await _getPrefs();
    return prefs.getString(_roofCatchmentAreaKey) ?? '';
  }

  Future<void> saveOtherIntake(String intake) async {
    final prefs = await _getPrefs();
    await prefs.setString(_otherIntakeKey, intake);
  }

  Future<String> loadOtherIntake() async {
    final prefs = await _getPrefs();
    return prefs.getString(_otherIntakeKey) ?? '';
  }

  // ======================
  // WATER USAGE DATA OPERATIONS
  // ======================

  Future<void> saveWaterUsageData({
    required int numOfPeople,
    required List<int> personWaterUsageList,
    required List<bool> isManualInputList,
  }) async {
    final prefs = await _getPrefs();

    await prefs.setInt(_numOfPeopleKey, numOfPeople);
    await prefs.setString(
      _personWaterUsageListKey,
      json.encode(personWaterUsageList),
    );
    await prefs.setString(
      _isManualInputListKey,
      json.encode(isManualInputList),
    );
  }

  Future<Map<String, dynamic>> loadWaterUsageData() async {
    final prefs = await _getPrefs();

    final int numOfPeople = prefs.getInt(_numOfPeopleKey) ?? 0;

    List<int> personWaterUsageList = [];
    final savedUsageListString = prefs.getString(_personWaterUsageListKey);
    if (savedUsageListString != null) {
      final List<dynamic> usageData = json.decode(savedUsageListString);
      personWaterUsageList = usageData.cast<int>();
    }

    List<bool> isManualInputList = [];
    final savedManualInputListString = prefs.getString(_isManualInputListKey);
    if (savedManualInputListString != null) {
      final List<dynamic> manualInputData = json.decode(
        savedManualInputListString,
      );
      isManualInputList = manualInputData.cast<bool>();
    }

    return {
      'numOfPeople': numOfPeople,
      'personWaterUsageList': personWaterUsageList,
      'isManualInputList': isManualInputList,
    };
  }

  Future<void> saveNumOfPeople(int numOfPeople) async {
    final prefs = await _getPrefs();
    await prefs.setInt(_numOfPeopleKey, numOfPeople);
  }

  Future<int> loadNumOfPeople() async {
    final prefs = await _getPrefs();
    return prefs.getInt(_numOfPeopleKey) ?? 0;
  }

  Future<void> savePersonWaterUsageList(List<int> usageList) async {
    final prefs = await _getPrefs();
    await prefs.setString(_personWaterUsageListKey, json.encode(usageList));
  }

  Future<List<int>> loadPersonWaterUsageList() async {
    final prefs = await _getPrefs();
    final savedUsageListString = prefs.getString(_personWaterUsageListKey);

    if (savedUsageListString == null) return [];

    final List<dynamic> usageData = json.decode(savedUsageListString);
    return usageData.cast<int>();
  }

  Future<void> saveIsManualInputList(List<bool> manualInputList) async {
    final prefs = await _getPrefs();
    await prefs.setString(_isManualInputListKey, json.encode(manualInputList));
  }

  Future<List<bool>> loadIsManualInputList() async {
    final prefs = await _getPrefs();
    final savedManualInputListString = prefs.getString(_isManualInputListKey);

    if (savedManualInputListString == null) return [];

    final List<dynamic> manualInputData = json.decode(
      savedManualInputListString,
    );
    return manualInputData.cast<bool>();
  }

  // ======================
  // UTILITY METHODS
  // ======================

  // Clear all data
  Future<void> clearAllData() async {
    final prefs = await _getPrefs();

    // Tank data
    await prefs.remove(_tanksKey);
    await prefs.remove(_tankCountKey);
    await prefs.remove(_tankStatesKey);

    // Location data
    await prefs.remove(_postcodeKey);
    await prefs.remove(_yearKey);
    await prefs.remove(_timePeriodKey);

    // Roof catchment data
    await prefs.remove(_knowRoofCatchmentKey);
    await prefs.remove(_roofCatchmentAreaKey);
    await prefs.remove(_otherIntakeKey);

    // Water usage data
    await prefs.remove(_numOfPeopleKey);
    await prefs.remove(_personWaterUsageListKey);
    await prefs.remove(_isManualInputListKey);
  }

  // Clear specific data sections
  Future<void> clearTankData() async {
    final prefs = await _getPrefs();
    await prefs.remove(_tanksKey);
    await prefs.remove(_tankCountKey);
    await prefs.remove(_tankStatesKey);
  }

  Future<void> clearLocationData() async {
    final prefs = await _getPrefs();
    await prefs.remove(_postcodeKey);
    await prefs.remove(_yearKey);
    await prefs.remove(_timePeriodKey);
  }

  Future<void> clearRoofCatchmentData() async {
    final prefs = await _getPrefs();
    await prefs.remove(_knowRoofCatchmentKey);
    await prefs.remove(_roofCatchmentAreaKey);
    await prefs.remove(_otherIntakeKey);
  }

  Future<void> clearWaterUsageData() async {
    final prefs = await _getPrefs();
    await prefs.remove(_numOfPeopleKey);
    await prefs.remove(_personWaterUsageListKey);
    await prefs.remove(_isManualInputListKey);
  }

  // Export data as JSON string (for backup/sharing)
  Future<String> exportData() async {
    final tankData = await loadTankData();
    final locationData = await loadLocationData();
    final roofCatchmentData = await loadRoofCatchmentData();
    final waterUsageData = await loadWaterUsageData();

    final exportData = {
      'tankData': tankData,
      'locationData': locationData,
      'roofCatchmentData': roofCatchmentData,
      'waterUsageData': waterUsageData,
      'exportDate': DateTime.now().toIso8601String(),
      'version': '1.0',
    };

    return json.encode(exportData);
  }

  // Import data from JSON string (for restore/sharing)
  Future<bool> importData(String jsonData) async {
    try {
      final Map<String, dynamic> importData = json.decode(jsonData);

      // Import tank data
      if (importData.containsKey('tankData')) {
        final tankData = importData['tankData'];
        await saveTankData(
          tankCount: tankData['tankCount'] ?? 1,
          tanks:
              (tankData['tanks'] as List<dynamic>? ?? [])
                  .map((tankJson) => Tank.fromJson(tankJson))
                  .toList(),
          tankStates:
              (tankData['tankStates'] as List<dynamic>? ?? []).map((state) {
                final Map<String, dynamic> stateMap =
                    state as Map<String, dynamic>;
                return {
                  'knowTankCapacity':
                      stateMap['knowTankCapacity'] as bool? ?? false,
                  'knowTankWaterLevel':
                      stateMap['knowTankWaterLevel'] as bool? ?? false,
                };
              }).toList(),
        );
      }

      // Import location data
      if (importData.containsKey('locationData')) {
        final locationData = importData['locationData'];
        await saveLocationData(
          postcode: locationData['postcode'],
          year: locationData['year'] ?? DateTime.now().year.toDouble(),
          timePeriod: locationData['timePeriod'] ?? "Monthly",
        );
      }

      // Import roof catchment data
      if (importData.containsKey('roofCatchmentData')) {
        final roofCatchmentData = importData['roofCatchmentData'];
        await saveRoofCatchmentData(
          knowRoofCatchment: roofCatchmentData['knowRoofCatchment'] ?? false,
          roofCatchmentArea: roofCatchmentData['roofCatchmentArea'] ?? '',
          otherIntake: roofCatchmentData['otherIntake'] ?? '',
        );
      }

      // Import water usage data
      if (importData.containsKey('waterUsageData')) {
        final waterUsageData = importData['waterUsageData'];
        await saveWaterUsageData(
          numOfPeople: waterUsageData['numOfPeople'] ?? 0,
          personWaterUsageList:
              (waterUsageData['personWaterUsageList'] as List<dynamic>? ?? [])
                  .cast<int>(),
          isManualInputList:
              (waterUsageData['isManualInputList'] as List<dynamic>? ?? [])
                  .cast<bool>(),
        );
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  // Check if data exists for different sections
  Future<bool> hasTankData() async {
    final prefs = await _getPrefs();
    return prefs.containsKey(_tanksKey);
  }

  Future<bool> hasLocationData() async {
    final prefs = await _getPrefs();
    return prefs.containsKey(_postcodeKey);
  }

  Future<bool> hasRoofCatchmentData() async {
    final prefs = await _getPrefs();
    return prefs.containsKey(_roofCatchmentAreaKey);
  }

  Future<bool> hasWaterUsageData() async {
    final prefs = await _getPrefs();
    return prefs.containsKey(_numOfPeopleKey);
  }

  // Get data summary for debugging
  Future<Map<String, bool>> getDataSummary() async {
    return {
      'hasTankData': await hasTankData(),
      'hasLocationData': await hasLocationData(),
      'hasRoofCatchmentData': await hasRoofCatchmentData(),
      'hasWaterUsageData': await hasWaterUsageData(),
    };
  }
}
