import 'package:flutter/material.dart';
import 'package:mapd722_project/PatientListScreen.dart';
import 'ForgotPasswordScreen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io' show Platform;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<StatefulWidget> createState() {
    return _LoginScreenState();
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

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  late final String apiUrl; 
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    apiUrl = '${getLocalHostUrl()}/login';  
  }

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
    });

    final String username = usernameController.text.trim();
    final String password = passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      _showMessage("Email and password cannot be empty");
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": username, "password": password}),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        _showMessage("Login successful!");

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const PatientListPage()),
        );
      } else {
        _showMessage(responseData["message"] ?? "Login failed");
      }
    } catch (error) {
      _showMessage("Network error, please try again");
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

  void _navigateToForgotPassword() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ForgotPasswordPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Patient Clinical Data Management App')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /*----- App Image -----*/
              Align(
                alignment: Alignment.topCenter,
                child: Image.asset(
                  'assets/Logo.png',
                  height: 250,
                  fit: BoxFit.cover,
                ),
              ),

              const SizedBox(height: 30),

              /*----- Username Field -----*/
              const SizedBox(height: 8),
              TextField(
                controller: usernameController,
                style: const TextStyle(fontSize: 18),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.person),
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.blue, width: 2),
                  ),
                  hintText: "Enter Username",
                ),
              ),

              const SizedBox(height: 20),

              /*----- Password Field -----*/
              const SizedBox(height: 8),
              TextField(
                controller: passwordController,
                style: const TextStyle(fontSize: 18),
                obscureText: !_isPasswordVisible,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.blue, width: 2),
                  ),
                  hintText: "Enter Password",
                ),
              ),
              /*----- Forgot Password -----*/
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _navigateToForgotPassword,
                  child: const Text(
                    "Forgot Password?",
                    style: TextStyle(fontSize: 16, color: Colors.blue, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              /*----- Login Button -----*/
              Center(
                child: SizedBox(
                  width: double.infinity, // Make the button width fit the screen
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: _isLoading ? null : _login,
                    child: const Text(
                      'Login',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
