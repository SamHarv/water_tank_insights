// lib/ui/views/location_view.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:water_tank_insights/ui/views/tank_inventory_view.dart';
import 'package:water_tank_insights/ui/widgets/constrained_width_widget.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../config/constants.dart';
import '../../data/api/rainfall_api.dart';
import '../../logic/services/postcode_service.dart';

class LocationView extends StatefulWidget {
  const LocationView({super.key});

  @override
  State<LocationView> createState() => _LocationViewState();
}

class _LocationViewState extends State<LocationView> {
  // Button state for press animation
  bool isPressed = false;
  double yearSelected = DateTime.now().year.toDouble();
  String timePeriod = "Monthly";
  String? selectedPostcode;

  // Chart data
  List<MonthlyRainfall>? monthlyRainfallData;
  double? annualRainfall;
  bool isLoadingChart = false;
  String? chartError;

  // Instant access to hardcoded postcodes
  List<PostcodeInfo> availablePostcodes =
      PostcodesService.getAvailablePostcodeInfos();

  // SharedPreferences keys
  static const String _postcodeKey = 'selected_postcode';
  static const String _yearKey = 'selected_year';
  static const String _timePeriodKey = 'selected_time_period';

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  // Load saved location data
  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      selectedPostcode = prefs.getString(_postcodeKey);
      yearSelected =
          prefs.getDouble(_yearKey) ?? DateTime.now().year.toDouble();
      timePeriod = prefs.getString(_timePeriodKey) ?? "Monthly";
    });

    // Load chart data if postcode is selected
    if (selectedPostcode != null) {
      _loadChartData();
    }
  }

  // Load chart data from API - only called after postcode selection
  Future<void> _loadChartData() async {
    if (selectedPostcode == null) return;

    // Enforce reasonable year limits (API might not have very old data)
    final constrainedYear = yearSelected.toInt().clamp(
      1990,
      DateTime.now().year,
    );

    setState(() {
      isLoadingChart = true;
      chartError = null;
    });

    try {
      print(
        'Loading data for postcode: $selectedPostcode, year: $constrainedYear',
      );

      // Fetch rainfall data from API
      final List<RainfallRecord> rainfallRecords =
          await RainfallApiService.getRainfallData(
            postcode: selectedPostcode!,
            year: constrainedYear,
          );

      print('Received ${rainfallRecords.length} records from API');

      if (timePeriod == "Monthly") {
        // Convert API data to monthly rainfall
        final monthlyData = _convertToMonthlyRainfall(
          rainfallRecords,
          constrainedYear,
        );
        setState(() {
          monthlyRainfallData = monthlyData;
          annualRainfall = null;
          isLoadingChart = false;
        });
      } else {
        // Calculate annual total
        final total = rainfallRecords
            .where((record) => record.year == constrainedYear)
            .fold<double>(0, (sum, record) => sum + record.rainfall);
        setState(() {
          annualRainfall = total;
          monthlyRainfallData = null;
          isLoadingChart = false;
        });
      }
    } catch (e) {
      print('Error loading chart data: $e');
      setState(() {
        chartError = 'Failed to load rainfall data: ${e.toString()}';
        isLoadingChart = false;
      });
    }
  }

  // Convert API rainfall records to monthly data
  List<MonthlyRainfall> _convertToMonthlyRainfall(
    List<RainfallRecord> records,
    int year,
  ) {
    // Group records by month
    Map<int, double> monthlyTotals = {};

    for (final record in records) {
      if (record.year == year) {
        monthlyTotals[record.month] =
            (monthlyTotals[record.month] ?? 0) + record.rainfall;
      }
    }

    // Create data for all 12 months (fill missing months with 0)
    return List.generate(12, (index) {
      final month = index + 1;
      return MonthlyRainfall(
        month: month,
        totalRainfall: monthlyTotals[month] ?? 0,
      );
    });
  }

  // Save location data
  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();

    if (selectedPostcode != null) {
      await prefs.setString(_postcodeKey, selectedPostcode!);
    }
    await prefs.setDouble(_yearKey, yearSelected);
    await prefs.setString(_timePeriodKey, timePeriod);
  }

  // Updated _buildRainfallChart method for location_view.dart
  Widget _buildRainfallChart() {
    if (isLoadingChart) {
      return Container(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: blue),
              SizedBox(height: 16),
              Text(
                'Loading rainfall data...',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    if (chartError != null) {
      return Container(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red),
              SizedBox(height: 16),
              Text(
                'Error Loading Data',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade700,
                ),
              ),
              SizedBox(height: 8),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  chartError!,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.red.shade600),
                ),
              ),
              SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _loadChartData,
                icon: Icon(Icons.refresh),
                label: Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: blue,
                  foregroundColor: white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (timePeriod == "Monthly" && monthlyRainfallData != null) {
      // Check if all months have zero rainfall (no data)
      final hasData = monthlyRainfallData!.any(
        (month) => month.totalRainfall > 0,
      );

      if (!hasData) {
        return _buildNoDataMessage();
      }

      return _buildMonthlyChart();
    } else if (timePeriod == "Annual" && annualRainfall != null) {
      if (annualRainfall == 0) {
        return _buildNoDataMessage();
      }
      return _buildAnnualChart();
    }

    return Container(
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_on, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              "Select a postcode to view rainfall data",
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  // Add this new method to show a no-data message
  Widget _buildNoDataMessage() {
    final constrainedYear = yearSelected.toInt().clamp(
      1990,
      DateTime.now().year,
    );

    return Container(
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No Weather Data Available',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Weather data for postcode $selectedPostcode\nis not available for $constrainedYear',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _loadChartData,
                  icon: Icon(Icons.refresh),
                  label: Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: blue,
                    foregroundColor: white,
                  ),
                ),
                SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    setState(() {
                      yearSelected = DateTime.now().year.toDouble();
                    });
                    _loadChartData();
                  },
                  child: Text('Try Current Year'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Build monthly bar chart
  Widget _buildMonthlyChart() {
    // Calculate max value, ensuring it's never 0
    final maxValue = monthlyRainfallData!
        .map((e) => e.totalRainfall)
        .reduce((a, b) => a > b ? a : b);

    // If all values are 0, set a default max to avoid division by zero
    final maxY = maxValue > 0 ? maxValue * 1.2 : 10.0;

    return Container(
      height: 200,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final month = monthlyRainfallData![group.x.toInt()];
                return BarTooltipItem(
                  '${month.monthName}\n${rod.toY.toStringAsFixed(1)} mm',
                  TextStyle(color: white, fontSize: 12),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() < monthlyRainfallData!.length) {
                    return Text(
                      monthlyRainfallData![value.toInt()].monthName,
                      style: TextStyle(
                        color: black,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    );
                  }
                  return Text('');
                },
                reservedSize: 30,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                interval: maxY > 10 ? null : 2,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${value.toInt()}',
                    style: TextStyle(
                      color: black,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  );
                },
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY > 0 ? maxY / 5 : 2,
            getDrawingHorizontalLine: (value) {
              return FlLine(color: Colors.grey.shade300, strokeWidth: 1);
            },
          ),
          borderData: FlBorderData(
            show: true,
            border: Border(
              bottom: BorderSide(color: black, width: 2),
              left: BorderSide(color: black, width: 2),
            ),
          ),
          barGroups:
              monthlyRainfallData!.asMap().entries.map((entry) {
                return BarChartGroupData(
                  x: entry.key,
                  barRods: [
                    BarChartRodData(
                      toY: entry.value.totalRainfall,
                      color: blue,
                      width: 20,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(6),
                        topRight: Radius.circular(6),
                      ),
                    ),
                  ],
                );
              }).toList(),
        ),
      ),
    );
  }

  // Build annual summary chart
  Widget _buildAnnualChart() {
    final constrainedYear = yearSelected.toInt().clamp(
      1990,
      DateTime.now().year,
    );

    return Container(
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.water_drop, size: 48, color: blue),
            SizedBox(height: 16),
            Text(
              'Total Annual Rainfall',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              '${annualRainfall!.toStringAsFixed(1)} mm',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: blue,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Year $constrainedYear',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            SizedBox(height: 4),
            Text(
              'Postcode $selectedPostcode',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaWidth = MediaQuery.sizeOf(context).width;
    final constrainedYear = yearSelected.toInt().clamp(
      1990,
      DateTime.now().year,
    );

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 80,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: true,
        leadingWidth: 80,
        leading: IconButton(
          icon: Padding(
            padding: EdgeInsets.fromLTRB(24, 12, 32, 12),
            child: Icon(Icons.arrow_back_ios_new),
          ),
          color: white,
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Hero(
            tag: "logo",
            child: Padding(
              padding: EdgeInsets.fromLTRB(0, 12, 48, 12),
              child: Image.asset(logo),
            ),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: kPadding,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 32,
              children: [
                ConstrainedWidthWidget(
                  child: Text("Location", style: headingStyle),
                ),
                ConstrainedWidthWidget(
                  child: Text("Enter your location:", style: inputFieldStyle),
                ),

                // Postcode dropdown
                Tooltip(
                  message: "Enter your postcode.",
                  child: ConstrainedWidthWidget(
                    child: DropdownMenu<String>(
                      width: mediaWidth * 0.8,
                      initialSelection: selectedPostcode,
                      dropdownMenuEntries:
                          availablePostcodes
                              .map(
                                (pc) => DropdownMenuEntry(
                                  value: pc.postcode,
                                  label: pc.postcode,
                                ),
                              )
                              .toList(),
                      label: Text("Postcode"),
                      menuStyle: MenuStyle(
                        maximumSize: WidgetStateProperty.all(
                          Size(mediaWidth * 0.8, 300),
                        ),
                        backgroundColor: WidgetStateProperty.all(white),
                        elevation: WidgetStateProperty.all(8),
                        shape: WidgetStateProperty.all(
                          RoundedRectangleBorder(
                            borderRadius: kBorderRadius,
                            side: kBorderSide,
                          ),
                        ),
                      ),
                      inputDecorationTheme: InputDecorationTheme(
                        border: inputBorder,
                        enabledBorder: inputBorder,
                        focusedBorder: inputBorder,
                        filled: true,
                        fillColor: white,
                        labelStyle: inputFieldStyle,
                      ),
                      textStyle: inputFieldStyle,
                      enableFilter: true,
                      hintText:
                          "Select postcode (${PostcodesService.count} available)",
                      onSelected: (postcode) {
                        setState(() {
                          selectedPostcode = postcode;
                        });
                        _saveData();
                        // Load data after postcode is selected
                        _loadChartData();
                      },
                    ),
                  ),
                ),

                // Year selection slider
                ConstrainedWidthWidget(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Year", style: inputFieldStyle),
                      SizedBox(width: 32),
                      Text(constrainedYear.toString(), style: headingStyle),
                      SizedBox(width: 8),
                      Expanded(
                        child: Slider(
                          value: yearSelected,
                          activeColor: black,
                          secondaryActiveColor: white,
                          thumbColor: white,
                          min:
                              1990.toDouble(), // Adjusted for API data availability
                          max: DateTime.now().year.toDouble(),
                          onChanged: (value) {
                            setState(() {
                              yearSelected = value;
                            });
                          },
                          onChangeEnd: (value) {
                            _saveData();
                            // Load data if postcode is selected
                            if (selectedPostcode != null) {
                              _loadChartData();
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // Chart to visualise rainfall
                ConstrainedWidthWidget(
                  child: Container(
                    decoration: BoxDecoration(
                      color: white,
                      border: Border.all(color: black, width: 3),
                      borderRadius: kBorderRadius,
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(
                        child: Column(
                          spacing: 16,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text("Rainfall Data", style: subHeadingStyle),
                                if (selectedPostcode != null && !isLoadingChart)
                                  Padding(
                                    padding: EdgeInsets.only(left: 8),
                                    child: Chip(
                                      label: Text(
                                        selectedPostcode!,
                                        style: TextStyle(fontSize: 12),
                                      ),
                                      backgroundColor: blue.withOpacity(0.1),
                                    ),
                                  ),
                              ],
                            ),
                            _buildRainfallChart(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Segmented button for monthly/annual view
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 500),
                  child: SizedBox(
                    width: mediaWidth * 0.8,
                    child: SegmentedButton(
                      selectedIcon: Icon(Icons.check, color: black),
                      style: segButtonStyle,
                      segments: [
                        ButtonSegment(
                          value: "Monthly",
                          label: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text("Monthly"),
                          ),
                        ),
                        ButtonSegment(
                          value: "Annual",
                          label: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text("Annual"),
                          ),
                        ),
                      ],
                      selected: {timePeriod},
                      onSelectionChanged: (Set<String> newSelection) {
                        setState(() {
                          timePeriod = newSelection.first;
                        });
                        _saveData();
                        // Load data if postcode is selected
                        if (selectedPostcode != null) {
                          _loadChartData();
                        }
                      },
                    ),
                  ),
                ),

                // Continue button
                Tooltip(
                  message: "Continue to next step",
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 500),
                    child: InkWell(
                      borderRadius: kBorderRadius,
                      onTap: () {
                        setState(() {
                          isPressed = true;
                        });
                        Future.delayed(const Duration(milliseconds: 150)).then((
                          value,
                        ) {
                          setState(() {
                            isPressed = false;
                          });
                        });

                        _saveData();

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const TankInventoryView(),
                          ),
                        );
                      },
                      child: AnimatedContainer(
                        width: mediaWidth * 0.8,
                        duration: const Duration(milliseconds: 100),
                        decoration: BoxDecoration(
                          color: white,
                          border: Border.all(color: black, width: 3),
                          borderRadius: kBorderRadius,
                          boxShadow: [isPressed ? BoxShadow() : kShadow],
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(
                            child: Text("Continue", style: subHeadingStyle),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Simple data model for monthly rainfall (matching your existing structure)
class MonthlyRainfall {
  final int month;
  final double totalRainfall;

  MonthlyRainfall({required this.month, required this.totalRainfall});

  String get monthName {
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
}
