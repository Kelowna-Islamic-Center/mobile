import "package:firebase_auth/firebase_auth.dart";
import "package:flutter/material.dart";
import "package:kelowna_islamic_center/sections/settings/admin/admin_page.dart";

import "package:flutter_gen/gen_l10n/app_localizations.dart";

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

  // Authentication with Firebase auth
  Future<Map<String, dynamic>> _authenticate() async {
    try {
      await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      return {
        "success": true,
        "message": "Successful login",
      };
    } on FirebaseAuthException catch (e) {
      String message;

      if (!context.mounted) {
        return {
          "success": false,
          "message": "Failure",
        };
      }
      
      if (e.code == "user-not-found" ||
          e.code == "wrong-password" ||
          e.code == "invalid-email") {
        message = AppLocalizations.of(context)!.incorrectPassword;
      } else if (e.code == "user-disabled") {
        message = AppLocalizations.of(context)!.disabledAccount;
      } else if (e.code == "network-request-failed") {
        message = AppLocalizations.of(context)!.offlineLogin;
      } else {
        message = AppLocalizations.of(context)!.errorLogin;
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
          title: Text(AppLocalizations.of(context)!.adminLoginTitle),
        ),
      body: Center(
          child: SingleChildScrollView(
              child: Card(
                  margin: const EdgeInsets.all(15),
                  elevation: 3,
                  child: Padding(
                      padding: const EdgeInsets.all(15),
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(AppLocalizations.of(context)!.adminLoginTitle,
                                style: const TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 10),
                            Row(children: [
                              const Icon(Icons.admin_panel_settings, size: 30),
                              const SizedBox(width: 10),
                              Flexible(
                                  child: Text(
                                      AppLocalizations.of(context)!.adminDescription,
                                      style: const TextStyle(fontSize: 14)))
                            ]),
                            const SizedBox(height: 20),
                            Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  /* Email Address Field */
                                  TextFormField(
                                    controller: emailController,
                                    decoration: InputDecoration(
                                        labelText: AppLocalizations.of(context)!.emailPlaceholder),
                                    keyboardType: TextInputType.emailAddress,
                                    onSaved: (String? value) => email = value!,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return AppLocalizations.of(context)!.emailRequired;
                                      }
                                      return null;
                                    },
                                  ),

                                  /* Password Field */
                                  TextFormField(
                                    decoration: InputDecoration(
                                        labelText: AppLocalizations.of(context)!.passwordPlaceholder),
                                    obscureText: true,
                                    enableSuggestions: false,
                                    autocorrect: false,
                                    keyboardType: TextInputType.visiblePassword,
                                    onSaved: (String? value) =>
                                        password = value!,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return AppLocalizations.of(context)!.passwordRequired;
                                      }
                                      return null;
                                    },
                                  ),
                                  Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16),
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
                                            child: Text(AppLocalizations.of(context)!.login),
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
