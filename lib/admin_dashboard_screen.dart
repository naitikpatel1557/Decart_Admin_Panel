import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'admin_login_screen.dart';

// Import the separated tabs
import 'admin_tabs/dashboard_tab.dart';
import 'admin_tabs/orders_management_tab.dart';
import 'admin_tabs/all_products_tab.dart'; // NEW IMPORT
import 'admin_tabs/add_product_tab.dart';
import 'admin_tabs/users_directory_tab.dart';
import 'admin_tabs/feedback_support_tab.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final Color brandColor = const Color(0xFF0F4C5C);

  int _selectedTabIndex = 0;
  String _appBarTitle = 'Dashboard';

  void _selectMenu(int index, String title) {
    setState(() {
      _selectedTabIndex = index;
      _appBarTitle = title;
    });
    Navigator.pop(context); // Close drawer
  }

  Widget _buildBody() {
    switch (_selectedTabIndex) {
      case 0: return const DashboardTab();
      case 1: return const OrdersManagementTab();
      case 2: return const AllProductsTab(); // All Products Catalog View
      case 3: return const AddProductTab();
      case 4: return const UsersDirectoryTab();
      case 5: return const FeedbackSupportTab();
      default: return const DashboardTab();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      appBar: AppBar(
        title: Text(_appBarTitle),
        backgroundColor: brandColor,
        foregroundColor: Colors.white,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: brandColor),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Icon(Icons.admin_panel_settings, size: 48, color: Colors.white),
                  const SizedBox(height: 12),
                  const Text('Decart Admin', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  Text(FirebaseAuth.instance.currentUser?.email ?? 'Admin', style: const TextStyle(color: Colors.white70, fontSize: 14)),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.dashboard, color: _selectedTabIndex == 0 ? brandColor : Colors.grey),
              title: Text('Dashboard', style: TextStyle(fontWeight: _selectedTabIndex == 0 ? FontWeight.bold : FontWeight.normal)),
              selected: _selectedTabIndex == 0,
              onTap: () => _selectMenu(0, 'Dashboard'),
            ),
            ListTile(
              leading: Icon(Icons.shopping_bag, color: _selectedTabIndex == 1 ? brandColor : Colors.grey),
              title: Text('Orders', style: TextStyle(fontWeight: _selectedTabIndex == 1 ? FontWeight.bold : FontWeight.normal)),
              selected: _selectedTabIndex == 1,
              onTap: () => _selectMenu(1, 'Manage Orders'),
            ),
            // NEW LIST TILE: ALL PRODUCTS
            ListTile(
              leading: Icon(Icons.inventory_2_outlined, color: _selectedTabIndex == 2 ? brandColor : Colors.grey),
              title: Text('All Products', style: TextStyle(fontWeight: _selectedTabIndex == 2 ? FontWeight.bold : FontWeight.normal)),
              selected: _selectedTabIndex == 2,
              onTap: () => _selectMenu(2, 'All Products'),
            ),
            ListTile(
              leading: Icon(Icons.add_box, color: _selectedTabIndex == 3 ? brandColor : Colors.grey),
              title: Text('Add Product', style: TextStyle(fontWeight: _selectedTabIndex == 3 ? FontWeight.bold : FontWeight.normal)),
              selected: _selectedTabIndex == 3,
              onTap: () => _selectMenu(3, 'Add New Product'),
            ),
            ListTile(
              leading: Icon(Icons.people, color: _selectedTabIndex == 4 ? brandColor : Colors.grey),
              title: Text('Users Directory', style: TextStyle(fontWeight: _selectedTabIndex == 4 ? FontWeight.bold : FontWeight.normal)),
              selected: _selectedTabIndex == 4,
              onTap: () => _selectMenu(4, 'Registered Users'),
            ),
            ListTile(
              leading: Icon(Icons.forum, color: _selectedTabIndex == 5 ? brandColor : Colors.grey),
              title: Text('Feedback & Support', style: TextStyle(fontWeight: _selectedTabIndex == 5 ? FontWeight.bold : FontWeight.normal)),
              selected: _selectedTabIndex == 5,
              onTap: () => _selectMenu(5, 'Feedback & Support'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AdminLoginScreen()));
                }
              },
            ),
          ],
        ),
      ),
      body: _buildBody(),
    );
  }
}