import 'package:flutter/material.dart';

class EditorPage extends StatefulWidget {
  const EditorPage({Key? key}) : super(key: key);

  @override
  EditorPageState createState() => EditorPageState();
}

class EditorPageState extends State<EditorPage> {
  
  String? email;
  String? password;

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(child: SingleChildScrollView(child:
          Card(
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
                        
                        Row(
                          children: const [
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
                                decoration: const InputDecoration(labelText: 'Email Address'),
                                keyboardType: TextInputType.emailAddress,
                                onSaved: (String? value) => email = value,
                                validator: (value) {
                                  if (value == null || value.isEmpty) return 'Email Address cannot be empty';
                                },
                              ),

                              /* Password Field */
                              TextFormField(
                                decoration: const InputDecoration(labelText: 'Password'),
                                obscureText: true,
                                enableSuggestions: false,
                                autocorrect: false,
                                keyboardType: TextInputType.visiblePassword,
                                onSaved: (String? value) => password = value,
                                validator: (value) {
                                  if (value == null || value.isEmpty) return 'Password cannot be empty';
                                },
                              ),

                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 16.0),
                                child: ElevatedButton(
                                  onPressed: () {
                                    if (_formKey.currentState!.validate()) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Signing In')),
                                      );
                                      _formKey.currentState!.save();
                                      
                                      // TODO: Handle input
                                    }
                                  },
                                  child: const Text('Login'),
                                ),
                              ),
                            ],
                          ),
                        )
                      ])))
        )));
}
