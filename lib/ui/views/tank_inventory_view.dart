import 'package:flutter/material.dart';

import '../../logic/services/data_persist_service.dart';
import '/logic/tank_volume_calculator.dart';
import 'water_usage_view.dart';
import '/ui/widgets/constrained_width_widget.dart';
import '/ui/widgets/input_field_widget.dart';
import '../../config/constants.dart';
import '../../data/models/tank_model.dart';
import 'roof_catchment_view.dart';

class TankInventoryView extends StatefulWidget {
  /// [TankInventoryView] to input the user's tanks and their inventory
  const TankInventoryView({super.key});

  @override
  State<TankInventoryView> createState() => _TankInventoryViewState();
}

class _TankInventoryViewState extends State<TankInventoryView> {
  // Data persist service
  final DataPersistService _dataPersistService = DataPersistService();

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
      final tankData = await _dataPersistService.loadTankData();

      numOfTanks = tankData['tankCount'];
      numOfTanksController.text = numOfTanks.toString();
      tanks = tankData['tanks'];
      tankStates = tankData['tankStates'];

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
  void _updateTankCount(int newCount) async {
    if (newCount < 1 || newCount > 20) return;

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
    });

    await _saveData(); // Save data
  }

  // Save data to SharedPreferences
  Future<void> _saveData() async {
    try {
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

      // Save using the service
      await _dataPersistService.saveTankData(
        tankCount: numOfTanks,
        tanks: tanks,
        tankStates: tankStates,
      );
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
      if (i < tankStates.length &&
          !tankStates[i]['knowTankWaterLevel']! &&
          !tankStates[i]['knowTankCapacity']!) {
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

      if (tankStates[i]['knowTankCapacity']! &&
          !tankStates[i]['knowTankWaterLevel']!) {
        tank.waterLevel = (tank.capacity * (tank.waterHeight / 100)).toInt();
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
                    style: subHeadingStyle,
                  ),
                  Text(
                    'Total Inventory: ${totalInventory.toInt()} L',
                    style: subHeadingStyle,
                  ),
                  Text(
                    'Available Space: ${(totalCapacity - totalInventory).toInt()} L',
                    style: subHeadingStyle,
                  ),
                  Text(
                    'Fill Percentage: ${totalCapacity > 0 ? ((totalInventory / totalCapacity) * 100).toStringAsFixed(1) : "0.0"}%',
                    style: subHeadingStyle,
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

  // Continue with 0 tanks - skip roof catchment and go directly to water usage
  void _continueWithZeroTanks() async {
    // Clear tanks and roof catchment data
    tanks.clear();
    tankStates.clear();
    tankControllers.clear();

    // Save the cleared state
    await _saveData();

    // Navigate directly to water usage view, skipping roof catchment
    Navigator.push(
      // ignore: use_build_context_synchronously
      context,
      MaterialPageRoute(builder: (context) => WaterUsageView()),
    );
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
        appBar: buildAppBar(context),
        body: Center(child: CircularProgressIndicator(color: white)),
      );
    }

    return Scaffold(
      appBar: buildAppBar(context),
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
                        if (newCount > 20 || newCount < 1) {
                          showAlertDialog(
                            "Please enter a number between 1 and 20",
                          );
                          numOfTanksController.text = numOfTanks.toString();
                          return;
                        }
                        _updateTankCount(newCount); // Update tank count
                      } catch (e) {
                        if (value.isNotEmpty) {
                          showAlertDialog(
                            "Please enter a valid number between 1 and 20",
                          );
                          numOfTanksController.text = numOfTanks.toString();
                        }
                      }
                    },
                    controller: numOfTanksController,
                    label: "Number of tanks (1-20)",
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

                            for (int i = 0; i < numOfTanks; i++) {
                              // Ensure tank data is valid

                              // Know tank capacity and tank level validation
                              if (tankStates[i]['knowTankCapacity']! &&
                                  tankStates[i]['knowTankWaterLevel']!) {
                                if (tanks[i].capacity == 0 ||
                                    tankControllers[i]['capacity']?.text ==
                                        "") {
                                  showAlertDialog(
                                    "Capacity must be a number greater than 0 for Tank ${i + 1}",
                                  );
                                  return;
                                } else if (tankControllers[i]['waterLevel']
                                        ?.text ==
                                    "") {
                                  showAlertDialog(
                                    "Tank level must have a value for Tank ${i + 1}",
                                  );
                                  return;
                                } else if (tanks[i].waterLevel >
                                    tanks[i].capacity) {
                                  showAlertDialog(
                                    "Tank level must be less than capacity for Tank ${i + 1}",
                                  );
                                  return;
                                }
                              }

                              // Know tank capacity but not water level validation
                              if (tankStates[i]['knowTankCapacity']! &&
                                  !tankStates[i]['knowTankWaterLevel']!) {
                                if (tanks[i].capacity == 0 ||
                                    tankControllers[i]['capacity']?.text ==
                                        "") {
                                  showAlertDialog(
                                    "Capacity must be greater than 0 for Tank ${i + 1}",
                                  );
                                  return;
                                } else if (tankControllers[i]['waterHeight']
                                        ?.text ==
                                    "") {
                                  showAlertDialog(
                                    "Water level must have a value for Tank ${i + 1}",
                                  );
                                  return;
                                } else if (tanks[i].waterHeight >
                                    tanks[i].capacity) {
                                  showAlertDialog(
                                    "Water level must be less than capacity for Tank ${i + 1}",
                                  );
                                  return;
                                }
                              }

                              // Know water level but not tank capacity validation
                              if (!tankStates[i]['knowTankCapacity']! &&
                                  tankStates[i]['knowTankWaterLevel']!) {
                                if (tankControllers[i]['waterLevel']?.text ==
                                    "") {
                                  showAlertDialog(
                                    "Tank level must have a value for Tank ${i + 1}",
                                  );
                                  return;
                                } else {
                                  if (tanks[i].isRectangular) {
                                    // check width & length are valid
                                    if (tanks[i].width == 0 ||
                                        tankControllers[i]['width']?.text ==
                                            "") {
                                      showAlertDialog(
                                        "Width must be greater than 0 for Tank ${i + 1}",
                                      );
                                      return;
                                    } else if (tanks[i].length == 0 ||
                                        tankControllers[i]['length']?.text ==
                                            "") {
                                      showAlertDialog(
                                        "Length must be greater than 0 for Tank ${i + 1}",
                                      );
                                      return;
                                    }
                                  } else {
                                    // check diameter is valid
                                    if (tanks[i].diameter == 0 ||
                                        tankControllers[i]['diameter']?.text ==
                                            "") {
                                      showAlertDialog(
                                        "Diameter must be greater than 0 for Tank ${i + 1}",
                                      );
                                      return;
                                    }
                                  }
                                  // check height is valid
                                  if (tanks[i].height == 0 ||
                                      tankControllers[i]['height']?.text ==
                                          "") {
                                    showAlertDialog(
                                      "Height must be greater than 0 for Tank ${i + 1}",
                                    );
                                    return;
                                  }
                                }
                              }

                              // Know neither tank capacity nor water level validation
                              if (!tankStates[i]['knowTankCapacity']! &&
                                  !tankStates[i]['knowTankWaterLevel']!) {
                                if (tankControllers[i]['waterHeight']?.text ==
                                    "") {
                                  showAlertDialog(
                                    "Water level must have a value for Tank ${i + 1}",
                                  );
                                  return;
                                } else {
                                  if (tanks[i].isRectangular) {
                                    // check width & length are valid

                                    if (tanks[i].width == 0 ||
                                        tankControllers[i]['width']?.text ==
                                            "") {
                                      showAlertDialog(
                                        "Width must be greater than 0 for Tank ${i + 1}",
                                      );
                                      return;
                                    } else if (tanks[i].length == 0 ||
                                        tankControllers[i]['length']?.text ==
                                            "") {
                                      showAlertDialog(
                                        "Length must be greater than 0 for Tank ${i + 1}",
                                      );
                                      return;
                                    }
                                  } else {
                                    // check diameter is valid
                                    if (tanks[i].diameter == 0 ||
                                        tankControllers[i]['diameter']?.text ==
                                            "") {
                                      showAlertDialog(
                                        "Diameter must be greater than 0 for Tank ${i + 1}",
                                      );
                                      return;
                                    } else if (tanks[i].height == 0 ||
                                        tankControllers[i]['height']?.text ==
                                            "") {
                                      showAlertDialog(
                                        "Height must be greater than 0 for Tank ${i + 1}",
                                      );
                                      return;
                                    }
                                  }
                                }
                              }
                            }

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
                ] else if (numOfTanks == 0) ...[
                  // Show message and continue button for 0 tanks
                  ConstrainedWidthWidget(
                    child: Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        border: Border.all(color: black, width: 3),
                        borderRadius: kBorderRadius,
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 32,
                            color: Colors.orange.shade800,
                          ),
                          SizedBox(height: 12),
                          Text(
                            "No Water Tanks",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade800,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            "Since you have no water tanks, we'll skip the roof catchment calculations and proceed directly to water usage.",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.orange.shade700,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Continue button for 0 tanks - skips roof catchment
                  Tooltip(
                    message: "Continue to water usage (skip roof catchment)",
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
                            _continueWithZeroTanks();
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
                              child: Text("Continue", style: subHeadingStyle),
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
                    // Capacity
                    if (tankStates[tankIndex]['knowTankCapacity']!) {
                      // clear height, width, diameter, length
                      controllers['height']!.clear();
                      tanks[tankIndex].height = 0;
                      controllers['width']!.clear();
                      tanks[tankIndex].width = 0;
                      controllers['diameter']!.clear();
                      tanks[tankIndex].diameter = 0;
                      controllers['length']!.clear();
                      tanks[tankIndex].length = 0;
                      tankStates[tankIndex]['knowTankWaterLevel'] = true;
                    } else if (!tankStates[tankIndex]['knowTankCapacity']!) {
                      // clear capacity
                      controllers['capacity']!.clear();
                      tanks[tankIndex].capacity = 0;
                    }

                    _saveData();
                  },
                ),
              ),

              // Tank capacity input (if known)
              if (states['knowTankCapacity']!) ...[
                InputFieldWidget(
                  controller: controllers['capacity']!,
                  label: "Tank capacity (litres)",
                  onChanged: (value) {
                    try {
                      if (tankControllers[tankIndex]['capacity']!
                          .text
                          .isNotEmpty) {
                        tanks[tankIndex].capacity = int.tryParse(value)!;
                      }
                    } catch (e) {
                      showAlertDialog("Please enter a number (litres)");
                      tankControllers[tankIndex]['capacity']!.clear();
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
                      if (tankStates[tankIndex]['knowTankCapacity']!) {
                        tankStates[tankIndex]['knowTankWaterLevel'] = true;
                        showAlertDialog(
                          "You must input current inventory (litres) if you "
                          "know the tank's capacity (litres).",
                        );
                      } else {
                        tankStates[tankIndex]['knowTankWaterLevel'] =
                            newSelection.first;
                      }
                    });

                    // water level
                    if (tankStates[tankIndex]['knowTankWaterLevel']!) {
                      // clear water height
                      controllers['waterHeight']!.clear();
                      tanks[tankIndex].waterHeight = 0;
                    } else if (!tankStates[tankIndex]['knowTankWaterLevel']!) {
                      // clear water level
                      controllers['waterLevel']!.clear();
                      tanks[tankIndex].waterLevel = 0;
                    }
                    _saveData();
                  },
                ),
              ),

              // Tank water level input (if known)
              if (states['knowTankWaterLevel']!) ...[
                InputFieldWidget(
                  controller: controllers['waterLevel']!,
                  label: "Tank level (litres)",
                  onChanged: (value) {
                    try {
                      if (tankControllers[tankIndex]['waterLevel']!
                          .text
                          .isNotEmpty) {
                        tanks[tankIndex].waterLevel = int.tryParse(value)!;
                        if (tanks[tankIndex].waterLevel >
                                tanks[tankIndex].capacity &&
                            tankStates[tankIndex]['knowTankCapacity']!) {
                          showAlertDialog(
                            "Tank level cannot be greater than capacity",
                          );
                          tanks[tankIndex].waterLevel =
                              tanks[tankIndex].capacity;
                          controllers['waterLevel']!.text =
                              tanks[tankIndex].waterLevel.toString();
                        }
                      }
                    } catch (e) {
                      showAlertDialog("Please enter a number (litres)");
                      tankControllers[tankIndex]['waterLevel']!.clear();
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
                      // Rectangular
                      if (tanks[tankIndex].isRectangular) {
                        // clear width, length
                        controllers['width']!.clear();
                        tanks[tankIndex].width = 0;
                        controllers['length']!.clear();
                        tanks[tankIndex].length = 0;
                      } else if (!tanks[tankIndex].isRectangular) {
                        // clear diameter
                        controllers['diameter']!.clear();
                        tanks[tankIndex].diameter = 0;
                      }
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
                          label: "Length (metres)",
                          onChanged: (value) {
                            try {
                              if (tankControllers[tankIndex]['length']!
                                  .text
                                  .isNotEmpty) {
                                tanks[tankIndex].length =
                                    double.tryParse(value)!;
                              }
                            } catch (e) {
                              showAlertDialog("Please enter a number (metres)");
                              tankControllers[tankIndex]['length']!.clear();
                            }
                          },
                        ),
                      ),
                      SizedBox(width: 16),

                      // Input width
                      Expanded(
                        child: InputFieldWidget(
                          controller: controllers['width']!,
                          label: "Width (metres)",
                          onChanged: (value) {
                            try {
                              if (tankControllers[tankIndex]['width']!
                                  .text
                                  .isNotEmpty) {
                                tanks[tankIndex].width =
                                    double.tryParse(value)!;
                              }
                            } catch (e) {
                              showAlertDialog("Please enter a number (metres)");
                              tankControllers[tankIndex]['width']!.clear();
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
                    label: "Diameter (metres)",
                    onChanged: (value) {
                      try {
                        if (tankControllers[tankIndex]['diameter']!
                            .text
                            .isNotEmpty) {
                          tanks[tankIndex].diameter = double.tryParse(value)!;
                        }
                      } catch (e) {
                        showAlertDialog("Please enter a number (metres)");
                        tankControllers[tankIndex]['diameter']!.clear();
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
                  label: "Height (metres)",
                  onChanged: (value) {
                    try {
                      if (tankControllers[tankIndex]['height']!
                          .text
                          .isNotEmpty) {
                        tanks[tankIndex].height = double.tryParse(value)!;
                      }
                    } catch (e) {
                      showAlertDialog("Please enter a number (metres)");
                      tankControllers[tankIndex]['height']!.clear();
                    }
                  },
                ),
              ],

              // Current water level (if not known)
              // gugvuy
              if (!states['knowTankWaterLevel']!) ...[
                Text(
                  states['knowTankCapacity']!
                      ? "How full is the tank?"
                      : "What is the current water level of the tank?",
                  style: inputFieldStyle,
                ),
                InputFieldWidget(
                  controller: controllers['waterHeight']!,
                  label:
                      states['knowTankCapacity']!
                          ? "Percentage estimate (%)"
                          : "Water Level (metres)",
                  onChanged: (value) {
                    try {
                      if (controllers['waterHeight']!.text.isNotEmpty) {
                        tanks[tankIndex].waterHeight = double.tryParse(value)!;
                      }
                    } catch (e) {
                      showAlertDialog(
                        states['knowTankCapacity']!
                            ? "Please enter a number (0-100)"
                            : "Please enter a number (metres)",
                      );
                      controllers['waterHeight']!.clear();
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
