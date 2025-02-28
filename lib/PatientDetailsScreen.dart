import 'package:flutter/material.dart';
import 'package:mapd722_project/AddMeasurementScreen.dart';
import 'EditPatientScreen.dart';

class PatientDetailsScreen extends StatefulWidget {
  final String patientName;
  final bool isCritical;

  const PatientDetailsScreen({super.key, required this.patientName, required this.isCritical});

  @override
  _PatientDetailsScreenState createState() => _PatientDetailsScreenState();
}

class _PatientDetailsScreenState extends State<PatientDetailsScreen> {
   int _selectedIndex = 0;
  List<Map<String, String>> measurementHistory = [
    {"date": "2024-02-20", "value": "Blood Pressure: 120/80"},
  ];

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
          // bottom: const TabBar(
          //   tabs: [
          //     Tab(icon: Icon(Icons.info), text: "Details"),
          //     Tab(icon: Icon(Icons.history), text: "Measurement History"),
          //   ],
          // ),
        ),
        body: _selectedIndex == 0 ? _buildDetailsTab() : _buildMeasurementHistoryTab(),
        // body: TabBarView(
        //   children: [
        //     /*----- First Tab: Patient's Details -----*/
        //     _buildDetailsTab(),
        //     /*----- Second Tab: Patient's measurement History -----*/
        //     _buildMeasurementHistoryTab(),
        //   ],
        // ),
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
          const Text("Patient Name:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(widget.patientName, style: const TextStyle(fontSize: 18)),

          const SizedBox(height: 20),

          const Text("Condition:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(
            widget.isCritical ? "Critical" : "Stable",
            style: TextStyle(fontSize: 18, color: widget.isCritical ? Colors.red : Colors.green),
          ),
        ],
      ),
    );
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
