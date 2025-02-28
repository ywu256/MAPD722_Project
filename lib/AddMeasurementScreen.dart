import 'package:flutter/material.dart';


class AddMeasurementPage extends StatefulWidget{
const AddMeasurementPage({super.key});

  @override
  State<StatefulWidget> createState() {
    return _AddMeasurementState();
  }
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

  void _submit () {
    String selectedMeasurement = dropdownvalue;
    String enteredValue = valueController.text.trim();

    Navigator.pop(context, {
      'measurementType': selectedMeasurement,
      'value': enteredValue,
    });
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
            const Text('Select Measurement Type:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),),
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
                return DropdownMenuItem(value: value, child: Text(value));
              }).toList(),
              )
            ),

            const SizedBox(height: 30,),

            Row(
              children: [
                const Text('Enter Value:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),),
                const SizedBox(width: 10),

                Expanded(child: 
                TextField(
                  controller: valueController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: Colors.grey[200],
                    hintText: 'Enter value',
                  ),
                ),
                ),
              ],
            ),

            const SizedBox(height: 30),
            
            Center(
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _submit,
                  child: const Text("Submit", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ],
        ),
        ),
    );
  }
  
}