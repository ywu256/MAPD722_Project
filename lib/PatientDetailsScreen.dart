import 'package:flutter/material.dart';
import 'package:mapd722_project/AddMeasurementScreen.dart';
import 'EditPatientScreen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:intl/intl.dart';

class PatientDetailsScreen extends StatefulWidget {
  final String patientName;
  final String patientId;
  final String condition;

  const PatientDetailsScreen({super.key, required this.patientName, required this.patientId,required this.condition});

  @override
  _PatientDetailsScreenState createState() => _PatientDetailsScreenState();
}

String getLocalHostUrl() {
  if (Platform.isAndroid) {
    return 'http://10.0.2.2:3001'; // Android emulator localhost address
  } else if (Platform.isIOS) {
    return 'http://127.0.0.1:3001'; // iOS simulator localhost address
  }
  return 'http://localhost:3001'; // Fallback
}

class _PatientDetailsScreenState extends State<PatientDetailsScreen> {
   int _selectedIndex = 0;
  List<Map<String, String>> measurementHistory = [];

  Map<String, dynamic>? patientDetails;
  late final String apiUrl;
  bool _isLoading = true;
  bool _isMeasurementLoading = true;

  @override
  void initState() {
    super.initState();
    apiUrl = '${getLocalHostUrl()}/patients/${widget.patientId}';
    _fetchPatientDetails();
    _fetchPatientClinicalData();
  }

