import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:water_tank_insights/logic/services/url_launcher.dart';
import 'package:water_tank_insights/ui/widgets/constrained_width_widget.dart';
import 'package:water_tank_insights/ui/widgets/input_field_widget.dart';

import '../../config/constants.dart';
import 'output_view.dart';

class WaterUsageView extends StatefulWidget {
  const WaterUsageView({super.key});

  @override
  State<WaterUsageView> createState() => _WaterUsageViewState();
}

class _WaterUsageViewState extends State<WaterUsageView> {
  late final TextEditingController numOfPeopleController;
  bool isPressed = false;
  int numOfPeople = 0;

  // List to store individual water usage for each person
  List<int> personWaterUsageList = [];

  // SharedPreferences keys
  static const String _numOfPeopleKey = 'num_of_people';
  static const String _personWaterUsageListKey = 'person_water_usage_list';

  // Loading state
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    numOfPeopleController = TextEditingController();
    _loadSavedData();
  }

  // Load saved data from SharedPreferences
  Future<void> _loadSavedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      setState(() {
        // Load number of people
        numOfPeople = prefs.getInt(_numOfPeopleKey) ?? 0;
        numOfPeopleController.text =
            numOfPeople > 0 ? numOfPeople.toString() : '';

        // Load individual person water usage
        final savedUsageList = prefs.getString(_personWaterUsageListKey);
        if (savedUsageList != null) {
          final List<dynamic> usageData = json.decode(savedUsageList);
          personWaterUsageList = usageData.cast<int>();
        }

        // Ensure the usage list matches the number of people
        _adjustUsageListSize();

        isLoading = false;
      });

      // Add listener for auto-save after loading data
      _addListener();
    } catch (e) {
      print('Error loading water usage data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  // Adjust usage list size to match number of people
  void _adjustUsageListSize() {
    while (personWaterUsageList.length < numOfPeople) {
      personWaterUsageList.add(200); // Default to average usage
    }
    if (personWaterUsageList.length > numOfPeople) {
      personWaterUsageList = personWaterUsageList.sublist(0, numOfPeople);
    }
  }

  // Add listener to controller for auto-save
  void _addListener() {
    numOfPeopleController.addListener(_saveData);
  }

  // Remove listener from controller
  void _removeListener() {
    numOfPeopleController.removeListener(_saveData);
  }

  // Save data to SharedPreferences
  Future<void> _saveData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Save number of people
      await prefs.setInt(_numOfPeopleKey, numOfPeople);

      // Save individual person water usage list
      await prefs.setString(
        _personWaterUsageListKey,
        json.encode(personWaterUsageList),
      );
    } catch (e) {
      print('Error saving water usage data: $e');
    }
  }

  // Update number of people and adjust usage list
  void _updateNumOfPeople(int newCount) {
    if (newCount < 0 || newCount > 20) return;

    setState(() {
      numOfPeople = newCount;
      _adjustUsageListSize();
    });

    _saveData(); // Save data when count changes
  }

  // Update individual person's water usage
  void _updatePersonUsage(int personIndex, int usage) {
    if (personIndex < personWaterUsageList.length) {
      setState(() {
        personWaterUsageList[personIndex] = usage;
      });
      _saveData(); // Save data when usage changes
    }
  }

  // Calculate total water usage
  int _calculateTotalUsage() {
    return personWaterUsageList.fold(0, (sum, usage) => sum + usage);
  }

  // Show alert dialog with message
  void showAlertDialog(String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: kBorderRadius,
              side: kBorderSide,
            ),
            title: Text(message, style: subHeadingStyle),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text("Close", style: TextStyle(color: black)),
              ),
            ],
          ),
    );
  }

  // Get usage level text for display
  String _getUsageLevelText(int usage) {
    switch (usage) {
      case 100:
        return "Low (100L)";
      case 200:
        return "Avg (200L)";
      case 300:
        return "High (300L)";
      default:
        return "Avg (200L)";
    }
  }

  @override
  void dispose() {
    _removeListener();
    numOfPeopleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Show loading spinner while data is being loaded
    if (isLoading) {
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
        body: Center(child: CircularProgressIndicator(color: white)),
      );
    }

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
              spacing: 32,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ConstrainedWidthWidget(
                  child: Text("Water Usage", style: headingStyle),
                ),
                ConstrainedWidthWidget(
                  child: Text(
                    "How many people live in your household?",
                    style: inputFieldStyle,
                  ),
                ),
                ConstrainedWidthWidget(
                  child: InputFieldWidget(
                    controller: numOfPeopleController,
                    label: "Number of people (1-20)",
                    onChanged: (number) {
                      // Ensure number within range
                      try {
                        final n = int.parse(number);
                        if (n < 1 || n > 20) {
                          if (number.isNotEmpty) {
                            showAlertDialog(
                              "Please enter a number of people between 1 and 20",
                            );
                          }
                          return;
                        }
                        _updateNumOfPeople(n);
                      } catch (e) {
                        if (number.isNotEmpty) {
                          showAlertDialog(
                            "Please enter a valid number of people between 1 and 20",
                          );
                        }
                      }
                    },
                  ),
                ),

                // Generate individual usage selectors for each person
                if (numOfPeople > 0) ...[
                  ConstrainedWidthWidget(
                    child: Text(
                      "Select water usage level for each person:",
                      style: inputFieldStyle,
                    ),
                  ),

                  for (int i = 0; i < numOfPeople; i++)
                    ConstrainedWidthWidget(
                      child: Card(
                        margin: EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: kBorderRadius,
                          side: BorderSide(
                            color: Colors.grey.shade300,
                            width: 1,
                          ),
                        ),
                        color: white,
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Person ${i + 1}",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: black,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                "Current: ${_getUsageLevelText(personWaterUsageList[i])} per day",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              SizedBox(height: 12),
                              SegmentedButton<int>(
                                style: segButtonStyle,
                                segments: [
                                  ButtonSegment(
                                    value: 100,
                                    label: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        children: [
                                          Text("Low"),
                                          Text(
                                            "100L",
                                            style: TextStyle(fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  ButtonSegment(
                                    value: 200,
                                    label: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        children: [
                                          Text("Avg"),
                                          Text(
                                            "200L",
                                            style: TextStyle(fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  ButtonSegment(
                                    value: 300,
                                    label: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        children: [
                                          Text("High"),
                                          Text(
                                            "300L",
                                            style: TextStyle(fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                                selected: {personWaterUsageList[i]},
                                onSelectionChanged: (value) {
                                  _updatePersonUsage(i, value.first);
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // Show total usage summary
                  ConstrainedWidthWidget(
                    child: Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        border: Border.all(
                          color: Colors.blue.shade200,
                          width: 2,
                        ),
                        borderRadius: kBorderRadius,
                      ),
                      child: Column(
                        children: [
                          Text(
                            "Household Total",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: black,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            "${_calculateTotalUsage()} litres per day",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                // Link to website for more accurate estimates
                ConstrainedWidthWidget(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "For more accurate estimates:",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      TextButton(
                        child: Text("click here"),
                        onPressed: () => UrlLauncher.launchWaterUsageTool(),
                      ),
                    ],
                  ),
                ),

                // Button to continue
                if (numOfPeople > 0)
                  Tooltip(
                    message: "Continue to results",
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: 500),
                      child: InkWell(
                        borderRadius: kBorderRadius,
                        onTap: () {
                          // Handle button press animation
                          setState(() {
                            isPressed = true;
                          });
                          Future.delayed(
                            const Duration(milliseconds: 150),
                          ).then((value) {
                            setState(() {
                              isPressed = false;
                            });
                          });

                          final totalWaterUsage = _calculateTotalUsage();

                          // Show dialog with results that enables nav to output page
                          showDialog(
                            context: context,
                            builder:
                                (context) => AlertDialog(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: kBorderRadius,
                                    side: kBorderSide,
                                  ),
                                  title: Text(
                                    'Water Usage Results',
                                    style: subHeadingStyle,
                                  ),
                                  content: SingleChildScrollView(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Household Summary:",
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: black,
                                          ),
                                        ),
                                        SizedBox(height: 8),
                                        for (int i = 0; i < numOfPeople; i++)
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 2,
                                            ),
                                            child: Text(
                                              "Person ${i + 1}: ${personWaterUsageList[i]}L/day",
                                              style: TextStyle(fontSize: 14),
                                            ),
                                          ),
                                        Divider(),
                                        Text(
                                          "Total: $totalWaterUsage litres per day",
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue.shade800,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed:
                                          () => Navigator.of(context).pop(),
                                      child: const Text(
                                        "Back",
                                        style: TextStyle(color: black),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();

                                        // Save data before navigating
                                        _saveData();

                                        // nav to output view
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => OutputView(),
                                          ),
                                        );
                                      },
                                      child: const Text(
                                        "Continue",
                                        style: TextStyle(
                                          color: black,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
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
