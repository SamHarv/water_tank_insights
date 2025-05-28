import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:water_tank_insights/logic/tank_volume_calculator.dart';
import 'package:water_tank_insights/ui/widgets/constrained_width_widget.dart';
import 'package:water_tank_insights/ui/widgets/input_field_widget.dart';

import '../../config/constants.dart';
import '../../data/models/tank_model.dart';
import 'roof_catchment_view.dart';

class TankInventoryView extends StatefulWidget {
  const TankInventoryView({super.key});

  @override
  State<TankInventoryView> createState() => _TankInventoryViewState();
}

class _TankInventoryViewState extends State<TankInventoryView> {
  // Button state for animation
  bool isPressed = false;

  // List of tanks for multi-tank inputs
  List<Tank> tanks = [];
  // Number of tanks
  int numOfTanks = 1; // Default

  // Text controllers for each tank's input fields
  List<Map<String, TextEditingController>> tankControllers = [];
  // Track whether user knows capacity/level states per tank
  List<Map<String, bool>> tankStates = [];

  late final TextEditingController numOfTanksController;

  // SharedPreferences keys
  static const String _tanksKey = 'tanks_data';
  static const String _tankCountKey = 'tank_count';
  static const String _tankStatesKey = 'tank_states';

  // Loading state to prevent premature UI builds
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    numOfTanksController = TextEditingController();
    _loadSavedData(); // Load saved data
  }

  // Load saved data from SharedPreferences
  Future<void> _loadSavedData() async {
    try {
      // Instance of SharedPreferences
      final prefs = await SharedPreferences.getInstance();

      // Load tank count
      numOfTanks = prefs.getInt(_tankCountKey) ?? 1;
      numOfTanksController.text = numOfTanks.toString();

      // Load tank data
      final String? savedTanksData = prefs.getString(_tanksKey);
      final String? savedStatesData = prefs.getString(_tankStatesKey);

      if (savedTanksData != null) {
        // Decode JSON to Tank objects
        final List<dynamic> tankDataList = json.decode(savedTanksData);
        tanks =
            tankDataList.map((tankData) => Tank.fromJson(tankData)).toList();
      }

      if (savedStatesData != null) {
        // Decode JSON to load tank states - FIXED CASTING
        final List<dynamic> statesDataList = json.decode(savedStatesData);
        tankStates =
            statesDataList.map((state) {
              // Ensure proper casting for each state item
              final Map<String, dynamic> stateMap =
                  state as Map<String, dynamic>;
              return {
                'knowTankCapacity':
                    stateMap['knowTankCapacity'] as bool? ?? false,
                'knowTankWaterLevel':
                    stateMap['knowTankWaterLevel'] as bool? ?? false,
              };
            }).toList();
      }

      // Ensure we have the correct number of tank states
      while (tankStates.length < numOfTanks) {
        tankStates.add({
          'knowTankCapacity': false,
          'knowTankWaterLevel': false,
        });
      }
      if (tankStates.length > numOfTanks) {
        tankStates = tankStates.sublist(0, numOfTanks);
      }

      // Initialise tanks and controllers if not loaded from saved data
      if (tanks.isEmpty) {
        _initialiseTanks();
      } else {
        // Ensure we have the correct number of tanks
        while (tanks.length < numOfTanks) {
          tanks.add(Tank(id: tanks.length.toString()));
        }
        if (tanks.length > numOfTanks) {
          tanks = tanks.sublist(0, numOfTanks);
        }
        _initialiseControllersWithData();
      }

      _addListeners();

      // Set loading to false and update UI
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      // If there's an error loading data, initialise with defaults
      showAlertDialog("Error loading saved data: $e");
      _initialiseTanks();
      setState(() {
        isLoading = false;
      });
    }
  }

  // Initialise new tanks
  void _initialiseTanks() {
    // Ensure tanks data is empty
    tanks.clear();
    tankStates.clear();
    // Add new tanks based on numOfTanks input from user
    for (int i = 0; i < numOfTanks; i++) {
      tanks.add(Tank(id: i.toString()));
      tankStates.add({'knowTankCapacity': false, 'knowTankWaterLevel': false});
    }
    _initialiseControllers(); // Initialise text controllers for inputs
  }

  void _initialiseControllers() {
    _removeListeners();
    // Ensure controllers data is empty
    tankControllers.clear();

    // Add new controllers based on numOfTanks
    for (int i = 0; i < numOfTanks; i++) {
      tankControllers.add({
        'capacity': TextEditingController(),
        'waterLevel': TextEditingController(),
        'diameter': TextEditingController(),
        'width': TextEditingController(),
        'length': TextEditingController(),
        'height': TextEditingController(),
        'waterHeight': TextEditingController(),
      });
    }
  }

  // Initialise controllers with data
  void _initialiseControllersWithData() {
    _removeListeners();
    tankControllers.clear();

    for (int i = 0; i < numOfTanks; i++) {
      final tank = i < tanks.length ? tanks[i] : Tank(id: i.toString());
      tankControllers.add({
        'capacity': TextEditingController(
          text: tank.capacity > 0 ? tank.capacity.toString() : '',
        ),
        'waterLevel': TextEditingController(
          text: tank.waterLevel > 0 ? tank.waterLevel.toString() : '',
        ),
        'diameter': TextEditingController(
          text: tank.diameter > 0 ? tank.diameter.toString() : '',
        ),
        'width': TextEditingController(
          text: tank.width > 0 ? tank.width.toString() : '',
        ),
        'length': TextEditingController(
          text: tank.length > 0 ? tank.length.toString() : '',
        ),
        'height': TextEditingController(
          text: tank.height > 0 ? tank.height.toString() : '',
        ),
        'waterHeight': TextEditingController(
          text: tank.waterHeight > 0 ? tank.waterHeight.toString() : '',
        ),
      });
    }
  }

  // Add listeners to controllers
  void _addListeners() {
    for (var tankMap in tankControllers) {
      for (var controller in tankMap.values) {
        controller.addListener(_saveData);
      }
    }
  }

  // Remove listeners from controllers
  void _removeListeners() {
    for (var tankMap in tankControllers) {
      for (var controller in tankMap.values) {
        controller.removeListener(_saveData);
      }
    }
  }

  // Update number of tanks
  void _updateTankCount(int newCount) {
    if (newCount < 0 || newCount > 20) return;

    setState(() {
      _removeListeners();

      // Dispose controllers that are no longer needed
      if (newCount < tankControllers.length) {
        for (int i = newCount; i < tankControllers.length; i++) {
          for (var controller in tankControllers[i].values) {
            controller.dispose();
          }
        }
        tankControllers = tankControllers.sublist(0, newCount);
        tanks = tanks.sublist(0, newCount);
        tankStates = tankStates.sublist(0, newCount);
      } else {
        // Add new controllers and tanks for additional tanks
        for (int i = tankControllers.length; i < newCount; i++) {
          tankControllers.add({
            'capacity': TextEditingController(),
            'waterLevel': TextEditingController(),
            'diameter': TextEditingController(),
            'width': TextEditingController(),
            'length': TextEditingController(),
            'height': TextEditingController(),
            'waterHeight': TextEditingController(),
          });

          // Ensure we don't go beyond existing tanks when adding
          if (i < tanks.length) {
            // Tank already exists, keep it
          } else {
            tanks.add(Tank(id: i.toString()));
          }

          // Add tank state
          if (i < tankStates.length) {
            // State already exists, keep it
          } else {
            tankStates.add({
              'knowTankCapacity': false,
              'knowTankWaterLevel': false,
            });
          }
        }
      }
      numOfTanks = newCount;

      _addListeners();
      _saveData(); // Save data
    });
  }

  // Save data to SharedPreferences
  Future<void> _saveData() async {
    try {
      // Instance
      final prefs = await SharedPreferences.getInstance();

      // Save tank count
      await prefs.setInt(_tankCountKey, numOfTanks);

      // Update tank data from text controllers
      for (int i = 0; i < tanks.length && i < tankControllers.length; i++) {
        final controllers = tankControllers[i];
        tanks[i] = tanks[i].copyWith(
          capacity:
              int.tryParse(controllers['capacity']!.text) ?? tanks[i].capacity,
          waterLevel:
              int.tryParse(controllers['waterLevel']!.text) ??
              tanks[i].waterLevel,
          diameter:
              double.tryParse(controllers['diameter']!.text) ??
              tanks[i].diameter,
          width: double.tryParse(controllers['width']!.text) ?? tanks[i].width,
          length:
              double.tryParse(controllers['length']!.text) ?? tanks[i].length,
          height:
              double.tryParse(controllers['height']!.text) ?? tanks[i].height,
          waterHeight:
              double.tryParse(controllers['waterHeight']!.text) ??
              tanks[i].waterHeight,
        );
      }

      // Save tank data as JSON
      final tankDataList = tanks.map((tank) => tank.toJson()).toList();
      // Save tank data
      await prefs.setString(_tanksKey, json.encode(tankDataList));

      // Save tank states
      await prefs.setString(_tankStatesKey, json.encode(tankStates));
    } catch (e) {
      showAlertDialog('Error saving data: $e');
    }
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

  // Perform calculations on all tanks for output
  void _calculateAllTanks() {
    // Calculator instance
    final tankVolumeCalculator = TankVolumeCalculator();

    // Initialise variables
    double totalCapacity = 0;
    double totalInventory = 0;
    List<String> tankResults = [];

    // Loop through all tanks
    for (int i = 0; i < tanks.length; i++) {
      final tank = tanks[i];

      // Calculate capacity if not known
      if (i < tankStates.length && !tankStates[i]['knowTankCapacity']!) {
        tank.capacity =
            tank.isRectangular
                ? tankVolumeCalculator.calculateRectVolume(
                  tank.height,
                  tank.width,
                  tank.length,
                )
                : tankVolumeCalculator.calculateCircVolume(
                  tank.diameter,
                  tank.height,
                );
      }

      // Calculate water level if not known
      if (i < tankStates.length && !tankStates[i]['knowTankWaterLevel']!) {
        if (tank.waterHeight > tank.height) {
          showAlertDialog(
            "Water level cannot be higher than tank height for Tank ${i + 1}",
          );
          return;
        }
        tank.waterLevel =
            tank.isRectangular
                ? tankVolumeCalculator.calculateRectVolume(
                  tank.waterHeight,
                  tank.width,
                  tank.length,
                )
                : tankVolumeCalculator.calculateCircVolume(
                  tank.diameter,
                  tank.waterHeight,
                );
      }

      // Calculate total capacity and inventory
      totalCapacity += tank.capacity;
      totalInventory += tank.waterLevel;
      // Add results to list of strings for output
      tankResults.add(
        "Tank ${i + 1}: ${tank.capacity}L capacity, ${tank.waterLevel}L current",
      );
    }

    // Show results dialog
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: kBorderRadius,
              side: kBorderSide,
            ),
            title: Text('Tank Analysis Results', style: subHeadingStyle),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Capacity: ${totalCapacity.toInt()} L',
                    style: outputValueStyle,
                  ),
                  Text(
                    'Total Inventory: ${totalInventory.toInt()} L',
                    style: outputValueStyle,
                  ),
                  Text(
                    'Available Space: ${(totalCapacity - totalInventory).toInt()} L',
                    style: outputValueStyle,
                  ),
                  Text(
                    'Fill Percentage: ${totalCapacity > 0 ? ((totalInventory / totalCapacity) * 100).toStringAsFixed(1) : "0.0"}%',
                    style: outputValueStyle,
                  ),
                  SizedBox(height: 16),
                  // Display results for each tank
                  Text('Individual Tanks:', style: subHeadingStyle),
                  ...tankResults.map(
                    (result) => Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: Text(result, style: TextStyle(fontSize: 14)),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("Back", style: TextStyle(color: black)),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RoofCatchmentView(),
                    ),
                  );
                },
                child: const Text(
                  "Continue",
                  style: TextStyle(color: black, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
    );

    _saveData(); // Save updated calculations
  }

  @override
  void dispose() {
    _removeListeners();
    numOfTanksController.dispose();
    // Dispose controllers
    for (var tankMap in tankControllers) {
      for (var controller in tankMap.values) {
        controller.dispose();
      }
    }
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
        body: Center(child: CircularProgressIndicator(color: white)),
      );
    }

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
                ConstrainedWidthWidget(
                  child: Text(
                    "Tank Inventory Calculations",
                    style: headingStyle,
                  ),
                ),
                // How many tanks?
                ConstrainedWidthWidget(
                  child: Text(
                    "How many water tanks do you have?",
                    style: inputFieldStyle,
                  ),
                ),
                ConstrainedWidthWidget(
                  child: InputFieldWidget(
                    onChanged: (value) {
                      try {
                        // Parse input to int
                        int newCount = int.parse(value);
                        // Control range
                        if (newCount > 20) {
                          showAlertDialog(
                            "Please enter a number between 0 and 20",
                          );
                          return;
                        }
                        _updateTankCount(newCount); // Update tank count
                      } catch (e) {
                        if (value.isNotEmpty) {
                          showAlertDialog(
                            "Please enter a valid number between 0 and 20",
                          );
                        }
                      }
                    },
                    controller: numOfTanksController,
                    label: "Number of tanks (0-20)",
                  ),
                ),

                // Individual tank configurations
                if (numOfTanks > 0) ...[
                  // Build tank card for each tank
                  for (int tankIndex = 0; tankIndex < numOfTanks; tankIndex++)
                    _buildTankCard(context, tankIndex),

                  // Calculate all tanks button
                  Tooltip(
                    message: "Calculate capacity and inventory for all tanks",
                    child: ConstrainedWidthWidget(
                      child: InkWell(
                        borderRadius: kBorderRadius,
                        onTap: () {
                          setState(() {
                            isPressed = true;
                          });
                          Future.delayed(
                            const Duration(milliseconds: 150),
                          ).then((value) {
                            setState(() {
                              isPressed = false;
                            });
                            _calculateAllTanks(); // Perform calculations
                          });
                        },
                        child: AnimatedContainer(
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
                              child: Text(
                                "Calculate All Tanks",
                                style: subHeadingStyle,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTankCard(BuildContext context, int tankIndex) {
    // Safety checks to prevent index out of range errors
    if (tankIndex >= tanks.length) return SizedBox.shrink();
    if (tankIndex >= tankControllers.length) return SizedBox.shrink();
    if (tankIndex >= tankStates.length) return SizedBox.shrink();

    // Get data
    final tank = tanks[tankIndex];
    final controllers = tankControllers[tankIndex];
    final states = tankStates[tankIndex];

    return ConstrainedWidthWidget(
      child: Card(
        margin: EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: kBorderRadius,
          side: kBorderSide,
        ),
        color: white,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 24,
            children: [
              // Tank header
              Text(
                "Tank ${tankIndex + 1} of $numOfTanks",
                style: inputFieldStyle,
              ),

              // Do you know the tank's capacity?
              Text("Do you know the tank's capacity?", style: inputFieldStyle),
              ConstrainedWidthWidget(
                child: SegmentedButton(
                  selectedIcon: Icon(Icons.check, color: black),
                  style: segButtonStyle,
                  segments: [
                    ButtonSegment(
                      value: true,
                      label: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text("Yes"),
                      ),
                    ),
                    ButtonSegment(
                      value: false,
                      label: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text("No"),
                      ),
                    ),
                  ],
                  // Set selected segment based on data
                  selected: {states['knowTankCapacity']!},
                  onSelectionChanged: (Set<bool> newSelection) {
                    // Update data
                    setState(() {
                      tankStates[tankIndex]['knowTankCapacity'] =
                          newSelection.first;
                    });
                    _saveData();
                  },
                ),
              ),

              // Tank capacity input (if known)
              if (states['knowTankCapacity']!) ...[
                InputFieldWidget(
                  controller: controllers['capacity']!,
                  label: "Tank capacity (L)",
                  onChanged: (value) {
                    try {
                      tanks[tankIndex].capacity = int.tryParse(value) ?? 0;
                    } catch (e) {
                      showAlertDialog("Please enter a number (litres)");
                    }
                  },
                ),
              ],

              // Do you know how full the tank is?
              Text("Do you know how full the tank is?", style: inputFieldStyle),
              ConstrainedWidthWidget(
                child: SegmentedButton(
                  selectedIcon: Icon(Icons.check, color: black),
                  style: segButtonStyle,
                  segments: [
                    ButtonSegment(
                      value: true,
                      label: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text("Yes"),
                      ),
                    ),
                    ButtonSegment(
                      value: false,
                      label: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text("No"),
                      ),
                    ),
                  ],
                  // Set selected segment based on data
                  selected: {states['knowTankWaterLevel']!},
                  onSelectionChanged: (Set<bool> newSelection) {
                    // Update data
                    setState(() {
                      tankStates[tankIndex]['knowTankWaterLevel'] =
                          newSelection.first;
                    });
                    _saveData();
                  },
                ),
              ),

              // Tank water level input (if known)
              if (states['knowTankWaterLevel']!) ...[
                InputFieldWidget(
                  controller: controllers['waterLevel']!,
                  label: "Tank level (L)",
                  onChanged: (value) {
                    try {
                      tanks[tankIndex].waterLevel = int.tryParse(value) ?? 0;
                      if (tanks[tankIndex].waterLevel >
                          tanks[tankIndex].capacity) {
                        showAlertDialog(
                          "Tank level cannot be greater than capacity",
                        );
                        tanks[tankIndex].waterLevel = tanks[tankIndex].capacity;
                        controllers['waterLevel']!.text =
                            tanks[tankIndex].waterLevel.toString();
                      }
                    } catch (e) {
                      showAlertDialog("Please enter a number (litres)");
                    }
                  },
                ),
              ],

              // Get dimensions based on shape of tank (if capacity not known)
              if (!states['knowTankCapacity']!) ...[
                Text(
                  "Is the footprint of the tank circular or rectangular?",
                  style: inputFieldStyle,
                ),
                ConstrainedWidthWidget(
                  child: SegmentedButton(
                    selectedIcon: Icon(Icons.check, color: black),
                    style: segButtonStyle,
                    segments: [
                      ButtonSegment(
                        value: false,
                        label: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text("Circular"),
                        ),
                      ),
                      ButtonSegment(
                        value: true,
                        label: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text("Rectangular"),
                        ),
                      ),
                    ],
                    // Set selected segment based on data
                    selected: {tank.isRectangular},
                    onSelectionChanged: (Set<bool> newSelection) {
                      // Update data
                      setState(() {
                        tanks[tankIndex].isRectangular = newSelection.first;
                      });
                      _saveData();
                    },
                  ),
                ),

                // Rectangular tank dimensions
                if (tank.isRectangular) ...[
                  Text(
                    "What are the length and width of the tank?",
                    style: inputFieldStyle,
                  ),
                  Row(
                    children: [
                      // Input length
                      Expanded(
                        child: InputFieldWidget(
                          controller: controllers['length']!,
                          label: "Length (m)",
                          onChanged: (value) {
                            try {
                              tanks[tankIndex].length =
                                  double.tryParse(value) ?? 0;
                            } catch (e) {
                              showAlertDialog("Please enter a number (metres)");
                            }
                          },
                        ),
                      ),
                      SizedBox(width: 16),

                      // Input width
                      Expanded(
                        child: InputFieldWidget(
                          controller: controllers['width']!,
                          label: "Width (m)",
                          onChanged: (value) {
                            try {
                              tanks[tankIndex].width =
                                  double.tryParse(value) ?? 0;
                            } catch (e) {
                              showAlertDialog("Please enter a number (metres)");
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  // Circular tank dimensions
                  Text(
                    "What is the diameter of the tank?",
                    style: inputFieldStyle,
                  ),
                  // Input diameter
                  InputFieldWidget(
                    controller: controllers['diameter']!,
                    label: "Diameter (m)",
                    onChanged: (value) {
                      try {
                        tanks[tankIndex].diameter = double.tryParse(value) ?? 0;
                      } catch (e) {
                        showAlertDialog("Please enter a number (metres)");
                      }
                    },
                  ),
                ],

                // Tank height
                Text(
                  "What is the maximum water height of the tank?",
                  style: inputFieldStyle,
                ),
                InputFieldWidget(
                  controller: controllers['height']!,
                  label: "Height (m)",
                  onChanged: (value) {
                    try {
                      tanks[tankIndex].height = double.tryParse(value) ?? 0;
                    } catch (e) {
                      showAlertDialog("Please enter a number (metres)");
                    }
                  },
                ),
              ],

              // Current water level (if not known)
              if (!states['knowTankWaterLevel']!) ...[
                Text(
                  "What is the current water level of the tank?",
                  style: inputFieldStyle,
                ),
                InputFieldWidget(
                  controller: controllers['waterHeight']!,
                  label: "Water Level (m)",
                  onChanged: (value) {
                    try {
                      tanks[tankIndex].waterHeight =
                          double.tryParse(value) ?? 0;
                    } catch (e) {
                      showAlertDialog("Please enter a number (metres)");
                    }
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
