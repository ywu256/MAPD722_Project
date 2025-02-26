import 'package:flutter/material.dart';
import 'package:mapd722_project/PatientListScreen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<StatefulWidget> createState() {
    return _LoginScreenState();
  }
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  void _navigateToPatientList() async {
    await Navigator.push(context, MaterialPageRoute(builder: (context) => PatientListPage()));
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
              // const Text('Username:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
              // const Text('Password:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
                    onPressed: _navigateToPatientList,
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
