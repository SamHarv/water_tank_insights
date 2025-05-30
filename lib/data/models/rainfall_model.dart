class RainfallModel {
  final String postcode;
  final String monthYear;
  final double rainfall;
  final String stationId;

  RainfallModel({
    required this.postcode,
    required this.monthYear,
    required this.rainfall,
    required this.stationId,
  });

  factory RainfallModel.fromJson(Map<String, dynamic> json, String postcode) {
    return RainfallModel(
      postcode: postcode,
      monthYear: json['month_year'],
      rainfall: json['precpt'],
      stationId: json['station_id'],
    );
  }

  Map<String, dynamic> toJson(String s) {
    return {
      'month': getMonth(monthYear),
      'monthYear': monthYear,
      'precpt': rainfall,
      'quality': 'Y',
      'station_id': stationId,
      'year': getYear(monthYear),
    };
  }

  String getMonth(String monthYear) {
    final month = monthYear.split('.')[0];
    return month;
  }

  String getYear(String monthYear) {
    final year = monthYear.split('.')[1];
    return year;
  }
}
