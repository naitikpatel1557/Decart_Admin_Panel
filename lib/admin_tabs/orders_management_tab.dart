import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OrdersManagementTab extends StatefulWidget {
  const OrdersManagementTab({super.key});

  @override
  State<OrdersManagementTab> createState() => _OrdersManagementTabState();
}

class _OrdersManagementTabState extends State<OrdersManagementTab> {
  final Color brandColor = const Color(0xFF0F4C5C);

  // --- UPDATE ORDER STATUS ---
  Future<void> _updateOrderStatus(DocumentReference docRef, String newStatus) async {
    try {
      await docRef.update({'status': newStatus});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Order updated to $newStatus'), backgroundColor: Colors.green)
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update status: $e'), backgroundColor: Colors.red)
        );
      }
    }
  }

  // --- DELETE ORDER ---
  void _confirmDeleteOrder(DocumentReference docRef, String orderId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Delete Order?', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text('Are you sure you want to permanently delete Order #$orderId? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await docRef.delete();
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order deleted successfully.'), backgroundColor: Colors.green));
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete order: $e'), backgroundColor: Colors.red));
                }
              }
            },
            child: const Text('Delete Permanently', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- EDIT ORDER DETAILS ---
  void _showEditOrderDialog(DocumentReference docRef, Map<String, dynamic> data) {
    final TextEditingController totalController = TextEditingController(text: data['totalAmount']?.toString() ?? '');

    // Extract current shipping details safely
    final dynamic rawShipping = data['shippingAddress'];
    String name = '';
    String phone = '';
    String address = '';

    if (rawShipping is Map<String, dynamic>) {
      name = rawShipping['title'] ?? rawShipping['name'] ?? '';
      phone = rawShipping['phone'] ?? rawShipping['phoneNumber'] ?? '';
      address = rawShipping['fullAddress'] ?? rawShipping['address'] ?? '';
    } else if (rawShipping is String) {
      address = rawShipping;
    }

    final TextEditingController nameController = TextEditingController(text: name);
    final TextEditingController phoneController = TextEditingController(text: phone);
    final TextEditingController addressController = TextEditingController(text: address);

    showDialog(
        context: context,
        builder: (context) {
          bool isSaving = false;
          return StatefulBuilder(
              builder: (context, setDialogState) {
                return AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  title: const Text('Edit Order Details', style: TextStyle(fontWeight: FontWeight.bold)),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: totalController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Total Amount (₹)', border: OutlineInputBorder()),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: nameController,
                          decoration: const InputDecoration(labelText: 'Shipping Name', border: OutlineInputBorder()),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder()),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: addressController,
                          maxLines: 3,
                          decoration: const InputDecoration(labelText: 'Full Address', border: OutlineInputBorder()),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: brandColor),
                      onPressed: isSaving ? null : () async {
                        setDialogState(() => isSaving = true);
                        try {
                          // Reconstruct the shipping map
                          Map<String, dynamic> updatedShipping = {};
                          if (rawShipping is Map<String, dynamic>) {
                            updatedShipping = Map.from(rawShipping);
                          }
                          updatedShipping['name'] = nameController.text.trim();
                          updatedShipping['title'] = nameController.text.trim(); // Save to both possible keys
                          updatedShipping['phone'] = phoneController.text.trim();
                          updatedShipping['phoneNumber'] = phoneController.text.trim();
                          updatedShipping['fullAddress'] = addressController.text.trim();

                          await docRef.update({
                            'totalAmount': double.tryParse(totalController.text.trim()) ?? data['totalAmount'],
                            'shippingAddress': updatedShipping,
                          });

                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order updated successfully!'), backgroundColor: Colors.green));
                          }
                        } catch (e) {
                          setDialogState(() => isSaving = false);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                          }
                        }
                      },
                      child: isSaving
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Save Changes', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                );
              }
          );
        }
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              isScrollable: true,
              labelColor: brandColor,
              unselectedLabelColor: Colors.grey,
              indicatorColor: brandColor,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: const [
                Tab(text: 'All Orders'),
                Tab(text: 'Pending'),
                Tab(text: 'Shipped'),
                Tab(text: 'Delivered'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildAdminOrdersList('All'),
                _buildAdminOrdersList('Pending'),
                _buildAdminOrdersList('Shipped'),
                _buildAdminOrdersList('Delivered'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminOrdersList(String filter) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collectionGroup('orders').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator(color: brandColor));
        if (snapshot.hasError) return Center(child: Text("Error loading orders: ${snapshot.error}"));
        final allDocs = snapshot.data?.docs ?? [];

        // Filter by Status
        final docs = allDocs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          String rawStatus = data['status'] ?? 'Placed';
          if (rawStatus == 'Order Confirmed') rawStatus = 'Processing';
          final String status = ['Placed', 'Processing', 'Shipped', 'Out for Delivery', 'Delivered'].contains(rawStatus) ? rawStatus : 'Placed';

          if (filter == 'All') return true;
          if (filter == 'Pending' && (status == 'Placed' || status == 'Processing')) return true;
          if (filter == 'Shipped' && (status == 'Shipped' || status == 'Out for Delivery')) return true;
          if (filter == 'Delivered' && status == 'Delivered') return true;
          return false;
        }).toList();

        // Sort by Date (Newest First)
        docs.sort((a, b) {
          final dataA = a.data() as Map<String, dynamic>;
          final dataB = b.data() as Map<String, dynamic>;
          final timeA = (dataA['orderDate'] ?? dataA['createdAt']) as Timestamp?;
          final timeB = (dataB['orderDate'] ?? dataB['createdAt']) as Timestamp?;
          if (timeA == null || timeB == null) return 0;
          return timeB.compareTo(timeA);
        });

        if (docs.isEmpty) return Center(child: Text("No $filter orders found.", style: const TextStyle(color: Colors.grey)));

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

            // --- ADDRESS PARSING LOGIC ---
            final String userId = data['userId']?.toString().trim() ?? '';
            final dynamic rawShipping = data['shippingAddress'];
            String shipName = 'Customer';
            String shipPhone = '';
            String formattedAddress = 'N/A';

            if (rawShipping is Map<String, dynamic>) {
              shipName = rawShipping['title'] ?? rawShipping['name'] ?? 'Customer';
              shipPhone = rawShipping['phone'] ?? rawShipping['phoneNumber'] ?? '';

              String tempAddr = rawShipping['fullAddress'] ?? rawShipping['address'] ?? '';
              if (tempAddr.isEmpty) {
                List<String> parts = [];
                for (String key in ['flat', 'houseNo', 'street', 'area', 'landmark', 'city', 'state', 'pincode', 'zipCode']) {
                  if (rawShipping[key] != null && rawShipping[key].toString().trim().isNotEmpty) {
                    parts.add(rawShipping[key].toString().trim());
                  }
                }
                tempAddr = parts.join(', ');
              }
              formattedAddress = tempAddr.isNotEmpty ? tempAddr : 'N/A';
            } else if (rawShipping is String) {
              formattedAddress = rawShipping;
            }

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- HEADER: ID, TOTAL, AND DROPDOWN ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Order #$orderId', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(height: 4),
                              Text('Total: ₹${total.toStringAsFixed(2)}', style: TextStyle(color: brandColor, fontWeight: FontWeight.bold, fontSize: 15)),
                            ],
                          ),
                        ),
                        Container(
                          height: 32,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.grey.shade300)
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: status,
                              style: TextStyle(fontSize: 12, color: brandColor, fontWeight: FontWeight.bold),
                              icon: const Icon(Icons.arrow_drop_down, size: 16),
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
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),

                    // --- USERNAME ---
                    if (userId.isNotEmpty)
                      FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
                          builder: (context, userSnap) {
                            String accountName = 'Loading...';
                            if (userSnap.hasData && userSnap.data!.exists) {
                              final uData = userSnap.data!.data() as Map<String, dynamic>;
                              accountName = uData['name'] ?? uData['fullName'] ?? 'Unknown User';
                            }
                            return Row(
                              children: [
                                const Icon(Icons.person, size: 16, color: Colors.grey),
                                const SizedBox(width: 8),
                                Text(accountName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              ],
                            );
                          }
                      )
                    else
                      const Row(
                        children: [
                          Icon(Icons.person, size: 16, color: Colors.grey),
                          SizedBox(width: 8),
                          Text('Guest User', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),

                    const SizedBox(height: 12),

                    // --- ADDRESS DETAILS ---
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.local_shipping, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(shipName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                              const SizedBox(height: 2),
                              Text(formattedAddress, style: TextStyle(fontSize: 12, height: 1.4, color: Colors.grey.shade800)),
                              if (shipPhone.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text('Phone: $shipPhone', style: TextStyle(fontSize: 12, color: Colors.grey.shade800)),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const Divider(height: 24),

                    // --- ACTION BUTTONS (EDIT & DELETE) ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          icon: Icon(Icons.edit, size: 18, color: brandColor),
                          label: Text('Edit', style: TextStyle(color: brandColor, fontWeight: FontWeight.bold)),
                          onPressed: () => _showEditOrderDialog(docRef, data),
                        ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                          label: const Text('Delete', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                          onPressed: () => _confirmDeleteOrder(docRef, orderId),
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