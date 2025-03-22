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
  List<Map<String, String>> measurementHistory = [
    {"date": "2024-02-20", "value": "Blood Pressure: 120/80"},
  ];

  Map<String, dynamic>? patientDetails;
  late final String apiUrl;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    apiUrl = '${getLocalHostUrl()}/patients/${widget.patientId}';
    _fetchPatientDetails();
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

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // Navigate to EditPatientScreen
  void _editPatient() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditPatientPage(patientName: widget.patientName,)),
    );
  }

  // Navigate to AddMeasurementScreen
  void _addMeasurement() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => AddMeasurementPage()));
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text("${widget.patientName} Details"),
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
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          //const Text("Patient Name:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(widget.patientName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),

          const SizedBox(height: 20),

          const Text("Condition:", style: TextStyle(fontSize: 18,)),
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
                fontSize: 18, fontWeight: FontWeight.bold,
                color: widget.condition == 'Critical' ? Colors.white : Colors.black, 
              ),
            ),
          ),

          const SizedBox(height: 20),

          if (patientDetails != null) ...[
            const Text("Additional Details:", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Text("Patient ID: ${patientDetails!['patientId']}", style: const TextStyle(fontSize: 20)),
            Text("Age: ${patientDetails!['age']}", style: const TextStyle(fontSize: 20)),
            Text("Gender: ${patientDetails!['gender']}", style: const TextStyle(fontSize: 20)),
            Text("Admission Date: ${_formatDate(patientDetails!['admissionDate'])}", style: const TextStyle(fontSize: 20)),

            const SizedBox(height: 20),

            const Text("Contact Details:", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Text("Phone: ${patientDetails!['phone']}", style: const TextStyle(fontSize: 20)),
            Text("Email: ${patientDetails!['email']}", style: const TextStyle(fontSize: 20)),
            Text("Address: ${patientDetails!['address']}", style: const TextStyle(fontSize: 20)),
            Text("Emergency Contact: ${patientDetails!['emergencyContactPhone']}", style: const TextStyle(fontSize: 20)),
          ],
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
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: measurementHistory.length,
      itemBuilder: (context, index) {
        final measurement = measurementHistory[index];
        return Card(
          child: ListTile(
            leading: const Icon(Icons.monitor_heart, color: Colors.blue),
            title: Text(measurement["value"]!),
            subtitle: Text("Date: ${measurement["date"]}"),
          ),
        );
      },
    );
  }
}
