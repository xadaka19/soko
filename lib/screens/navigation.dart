import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'plan_selection_screen.dart';
import 'messages_screen.dart';
import 'profile_screen.dart';
import '../utils/session_manager.dart';
import '../widgets/login_modal.dart';

class NavigationScreen extends StatefulWidget {
  const NavigationScreen({super.key});

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const PlanSelectionScreen(),
    const MessagesScreen(),
    const ProfileScreen(),
  ];

  Future<void> _onTabTapped(int index) async {
    // Home tab (index 0) is always accessible
    if (index == 0) {
      setState(() => _currentIndex = index);
      return;
    }

    // Check authentication for protected tabs (Sell, Messages, Profile)
    final isLoggedIn = await SessionManager.isLoggedIn();

    if (isLoggedIn) {
      setState(() => _currentIndex = index);
    } else {
      // Show login modal for unauthenticated users
      _showLoginModal();
    }
  }

  void _showLoginModal() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => LoginModal(
        onLoginSuccess: () {
          // After successful login, stay on current tab or navigate to the intended tab
          setState(() {});
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        selectedItemColor: const Color(0xFF5BE206),
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_box_outlined),
            activeIcon: Icon(Icons.add_box),
            label: 'Sell',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message_outlined),
            activeIcon: Icon(Icons.message),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outlined),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
