import 'package:flutter/material.dart';
import '../../services/firebase_service.dart';
import '../../services/crash_reporting_service.dart';
import '../../widgets/sokofiti_logo.dart';
import 'admin_dashboard_screen.dart';
import 'monthly_reports_screen.dart';

/// Desktop-optimized admin dashboard
class DesktopAdminDashboard extends StatefulWidget {
  const DesktopAdminDashboard({super.key});

  @override
  State<DesktopAdminDashboard> createState() => _DesktopAdminDashboardState();
}

class _DesktopAdminDashboardState extends State<DesktopAdminDashboard> {
  int _selectedIndex = 0;
  bool _isAuthenticated = false;
  bool _isLoading = true;
  final TextEditingController _passwordController = TextEditingController();

  final List<_AdminMenuItem> _menuItems = [
    _AdminMenuItem(
      icon: Icons.dashboard,
      title: 'Dashboard',
      screen: const AdminDashboardScreen(),
    ),
    _AdminMenuItem(
      icon: Icons.analytics,
      title: 'Monthly Reports',
      screen: const MonthlyReportsScreen(),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _checkAuthentication();

    // Track admin dashboard access
    FirebaseService.trackScreenView('desktop_admin_dashboard');
    CrashReportingService.addBreadcrumb('Desktop admin dashboard accessed');
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _checkAuthentication() async {
    setState(() => _isLoading = true);

    try {
      // Simple check - in a real app, this would check session/token
      setState(() {
        _isAuthenticated = false; // Always require login for security
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      CrashReportingService.addBreadcrumb(
        'Admin authentication check failed: $e',
      );
    }
  }

  Future<void> _authenticate() async {
    if (_passwordController.text.isEmpty) {
      _showError('Please enter admin password');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Simple password check - in production, use proper authentication
      final success = _passwordController.text == 'sokofiti_admin_2024';

      if (success) {
        setState(() {
          _isAuthenticated = true;
          _isLoading = false;
        });

        // Track successful admin login
        await FirebaseService.logEvent('admin_login_success', {
          'platform': 'desktop',
        });

        CrashReportingService.addBreadcrumb('Admin authentication successful');
      } else {
        setState(() => _isLoading = false);
        _showError('Invalid admin password');

        // Track failed admin login
        await FirebaseService.logEvent('admin_login_failed', {
          'platform': 'desktop',
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Authentication failed: $e');

      await CrashReportingService.logError(
        e,
        StackTrace.current,
        reason: 'Admin authentication failed',
      );
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _logout() async {
    try {
      setState(() => _isAuthenticated = false);
      _passwordController.clear();

      // Track admin logout
      await FirebaseService.logEvent('admin_logout', {'platform': 'desktop'});

      CrashReportingService.addBreadcrumb('Admin logged out');
    } catch (e) {
      _showError('Logout failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!_isAuthenticated) {
      return _buildLoginScreen();
    }

    return _buildDashboard();
  }

  Widget _buildLoginScreen() {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SokofitiLogo(
                size: 80,
                backgroundColor: Colors.green,
                borderRadius: 20,
                useWhiteLogo: true,
              ),
              const SizedBox(height: 24),
              const Text(
                'Sokofiti Admin',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Desktop Dashboard',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Admin Password',
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => _authenticate(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _authenticate,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text('Login', style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Access restricted to authorized administrators only',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboard() {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 280,
            color: Colors.green.shade700,
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(24),
                  child: const Column(
                    children: [
                      SokofitiLogo(
                        size: 60,
                        backgroundColor: Colors.white,
                        borderRadius: 15,
                        showShadow: false,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Admin Dashboard',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // Menu items
                Expanded(
                  child: ListView.builder(
                    itemCount: _menuItems.length,
                    itemBuilder: (context, index) {
                      final item = _menuItems[index];
                      final isSelected = _selectedIndex == index;

                      return Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 2,
                        ),
                        child: ListTile(
                          leading: Icon(
                            item.icon,
                            color: isSelected
                                ? Colors.green.shade700
                                : Colors.white70,
                          ),
                          title: Text(
                            item.title,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.green.shade700
                                  : Colors.white,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          selected: isSelected,
                          selectedTileColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          onTap: () {
                            setState(() => _selectedIndex = index);

                            // Track navigation
                            FirebaseService.logEvent('admin_navigation', {
                              'screen': item.title.toLowerCase().replaceAll(
                                ' ',
                                '_',
                              ),
                            });
                          },
                        ),
                      );
                    },
                  ),
                ),

                // Logout button
                Container(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout, color: Colors.white),
                      label: const Text(
                        'Logout',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Main content
          Expanded(child: _menuItems[_selectedIndex].screen),
        ],
      ),
    );
  }
}

class _AdminMenuItem {
  final IconData icon;
  final String title;
  final Widget screen;

  _AdminMenuItem({
    required this.icon,
    required this.title,
    required this.screen,
  });
}
