// lib/logic/services/postcodes_service.dart
// This service manages the hardcoded postcodes efficiently

class PostcodesService {
  static const List<int> _availablePostcodes = [
    5159,
    5000,
    5001,
    5800,
    5801,
    5810,
    5839,
    5950,
    5005,
    5014,
    5154,
    5173,
    5009,
    5351,
    5114,
    5255,
    5010,
    5117,
    5043,
    5157,
    5035,
    5137,
    5076,
    5012,
    5072,
    5501,
    5211,
    5203,
    5242,
    5091,
    5138,
    5066,
    5042,
    5052,
    5050,
    5352,
    5067,
    5118,
    5153,
    5234,
    5015,
    5201,
    5051,
    5084,
    5250,
    5171,
    5110,
    5007,
    5109,
    5155,
    5048,
    5083,
    5032,
    5062,
    5252,
    5120,
    5251,
    5038,
    5074,
    5204,
    5144,
    5094,
    5231,
    5244,
    5134,
    5164,
    5165,
    5039,
    5034,
    5256,
    5085,
    5152,
    5069,
    5081,
    5041,
    5033,
    5235,
    5008,
    5232,
    5214,
    5047,
    5355,
    5113,
    5075,
    5172,
    5065,
    5150,
    5063,
    5111,
    5112,
    5116,
    5019,
    5121,
    5126,
    5070,
    5023,
    5502,
    5082,
    5025,
    5139,
    5233,
    5372,
    5024,
    5086,
    5013,
    5037,
    5045,
    5044,
    5064,
    5125,
    5022,
    5107,
    5140,
    5360,
    5096,
    5163,
    5245,
    5158,
    5068,
    5073,
    5089,
    5202,
    5088,
    5090,
    5141,
    5131,
    5061,
    5098,
    5133,
    5071,
    5049,
    5087,
    5115,
    5259,
    5016,
    5240,
    5241,
    5160,
    5170,
    5095,
    5213,
    5031,
    5169,
    5092,
    5162,
    5210,
    5168,
    5006,
    5018,
    5136,
    5040,
    5243,
    5046,
    5161,
    5017,
    5166,
    5132,
    5106,
    5108,
    5093,
    5353,
    5254,
    5151,
    5400,
    5212,
    5167,
    5097,
    5942,
    5350,
    5371,
    5174,
    5011,
    5236,
    5156,
    5142,
    5021,
    5020,
    5127,
  ];

  // Get available postcodes length
  static int get length => _availablePostcodes.length;

  /// Get all available postcodes as strings
  static List<String> getAvailablePostcodes() {
    return _availablePostcodes.map((postcode) => postcode.toString()).toList();
  }

  /// Get all available postcodes as PostcodeInfo objects
  static List<PostcodeInfo> getAvailablePostcodeInfos() {
    return _availablePostcodes
        .map((postcode) => PostcodeInfo(postcode: postcode.toString()))
        .toList();
  }

  /// Check if a postcode is valid/available
  static bool isValidPostcode(String postcode) {
    try {
      final postcodeInt = int.parse(postcode);
      return _availablePostcodes.contains(postcodeInt);
    } catch (e) {
      return false;
    }
  }

  /// Get total number of available postcodes
  static int get count => _availablePostcodes.length;

  /// Search postcodes by prefix (for filtering)
  static List<String> searchPostcodes(String prefix) {
    if (prefix.isEmpty) return getAvailablePostcodes();

    return _availablePostcodes
        .where((postcode) => postcode.toString().startsWith(prefix))
        .map((postcode) => postcode.toString())
        .toList();
  }
}

// Simplified PostcodeInfo class
class PostcodeInfo {
  final String postcode;

  PostcodeInfo({required this.postcode});

  String get displayName => postcode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PostcodeInfo &&
          runtimeType == other.runtimeType &&
          postcode == other.postcode;

  @override
  int get hashCode => postcode.hashCode;

  @override
  String toString() => postcode;
}
