import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:water_tank_insights/config/constants.dart';
import '../../data/api/rainfall_api.dart';

class ApiDemo extends StatefulWidget {
  const ApiDemo({super.key});

  @override
  State<ApiDemo> createState() => _ApiDemoState();
}

class _ApiDemoState extends State<ApiDemo> {
  List<RainfallRecord>? rainfallData;
  String? errorMessage;
  bool isLoading = false;
  String selectedPostcode = '5000'; // Default to Adelaide CBD

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Rainfall API Demo'),
        backgroundColor: blue,
        foregroundColor: white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Postcode selection
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Postcode',
                      hintText: 'Enter postcode (e.g., 5000)',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        selectedPostcode = value;
                      });
                    },
                    controller: TextEditingController(text: selectedPostcode),
                  ),
                ),
                SizedBox(width: 16),
                ElevatedButton(
                  onPressed: isLoading ? null : _fetchData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: blue,
                    foregroundColor: white,
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                  child:
                      isLoading
                          ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    white,
                                  ),
                                ),
                              ),
                              SizedBox(width: 8),
                              Text('Loading...'),
                            ],
                          )
                          : Text('Fetch Data'),
                ),
              ],
            ),

            SizedBox(height: 16),

            // Results area
            Expanded(child: _buildResultsWidget()),
          ],
        ),
      ),
    );
  }

  Future<void> _fetchData() async {
    if (selectedPostcode.trim().isEmpty) {
      setState(() {
        errorMessage = 'Please enter a postcode';
      });
      return;
    }

    setState(() {
      isLoading = true;
      rainfallData = null;
      errorMessage = null;
    });

    try {
      // Fetch rainfall data for the last 2 years
      final List<RainfallRecord> result =
          await RainfallApiService.getRainfallData(
            postcode: selectedPostcode.trim(),
            year: DateTime.now().year, // Current year
          );

      setState(() {
        rainfallData = result;
        isLoading = false;
      });

      print(
        'Successfully fetched ${result.length} records for postcode $selectedPostcode',
      );
    } catch (e) {
      setState(() {
        errorMessage = 'Error: $e';
        isLoading = false;
      });
      print('API Error: $e');
    }
  }

  Widget _buildResultsWidget() {
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: blue),
            SizedBox(height: 16),
            Text('Fetching rainfall data...'),
          ],
        ),
      );
    }

    if (errorMessage != null) {
      return _buildErrorWidget();
    }

    if (rainfallData == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Enter a postcode and click "Fetch Data" to test the API',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return _buildSuccessWidget();
  }

  Widget _buildErrorWidget() {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.error, color: Colors.red),
                SizedBox(width: 8),
                Text(
                  'API Error:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade300),
                  ),
                  child: Text(
                    errorMessage!,
                    style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                ),
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Tips:\n• Check if the postcode exists in the database\n• Try a South Australian postcode (5000-5999)\n• Check your internet connection',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessWidget() {
    final totalRainfall = rainfallData!.fold<double>(
      0,
      (sum, record) => sum + record.rainfall,
    );

    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  'API Success:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),

            // Summary stats
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Summary for Postcode: $selectedPostcode',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  SizedBox(height: 8),
                  Text('📊 Records found: ${rainfallData!.length}'),
                  Text(
                    '🌧️ Total rainfall: ${totalRainfall.toStringAsFixed(1)} mm',
                  ),
                  if (rainfallData!.isNotEmpty) ...[
                    Text('📅 From: ${rainfallData!.first.monthYear}'),
                    Text('📅 To: ${rainfallData!.last.monthYear}'),
                    Text('🆔 Station ID: ${rainfallData!.first.stationId}'),
                  ],
                ],
              ),
            ),

            SizedBox(height: 12),

            // Detailed data
            Text(
              'Detailed Data:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),

            Expanded(
              child: SingleChildScrollView(
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children:
                        rainfallData!
                            .map(
                              (record) => Padding(
                                padding: EdgeInsets.only(bottom: 4),
                                child: Text(
                                  '${record.monthYear}: ${record.rainfall.toStringAsFixed(1)}mm (${record.quality})',
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                  ),
                ),
              ),
            ),

            SizedBox(height: 12),

            // Test daily conversion
            ElevatedButton.icon(
              onPressed: _testDailyConversion,
              icon: Icon(Icons.calendar_today),
              label: Text('Test Daily Conversion'),
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

  void _testDailyConversion() {
    if (rainfallData == null || rainfallData!.isEmpty) return;

    // Test converting the first record to daily data
    final firstRecord = rainfallData!.first;
    final dailyData = firstRecord.toDailyWeatherData();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Daily Conversion Test'),
            content: SizedBox(
              width: double.maxFinite,
              height: 300,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Converting ${firstRecord.monthYear} (${firstRecord.rainfall}mm) to daily data:',
                    ),
                    SizedBox(height: 16),
                    ...dailyData
                        .take(10)
                        .map(
                          (day) => Text(
                            '${day.date.toString().split(' ')[0]}: ${day.rainfall.toStringAsFixed(1)}mm, ${day.temperature.toStringAsFixed(1)}°C',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          ),
                        ),
                    if (dailyData.length > 10)
                      Text('... and ${dailyData.length - 10} more days'),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Close'),
              ),
            ],
          ),
    );
  }
}
