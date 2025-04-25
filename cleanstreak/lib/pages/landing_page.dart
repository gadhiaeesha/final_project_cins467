import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth/firebase_auth.dart';
import 'dashboard_page.dart';
import 'login_page.dart';

class LandingPage extends StatelessWidget {
  final FirebaseAuthService _auth = FirebaseAuthService();

  LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _auth.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasData) {
          return DashboardPage(auth: _auth);
        }

        return LoginPage(auth: _auth);
      },
    );
  }
}
