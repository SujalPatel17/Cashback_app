import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/add_transaction_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/pending_check_screen.dart';
import 'screens/transaction_history_screen.dart';
import 'notifications/notification_service.dart';
import 'package:timezone/data/latest.dart' as tz;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize timezone and notifications
  tz.initializeTimeZones();
  await NotificationService().init();

  runApp(const CashbackTrackerApp());
}

class CashbackTrackerApp extends StatefulWidget {
  const CashbackTrackerApp({super.key});

  @override
  _CashbackTrackerAppState createState() => _CashbackTrackerAppState();
}

class _CashbackTrackerAppState extends State<CashbackTrackerApp> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const AnalyticsScreen(),
    const PendingCheckScreen(),
    const TransactionHistoryScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cashback Tracker',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.teal),
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/':
            (context) => Scaffold(
              appBar: AppBar(
                title: Text(
                  _selectedIndex == 0
                      ? 'Home'
                      : _selectedIndex == 1
                      ? 'Analytics'
                      : _selectedIndex == 2
                      ? 'Pending Checks'
                      : 'Transactions',
                ),
              ),
              body: _screens[_selectedIndex],
              bottomNavigationBar: BottomNavigationBar(
                currentIndex: _selectedIndex,
                onTap: _onItemTapped,
                backgroundColor: Colors.black, // 🔲 Black background
                selectedItemColor: Colors.blue, // 🔵 Blue when selected
                unselectedItemColor: Colors.white, // ⚪ White icons
                type: BottomNavigationBarType.fixed,
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.home),
                    label: 'Home',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.analytics),
                    label: 'Analytics',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.check_circle_outline),
                    label: 'Pending Checks',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.history),
                    label: 'Transactions',
                  ),
                ],
              ),
            ),
        '/add': (context) => const AddTransactionScreen(),
      },
    );
  }
}
