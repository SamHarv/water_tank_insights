import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:water_tank_insights/ui/views/tank_inventory_view.dart';
import 'package:water_tank_insights/ui/widgets/constrained_width_widget.dart';

import '../../config/constants.dart';

class LocationView extends StatefulWidget {
  const LocationView({super.key});

  @override
  State<LocationView> createState() => _LocationViewState();
}

class _LocationViewState extends State<LocationView> {
  // Button state for animation
  bool isPressed = false;
  double yearSelected = DateTime.now().year.toDouble();
  String timePeriod = "Monthly";
  String? selectedPostcode;

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

  @override
  Widget build(BuildContext context) {
    // Width of screen
    final mediaWidth = MediaQuery.sizeOf(context).width;
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
          onPressed: () => Navigator.pop(context), // Back to prev view
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
                // Enter your location
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
                      dropdownMenuEntries: [
                        // TODO: update postcodes
                        DropdownMenuEntry(
                          value: "0000",
                          label: "0000 - Sample Area",
                        ),
                        DropdownMenuEntry(
                          value: "3000",
                          label: "3000 - Melbourne CBD",
                        ),
                        DropdownMenuEntry(
                          value: "5000",
                          label: "5000 - Adelaide CBD",
                        ),
                      ],
                      label: Text("Postcode"),
                      menuStyle: MenuStyle(
                        maximumSize: WidgetStateProperty.all(
                          Size.fromWidth(500),
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
                      hintText: "Select postcode",
                      onSelected: (postcode) {
                        setState(() {
                          selectedPostcode = postcode;
                        });
                        _saveData(); // Auto-save when postcode changes
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
                      Text(
                        yearSelected.toInt().toString(),
                        style: headingStyle,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Slider(
                          value: yearSelected,
                          activeColor: black,
                          secondaryActiveColor: white,
                          thumbColor: white,
                          // TODO: double check 1890 is earliest year
                          min: 1890,
                          // Default to current year
                          max: DateTime.now().year.toDouble(),
                          onChanged: (value) {
                            setState(() {
                              yearSelected = value;
                            });
                          },
                          onChangeEnd: (value) {
                            _saveData(); // Save when slider stops moving
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
                            Text("Rainfall Data", style: subHeadingStyle),
                            // TODO: Bar chart indicating rainfall in location for given period
                            Placeholder(fallbackHeight: 150),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                // Segmented button for monthly/ annual rainfall filter for chart
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
                        _saveData(); // Auto-save when time period changes
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
                        // Handle button press animation
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

                        // Save data before navigating
                        _saveData();

                        // Navigate to tank inventory calculator
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
