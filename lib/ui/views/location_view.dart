import 'package:flutter/material.dart';
import 'package:water_tank_insights/ui/views/tank_inventory_view.dart';

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
        child: SingleChildScrollView(
          child: Padding(
            padding: kPadding,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 32,
              children: [
                // Enter your location
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 500),
                  child: SizedBox(
                    width: mediaWidth * 0.8,
                    child: Text("Enter your location:", style: inputFieldStyle),
                  ),
                ),
                // Postcode dropdown
                Tooltip(
                  message: "Enter your postcode.",
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 500),
                    child: DropdownMenu(
                      width: mediaWidth * 0.8,
                      dropdownMenuEntries: [
                        // Potentially use enum for postcodes
                        // DropdownMenuEntry(
                        //   value: InvestmentFrequency.none,
                        //   label: "None",
                        // ),
                        DropdownMenuEntry(value: "None", label: "None"),
                        DropdownMenuEntry(value: "0000", label: "0000"),
                      ],
                      label: Text("Postcode"),
                      menuStyle: MenuStyle(
                        maximumSize: WidgetStateProperty.all(
                          Size.fromWidth(mediaWidth),
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
                      hintText: "Postcode",
                      onSelected: (year) {
                        // Example onSelected logic
                        // Enable/ disable recurring investment field based on frequency
                        // frequency == InvestmentFrequency.none
                        //     ? setState(() {
                        //         recurringInvestmentEnabled = false;
                        //         recurringInvestmentController.clear();
                        //       })
                        //     : setState(() {
                        //         recurringInvestmentEnabled = true;
                        //       });
                        // setState(() {
                        //   investmentFrequency = frequency!;
                        // });
                      },
                    ),
                  ),
                ),
                // Year slider
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 500),
                  child: SizedBox(
                    width: mediaWidth * 0.8,
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
                            min: 1890,
                            max: DateTime.now().year.toDouble(),
                            onChanged: (value) {
                              setState(() {
                                yearSelected = value;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // TODO: Bar chart indicating rainfall in location for given period
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 500),
                  child: Container(
                    width: mediaWidth * 0.8,
                    decoration: BoxDecoration(
                      color: white,
                      border: Border.all(color: black, width: 3),
                      borderRadius: kBorderRadius,
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: Placeholder(fallbackHeight: 200)),
                    ),
                  ),
                ),
                // Segmented button for monthly/ annual
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
                        // TODO: Navigate to next step
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
