import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;
import 'dart:convert';

class AddMeasurementPage extends StatefulWidget{
  final String patientId;
const AddMeasurementPage({super.key, required this.patientId});

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

  Future<void> _submit () async {
    setState(() {
      _isLoading = true;
    });
    try {
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
      switch (dropdownvalue) {
        case "Blood Pressure":
          measurementData['value'] = '${sysController.text.trim()}/${diaController.text.trim()} mmHg';
          measurementData['systolic'] = int.tryParse(sysController.text.trim());
          measurementData['diastolic'] = int.tryParse(diaController.text.trim());
          break;
        case "Heartbeat Rate":
          measurementData['value'] = '${valueController.text.trim()} bpm';
          measurementData['bpm'] = int.tryParse(valueController.text.trim());
          break;
        case "Blood Oxygen Level":
          measurementData['value'] = '${valueController.text.trim()} %';
          measurementData['spo2'] = int.tryParse(valueController.text.trim());
          break;
        case "Respiratory Rate":
          measurementData['value'] = '${valueController.text.trim()} breaths/min';
          measurementData['respiratoryRate'] = int.tryParse(valueController.text.trim());
          break;
      }

      final response = await http.post(
        Uri.parse('${getLocalHostUrl()}/clinical'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(measurementData),
      );

      if (response.statusCode == 201) {
        Navigator.pop(context, 'added');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save measurement: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
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