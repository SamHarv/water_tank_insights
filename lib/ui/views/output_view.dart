import 'package:flutter/material.dart';
import 'package:water_tank_insights/ui/views/home_view.dart';
import 'package:water_tank_insights/ui/widgets/constrained_width_widget.dart';

import '../../config/constants.dart';

class OutputView extends StatefulWidget {
  const OutputView({super.key});

  @override
  State<OutputView> createState() => _OutputViewState();
}

class _OutputViewState extends State<OutputView> {
  bool isPressed = false;
  bool optimisationIsPressed = false;
  int daysLeft = 0;
  int currentInventory = 0;
  double waterUsage = 0;
  String selectedRainfall = "10-year median";
  @override
  Widget build(BuildContext context) {
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
                  child: Text("Results", style: headingStyle),
                ),
                Column(
                  spacing: 16,
                  children: [
                    ConstrainedWidthWidget(
                      child: Text(
                        "$daysLeft days remaining",
                        style: headingStyle,
                      ),
                    ),
                    ConstrainedWidthWidget(
                      child: Text(
                        "${currentInventory}L of current inventory.",
                        style: headingStyle,
                      ),
                    ),
                  ],
                ),

                // Chart to visualise tank levels
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
                            // TODO: Line chart indicating tank levels over time with current usage and intake
                            Placeholder(fallbackHeight: 150),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                // Water usage slider
                Column(
                  spacing: 16,
                  children: [
                    ConstrainedWidthWidget(
                      child: Text(
                        "Per person water usage:",
                        style: inputFieldStyle,
                      ),
                    ),
                    // Slider
                    ConstrainedWidthWidget(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "${waterUsage.toInt().toString()}L/day",
                            style: headingStyle,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Slider(
                              value: waterUsage,
                              activeColor: black,
                              secondaryActiveColor: white,
                              thumbColor: white,
                              // TODO: double check 1890 is earliest year
                              min: 0,
                              max: 600,
                              onChanged: (value) {
                                setState(() {
                                  waterUsage = value;
                                });
                              },
                              // onChangeEnd: (value) {
                              //   _saveData(); // Save when slider stops moving
                              // },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                Tooltip(
                  message: "Enter your assumed rainfall pattern.",
                  child: ConstrainedWidthWidget(
                    child: DropdownMenu<String>(
                      width: mediaWidth * 0.8,
                      initialSelection: selectedRainfall,
                      dropdownMenuEntries: [
                        // TODO: update rainfall patterns
                        DropdownMenuEntry(
                          value: "Lowest recorded",
                          label: "Lowest recorded",
                        ),
                        DropdownMenuEntry(
                          value: "10-year median",
                          label: "10-year median",
                        ),

                        DropdownMenuEntry(
                          value: "Highest recorded",
                          label: "Highest recorded",
                        ),
                      ],
                      label: Text("Rainfall Pattern", style: inputFieldStyle),
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
                      hintText: "Select rainfall pattern",
                      onSelected: (rainfall) {
                        setState(() {
                          selectedRainfall = rainfall!;
                        });
                        // _saveData(); // Auto-save when postcode changes
                      },
                    ),
                  ),
                ),
                // Tips for water optimisation
                ConstrainedWidthWidget(
                  child: Row(
                    spacing: 32,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(
                        Icons.local_library_outlined,
                        color: white,
                        size: 60,
                      ),
                      Expanded(
                        child: Tooltip(
                          message: "Water optimisation tips.",
                          child: InkWell(
                            borderRadius: kBorderRadius,
                            onTap: () {
                              // Handle button press animation
                              setState(() {
                                optimisationIsPressed = true;
                              });
                              Future.delayed(
                                const Duration(milliseconds: 150),
                              ).then((value) {
                                setState(() {
                                  optimisationIsPressed = false;
                                });
                              });

                              // Save data before navigating
                              // _saveData();

                              // Navigate to water optimisation tips
                              // Navigator.push(
                              //   context,
                              //   MaterialPageRoute(
                              //     builder: (context) => OptimisationTipsView(),
                              //   ),
                              // );
                            },
                            child: AnimatedContainer(
                              // width: mediaWidth * 0.8,
                              duration: const Duration(milliseconds: 100),
                              decoration: BoxDecoration(
                                color: white,
                                border: Border.all(color: black, width: 3),
                                borderRadius: kBorderRadius,
                                boxShadow: [
                                  optimisationIsPressed ? BoxShadow() : kShadow,
                                ],
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(
                                  child: Text(
                                    "Optimisation Tips",
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
                ),
                // Button to start again
                Tooltip(
                  message: "Return to home page and start again.",
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
                        // _saveData();

                        // Navigate to water usage view
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => HomeView()),
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
                            child: Text("Start Again", style: subHeadingStyle),
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
