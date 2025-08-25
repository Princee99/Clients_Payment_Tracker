import 'package:cash_in_out/services/auth_manager.dart';
import 'package:cash_in_out/services/base_service.dart';
import 'package:flutter/material.dart';
import 'client_list_page.dart';
import 'payments_list_screen.dart';
import 'installments_list_screen.dart';
import 'reports_screen.dart';
import 'login.dart';
import '../config.dart';
import '../services/user_session.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String username = '';
  int? userId;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();

    // IMPORTANT: Delay token validation to prevent immediate logout
    Future.delayed(Duration(seconds: 1), () {
      if (mounted) {
        _loadUserInfo();
      }
    });
  }

  Future<void> _loadUserInfo() async {
    try {
      print('HomeScreen._loadUserInfo called');

      // Debug: Print all stored values
      await UserSession.debugPrintAllValues();

      // Refresh cache from SharedPreferences
      await UserSession.refreshCache();

      final userInfo = await UserSession.getUserInfo();
      print('HomeScreen._loadUserInfo - userInfo: $userInfo');

      // Print memory cache status
      UserSession.printMemoryCacheStatus();

      // CRITICAL FIX: Don't validate token here, just use the data
      if (userInfo != null) {
        setState(() {
          username = userInfo['username'] ?? '';
          userId = userInfo['user_id'];
          isLoading = false;
        });
        print(
          'HomeScreen._loadUserInfo - Set username: $username, userId: $userId',
        );
      } else {
        print('HomeScreen._loadUserInfo - No user info available');
      }
    } catch (e) {
      print('Error in _loadUserInfo: $e');
      // IMPORTANT: Don't navigate to login here on error
    }
  }

  Future<void> _logout() async {
    await UserSession.clearSession();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cash In-Out'),
        backgroundColor: Colors.teal[700],
        elevation: 0,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 26,
          fontWeight: FontWeight.bold,
        ),
        actions: [
          if (username.isNotEmpty)
            PopupMenuButton<String>(
              icon: const Icon(Icons.account_circle, color: Colors.white),
              onSelected: (value) {
                if (value == 'logout') {
                  _logout();
                }
              },
              itemBuilder:
                  (context) => [
                    PopupMenuItem(
                      value: 'profile',
                      child: Row(
                        children: [
                          const Icon(Icons.person),
                          const SizedBox(width: 8),
                          Text('Logged in as $username'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'logout',
                      child: Row(
                        children: [
                          Icon(Icons.logout),
                          SizedBox(width: 8),
                          Text('Logout'),
                        ],
                      ),
                    ),
                  ],
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.teal[700]!, Colors.teal[100]!],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Welcome Section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.account_balance_wallet,
                      size: 60,
                      color: Colors.teal[700],
                    ),
                    const SizedBox(height: 15),
                    Text(
                      'Welcome to Cash In-Out',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal[700],
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (username.isNotEmpty)
                      Text(
                        'Hello, $username!',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.teal[600],
                        ),
                      ),
                    const SizedBox(height: 10),
                    Text(
                      'Manage your financial transactions efficiently',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              // Menu Grid
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                  children: [
                    _buildMenuCard(
                      context,
                      'Clients',
                      Icons.people,
                      Colors.blue,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ClientListPage()),
                      ),
                    ),
                    _buildMenuCard(
                      context,
                      'Payments',
                      Icons.payment,
                      Colors.green,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PaymentsListPage(),
                        ),
                      ),
                    ),
                    _buildMenuCard(
                      context,
                      'Installments',
                      Icons.schedule,
                      Colors.orange,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const InstallmentsListScreen(),
                        ),
                      ),
                    ),
                    _buildMenuCard(
                      context,
                      'Reports',
                      Icons.analytics,
                      Colors.purple,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ReportsScreen()),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: color),
            ),
            const SizedBox(height: 15),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
