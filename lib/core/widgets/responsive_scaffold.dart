// lib/core/widgets/responsive_scaffold.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../features/auth/controllers/auth_state.dart';

class ResponsiveScaffold extends StatefulWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;

  const ResponsiveScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
  });

  @override
  State<ResponsiveScaffold> createState() => _ResponsiveScaffoldState();
}

class _ResponsiveScaffoldState extends State<ResponsiveScaffold> {
  bool _isSidebarExpanded = true; // State for desktop sidebar toggle

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isDesktop = screenSize.width >= 900;

    return Scaffold(
      // --- HEADER (Top App Bar) ---
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: isDesktop
            ? IconButton(
                icon: Icon(
                  _isSidebarExpanded
                      ? Icons.menu_open_rounded
                      : Icons.menu_rounded,
                ),
                tooltip: 'Toggle Sidebar',
                onPressed: () {
                  setState(() {
                    _isSidebarExpanded = !_isSidebarExpanded;
                  });
                },
              )
            : null, // Mobile uses standard hamburger drawer button
        actions: [
          ...?widget.actions,
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Logout',
            onPressed: () => _handleLogout(context),
          ),
        ],
      ),

      // --- SIDEBAR (Drawer for Mobile, Permanent Panel for Desktop) ---
      drawer: isDesktop ? null : _buildNavigationDrawer(context),

      // --- BODY & FOOTER CONTAINER ---
      body: Row(
        children: [
          // Desktop Collapsible Sidebar Navigation
          if (isDesktop && _isSidebarExpanded)
            Container(
              width: 260,
              color: const Color(0xFF1B5E20),
              child: _buildNavigationContent(context),
            ),

          // Main Content & Footer Area
          Expanded(
            child: Column(
              children: [
                // Main Scrollable Body
                Expanded(
                  child: Container(
                    color: const Color(0xFFF5F8F5),
                    child: widget.body,
                  ),
                ),

                // --- FOOTER ---
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  color: Colors.white,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '© 2026 Smart Nutrition & Health. All rights reserved.',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      Row(
                        children: [
                          TextButton(
                            onPressed: () {},
                            child: const Text(
                              'Privacy Policy',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                          ),
                          const Text('•', style: TextStyle(color: Colors.grey)),
                          TextButton(
                            onPressed: () {},
                            child: const Text(
                              'Terms of Service',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Shared Navigation Links Content
  Widget _buildNavigationContent(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        const DrawerHeader(
          decoration: BoxDecoration(color: Color(0xFF1B5E20)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'Smart Nutrition & Health',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Clinical & Metabolic AI Suite',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
        ListTile(
          leading: const Icon(Icons.home_outlined, color: Colors.white),
          title: const Text(
            'Home Dashboard',
            style: TextStyle(color: Colors.white),
          ),
          onTap: () => Navigator.pushReplacementNamed(context, '/home'),
        ),
        ListTile(
          leading: const Icon(
            Icons.restaurant_menu_rounded,
            color: Colors.white,
          ),
          title: const Text(
            'Meal Logger & GL',
            style: TextStyle(color: Colors.white),
          ),
          onTap: () => Navigator.pushNamed(context, '/meal-logging'),
        ),
        ListTile(
          leading: const Icon(Icons.menu_book_rounded, color: Colors.white),
          title: const Text(
            'Resource Hub',
            style: TextStyle(color: Colors.white),
          ),
          onTap: () => Navigator.pushNamed(context, '/resources'),
        ),
        ListTile(
          leading: const Icon(Icons.auto_awesome_rounded, color: Colors.white),
          title: const Text(
            'AI Meal Planner',
            style: TextStyle(color: Colors.white),
          ),
          onTap: () => Navigator.pushNamed(context, '/meal-plan'),
        ),
        ListTile(
          leading: const Icon(
            Icons.workspace_premium_rounded,
            color: Colors.orangeAccent,
          ),
          title: const Text(
            'Upgrade Premium',
            style: TextStyle(color: Colors.orangeAccent),
          ),
          onTap: () => Navigator.pushNamed(context, '/paywall'),
        ),
      ],
    );
  }

  Widget _buildNavigationDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF1B5E20),
      child: _buildNavigationContent(context),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final authState = Provider.of<AuthState>(context, listen: false);
    await authState.logout();

    if (!context.mounted) return;

    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
  }
}
