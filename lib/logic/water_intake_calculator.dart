import '../../data/database/database_service.dart';
import '/ui/views/water_usage_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WaterIntakeCalculator {
  // Calculate avg rainfall for each month by postcode
  Future<Map<String, double>> calculateAverageRainfallForEachMonth(
    String postcode,
    String roofCatchement,
  ) async {
    final roofCatchmentArea = double.parse(roofCatchement);
    Map<String, double> monthlyRainfall = {
      'Jan': 0,
      'Feb': 0,
      'Mar': 0,
      'Apr': 0,
      'May': 0,
      'Jun': 0,
      'Jul': 0,
      'Aug': 0,
      'Sep': 0,
      'Oct': 0,
      'Nov': 0,
      'Dec': 0,
    };

    final thisYear = DateTime.now().year;
    // Calculate daily rainfall average data for last 10 years for each month

    // Year<List<MonthlyRainfall>>
    List<List<MonthlyRainfall>> monthlyRainfallList = [];

    // Get 10 years of rainfall data
    for (int i = thisYear; i > thisYear - 10; i--) {
      monthlyRainfallList.add(
        await DatabaseService().getMonthlyRainfall(postcode: postcode, year: i),
      );
    }

    // Get average rainfall for each month for last 10 years
    for (int i = 0; i < 12; i++) {
      for (int j = 0; j < 10; j++) {
        switch (i) {
          case 0:
            monthlyRainfall['Jan'] =
                (monthlyRainfall['Jan'] ?? 0) +
                monthlyRainfallList[j][i].totalRainfall;
            break;
          case 1:
            monthlyRainfall['Feb'] =
                (monthlyRainfall['Feb'] ?? 0) +
                monthlyRainfallList[j][i].totalRainfall;
            break;
          case 2:
            monthlyRainfall['Mar'] =
                (monthlyRainfall['Mar'] ?? 0) +
                monthlyRainfallList[j][i].totalRainfall;
            break;
          case 3:
            monthlyRainfall['Apr'] =
                (monthlyRainfall['Apr'] ?? 0) +
                monthlyRainfallList[j][i].totalRainfall;
            break;
          case 4:
            monthlyRainfall['May'] =
                (monthlyRainfall['May'] ?? 0) +
                monthlyRainfallList[j][i].totalRainfall;
            break;
          case 5:
            monthlyRainfall['Jun'] =
                (monthlyRainfall['Jun'] ?? 0) +
                monthlyRainfallList[j][i].totalRainfall;
            break;
          case 6:
            monthlyRainfall['Jul'] =
                (monthlyRainfall['Jul'] ?? 0) +
                monthlyRainfallList[j][i].totalRainfall;
            break;
          case 7:
            monthlyRainfall['Aug'] =
                (monthlyRainfall['Aug'] ?? 0) +
                monthlyRainfallList[j][i].totalRainfall;
            break;
          case 8:
            monthlyRainfall['Sep'] =
                (monthlyRainfall['Sep'] ?? 0) +
                monthlyRainfallList[j][i].totalRainfall;
            break;
          case 9:
            monthlyRainfall['Oct'] =
                (monthlyRainfall['Oct'] ?? 0) +
                monthlyRainfallList[j][i].totalRainfall;
            break;
          case 10:
            monthlyRainfall['Nov'] =
                (monthlyRainfall['Nov'] ?? 0) +
                monthlyRainfallList[j][i].totalRainfall;
            break;
          case 11:
            monthlyRainfall['Dec'] =
                (monthlyRainfall['Dec'] ?? 0) +
                monthlyRainfallList[j][i].totalRainfall;
            break;
        }
      }
    }

    monthlyRainfall.forEach((key, value) {
      monthlyRainfall[key] = (value / 10) * (roofCatchmentArea);
    });

    monthlyRainfall.forEach((key, value) {
      // limit value to 2 decimal places
      monthlyRainfall[key] = double.parse(value.toStringAsFixed(2));
    });

    return monthlyRainfall;
  }

  // Add other intake in L/day
  Future<Map<String, double>> totalMontlyIntake(
    Map<String, double> monthlyRainfall,
  ) async {
    Map<String, double> totalIntake = {
      'Jan': 0,
      'Feb': 0,
      'Mar': 0,
      'Apr': 0,
      'May': 0,
      'Jun': 0,
      'Jul': 0,
      'Aug': 0,
      'Sep': 0,
      'Oct': 0,
      'Nov': 0,
      'Dec': 0,
    };
    monthlyRainfall.forEach((key, value) {
      totalIntake[key] = value * 0.95;
    });

    // other intake from shared prefs
    const String otherIntakeKey = 'other_intake';
    final prefs = await SharedPreferences.getInstance();
    final otherIntake = prefs.getDouble(otherIntakeKey) ?? 0.0;
    totalIntake.forEach((key, value) {
      totalIntake[key] = value + (otherIntake * 30);
    });

    totalIntake.forEach((key, value) {
      print("$key: $value");
    });
    return totalIntake;
  }
}
