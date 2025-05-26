class Tank {
  final String id;
  int capacity;
  int waterLevel;
  bool isRectangular;
  double length;
  double width;
  double height;
  double waterHeight;
  double diameter;

  Tank({
    required this.id,
    this.capacity = 0,
    this.waterLevel = 0,
    this.isRectangular = true,
    this.length = 0,
    this.width = 0,
    this.height = 0,
    this.waterHeight = 0,
    this.diameter = 0,
  });
}
