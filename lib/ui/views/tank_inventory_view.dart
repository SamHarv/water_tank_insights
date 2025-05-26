import 'package:flutter/material.dart';
import 'package:water_tank_insights/logic/tank_volume_calculator.dart';
import 'package:water_tank_insights/ui/widgets/constrained_width_widget.dart';
import 'package:water_tank_insights/ui/widgets/input_field_widget.dart';

import '../../config/constants.dart';
import '../../data/models/tank_model.dart';

// TODO: validate inputs

class TankInventoryView extends StatefulWidget {
  const TankInventoryView({super.key});

  @override
  State<TankInventoryView> createState() => _TankInventoryViewState();
}

class _TankInventoryViewState extends State<TankInventoryView> {
  // Button state for animation
  bool isPressed = false;
  double yearSelected = DateTime.now().year.toDouble();
  List<Tank> tanks = [];
  int numOfTanks = 0;
  bool knowTankCapacity = false;
  bool knowTankWaterLevel = false;
  int tankWaterLevel = 0;
  int tankCapacity = 0;
  bool showResults = false;

  late final TextEditingController numOfTanksController;
  late final TextEditingController tankCapacityController;
  late final TextEditingController tankWaterLevelController;
  late final TextEditingController tankDiameterController;
  late final TextEditingController tankWidthController;
  late final TextEditingController tankLengthController;
  late final TextEditingController tankHeightController;
  late final TextEditingController waterHeightController;

  @override
  void initState() {
    super.initState();
    numOfTanksController =
        TextEditingController(); // TODO: text: saved value for these

    // TODO: fix: all tanks will have the same value
    tankCapacityController = TextEditingController();
    tankWaterLevelController = TextEditingController();
    tankDiameterController = TextEditingController();
    tankWidthController = TextEditingController();
    tankLengthController = TextEditingController();
    tankHeightController = TextEditingController();
    waterHeightController = TextEditingController();
  }

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

