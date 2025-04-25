import 'package:flutter/material.dart';
import '../auth/firebase_auth.dart';

class DashboardPage extends StatelessWidget {
  final FirebaseAuthService auth;
  
  const DashboardPage({super.key, required this.auth});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await auth.signOut();
            },
          ),
        ],
      ),
      body: const Center(
        child: Text('Welcome to your Dashboard!'),
      ),
    );
  }
}
