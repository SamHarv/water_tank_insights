import 'package:flutter_test/flutter_test.dart';
import 'package:water_tank_insights/logic/tank_volume_calculator.dart';

void main() {
  // write some unit tests for my TankVolumeCalculator class
  group("Tank Volume Calculator", () {
    final tankVolumeCalculator = TankVolumeCalculator();
    test("Calculate Rectangular Tank Volume", () {
      // Test the recatangular tank volume calculator
      // Test 1
      expect(tankVolumeCalculator.calculateRectVolume(1, 1, 1), 1000);
      // Test 2
      expect(tankVolumeCalculator.calculateRectVolume(0.5, 1, 1), 500);
    });
    test("Calculate Circular Tank Volume", () {});
    test("Cubic Metres to Litres", () {});
  });
}
