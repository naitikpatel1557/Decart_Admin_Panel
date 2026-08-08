import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'admin_login_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final Color brandColor = const Color(0xFF0F4C5C);
  final Color brandBlue = const Color(0xFF1F3BB3);

  int _selectedTabIndex = 0;
  String _appBarTitle = 'Dashboard';

  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  final _categoryController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isUploading = false;

  // --- NEW VARIABLES FOR DYNAMIC CHART FILTERS ---
  String _chartViewMode = 'Weekly'; // 'Weekly', 'Monthly', 'Annual'
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  final List<String> _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

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
  // USER MANAGEMENT LOGIC
  // ==============================================================
  void _showEditUserDialog(String userId, Map<String, dynamic> userData) {
    final TextEditingController nameController = TextEditingController(text: userData['name'] ?? userData['fullName'] ?? '');
    bool isAdmin = userData['isAdmin'] == true;
    bool hasVipCoupon = userData['hasVipCoupon'] == true;
    bool grantCoupon = hasVipCoupon;

    Future<List<String>> _fetchUserAddresses() async {
      List<String> foundAddresses = [];
      try {
        final addressSnap = await FirebaseFirestore.instance.collection('users').doc(userId).collection('addresses').get();
        if (addressSnap.docs.isNotEmpty) {
          for (var doc in addressSnap.docs) {
            final data = doc.data();
            String addr = data['fullAddress'] ?? data['address'] ?? '';
            if (addr.isEmpty) {
              List<String> parts = [];
              for (String key in ['flat', 'houseNo', 'street', 'area', 'city', 'state', 'pincode']) {
                if (data[key] != null && data[key].toString().trim().isNotEmpty) parts.add(data[key].toString().trim());
              }
              addr = parts.join(', ');
            }
            if (addr.isNotEmpty) foundAddresses.add(addr);
          }
          return foundAddresses;
        }

        if (userData['addresses'] != null && userData['addresses'] is List) {
          for (var item in userData['addresses']) {
            if (item is Map) {
              String addr = item['fullAddress'] ?? item['address'] ?? item.values.join(', ');
              foundAddresses.add(addr);
            } else if (item is String) {
              foundAddresses.add(item);
            }
          }
          return foundAddresses;
        }

        if (userData['address'] != null && userData['address'].toString().trim().isNotEmpty) {
          foundAddresses.add(userData['address'].toString());
        } else if (userData['shippingAddress'] != null) {
          final addrMap = userData['shippingAddress'] as Map<String, dynamic>;
          foundAddresses.add(addrMap['fullAddress'] ?? addrMap['city'] ?? '');
        }
      } catch (e) {}
      return foundAddresses.where((a) => a.isNotEmpty).toList();
    }

    Future<int> _getUserReviewCount() async {
      try {
        final query = await FirebaseFirestore.instance.collectionGroup('reviews').where('userId', isEqualTo: userId).get();
        return query.docs.length;
      } catch (e) {
        return 0;
      }
    }

    showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(
              builder: (context, setDialogState) {
                return AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  title: const Text('Edit User Profile', style: TextStyle(fontWeight: FontWeight.bold)),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder())),
                        const SizedBox(height: 16),
                        const Text('Saved Addresses:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                        const SizedBox(height: 6),
                        FutureBuilder<List<String>>(
                            future: _fetchUserAddresses(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) return const Text('Loading addresses...', style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic));
                              final addresses = snapshot.data ?? [];
                              if (addresses.isEmpty) return const Text('No address on file.', style: TextStyle(fontSize: 14));
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: addresses.map((addr) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.location_on, size: 16, color: Colors.teal),
                                      const SizedBox(width: 6),
                                      Expanded(child: Text(addr, style: const TextStyle(fontSize: 13, height: 1.3))),
                                    ],
                                  ),
                                )).toList(),
                              );
                            }
                        ),
                        const Divider(height: 24),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Admin Privileges', style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: const Text('Turn on to grant Admin Panel access', style: TextStyle(fontSize: 12)),
                          value: isAdmin,
                          activeColor: brandColor,
                          onChanged: (value) => setDialogState(() => isAdmin = value),
                        ),
                        const Divider(height: 24),
                        FutureBuilder<int>(
                            future: _getUserReviewCount(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()));
                              int reviewCount = snapshot.data ?? 0;
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                    const Icon(Icons.star, color: Colors.amber, size: 20),
                                    const SizedBox(width: 8),
                                    Text('Product Reviews Given: $reviewCount', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  ]),
                                  if (reviewCount >= 10) ...[
                                    const SizedBox(height: 16),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(color: Colors.amber.shade50, border: Border.all(color: Colors.amber), borderRadius: BorderRadius.circular(8)),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('⭐ Top Reviewer Reward', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                                          const SizedBox(height: 4),
                                          const Text('This user has left 10+ reviews. Reward them with a 15% VIP discount coupon!', style: TextStyle(fontSize: 12)),
                                          const SizedBox(height: 8),
                                          SwitchListTile(
                                            contentPadding: EdgeInsets.zero,
                                            title: const Text('Grant 15% VIP Coupon', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                            value: grantCoupon,
                                            activeColor: Colors.orange,
                                            onChanged: (val) => setDialogState(() => grantCoupon = val),
                                          )
                                        ],
                                      ),
                                    )
                                  ] else ...[
                                    const SizedBox(height: 8),
                                    Text('User needs ${10 - reviewCount} more reviews to unlock the VIP reward.', style: const TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic)),
                                  ]
                                ],
                              );
                            }
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: brandColor),
                      onPressed: () async {
                        await FirebaseFirestore.instance.collection('users').doc(userId).update({
                          'name': nameController.text.trim(),
                          'fullName': nameController.text.trim(),
                          'isAdmin': isAdmin,
                          'hasVipCoupon': grantCoupon,
                          'vipCouponCode': grantCoupon ? 'VIP15DECART' : null,
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
        content: Text('Are you sure you want to permanently delete $userName from the database?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
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

  Future<void> _updateOrderStatus(DocumentReference docRef, String newStatus) async {
    try {
      await docRef.update({'status': newStatus});
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Order updated to $newStatus'), backgroundColor: Colors.green));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update status: $e')));
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
            ListTile(
              leading: Icon(Icons.add_box, color: _selectedTabIndex == 2 ? brandColor : Colors.grey),
              title: Text('Add Product', style: TextStyle(fontWeight: _selectedTabIndex == 2 ? FontWeight.bold : FontWeight.normal)),
              selected: _selectedTabIndex == 2,
              onTap: () => _selectMenu(2, 'Add New Product'),
            ),
            ListTile(
              leading: Icon(Icons.people, color: _selectedTabIndex == 3 ? brandColor : Colors.grey),
              title: Text('Users Directory', style: TextStyle(fontWeight: _selectedTabIndex == 3 ? FontWeight.bold : FontWeight.normal)),
              selected: _selectedTabIndex == 3,
              onTap: () => _selectMenu(3, 'Registered Users'),
            ),
            ListTile(
              leading: Icon(Icons.forum, color: _selectedTabIndex == 4 ? brandColor : Colors.grey),
              title: Text('Feedback & Support', style: TextStyle(fontWeight: _selectedTabIndex == 4 ? FontWeight.bold : FontWeight.normal)),
              selected: _selectedTabIndex == 4,
              onTap: () => _selectMenu(4, 'Feedback & Support'),
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
      case 0: return _buildMainDashboardTab();
      case 1: return _buildOrdersTab();
      case 2: return _buildAddProductTab();
      case 3: return _buildUsersTab();
      case 4: return _buildFeedbackAndSupportTab();
      default: return _buildMainDashboardTab();
    }
  }

  // ==============================================================
  // TAB 0: MAIN DASHBOARD WITH DYNAMIC CHART FILTERS
  // ==============================================================
  Widget _buildMainDashboardTab() {
    final user = FirebaseAuth.instance.currentUser;
    final String emailName = user?.email?.split('@')[0] ?? 'Admin';

    return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collectionGroup('orders').snapshots(),
        builder: (context, orderSnapshot) {
          if (orderSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final orderDocs = orderSnapshot.data?.docs ?? [];

          double totalRevenue = 0;
          int deliveredCount = 0;
          int activeCount = 0;

          // --- DYNAMIC CHART DATA INITIALIZATION ---
          Map<int, double> ordersChartData = {};
          double maxOrdersCount = 5;
          double chartMinX = 0;
          double chartMaxX = 6;

          if (_chartViewMode == 'Weekly') {
            for (int i = 0; i <= 6; i++) ordersChartData[i] = 0;
            chartMinX = 0; chartMaxX = 6;
          } else if (_chartViewMode == 'Monthly') {
            int daysInMonth = DateTime(_selectedYear, _selectedMonth + 1, 0).day;
            for (int i = 1; i <= daysInMonth; i++) ordersChartData[i] = 0;
            chartMinX = 1; chartMaxX = daysInMonth.toDouble();
          } else if (_chartViewMode == 'Annual') {
            for (int i = 1; i <= 12; i++) ordersChartData[i] = 0;
            chartMinX = 1; chartMaxX = 12;
          }

          for (var doc in orderDocs) {
            final data = doc.data() as Map<String, dynamic>;
            final double amount = (data['totalAmount'] ?? 0.0).toDouble();
            final String status = (data['status'] ?? '').toString().toLowerCase();
            final Timestamp? dateStamp = data['orderDate'] ?? data['createdAt'];

            if (status != 'cancelled') totalRevenue += amount;
            if (status == 'delivered') {
              deliveredCount++;
            } else if (status != 'cancelled') {
              activeCount++;
            }

            // --- MAP ORDERS TO SELECTED CHART VIEW ---
            if (dateStamp != null) {
              DateTime dt = dateStamp.toDate();

              if (_chartViewMode == 'Weekly') {
                if (DateTime.now().difference(dt).inDays <= 7) {
                  int dayIndex = dt.weekday == 7 ? 0 : dt.weekday;
                  ordersChartData[dayIndex] = (ordersChartData[dayIndex] ?? 0) + 1;
                  if (ordersChartData[dayIndex]! > maxOrdersCount) maxOrdersCount = ordersChartData[dayIndex]!;
                }
              } else if (_chartViewMode == 'Monthly') {
                if (dt.year == _selectedYear && dt.month == _selectedMonth) {
                  ordersChartData[dt.day] = (ordersChartData[dt.day] ?? 0) + 1;
                  if (ordersChartData[dt.day]! > maxOrdersCount) maxOrdersCount = ordersChartData[dt.day]!;
                }
              } else if (_chartViewMode == 'Annual') {
                if (dt.year == _selectedYear) {
                  ordersChartData[dt.month] = (ordersChartData[dt.month] ?? 0) + 1;
                  if (ordersChartData[dt.month]! > maxOrdersCount) maxOrdersCount = ordersChartData[dt.month]!;
                }
              }
            }
          }

          List<FlSpot> chartSpots = [];
          ordersChartData.forEach((key, value) {
            chartSpots.add(FlSpot(key.toDouble(), value));
          });
          chartSpots.sort((a, b) => a.x.compareTo(b.x)); // Ensure lines connect left to right

          double fulfillmentRate = orderDocs.isEmpty ? 0 : (deliveredCount / orderDocs.length) * 100;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Good Morning, $emailName', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text('Your live performance summary', style: TextStyle(color: Colors.grey, fontSize: 14)),
                const SizedBox(height: 24),

                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildStatCard('Total Revenue', '₹${totalRevenue.toStringAsFixed(0)}', 'Active', true),
                      _buildStatCard('Total Orders', '${orderDocs.length}', 'Lifetime', true),
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance.collection('users').snapshots(),
                        builder: (c, snap) => _buildStatCard('Total Users', '${snap.data?.docs.length ?? 0}', 'Registered', true),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // --- DYNAMIC PERFORMANCE LINE CHART WITH DROPDOWN FILTERS ---
                Container(
                  height: 400, // Slightly taller to accommodate dropdowns
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Dynamic Header & Filters
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Orders Chart', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text('Total orders: $_chartViewMode', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              // Main Mode Dropdown
                              Container(
                                height: 30,
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(6)),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _chartViewMode,
                                    isDense: true,
                                    style: const TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.bold),
                                    items: ['Weekly', 'Monthly', 'Annual'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                                    onChanged: (val) => setState(() => _chartViewMode = val!),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Secondary Dynamic Dropdowns
                              if (_chartViewMode == 'Monthly')
                                Row(
                                  children: [
                                    Container(
                                      height: 30,
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(6)),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<int>(
                                          value: _selectedMonth,
                                          isDense: true,
                                          style: const TextStyle(fontSize: 12, color: Colors.black87),
                                          items: List.generate(12, (index) => DropdownMenuItem(value: index + 1, child: Text(_months[index]))),
                                          onChanged: (val) => setState(() => _selectedMonth = val!),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      height: 30,
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(6)),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<int>(
                                          value: _selectedYear,
                                          isDense: true,
                                          style: const TextStyle(fontSize: 12, color: Colors.black87),
                                          items: List.generate(5, (index) => DropdownMenuItem(value: DateTime.now().year - index, child: Text('${DateTime.now().year - index}'))),
                                          onChanged: (val) => setState(() => _selectedYear = val!),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              if (_chartViewMode == 'Annual')
                                Container(
                                  height: 30,
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(6)),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<int>(
                                      value: _selectedYear,
                                      isDense: true,
                                      style: const TextStyle(fontSize: 12, color: Colors.black87),
                                      items: List.generate(5, (index) => DropdownMenuItem(value: DateTime.now().year - index, child: Text('${DateTime.now().year - index}'))),
                                      onChanged: (val) => setState(() => _selectedYear = val!),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // The Actual Chart Widget
                      Expanded(
                        child: LineChart(
                          LineChartData(
                            minY: 0,
                            maxY: maxOrdersCount + 2,
                            minX: chartMinX,
                            maxX: chartMaxX,
                            gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade200, strokeWidth: 1)),
                            titlesData: FlTitlesData(
                              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30)),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  interval: _chartViewMode == 'Monthly' ? 5 : 1, // Skip labels on monthly to prevent crowding
                                  getTitlesWidget: (value, meta) {
                                    int intVal = value.toInt();

                                    if (_chartViewMode == 'Weekly') {
                                      const days = ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];
                                      if (intVal >= 0 && intVal < days.length) return Padding(padding: const EdgeInsets.only(top: 8.0), child: Text(days[intVal], style: const TextStyle(color: Colors.grey, fontSize: 10)));
                                    }
                                    else if (_chartViewMode == 'Monthly') {
                                      if (intVal == 1 || intVal % 5 == 0) return Padding(padding: const EdgeInsets.only(top: 8.0), child: Text('$intVal', style: const TextStyle(color: Colors.grey, fontSize: 10)));
                                    }
                                    else if (_chartViewMode == 'Annual') {
                                      if (intVal >= 1 && intVal <= 12) return Padding(padding: const EdgeInsets.only(top: 8.0), child: Text(_months[intVal - 1], style: const TextStyle(color: Colors.grey, fontSize: 10)));
                                    }
                                    return const Text('');
                                  },
                                ),
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            lineBarsData: [
                              LineChartBarData(
                                spots: chartSpots,
                                isCurved: true, color: brandBlue, barWidth: 3, dotData: FlDotData(show: true),
                                belowBarData: BarAreaData(show: true, color: brandBlue.withOpacity(0.1)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: const Color(0xFF0C82EE), borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Order Fulfillment', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 24),
                      const Text('Active / Processing Orders', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      Text('$activeCount', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      const Divider(color: Colors.white24, thickness: 2),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _circularStat('Fulfillment Rate', '${fulfillmentRate.toStringAsFixed(1)}%', fulfillmentRate / 100),
                      _circularStat('Total Delivered', '$deliveredCount', deliveredCount / (orderDocs.isEmpty ? 1 : orderDocs.length)),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        }
    );
  }

  Widget _buildStatCard(String title, String value, String subtext, bool isPositive) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(isPositive ? Icons.check_circle : Icons.warning, color: isPositive ? Colors.green : Colors.orange, size: 12),
              const SizedBox(width: 4),
              Text(subtext, style: TextStyle(color: isPositive ? Colors.green : Colors.orange, fontSize: 11, fontWeight: FontWeight.bold)),
            ],
          )
        ],
      ),
    );
  }

  Widget _circularStat(String title, String value, double progress) {
    return Column(
      children: [
        SizedBox(
          width: 50, height: 50,
          child: CircularProgressIndicator(value: progress.clamp(0.0, 1.0), strokeWidth: 6, backgroundColor: Colors.grey.shade200, color: brandBlue),
        ),
        const SizedBox(height: 12),
        Text(title, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }

  // ==============================================================
  // TAB 1: MANAGE CUSTOMER ORDERS
  // ==============================================================
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
            final DocumentReference docRef = docs[index].reference;

            String rawStatus = data['status'] ?? 'Placed';
            if (rawStatus == 'Order Confirmed') rawStatus = 'Processing';
            final String status = ['Placed', 'Processing', 'Shipped', 'Out for Delivery', 'Delivered'].contains(rawStatus) ? rawStatus : 'Placed';
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

  // ==============================================================
  // TAB 2: ADD NEW PRODUCT
  // ==============================================================
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
  // TAB 3: REGISTERED USERS DIRECTORY
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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isAdmin ? Colors.green.shade100 : Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isAdmin ? 'Admin' : 'Customer',
                        style: TextStyle(color: isAdmin ? Colors.green.shade800 : Colors.blue.shade800, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 8),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.grey),
                      onSelected: (value) {
                        if (value == 'edit') _showEditUserDialog(userId, data);
                        else if (value == 'delete') _confirmDeleteUser(userId, name);
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 20, color: Colors.blue), SizedBox(width: 12), Text('Edit Profile')])),
                        const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 20, color: Colors.red), SizedBox(width: 12), Text('Remove User', style: TextStyle(color: Colors.red))])),
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

  // ==============================================================
  // TAB 4: FEEDBACK AND SUPPORT HUB
  // ==============================================================
  Widget _buildFeedbackAndSupportTab() {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              labelColor: brandColor,
              unselectedLabelColor: Colors.grey,
              indicatorColor: brandColor,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: const [
                Tab(text: 'Support Tickets'),
                Tab(text: 'Seller Feedback'),
                Tab(text: 'Delivery Feedback'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildFeedbackList('support_tickets'),
                _buildFeedbackList('seller_feedback'),
                _buildFeedbackList('delivery_feedback'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackList(String collectionName) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection(collectionName).orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator(color: brandColor));
        if (snapshot.hasError) return const Center(child: Text("Error loading data."));

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return Center(child: Text("No records found in $collectionName.", style: const TextStyle(color: Colors.grey)));

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final String docId = docs[index].id;
            final String userId = data['userId'] ?? '';
            final String productId = data['productId'] ?? '';
            final String comment = data['comment'] ?? data['issue'] ?? 'No text provided.';
            final int rating = data['rating'] ?? 0;
            final String status = data['status'] ?? '';

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
                        builder: (context, userSnap) {
                          String userName = 'Unknown User';
                          if (userSnap.hasData && userSnap.data!.exists) {
                            final userData = userSnap.data!.data() as Map<String, dynamic>;
                            userName = userData['name'] ?? userData['fullName'] ?? 'Unknown User';
                          }
                          return Row(
                            children: [
                              const Icon(Icons.person, size: 16, color: Colors.grey),
                              const SizedBox(width: 8),
                              Text(userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            ],
                          );
                        }
                    ),
                    const SizedBox(height: 8),

                    if (productId.isNotEmpty)
                      FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance.collection('products').doc(productId).get(),
                          builder: (context, prodSnap) {
                            String prodName = data['productTitle'] ?? data['productName'] ?? data['name'] ?? 'Loading...';
                            if (prodName == 'Product' || prodName == 'Loading...') {
                              if (prodSnap.hasData && prodSnap.data!.exists) {
                                final prodData = prodSnap.data!.data() as Map<String, dynamic>;
                                prodName = prodData['title'] ?? prodData['name'] ?? 'Unknown Item';
                              }
                            }
                            return Text('Item: $prodName', style: TextStyle(color: brandColor, fontSize: 13, fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis);
                          }
                      ),

                    const Divider(height: 24),

                    if (rating > 0)
                      Row(
                        children: List.generate(5, (starIndex) => Icon(starIndex < rating ? Icons.star : Icons.star_border, color: Colors.amber, size: 20)),
                      ),

                    if (rating > 0) const SizedBox(height: 8),

                    Text(comment, style: const TextStyle(fontSize: 14, height: 1.4)),

                    if (status.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Ticket Status:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          DropdownButton<String>(
                            value: ['Open', 'In Progress', 'Resolved'].contains(status) ? status : 'Open',
                            style: TextStyle(color: status == 'Resolved' ? Colors.green : brandColor, fontWeight: FontWeight.bold, fontSize: 13),
                            onChanged: (newStatus) async {
                              if (newStatus != null) {
                                await FirebaseFirestore.instance.collection('support_tickets').doc(docId).update({'status': newStatus});
                                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ticket updated!')));
                              }
                            },
                            items: const [
                              DropdownMenuItem(value: 'Open', child: Text('Open')),
                              DropdownMenuItem(value: 'In Progress', child: Text('In Progress')),
                              DropdownMenuItem(value: 'Resolved', child: Text('Resolved')),
                            ],
                          )
                        ],
                      )
                    ]
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