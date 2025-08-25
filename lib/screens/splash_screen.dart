import 'dart:async';
import 'package:cash_in_out/screens/login.dart';
import 'package:cash_in_out/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../services/user_session.dart';
import '../services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      // Wait for 2 seconds to show splash
      await Future.delayed(Duration(seconds: 2));

      if (!mounted) return;

      print('SplashScreen._checkAuthStatus called');

      // Check if user is logged in
      final isLoggedIn = await UserSession.isLoggedIn();
      print('SplashScreen._checkAuthStatus - isLoggedIn: $isLoggedIn');

      if (!mounted) return;

      if (isLoggedIn) {
        // Refresh cache to ensure it's properly updated
        await UserSession.refreshCache();

        if (!mounted) return;

        // Try to ensure token is valid
        final isValid = await AuthService.ensureValidToken();
        print(
          'SplashScreen._checkAuthStatus - Token validation result: $isValid',
        );

        if (!mounted) return;

        if (isValid) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomeScreen()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => LoginScreen()),
          );
        }
      } else {
        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
      }
    } catch (e) {
      print('Error in _checkAuthStatus: $e');
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              'assets/animations/wallet.json',
              height: MediaQuery.of(context).size.height * 0.5,
            ),
            // SizedBox(height: 10),
            Text(
              "Cash In-Out",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
            SizedBox(height: 10),
            Text(
              "Simplifying Textile Payments",
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
            SizedBox(height: 30),
            // CircularProgressIndicator(color: Colors.blueAccent),
          ],
        ),
      ),
    );
  }
}