  Future<void> _fetchPatientDetails() async {
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if(response.statusCode == 200) {
        final Map<String, dynamic> patientData = jsonDecode(response.body);
        setState(() {
          patientDetails = patientData['patient'];
          _isLoading = false;
        });
      } else {
        _showMessage("Failed to load patient details");
      }
    } catch (error) {
      _showMessage("Network error. Please try again");
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _fetchPatientClinicalData() async {
    setState(() => _isMeasurementLoading = true);
    try {
      final response = await http.get(Uri.parse('${getLocalHostUrl()}/clinical/${widget.patientId}'));

      if(response.statusCode == 200) {
        final List<dynamic> clinicalData = jsonDecode(response.body);
        // Coverting date to sort
        List<Map<String, String>> measurements = clinicalData.map((measurement) {
          return {
              'type': (measurement['type'] ?? '').toString(),
              'value': (measurement['value']?? '').toString(),
              'dateTime': (measurement['dateTime']?? '').toString(),
            };
          }).toList();
          // Sort in descending order
          measurements.sort((a,b) {
            try {
              final DateA = DateTime.parse(a['dateTime']!);
              final DateB =  DateTime.parse(b['dateTime']!);
              return DateB.compareTo(DateA);
            } catch (error) {
              return 0;
            }
          });
          setState(() {
            measurementHistory = measurements;
          });
        } else {
          _showMessage("Failed to load clinical data: ${response.statusCode}");
        }
      } catch (error) {
        _showMessage("Network error: ${error.toString()}");
      } finally {
        setState(() => _isMeasurementLoading = false);
      }
    }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // Navigate to EditPatientScreen
  void _editPatient() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditPatientPage(
          patientId: widget.patientId,
        ),
      ),
    );

    if (result == 'updated') {
      _fetchPatientDetails();
    }
  }

  // Navigate to AddMeasurementScreen
  void _addMeasurement() async {
  final result = await Navigator.push(
    context, 
    MaterialPageRoute(
      builder: (context) => AddMeasurementPage(
        patientId: widget.patientId,
        patientName: widget.patientName,
      ),
    ),
  );

  if (result != null && result['refresh'] == true) {
    _fetchPatientClinicalData();
    if (result['isAbnormal'] == true) {
      _fetchPatientDetails(); 
    }
  }
}

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          actions: [
            /*----- Edit Patient -----*/
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.black),
              onPressed: _editPatient,
            ),
          ],
        ),
        body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _selectedIndex == 0 ? _buildDetailsTab() : _buildMeasurementHistoryTab(),
  
        floatingActionButton: FloatingActionButton(
          onPressed: _addMeasurement,
          backgroundColor: Colors.blue,
          child: const Icon(Icons.add, color: Colors.white),
        ),
        bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.info), label: "Details"),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: "History"),
        ],
      ),
      ),
    );
  }

  // Create a patient's details page
  Widget _buildDetailsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /* --- Patient's Photo --- */
          if (patientDetails != null && patientDetails!['photoUrl'] != null)
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child: Image.network(
                  patientDetails!['photoUrl'],
                  height: 150,
                  width: 150,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, size: 150),
                ),
              ),
            ),

          const SizedBox(height: 20),

          /* --- Patient's Name and Condition --- */
          Center(
            child: Column(
              children: [
                Text(
                  widget.patientName,
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: widget.condition == 'Critical'
                        ? const Color.fromARGB(255, 233, 144, 137)
                        : const Color.fromARGB(255, 230, 230, 230),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.condition,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: widget.condition == 'Critical' ? Colors.white : Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          if (patientDetails != null) ...[
            /* --- Patient's Personal Info --- */
            const Text("Personal Info", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _buildInfoRow("Patient ID", patientDetails?['patientId']),
            _buildInfoRow("Age", patientDetails?['age']?.toString()),
            _buildInfoRow("Gender", patientDetails?['gender']),
            _buildInfoRow("Blood Type", patientDetails?['bloodType']),
            _buildInfoRow("Admission Date", _formatDate(patientDetails?['admissionDate'])),

            const SizedBox(height: 20),

            /* --- Patient's Contact Info --- */
            const Text("Contact Info", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _buildInfoRow("Phone", patientDetails?['phone']),
            _buildInfoRow("Email", patientDetails?['email']),
            _buildInfoRow("Address", patientDetails?['address']),
            _buildInfoRow("Emergency Contact", patientDetails?['emergencyContactPhone']),

            const SizedBox(height: 20),

            /* --- Patient's Medical Details --- */
            const Text("Medical Details", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _buildInfoRow("Medical History", patientDetails?['medicalHistory']),
            _buildInfoRow("Allergies", patientDetails?['allergies']),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 140, child: Text("$label:", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500))),
          Expanded(child: Text(value ?? "N/A", style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }


  String _formatDate(String isoDate) {
  try {
    final DateTime dateTime = DateTime.parse(isoDate);
    final DateFormat formatter = DateFormat('yyyy-MM-dd'); 
    return formatter.format(dateTime);
  } catch (e) {
    return 'Invalid Date';
  }
}

  // Create a patient's measurement history page
Widget _buildMeasurementHistoryTab() {
  if (_isMeasurementLoading) {
    return const Center(child: CircularProgressIndicator());
  }
  if (measurementHistory.isEmpty) {
    return const Center(
      child: Text(
        "No measurements recorded",
        style: TextStyle(fontSize: 20, color: Colors.grey),
      ),
    );
  }
  
  return ListView.builder(
    padding: const EdgeInsets.all(20),
    itemCount: measurementHistory.length,
    itemBuilder: (context, index) {
      final measurement = measurementHistory[index];
      final isCritical = _isCriticalMeasurement(measurement);
      
      return Card(
        elevation: 3,
        margin: const EdgeInsets.only(bottom: 15),
        color: isCritical ? Colors.red[50] : null,
        shape: isCritical 
            ? RoundedRectangleBorder(
                side: BorderSide(color: Colors.red, width: 2),
                borderRadius: BorderRadius.circular(10),
              )
            : null,
        child: ListTile(
          leading: Icon(
            Icons.monitor_heart,
            color: isCritical ? Colors.red : Colors.blue,
            size: 30,
          ),
          title: Text(
            measurement["type"]!,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isCritical ? Colors.red : null,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                measurement["value"] ?? '',
                style: TextStyle(
                  fontSize: 16,
                  color: isCritical ? Colors.red : null,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                measurement["dateTime"] ?? '',
                style: TextStyle(
                  fontSize: 14,
                  color: isCritical ? Colors.red[700] : Colors.grey,
                ),
              ),
            ],
          ),
          trailing: isCritical
              ? const Icon(Icons.warning, color: Colors.red)
              : null,
        ),
      );
    },
  );
}

bool _isCriticalMeasurement(Map<String, String> measurement) {
  try {
    switch (measurement['type']) {
      case 'Blood Pressure':
        final parts = measurement['value']?.split('/');
        if (parts != null && parts.length == 2) {
          final systolic = int.tryParse(parts[0]);
          final diastolicStr = parts[1].split(' ')[0];
          final diastolic = int.tryParse(diastolicStr);
          
          return systolic != null && 
                 diastolic != null && 
                 (systolic > 180 || systolic < 90 || diastolic > 120 || diastolic < 60);
        }
        return false;
      
      case 'Heartbeat Rate':
        final bpmStr = measurement['value']?.split(' ')[0];
        final bpm = int.tryParse(bpmStr ?? '');
        return bpm != null && (bpm < 60 || bpm > 100);
      
      case 'Blood Oxygen Level':
        final spo2Str = measurement['value']?.split(' ')[0];
        final spo2 = int.tryParse(spo2Str ?? '');
        return spo2 != null && spo2 < 90;
      
      case 'Respiratory Rate':
        final rateStr = measurement['value']?.split(' ')[0];
        final rate = int.tryParse(rateStr ?? '');
        return rate != null && (rate < 12 || rate > 20);
      
      default:
        return false;
    }
  } catch (error) {
    debugPrint('Error checking critical measurement: $error');
    return false;
  }
}
}