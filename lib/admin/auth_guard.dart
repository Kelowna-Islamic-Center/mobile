import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../admin/admin_page.dart';

class AdminAuthPage extends StatefulWidget {
  const AdminAuthPage({Key? key}) : super(key: key);

  @override
  AdminAuthPageState createState() => AdminAuthPageState();
}

class AdminAuthPageState extends State<AdminAuthPage> {
  String email = "";
  String password = "";
  bool loading = false;

  final _formKey = GlobalKey<FormState>();
  TextEditingController emailController = TextEditingController(text: "");

  @override
  void initState() {
    super.initState();

    // Set initalValue of email to saved email address for easier login
    SharedPreferences.getInstance().then((prefs) {
      String? savedEmail = prefs.getString("adminEmail");

      if (savedEmail != null) {
        setState(() => emailController.text = savedEmail);
      }
    });
  }

  // Authentiction with Firebase auth
  Future<Map<String, dynamic>> _authenticate() async {
    try {
      await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      // Save email address for easier login next time
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("adminEmail", email);

      return {
        "success": true,
        "message": "Successful login",
      };
    } on FirebaseAuthException catch (e) {
      String message;
      if (e.code == 'user-not-found' ||
          e.code == 'wrong-password' ||
          e.code == 'invalid-email') {
        message = "Incorrect email address or password";
      } else if (e.code == 'user-disabled') {
        message = "This account is disabled";
      } else if (e.code == 'network-request-failed') {
        message = "Couldn't login, you might be offline";
      } else {
        message = "An error occured";
      }

      return {
        "success": false,
        "message": message,
      };
    }
  }

  // Route to admin tools page on success
  _navigateOnSuccess() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const AdminPage()),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
          title: const Text("Admin Tools"),
        ),
      body: Center(
          child: SingleChildScrollView(
              child: Card(
                  margin: const EdgeInsets.all(15.0),
                  elevation: 3,
                  child: Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Admin Login",
                                style: TextStyle(
                                    fontSize: 30.0,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 10.0),
                            const Row(children: [
                              Icon(Icons.admin_panel_settings, size: 30),
                              SizedBox(width: 10.0),
                              Flexible(
                                  child: Text(
                                      "This page is for admin use only and require an Admin Login. Contact the Masjid Board for further information.",
                                      style: TextStyle(fontSize: 14)))
                            ]),
                            const SizedBox(height: 20.0),
                            Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  /* Email Address Field */
                                  TextFormField(
                                    controller: emailController,
                                    decoration: const InputDecoration(
                                        labelText: 'Email Address'),
                                    keyboardType: TextInputType.emailAddress,
                                    onSaved: (String? value) => email = value!,
                                    validator: (value) {
                                      if (value == null || value.isEmpty)
                                        return 'Email Address cannot be empty';
                                      return null;
                                    },
                                  ),

                                  /* Password Field */
                                  TextFormField(
                                    decoration: const InputDecoration(
                                        labelText: 'Password'),
                                    obscureText: true,
                                    enableSuggestions: false,
                                    autocorrect: false,
                                    keyboardType: TextInputType.visiblePassword,
                                    onSaved: (String? value) =>
                                        password = value!,
                                    validator: (value) {
                                      if (value == null || value.isEmpty)
                                        return 'Password cannot be empty';
                                      return null;
                                    },
                                  ),
                                  Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16.0),
                                      child: Row(
                                        children: [
                                          /* Submit Button */
                                          ElevatedButton(
                                            // style: ButtonStyle(backgroundColor: WidgetStateColor.resolveWith((_) => Theme.of(context).colorScheme.primary)),
                                            onPressed: () async {
                                              if (_formKey.currentState!
                                                  .validate()) {
                                                loading = true;
                                                _formKey.currentState!.save();

                                                Map<String, dynamic> auth =
                                                    await _authenticate();
                                                loading = false;

                                                if (auth["success"]) {
                                                  _navigateOnSuccess();
                                                } else {
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    SnackBar(
                                                        content: Text(
                                                            auth["message"])),
                                                  );
                                                }
                                              }
                                            },
                                            child: const Text('Login'),
                                          ),
                                          const SizedBox(width: 20),
                                          if (loading)
                                            const CircularProgressIndicator()
                                        ],
                                      ))
                                ],
                              ),
                            )
                          ]))))));
}
