import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';

class EditPatientPage extends StatefulWidget {
  final String patientId;

  const EditPatientPage({super.key, required this.patientId});

  @override
  _EditPatientPageState createState() => _EditPatientPageState();
}

String getLocalHostUrl() {
  if (Platform.isAndroid) {
    return 'http://10.0.2.2:3001'; // Android emulator localhost address
  } else if (Platform.isIOS) {
    return 'http://127.0.0.1:3001'; // iOS simulator localhost address
  }
  return 'http://localhost:3001'; // Fallback
}

class _EditPatientPageState extends State<EditPatientPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;
  bool _isLoading = true;
  Map<String, dynamic>? patientDetails;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _emergencyController = TextEditingController();
  final TextEditingController _medicalController = TextEditingController();
  final TextEditingController _allergyController = TextEditingController();

  String? _selectedGender;
  String? _selectedBloodType;

  @override
  void initState() {
    super.initState();
    _fetchPatient();
  }

  Future<void> _fetchPatient() async {
    final response = await http.get(Uri.parse('${getLocalHostUrl()}/patients/${widget.patientId}'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        patientDetails = data['patient'];
        _nameController.text = patientDetails?['name'] ?? '';
        _ageController.text = patientDetails?['age']?.toString() ?? '';
        _selectedGender = patientDetails?['gender'];
        _selectedBloodType = (patientDetails?['bloodType'] ?? '').toString().isEmpty ? null : patientDetails?['bloodType'];
        _phoneController.text = patientDetails?['phone'] ?? '';
        _emailController.text = patientDetails?['email'] ?? '';
        _addressController.text = patientDetails?['address'] ?? '';
        _emergencyController.text = patientDetails?['emergencyContactPhone'] ?? '';
        _medicalController.text = patientDetails?['medicalHistory'] ?? '';
        _allergyController.text = patientDetails?['allergies'] ?? '';
        _isLoading = false;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to load patient data")));
      setState(() => _isLoading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final response = await http.put(
      Uri.parse('${getLocalHostUrl()}/patients/${widget.patientId}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': _nameController.text.trim(),
        'age': int.tryParse(_ageController.text.trim()),
        'gender': _selectedGender,
        'bloodType': _selectedBloodType,
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'address': _addressController.text.trim(),
        'emergencyContactPhone': _emergencyController.text.trim(),
        'medicalHistory': _medicalController.text.trim(),
        'allergies': _allergyController.text.trim(),
      }),
    );

    setState(() => _isSaving = false);

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Patient updated successfully")));
      Navigator.pop(context, 'updated');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to update patient")));
    }
  }

  Widget _buildInputField(
    String label, 
    TextEditingController controller, {
      TextInputType keyboardType = TextInputType.text, 
      bool isRequired = true, 
      String? Function(String?)? validator
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          filled: true,
          fillColor: Colors.grey[200],
        ),
        validator: validator ??
            (isRequired
                ? (value) => value == null || value.trim().isEmpty ? '$label is required' : null
                : null),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Patient'),
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
          _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Personal Info", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    _buildInputField("Name", _nameController),
                    _buildInputField("Age", _ageController, keyboardType: TextInputType.number, validator: (value) {
                      if (value == null || value.trim().isEmpty) return 'Age is required';
                      final age = int.tryParse(value.trim());
                      if (age == null || age <= 0) return 'Please enter a valid age.';
                      return null;
                    }),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: DropdownButtonFormField<String>(
                        value: _selectedGender,
                        decoration: InputDecoration(
                          labelText: "Gender",
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          filled: true,
                          fillColor: Colors.grey[200],
                        ),
                        items: const [
                          DropdownMenuItem(value: "male", child: Text("Male")),
                          DropdownMenuItem(value: "female", child: Text("Female")),
                          DropdownMenuItem(value: "other", child: Text("Other")),
                        ],
                        onChanged: (value) => setState(() => _selectedGender = value),
                        validator: (value) => value == null || value.isEmpty ? 'Gender is required' : null,
                      ),
                    ),
                    
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: DropdownButtonFormField<String>(
                        value: _selectedBloodType,
                        decoration: InputDecoration(
                          labelText: "Blood Type",
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          filled: true,
                          fillColor: Colors.grey[200],
                        ),
                        items: ["O+", "O-", "A+", "A-", "B+", "B-", "AB+", "AB-"]
                            .map((type) => DropdownMenuItem(
                                  value: type,
                                  child: Text(type),
                                ))
                            .toList(),
                        onChanged: (value) => setState(() => _selectedBloodType = value),
                        validator: (value) => value == null || value.isEmpty ? 'Blood Type is required' : null,
                      ),
                    ),

                    const SizedBox(height: 20),
                    const Text("Contact Info", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    _buildInputField("Phone", _phoneController, keyboardType: TextInputType.phone, validator: (value) {
                      final cleaned = value?.replaceAll(RegExp(r'[^0-9]'), '') ?? '';
                      if (cleaned.isEmpty) return 'Phone is required';
                      if (cleaned.length != 10) return 'Phone must be 10 digits';
                      return null;
                    }),
                    _buildInputField("Email", _emailController, keyboardType: TextInputType.emailAddress, validator: (value) {
                      if (value == null || value.trim().isEmpty) return 'Email is required';
                      final emailRegex = RegExp(r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,}$');
                      if (!emailRegex.hasMatch(value.trim())) return 'Please enter a valid email';
                      return null;
                    }),
                    _buildInputField("Address", _addressController),
                    _buildInputField("Emergency Contact", _emergencyController, keyboardType: TextInputType.phone, validator: (value) {
                      final cleaned = value?.replaceAll(RegExp(r'[^0-9]'), '') ?? '';
                      if (cleaned.isEmpty) return 'Emergency Contact is required';
                      if (cleaned.length != 10) return 'Emergency Contact must be 10 digits';
                      return null;
                    }),

                    const SizedBox(height: 20),
                    const Text("Medical Details", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    _buildInputField("Medical History", _medicalController, isRequired: false),
                    _buildInputField("Allergies", _allergyController, isRequired: false),

                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _save,
                        child: _isSaving
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text("Save", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ]
      )
    );
  }
}
