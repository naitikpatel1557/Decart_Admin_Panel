import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UsersDirectoryTab extends StatefulWidget {
  const UsersDirectoryTab({super.key});

  @override
  State<UsersDirectoryTab> createState() => _UsersDirectoryTabState();
}

class _UsersDirectoryTabState extends State<UsersDirectoryTab> {
  final Color brandColor = const Color(0xFF0F4C5C);

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

  @override
  Widget build(BuildContext context) {
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
}