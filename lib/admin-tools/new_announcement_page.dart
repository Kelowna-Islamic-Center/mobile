import 'package:flutter/material.dart';

class NewAnnouncementsPage extends StatefulWidget {
  const NewAnnouncementsPage({Key? key}) : super(key: key);

  @override
  NewAnnouncementsPageState createState() => NewAnnouncementsPageState();
}


class NewAnnouncementsPageState extends State<NewAnnouncementsPage> {
  
  String title = "";
  String description = "";
  bool loading = false;

  final _formKey = GlobalKey<FormState>();

  Future<Map<String, dynamic>> _addAnnouncement() async {
    // TODO: Implement method
    return {
      "success": true,
      "message": "works"
    };
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text("Add an Announcement"),
    ),

    body: SingleChildScrollView(child: 
      Card(
        margin: const EdgeInsets.all(15.0),
        elevation: 3,
        child: Padding(padding: const EdgeInsets.all(15.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Add Announcement".toUpperCase(),
                style: const TextStyle(
                  fontSize: 20.0, 
                  fontWeight: FontWeight.bold)),

              const SizedBox(height: 10.0),

              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /* Email Address Field */
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Enter Title'),
                      keyboardType: TextInputType.text,
                      onSaved: (String? value) => title = value!,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Title cannot be empty';
                        return null;
                      },
                    ),

                    /* Password Field */
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Enter Description'),
                      keyboardType: TextInputType.multiline,
                      maxLines: null,
                      onSaved: (String? value) => description = value!,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Description cannot be empty';
                        return null;
                      },
                    ),
                    Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: Row(
                          children: [
                            /* Submit Button */
                            ElevatedButton(
                              onPressed: () async {
                                if (_formKey.currentState!.validate()) {
                                  loading = true;
                                  _formKey.currentState!.save();

                                  Map<String, dynamic> auth = await _addAnnouncement();
                                  loading = false;

                                  if (auth["success"]) {
                                    
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(auth["message"])),
                                    );
                                  }
                                }
                              },
                              child: const Text('Add Announcement'),
                            ),
                            const SizedBox(width: 20),
                            if (loading) const CircularProgressIndicator()
                          ],
                        ))
                  ],
                ),
              )
            ],
          ),
        ),
      )
    )
  );
}