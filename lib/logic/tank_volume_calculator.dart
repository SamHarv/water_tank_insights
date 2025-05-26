class TankVolumeCalculator {
  int calculateRectVolume(double height, double width, double length) {
    final volume = height * width * length;
    return cubicMToLitres(volume);
  }

  int calculateCircVolume(double diameter, double height) {
    final radius = diameter / 2;
    final volume = 3.14 * radius * radius * height;
    return cubicMToLitres(volume);
  }

  int cubicMToLitres(double cubicMeters) {
    return (cubicMeters * 1000).round();
  }
}
