import 'package:flutter/material.dart';
import 'package:hotel_management_system/presentation/admin_screens/buisness_management_screen/edit_buisness_screen.dart';

class BusinessManagementScreen extends StatelessWidget {
  const BusinessManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Sample business details (later you can load from database / API)
    final business = {
      "title": "My SaaS Business",
      "logoUrl": "https://via.placeholder.com/150",
      "location": "Bahawalpur, Pakistan",
      "email": "contact@mysaas.com",
      "phone": "+92 300 1234567",
      "description":
          "We provide next-generation SaaS solutions for businesses worldwide.",
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text("Business Management"),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditBusinessScreen(business: business),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Business Logo
            CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage(business["logoUrl"]!),
            ),
            const SizedBox(height: 20),

            // Business Info in Card
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.business),
                    title: Text(
                      business["title"]!,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.location_on),
                    title: Text(business["location"]!),
                  ),
                  ListTile(
                    leading: const Icon(Icons.email),
                    title: Text(business["email"]!),
                  ),
                  ListTile(
                    leading: const Icon(Icons.phone),
                    title: Text(business["phone"]!),
                  ),
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: Text(business["description"]!),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
