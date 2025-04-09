import 'package:flutter/material.dart';
import 'AddPatientScreen.dart';
import 'PatientDetailsScreen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io' show Platform;

class PatientListPage extends StatefulWidget {
  const PatientListPage({super.key});

  @override
  State<StatefulWidget> createState() {
    return _PatientListState();
  }
}

String getLocalHostUrl() {
  if (Platform.isAndroid) {
    return 'http://10.0.2.2:3001'; // Android emulator localhost address
  } else if (Platform.isIOS) {
    return 'http://127.0.0.1:3001'; // iOS simulator localhost address
  }
  return 'http://localhost:3001'; // Fallback
}

class _PatientListState extends State<PatientListPage> {
  final TextEditingController searchController = TextEditingController();
  late final String apiUrl;
  List<Map<String, dynamic>> patients = [];
  bool _isLoading = false;
  List<Map<String, dynamic>> filteredPatients = [];
  String searchPatient = '';

  @override
  void initState() {
    super.initState();
    apiUrl = '${getLocalHostUrl()}/patients';
    _fetchPatients();
  }

  Future<void> _fetchPatients() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          patients = data.map((patient) => {
            '_id': patient['_id'],
            'patientId': patient['patientId'],
            'name': patient['name'],
            'condition': patient['condition'],
          }).toList();

          patients.sort((a,b) {
            if (a['condition'] == 'Critical' && b['condition'] != 'Critical') {
              return -1;
            } else if (a['condition'] != 'Critical' && b['condition'] == 'Critical') {
              return 1;
            } else {
              return 0;
            }
          });
          filteredPatients = List.from(patients);
        });
      } else {
        _showMessage("Failed to load patients");
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

  void filterSearch(String query) {
    setState(() {
      searchPatient = query;
      if(query.isEmpty) {
        filteredPatients = List.from(patients);
      } else {
        filteredPatients = patients
        .where((patient) => patient['name'].toLowerCase().contains(query.toLowerCase()))
        .toList();
      }
    });
  }

  // To add a patient
  void _addPatient() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddPatientPage()),
    );

    if (result == 'added') {
      _fetchPatients();
    }
  }
  
  // To delete a patient
  void _deletePatient(String patientId) async {
    try{
      final response = await http.delete(Uri.parse('$apiUrl/$patientId'));

      if(response.statusCode == 200) {
        setState(() {
          patients.removeWhere((p) => p['_id'] == patientId);
          filteredPatients = List.from(patients);
        });
        _showMessage("Patient deleted successfully.");
      } else {
        _showMessage("Failed to delete patient");
      }
    } catch(error) {
      _showMessage("Network error. Please try again.");
    }
  }

  void _viewPatientDetails(Map<String, dynamic> patient) async{
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PatientDetailsScreen(
          patientName: patient['name'],
          patientId: patient["_id"].toString(),
          condition: patient['condition'],
        ),
      ),
    );
    if (result == 'updated') {
      _fetchPatients();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Patient List"),
        elevation: 0,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/background.jpg',
              fit: BoxFit.cover,
            ),
          ),
          Column(
            children: [
              Padding(
                padding: EdgeInsets.all(18),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: searchController,
                        onChanged: (value) => filterSearch(value),
                        decoration: InputDecoration(
                            hintText: 'Search',
                            hintStyle: TextStyle(fontSize: 20),
                            prefixIcon: Icon(Icons.search, size: 30,),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10))),
                      ),
                    ),
                    IconButton(
                      onPressed: _addPatient,
                      icon: Icon(Icons.person_add, color: Colors.black),
                      iconSize: 30,
                    ),
                  ],
                ),
              ),
              Expanded(
                  child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredPatients.isEmpty
                        ? const Center(
                            child: Text(
                              "No patients found",
                              style: TextStyle(fontSize: 20, color: Colors.grey),
                            ),
                          )
                  : ListView.builder(
                      padding: EdgeInsets.all(18),
                      itemCount: filteredPatients.length,
                      itemBuilder: (context, index) {
                        final patient = filteredPatients[index];
                        return Dismissible(
                          key: Key(patient['_id']),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            color: Colors.red,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: const Icon(Icons.delete, color: Colors.white),
                          ),
                          confirmDismiss: (direction) async {
                            final shouldDelete = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text("Confirm Deletion"),
                                content: const Text("Are you sure you want to delete this patient?"), 
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: const Text("Cancel"),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    child: const Text("Delete"),
                                  ),
                                ],
                              ),
                            );

                            if (shouldDelete == true) {
                              _deletePatient(patient['_id']);
                              return true; // Allow to Dismiss
                            }
                            return false; // No Allow to Dismiss
                          },
                          child: Card(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                            color: patient['condition'] == 'Critical'
                                ? const Color.fromARGB(255, 233, 144, 137)
                                : const Color.fromARGB(255, 230, 230, 230),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(left: 16.0),
                                  child:
                                  Row(
                                    children: [
                                      Text(patient['patientId'] as String,
                                        style: TextStyle(fontSize: 18),
                                      ),
                                      SizedBox(width: 20,),
                                      Text(patient['name'] as String,
                                        style: TextStyle(fontSize: 20),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => _viewPatientDetails(patient),
                                  icon: const Icon(Icons.info, color: Colors.blue),
                                  iconSize: 30,
                                ),
                              ],
                            ),
                          ),
                        );
                      }))
            ],
          ),
        ]
      )
    );
  }
}
