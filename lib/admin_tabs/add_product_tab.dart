import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddProductTab extends StatefulWidget {
  const AddProductTab({super.key});

  @override
  State<AddProductTab> createState() => _AddProductTabState();
}

class _AddProductTabState extends State<AddProductTab> {
  final Color brandColor = const Color(0xFF0F4C5C);

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

  @override
  Widget build(BuildContext context) {
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
}