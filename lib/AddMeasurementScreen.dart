import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;
import 'dart:convert';

class AddMeasurementPage extends StatefulWidget{
  final String patientId;
  final String patientName;
  final Map<String, dynamic>? patientDetails;

const AddMeasurementPage({super.key, 
  required this.patientId,
  required this.patientName,
  this.patientDetails});

  @override
  State<StatefulWidget> createState() {
    return _AddMeasurementState();
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

class _AddMeasurementState extends State<AddMeasurementPage> {

static const List<String> measurementTypes = <String>[
    "Blood Pressure",
    "Heartbeat Rate",
    "Blood Oxygen Level",
    "Respiratory Rate"
  ];

  String dropdownvalue = measurementTypes.first;

  final TextEditingController valueController = TextEditingController();
  final TextEditingController sysController = TextEditingController();
  final TextEditingController diaController = TextEditingController();
  bool _isLoading = false;

  // Time picker to select time
  TimeOfDay selectedTime = TimeOfDay.now();

  Future<void> _selectTime() async {
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: selectedTime,
    );
    if (time != null) {
      setState(() {
        selectedTime = time;
      });
    }
  }

  // Date picker to select date
  DateTime selectedDate = DateTime.now();

  Future<void> _selectDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2021),
      lastDate: DateTime(2030),
    );

    if (pickedDate != null) {
      setState(() {
        selectedDate = pickedDate;
      });
    }
  }

  Future<void> _submit() async {
  setState(() => _isLoading = true);

  try {
    // 1. Prepare measurement data
    final measurementDateTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );

    Map<String, dynamic> measurementData = {
      'patient_id': widget.patientId,
      'type': dropdownvalue,
      'dateTime': measurementDateTime.toIso8601String(),
    };

    bool isAbnormal = false;
    int? numericValue1;
    int? numericValue2;

    // 2. Parse values and check for abnormalities
    switch (dropdownvalue) {
      case "Blood Pressure":
        numericValue1 = int.tryParse(sysController.text.trim());
        numericValue2 = int.tryParse(diaController.text.trim());
        if (numericValue1 == null || numericValue2 == null) {
          throw Exception("Please enter valid numbers for blood pressure");
        }
        
        measurementData['value'] = '$numericValue1/${numericValue2} mmHg';
        measurementData['systolic'] = numericValue1;
        measurementData['diastolic'] = numericValue2;
        
        isAbnormal = numericValue1 > 180 || 
                    numericValue1 < 90 || 
                    numericValue2 > 120 || 
                    numericValue2 < 60;
        break;

      case "Heartbeat Rate":
        numericValue1 = int.tryParse(valueController.text.trim());
        if (numericValue1 == null) {
          throw Exception("Please enter a valid number for heartbeat rate");
        }
        
        measurementData['value'] = '$numericValue1 bpm';
        measurementData['bpm'] = numericValue1;
        
        isAbnormal = numericValue1 < 60 || numericValue1 > 100;
        break;

      case "Blood Oxygen Level":
        numericValue1 = int.tryParse(valueController.text.trim());
        if (numericValue1 == null) {
          throw Exception("Please enter a valid number for blood oxygen level");
        }
        
        measurementData['value'] = '$numericValue1 %';
        measurementData['spo2'] = numericValue1;
        
        isAbnormal = numericValue1 < 90;
        break;

      case "Respiratory Rate":
        numericValue1 = int.tryParse(valueController.text.trim());
        if (numericValue1 == null) {
          throw Exception("Please enter a valid number for respiratory rate");
        }
        
        measurementData['value'] = '$numericValue1 breaths/min';
        measurementData['respiratoryRate'] = numericValue1;
        
        isAbnormal = numericValue1 < 12 || numericValue1 > 20;
        break;
    }

    // 3. Save the measurement
    final measurementResponse = await http.post(
      Uri.parse('${getLocalHostUrl()}/clinical'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(measurementData),
    );

    if (measurementResponse.statusCode == 201) {
      // 4. If abnormal, update patient condition
      if (isAbnormal) {
        final patientUpdateResponse = await http.put(
          Uri.parse('${getLocalHostUrl()}/patients/${widget.patientId}'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'condition': 'Critical',
            // Include all required fields for patient update
            'name': widget.patientName, 
            // Add other required fields here
          }),
        );

        if (patientUpdateResponse.statusCode != 200) {
          throw Exception('Failed to update patient condition');
        }
      }

      // 5. Return to previous screen with refresh flag
      Navigator.pop(context, {
        'refresh': true,
        'isAbnormal': isAbnormal,
      });
    } else {
      throw Exception('Failed to save measurement: ${measurementResponse.body}');
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.toString())),
    );
  } finally {
    setState(() => _isLoading = false);
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Measurement"),),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select Measurement Type:', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),),
            const SizedBox(height: 30,),

            // Dropdown for selecting measurement type
            SizedBox(
              width: double.infinity,
              child: DropdownButtonFormField<String>(
              value: dropdownvalue, 
              isExpanded: true,
              onChanged:(String? newValue) {
                setState(() {
                  dropdownvalue = newValue!;
                });
              },
              items: measurementTypes.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem(value: value, child: Text(value, style: TextStyle(fontSize: 20),));
              }).toList(),
              )
            ),

            const SizedBox(height: 30,),

            if(dropdownvalue == "Blood Pressure")
            Row(children: [
              Expanded(child: 
              TextField(
                controller: sysController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)
                  ),
                  filled: true,
                  fillColor: Colors.grey[200],
                  hintText: 'Systolic'
                ),
              )),
              const SizedBox(width: 10,),
              const Text('/', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 10,),

              Expanded(child:
              TextField(
                controller: diaController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)
                  ),
                  filled: true,
                  fillColor: Colors.grey[200],
                  hintText: 'Diastolic'
                ),
              )),
              const SizedBox(width: 10,),
              const Text('mmHg', style: TextStyle(fontSize: 20),)
            ],)
            else
            Row(children: [
              Expanded(child: 
              TextField(
              controller: valueController,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10)
                ),
                filled: true,
                fillColor: Colors.grey[200],
                hintText: dropdownvalue == "Heartbeat Rate"
                ? "Enter Heartbeat Value"
                : dropdownvalue == "Blood Oxygen Level"
                ? "Enter blood oxygen value"
                : "Enter Respiratory Rate"
              ),
            ),
              ),
              const SizedBox(width: 10,),
              Text(
                dropdownvalue == "Heartbeat Rate"
              ? "bpm"
              : dropdownvalue == "Blood Oxygen Level"
              ? "%"
              : "breaths/min", style: TextStyle(fontSize: 20),),
            ],),
            

            const SizedBox(height: 30,),

            const Text('Select Date & Time:', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),),
             const SizedBox(height: 30),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
            IconButton(
              onPressed: _selectTime,
              icon: Icon(Icons.access_time_outlined, size: 30,),
            ),
            GestureDetector(
              onTap: _selectTime,
              child: 
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  selectedTime.format(context),
                  style: const TextStyle(fontSize: 20)
                ),
              ),
            ),
            
            SizedBox(width: 20),
              IconButton(
                onPressed: _selectDate, 
                icon: Icon(Icons.calendar_month, size: 30,),),
              GestureDetector(
                onTap: _selectDate,
                child: 
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(5)
                  ),
                  child: Text(
                    '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                    style: const TextStyle(fontSize: 20)
                  ),
                ),
              ),
            ],),

            const SizedBox(height: 30),

            Center(
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Submit", 
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ],
        ),
        ),
    );
  }
  
}