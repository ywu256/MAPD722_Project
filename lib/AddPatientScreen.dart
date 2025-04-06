import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';

class AddPatientPage extends StatefulWidget {
  const AddPatientPage({super.key});

  @override
  _AddPatientPageState createState() => _AddPatientPageState();
}

class _AddPatientPageState extends State<AddPatientPage> {
  final _formKey = GlobalKey<FormState>();
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
  
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = false;

  String getLocalHostUrl() {
  if (Platform.isAndroid) {
    return 'http://10.0.2.2:3001'; // Android emulator localhost address
  } else if (Platform.isIOS) {
    return 'http://127.0.0.1:3001'; // iOS simulator localhost address
  }
  return 'http://localhost:3001'; // Fallback
}

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadPhoto(File image) async {
    var request = http.MultipartRequest('POST', Uri.parse('${getLocalHostUrl()}/upload'));
    request.files.add(await http.MultipartFile.fromPath('photo', image.path));
    var response = await request.send();

    if (response.statusCode == 200) {
      var responseData = await response.stream.bytesToString();
      final decoded = jsonDecode(responseData);
      return decoded['photoUrl'];
    } else {
      return null;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    String? photoUrl;
    if (_selectedImage != null) {
      photoUrl = await _uploadPhoto(_selectedImage!);
    }

    final response = await http.post(
      Uri.parse('${getLocalHostUrl()}/patients'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': _nameController.text.trim(),
        'age': int.parse(_ageController.text.trim()),
        'gender': _selectedGender,
        'admissionDate': DateTime.now().toIso8601String(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'address': _addressController.text.trim(),
        'emergencyContactPhone': _emergencyController.text.trim(),
        'medicalHistory': _medicalController.text.trim(),
        'allergies': _allergyController.text.trim(),
        'bloodType': _selectedBloodType,
        'photoUrl': photoUrl
      }),
    );

    setState(() => _isLoading = false);

    if (response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Patient added successfully")));
      Navigator.pop(context, 'added');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to add patient")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Patient')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 60,
                      backgroundImage: _selectedImage != null ? FileImage(_selectedImage!) : null,
                      child: _selectedImage == null ? const Icon(Icons.camera_alt, size: 40) : null,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

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
                
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Submit", style: TextStyle(fontSize: 18)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(
    String label,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
    bool isRequired = true,
    String? Function(String?)? validator,
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
}
