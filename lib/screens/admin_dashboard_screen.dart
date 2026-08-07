import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'admin_login_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final Color brandColor = const Color(0xFF0F4C5C);

  int _selectedTabIndex = 0;
  String _appBarTitle = 'Manage Orders';

  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  final _categoryController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isUploading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _categoryController.dispose();
    _imageUrlController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _selectMenu(int index, String title) {
    setState(() {
      _selectedTabIndex = index;
      _appBarTitle = title;
    });
    Navigator.pop(context);
  }

  // ==============================================================
  // USER MANAGEMENT LOGIC (EDIT & DELETE)
  // ==============================================================
  void _showEditUserDialog(String userId, Map<String, dynamic> userData) {
    final TextEditingController nameController = TextEditingController(text: userData['name'] ?? userData['fullName'] ?? '');
    bool isAdmin = userData['isAdmin'] == true;

    showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(
              builder: (context, setDialogState) {
                return AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  title: const Text('Edit User Profile', style: TextStyle(fontWeight: FontWeight.bold)),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: const Text('Admin Privileges', style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: const Text('Turn on to grant Admin Panel access', style: TextStyle(fontSize: 12)),
                        value: isAdmin,
                        activeColor: brandColor,
                        onChanged: (value) {
                          setDialogState(() => isAdmin = value);
                        },
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: brandColor),
                      onPressed: () async {
                        await FirebaseFirestore.instance.collection('users').doc(userId).update({
                          'name': nameController.text.trim(),
                          'fullName': nameController.text.trim(),
                          'isAdmin': isAdmin,
                        });
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User successfully updated!'), backgroundColor: Colors.green));
                        }
                      },
                      child: const Text('Save Changes', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                );
              }
          );
        }
    );
  }

  void _confirmDeleteUser(String userId, String userName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Remove User?', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to permanently delete $userName from the database? They will lose access to their profile.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await FirebaseFirestore.instance.collection('users').doc(userId).delete();
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User deleted.'), backgroundColor: Colors.red));
              }
            },
            child: const Text('Delete Permanently', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- ADD PRODUCT LOGIC ---
  Future<void> _addNewProduct() async {
    if (_titleController.text.trim().isEmpty || _priceController.text.trim().isEmpty || _imageUrlController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required fields!')));
      return;
    }
    setState(() => _isUploading = true);
    try {
      final double price = double.tryParse(_priceController.text.trim()) ?? 0.0;
      await FirebaseFirestore.instance.collection('products').add({
        'title': _titleController.text.trim(),
        'price': price,
        'category': _categoryController.text.trim().isNotEmpty ? _categoryController.text.trim() : 'General',
        'imageUrl': _imageUrlController.text.trim(),
        'description': _descriptionController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      _titleController.clear();
      _priceController.clear();
      _categoryController.clear();
      _imageUrlController.clear();
      _descriptionController.clear();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product added successfully!'), backgroundColor: Colors.green));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to add product: $e')));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  // --- UPDATE ORDER STATUS LOGIC ---
  Future<void> _updateOrderStatus(DocumentReference docRef, String newStatus) async {
    try {
      // Use the exact reference to update the document, no matter where it is hidden!
      await docRef.update({'status': newStatus});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Order updated to $newStatus'), backgroundColor: Colors.green)
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update status: $e'))
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              leading: Icon(Icons.shopping_bag, color: _selectedTabIndex == 0 ? brandColor : Colors.grey),
              title: Text('Orders', style: TextStyle(fontWeight: _selectedTabIndex == 0 ? FontWeight.bold : FontWeight.normal)),
              selected: _selectedTabIndex == 0,
              onTap: () => _selectMenu(0, 'Manage Orders'),
            ),
            ListTile(
              leading: Icon(Icons.add_box, color: _selectedTabIndex == 1 ? brandColor : Colors.grey),
              title: Text('Add Product', style: TextStyle(fontWeight: _selectedTabIndex == 1 ? FontWeight.bold : FontWeight.normal)),
              selected: _selectedTabIndex == 1,
              onTap: () => _selectMenu(1, 'Add New Product'),
            ),
            ListTile(
              leading: Icon(Icons.people, color: _selectedTabIndex == 2 ? brandColor : Colors.grey),
              title: Text('Users Directory', style: TextStyle(fontWeight: _selectedTabIndex == 2 ? FontWeight.bold : FontWeight.normal)),
              selected: _selectedTabIndex == 2,
              onTap: () => _selectMenu(2, 'Registered Users'),
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

  Widget _buildBody() {
    switch (_selectedTabIndex) {
      case 0:
        return _buildOrdersTab();
      case 1:
        return _buildAddProductTab();
      case 2:
        return _buildUsersTab();
      default:
        return _buildOrdersTab();
    }
  }

  Widget _buildOrdersTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collectionGroup('orders').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator(color: brandColor));
        if (snapshot.hasError) return Center(child: Text("Error loading orders: ${snapshot.error}"));
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return const Center(child: Text("No customer orders found."));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final String orderId = docs[index].id;

            // 1. WE MUST GRAB THE ACTUAL DOCUMENT REFERENCE FROM FIREBASE
            final DocumentReference docRef = docs[index].reference;

            // 2. We handle legacy statuses like "Order Confirmed" so the dropdown doesn't break
            String rawStatus = data['status'] ?? 'Placed';
            if (rawStatus == 'Order Confirmed') rawStatus = 'Processing';

            final String status = ['Placed', 'Processing', 'Shipped', 'Out for Delivery', 'Delivered'].contains(rawStatus)
                ? rawStatus
                : 'Placed';

            final double total = (data['totalAmount'] ?? 0.0).toDouble();

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              child: ExpansionTile(
                title: Text('Order #$orderId', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: Text('Total: ₹${total.toStringAsFixed(2)} | Status: $status'),
                trailing: DropdownButton<String>(
                  value: status,
                  onChanged: (newStatus) {
                    // 3. PASS THE 'docRef' INSTEAD OF THE 'orderId'
                    if (newStatus != null) _updateOrderStatus(docRef, newStatus);
                  },
                  items: const [
                    DropdownMenuItem(value: 'Placed', child: Text('Placed')),
                    DropdownMenuItem(value: 'Processing', child: Text('Processing')),
                    DropdownMenuItem(value: 'Shipped', child: Text('Shipped')),
                    DropdownMenuItem(value: 'Out for Delivery', child: Text('Out for Delivery')),
                    DropdownMenuItem(value: 'Delivered', child: Text('Delivered')),
                  ],
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Customer UID: ${data['userId'] ?? 'Guest'}'),
                        const SizedBox(height: 8),
                        Text('Address: ${data['shippingAddress'] ?? 'N/A'}'),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAddProductTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Add New Catalog Item', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'Product Title', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: _priceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Price (₹)', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: _categoryController, decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: _imageUrlController, decoration: const InputDecoration(labelText: 'Image URL', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: _descriptionController, maxLines: 3, decoration: const InputDecoration(labelText: 'Product Description', border: OutlineInputBorder())),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity, height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: brandColor),
              onPressed: _isUploading ? null : _addNewProduct,
              child: _isUploading ? const CircularProgressIndicator(color: Colors.white) : const Text('Upload Product', style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  // ==============================================================
  // TAB 3: REGISTERED USERS DIRECTORY (WITH EDIT/DELETE)
  // ==============================================================
  Widget _buildUsersTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator(color: brandColor));
        if (snapshot.hasError) return Center(child: Text("Error loading users: ${snapshot.error}"));
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return const Center(child: Text("No users found in database."));

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final String userId = docs[index].id;
            final String name = data['name'] ?? data['fullName'] ?? 'Unknown User';
            final String email = data['email'] ?? 'No Email';
            final bool isAdmin = data['isAdmin'] == true;

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              elevation: 1,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isAdmin ? brandColor : Colors.grey.shade300,
                  child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: TextStyle(color: isAdmin ? Colors.white : Colors.black, fontWeight: FontWeight.bold)
                  ),
                ),
                title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(email),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Admin / Customer Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isAdmin ? Colors.green.shade100 : Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isAdmin ? 'Admin' : 'Customer',
                        style: TextStyle(
                            color: isAdmin ? Colors.green.shade800 : Colors.blue.shade800,
                            fontSize: 12, fontWeight: FontWeight.bold
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Action Menu
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.grey),
                      onSelected: (value) {
                        if (value == 'edit') {
                          _showEditUserDialog(userId, data);
                        } else if (value == 'delete') {
                          _confirmDeleteUser(userId, name);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(children: [Icon(Icons.edit, size: 20, color: Colors.blue), SizedBox(width: 12), Text('Edit Profile')]),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(children: [Icon(Icons.delete, size: 20, color: Colors.red), SizedBox(width: 12), Text('Remove User', style: TextStyle(color: Colors.red))]),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}