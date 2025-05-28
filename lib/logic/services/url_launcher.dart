import 'package:url_launcher/url_launcher.dart';

class UrlLauncher {
  /// Class to acces [UrlLauncher]

  /// Launch water usage estimate website
  static Future<void> launchWaterUsageTool() async {
    if (!await launchUrl(
      Uri.parse('https://smartwatermark.org/watercalculator/NSW/#results'),
    )) {
      throw 'Could not launch https://smartwatermark.org/watercalculator/NSW/#results';
    }
  }

  /// Launch water optimisation tips website
  static Future<void> launchOptimisationTips() async {
    if (!await launchUrl(
      Uri.parse('https://www.yourhome.gov.au/water/reducing-water-use'),
    )) {
      throw 'Could not launch https://www.yourhome.gov.au/water/reducing-water-use';
    }
  }
}