  @override
  void dispose() {
    numOfTanksController.dispose();
    tankCapacityController.dispose();
    tankWaterLevelController.dispose();
    tankDiameterController.dispose();
    tankWidthController.dispose();
    tankLengthController.dispose();
    tankHeightController.dispose();
    waterHeightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaWidth = MediaQuery.sizeOf(context).width;
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 120,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: true,
        leadingWidth: 120,
        leading: IconButton(
          icon: Padding(
            padding: kPadding,
            child: Icon(Icons.arrow_back_ios_new),
          ),
          color: white,
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Hero(
            tag: "logo",
            child: Padding(padding: kPadding, child: Image.asset(logo)),
          ),
          SizedBox(width: 16),
        ],
      ),
      body: Center(
        child:
            showResults
                ? Padding(
                  padding: kPadding,
                  child: Text(
                    "Your tank capacity is $tankCapacity liters.\n\n"
                    "Your tank water level is $tankWaterLevel liters.",
                  ),
                )
                : SingleChildScrollView(
                  child: Padding(
                    padding: kPadding,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      spacing: 32,
                      children: [
                        // How many tanks?
                        ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: 500),
                          child: SizedBox(
                            width: mediaWidth * 0.8,
                            child: Text(
                              "How many water tanks do you have?",
                              style: inputFieldStyle,
                            ),
                          ),
                        ),
                        ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: 500),
                          child: SizedBox(
                            width: mediaWidth * 0.8,
                            child: InputFieldWidget(
                              onChanged:
                                  (value) => setState(() {
                                    try {
                                      numOfTanks = int.parse(value);
                                      if (numOfTanks > 20) throw RangeError("");
                                    } catch (e) {
                                      showAlertDialog(
                                        "Please enter a number between 1 and 20",
                                      );
                                    }

                                    for (int i = 0; i < numOfTanks; i++) {
                                      tanks.add(
                                        Tank(id: tanks.length.toString()),
                                      );
                                    }
                                  }),
                              controller: numOfTanksController,
                              label: "Number of tanks",
                            ),
                          ),
                        ),
                        // For each tank: // TODO: fix multi tank logic
                        for (Tank tank in tanks)
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            spacing: 24,
                            children: [
                              ConstrainedWidthWidget(
                                child: Text(
                                  "Tank ${tanks.indexOf(tank) + 1} of $numOfTanks",
                                  style: inputFieldStyle,
                                ),
                              ),
                              // Do you know the tank's capacity?
                              ConstrainedWidthWidget(
                                child: Text(
                                  "Do you know the tank's capacity?",
                                  style: inputFieldStyle,
                                ),
                              ),
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
                                  selected: {knowTankCapacity},
                                  onSelectionChanged: (Set<bool> newSelection) {
                                    setState(() {
                                      knowTankCapacity = newSelection.first;
                                    });
                                  },
                                ),
                              ),
                              knowTankCapacity
                                  ? ConstrainedWidthWidget(
                                    child: InputFieldWidget(
                                      controller: tankCapacityController,
                                      label: "Tank capacity (L)",
                                      onChanged:
                                          (value) => setState(() {
                                            // tankCapacityController.text = value;
                                            try {
                                              tank.capacity = int.parse(value);
                                            } catch (e) {
                                              showAlertDialog(
                                                "Please enter a number (litres)",
                                              );
                                            }
                                          }),
                                    ),
                                  )
                                  : SizedBox(),

                              // Do you know how full the tank is?
                              ConstrainedWidthWidget(
                                child: Text(
                                  "Do you know full the tank is?",
                                  style: inputFieldStyle,
                                ),
                              ),
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
                                  selected: {knowTankWaterLevel},
                                  onSelectionChanged: (Set<bool> newSelection) {
                                    setState(() {
                                      knowTankWaterLevel = newSelection.first;
                                    });
                                  },
                                ),
                              ),
                              knowTankWaterLevel
                                  ? ConstrainedWidthWidget(
                                    child: InputFieldWidget(
                                      controller: tankWaterLevelController,
                                      label: "Tank level (L)",
                                      onChanged:
                                          (value) => setState(() {
                                            // tankWaterLevelController.text =
                                            //     value;
                                            try {
                                              tank.waterLevel = int.parse(
                                                value,
                                              );
                                            } catch (e) {
                                              showAlertDialog(
                                                "Please enter a number (litres)",
                                              );
                                            }
                                          }),
                                    ),
                                  )
                                  : SizedBox(),

                              // Get dimensions based on shape of tank
                              knowTankCapacity
                                  ? SizedBox()
                                  : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    spacing: 24,
                                    children: [
                                      ConstrainedWidthWidget(
                                        child: Text(
                                          "Is the footprint of the tank rectangular or circular?",
                                          style: inputFieldStyle,
                                        ),
                                      ),
                                      ConstrainedWidthWidget(
                                        child: SegmentedButton(
                                          selectedIcon: Icon(
                                            Icons.check,
                                            color: black,
                                          ),
                                          style: segButtonStyle,
                                          segments: [
                                            ButtonSegment(
                                              value: true,
                                              label: Padding(
                                                padding: const EdgeInsets.all(
                                                  16,
                                                ),
                                                child: Text("Rect"),
                                              ),
                                            ),
                                            ButtonSegment(
                                              value: false,
                                              label: Padding(
                                                padding: const EdgeInsets.all(
                                                  16,
                                                ),
                                                child: Text("Circular"),
                                              ),
                                            ),
                                          ],
                                          selected: {tank.isRectangular},
                                          onSelectionChanged: (
                                            Set<bool> newSelection,
                                          ) {
                                            setState(() {
                                              tank.isRectangular =
                                                  newSelection.first;
                                            });
                                          },
                                        ),
                                      ),
                                      tank.isRectangular
                                          ? Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            spacing: 24,
                                            children: [
                                              ConstrainedWidthWidget(
                                                child: Text(
                                                  "What are the length and width of the tank?",
                                                  style: inputFieldStyle,
                                                ),
                                              ),
                                              ConstrainedWidthWidget(
                                                child: InputFieldWidget(
                                                  controller:
                                                      tankLengthController,
                                                  label: "Length (m)",
                                                  onChanged:
                                                      (value) => setState(() {
                                                        // tankLengthController
                                                        //     .text = value;
                                                        try {
                                                          tank.length =
                                                              double.parse(
                                                                value,
                                                              );
                                                        } catch (e) {
                                                          showAlertDialog(
                                                            "Please enter a number (metres)",
                                                          );
                                                        }
                                                      }),
                                                ),
                                              ),
                                              ConstrainedWidthWidget(
                                                child: InputFieldWidget(
                                                  controller:
                                                      tankWidthController,
                                                  label: "Width (m)",
                                                  onChanged:
                                                      (value) => setState(() {
                                                        // tankWidthController
                                                        //     .text = value;
                                                        try {
                                                          tank.width =
                                                              double.parse(
                                                                value,
                                                              );
                                                        } catch (e) {
                                                          showAlertDialog(
                                                            "Please enter a number (metres)",
                                                          );
                                                        }
                                                      }),
                                                ),
                                              ),
                                            ],
                                          )
                                          : // Not rectangular (assuming circular)
                                          Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            spacing: 24,
                                            children: [
                                              ConstrainedWidthWidget(
                                                child: Text(
                                                  "What is the diameter of the tank?",
                                                  style: inputFieldStyle,
                                                ),
                                              ),
                                              ConstrainedWidthWidget(
                                                child: InputFieldWidget(
                                                  controller:
                                                      tankDiameterController,
                                                  label: "Diameter (m)",
                                                  onChanged:
                                                      (value) => setState(() {
                                                        // tankDiameterController
                                                        //     .text = value;
                                                        try {
                                                          tank.diameter =
                                                              double.parse(
                                                                value,
                                                              );
                                                        } catch (e) {
                                                          showAlertDialog(
                                                            "Please enter a number (metres)",
                                                          );
                                                        }
                                                      }),
                                                ),
                                              ),
                                            ],
                                          ),
                                      ConstrainedWidthWidget(
                                        child: Text(
                                          "What is the maximum water height of the tank?",
                                          style: inputFieldStyle,
                                        ),
                                      ),
                                      ConstrainedWidthWidget(
                                        child: InputFieldWidget(
                                          controller: tankHeightController,
                                          label: "Height (m)",
                                          onChanged:
                                              (value) => setState(() {
                                                // tankHeightController.text =
                                                //     value;
                                                try {
                                                  tank.height = double.parse(
                                                    value,
                                                  );
                                                } catch (e) {
                                                  showAlertDialog(
                                                    "Please enter a number (metres)",
                                                  );
                                                }
                                              }),
                                        ),
                                      ),
                                    ],
                                  ),
                              // Current water level
                              knowTankWaterLevel
                                  ? SizedBox()
                                  : Column(
                                    spacing: 24,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      ConstrainedWidthWidget(
                                        child: Text(
                                          "What is the current water level of the tank?",
                                          style: inputFieldStyle,
                                        ),
                                      ),
                                      ConstrainedWidthWidget(
                                        child: InputFieldWidget(
                                          controller: waterHeightController,
                                          label: "Water Level (m)",
                                          onChanged:
                                              (value) => setState(() {
                                                // waterHeightController.text =
                                                //     value;
                                                try {
                                                  tank.waterHeight =
                                                      double.parse(value);
                                                } catch (e) {
                                                  showAlertDialog(
                                                    "Please enter a number (metres)",
                                                  );
                                                }
                                              }),
                                        ),
                                      ),
                                    ],
                                  ),
                              // Button to calculate / continue
                              Tooltip(
                                message:
                                    knowTankCapacity && knowTankWaterLevel
                                        ? "Continue to next step"
                                        : "Calculate tank capacity and current inventory",
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
                                      // Tank Volume Calculator Object
                                      final tankVolumeCalculator =
                                          TankVolumeCalculator();
                                      // Calculate tank capacity
                                      tank.isRectangular
                                          ? tank.capacity = tankVolumeCalculator
                                              .calculateRectVolume(
                                                tank.height,
                                                tank.width,
                                                tank.length,
                                              )
                                          : tank.capacity = tankVolumeCalculator
                                              .calculateCircVolume(
                                                tank.diameter,
                                                tank.height,
                                              );

                                      // Calculate tank inventory
                                      tank.isRectangular
                                          ? tank
                                              .waterLevel = tankVolumeCalculator
                                              .calculateRectVolume(
                                                tank.waterHeight,
                                                tank.width,
                                                tank.length,
                                              )
                                          : tank
                                              .waterLevel = tankVolumeCalculator
                                              .calculateCircVolume(
                                                tank.diameter,
                                                tank.waterHeight,
                                              );
                                      setState(() {
                                        tankCapacity = tank.capacity;
                                        tankWaterLevel = tank.waterLevel;
                                        showResults = true;
                                      });
                                      // TODO: Navigate to next step
                                    },
                                    child: AnimatedContainer(
                                      width: mediaWidth * 0.8,
                                      duration: const Duration(
                                        milliseconds: 100,
                                      ),
                                      decoration: BoxDecoration(
                                        color: white,
                                        border: Border.all(
                                          color: black,
                                          width: 3,
                                        ),
                                        borderRadius: kBorderRadius,
                                        boxShadow: [
                                          isPressed ? BoxShadow() : kShadow,
                                        ],
                                      ),
                                      child: Padding(
                                        padding: EdgeInsets.all(16),
                                        child: Center(
                                          child: Text(
                                            knowTankCapacity &&
                                                    knowTankWaterLevel
                                                ? "Continue"
                                                : "Calculate",
                                            style: subHeadingStyle,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
      ),
    );
  }
}
