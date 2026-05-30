import 'package:flutter/material.dart';

class EditBusinessScreen extends StatefulWidget {
  final Map<String, String> business;

  const EditBusinessScreen({super.key, required this.business});

  @override
  State<EditBusinessScreen> createState() => _EditBusinessScreenState();
}

class _EditBusinessScreenState extends State<EditBusinessScreen> {
  late TextEditingController titleCtrl;
  late TextEditingController logoCtrl;
  late TextEditingController locationCtrl;
  late TextEditingController emailCtrl;
  late TextEditingController phoneCtrl;
  late TextEditingController descCtrl;

  @override
  void initState() {
    super.initState();
    titleCtrl = TextEditingController(text: widget.business["title"]);
    logoCtrl = TextEditingController(text: widget.business["logoUrl"]);
    locationCtrl = TextEditingController(text: widget.business["location"]);
    emailCtrl = TextEditingController(text: widget.business["email"]);
    phoneCtrl = TextEditingController(text: widget.business["phone"]);
    descCtrl = TextEditingController(text: widget.business["description"]);
  }

  @override
  void dispose() {
    titleCtrl.dispose();
    logoCtrl.dispose();
    locationCtrl.dispose();
    emailCtrl.dispose();
    phoneCtrl.dispose();
    descCtrl.dispose();
    super.dispose();
  }

  void _saveBusiness() {
    // Later replace with DB / API save logic
    final updatedBusiness = {
      "title": titleCtrl.text,
      "logoUrl": logoCtrl.text,
      "location": locationCtrl.text,
      "email": emailCtrl.text,
      "phone": phoneCtrl.text,
      "description": descCtrl.text,
    };

    Navigator.pop(context, updatedBusiness); // send back updated data
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Business Details"),
        actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: _saveBusiness),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: "Business Title"),
            ),
            TextField(
              controller: logoCtrl,
              decoration: const InputDecoration(labelText: "Logo URL"),
            ),
            TextField(
              controller: locationCtrl,
              decoration: const InputDecoration(labelText: "Location"),
            ),
            TextField(
              controller: emailCtrl,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            TextField(
              controller: phoneCtrl,
              decoration: const InputDecoration(labelText: "Phone"),
            ),
            TextField(
              controller: descCtrl,
              maxLines: 3,
              decoration: const InputDecoration(labelText: "Description"),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _saveBusiness,
              icon: const Icon(Icons.save),
              label: const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }
}
