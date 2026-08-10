import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FeedbackSupportTab extends StatelessWidget {
  const FeedbackSupportTab({super.key});

  final Color brandColor = const Color(0xFF0F4C5C);

  @override
  Widget build(BuildContext context) {
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