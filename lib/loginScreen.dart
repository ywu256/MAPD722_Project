import 'package:flutter/material.dart';
import 'package:mapd722_project/PatientListScreen.dart';


class LoginScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _LoginScreenState();
  }
  
}

class _LoginScreenState extends State<LoginScreen> {

  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  void _navigateToPatientList() async {
    await Navigator.push(context, MaterialPageRoute(builder: (context) => PatientListPage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MAPD722 Project')),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, 
            children: [
              Align(
                alignment: Alignment.topCenter,
                child: Image.asset(
                  'assets/Logo.jpg',
                  height: 300,
                  fit: BoxFit.cover,
                ),
              ),
              SizedBox(height: 30),
              Text('Username:', style: TextStyle(fontSize: 20)),
              TextField(
                controller: usernameController,
                
                style: TextStyle(fontSize: 20),
                decoration: InputDecoration(border: OutlineInputBorder(), hintText: "Enter Username"),
              ),
              SizedBox(height: 20),
              Text('Password:', style: TextStyle(fontSize: 20)),
              TextField(
                controller: passwordController,
                style: TextStyle(fontSize: 20),
                obscureText: true,
                decoration: InputDecoration(border: OutlineInputBorder(), hintText: "Enter Password"),
              ),
              SizedBox(height: 30),
              Center(
                child: ElevatedButton(
                  onPressed: _navigateToPatientList,
                  child: const Text(
                    'Login',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
  
}
