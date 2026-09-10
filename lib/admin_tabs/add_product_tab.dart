import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class AddProductTab extends StatefulWidget {
  const AddProductTab({super.key});

  @override
  State<AddProductTab> createState() => _AddProductTabState();
}

class _AddProductTabState extends State<AddProductTab> {
  final Color brandColor = const Color(0xFF0F4C5C);

  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _customCategoryController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _featuresController = TextEditingController(); // NEW: Features Controller

  // Store multiple images up to a max of 5
  List<Map<String, dynamic>> _selectedImages = [];
  bool _isUploading = false;

  final List<String> _categories = [
    'Electronics',
    'Mobiles & Accessories',
    'Fashion & Apparel',
    'Footwear',
    'Home & Kitchen',
    'Beauty & Personal Care',
    'Sports & Fitness',
    'Books & Stationery',
    'Groceries',
    'Toys & Baby Products',
    'Automotive',
    'Other / Custom',
  ];

  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _selectedCategory = _categories.first;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _customCategoryController.dispose();
    _descriptionController.dispose();
    _featuresController.dispose(); // NEW: Dispose Features Controller
    super.dispose();
  }

  Future<void> _pickImages() async {
    if (_selectedImages.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can only upload a maximum of 5 images per product.'), backgroundColor: Colors.orange),
      );
      return;
    }

    try {
      final ImagePicker picker = ImagePicker();
      // Allow multi-selection
      final List<XFile> files = await picker.pickMultiImage();

      if (files.isEmpty) return;

      int addedCount = 0;

      for (var file in files) {
        if (_selectedImages.length >= 5) {
          break; // Enforce the max 5 limit
        }

        final Uint8List bytes = await file.readAsBytes();

        setState(() {
          _selectedImages.add({
            'bytes': bytes,
            'name': file.name,
          });
        });
        addedCount++;
      }

      if (mounted && addedCount > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added $addedCount image(s) successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking images: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _addNewProduct() async {
    final String finalCategory = (_selectedCategory == 'Other / Custom')
        ? _customCategoryController.text.trim()
        : (_selectedCategory ?? '');

    if (_titleController.text.trim().isEmpty ||
        _priceController.text.trim().isEmpty ||
        _stockController.text.trim().isEmpty ||
        finalCategory.isEmpty ||
        _descriptionController.text.trim().isEmpty ||
        _featuresController.text.trim().isEmpty || // NEW: Validate Features
        _selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields and select at least one image!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final double price = double.tryParse(_priceController.text.trim()) ?? 0.0;
      final int stock = int.tryParse(_stockController.text.trim()) ?? 0;

      // 1. Upload all images to Firebase Storage in parallel
      List<Future<String>> uploadTasks = [];

      for (int i = 0; i < _selectedImages.length; i++) {
        final Uint8List bytes = _selectedImages[i]['bytes'];
        final String fileName = 'prod_${DateTime.now().millisecondsSinceEpoch}_$i.png';
        final Reference storageRef = FirebaseStorage.instance
            .ref()
            .child('product_images')
            .child(fileName);

        final SettableMetadata metadata = SettableMetadata(contentType: 'image/png');

        uploadTasks.add(
            storageRef.putData(bytes, metadata).then((snapshot) => snapshot.ref.getDownloadURL())
        );
      }

      // Wait for all uploads to complete
      final List<String> downloadUrls = await Future.wait(uploadTasks).timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          throw Exception('Image uploads timed out. Check your network.');
        },
      );

      // 2. Save document to Firestore
      await FirebaseFirestore.instance.collection('products').add({
        'title': _titleController.text.trim(),
        'name': _titleController.text.trim(),
        'price': price,
        'stock': stock,
        'category': finalCategory,
        'imageUrl': downloadUrls.first,
        'imageUrls': downloadUrls,
        'createdAt': FieldValue.serverTimestamp(),
        'description': _descriptionController.text.trim(), // Used for Overview tab
        'features': _featuresController.text.trim(), // NEW: Used for Features tab
      }).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Firestore document creation timed out.');
        },
      );

      // Clear input fields on success
      _titleController.clear();
      _priceController.clear();
      _stockController.clear();
      _customCategoryController.clear();
      _descriptionController.clear();
      _featuresController.clear(); // NEW: Clear Features input

      setState(() {
        _selectedImages.clear();
        _selectedCategory = _categories.first;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product and images uploaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload product: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Add New Catalog Item',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Product Title
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Product Title',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),

          // Price & Stock Quantity in a Row
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Price (₹)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _stockController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Stock Quantity',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Category Dropdown
          DropdownButtonFormField<String>(
            value: _selectedCategory,
            decoration: const InputDecoration(
              labelText: 'Select Category',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            ),
            icon: const Icon(Icons.arrow_drop_down),
            items: _categories.map((String category) {
              return DropdownMenuItem<String>(
                value: category,
                child: Text(category),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                _selectedCategory = newValue;
              });
            },
          ),

          if (_selectedCategory == 'Other / Custom') ...[
            const SizedBox(height: 12),
            TextField(
              controller: _customCategoryController,
              decoration: const InputDecoration(
                labelText: 'Enter Custom Category Name',
                border: OutlineInputBorder(),
              ),
            ),
          ],
          const SizedBox(height: 16),

          // Local Image Picker & Preview Container (Supports up to 5)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _selectedImages.isNotEmpty ? Colors.green : Colors.grey.shade300,
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Product Images (${_selectedImages.length}/5)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 2),
                        const Text('Upload up to 5 images for this product', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: brandColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      onPressed: (_isUploading || _selectedImages.length >= 5) ? null : _pickImages,
                      icon: const Icon(Icons.photo_library, size: 18),
                      label: const Text('Add Images'),
                    ),
                  ],
                ),

                // Show grid of selected images
                if (_selectedImages.isNotEmpty) ...[
                  const Divider(height: 24),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: _selectedImages.asMap().entries.map((entry) {
                      int index = entry.key;
                      Map<String, dynamic> imgData = entry.value;

                      return Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.memory(
                                imgData['bytes'],
                                width: 90,
                                height: 90,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            top: -8,
                            right: -8,
                            child: IconButton(
                              icon: const Icon(Icons.cancel, color: Colors.red, size: 22),
                              onPressed: () {
                                setState(() {
                                  _selectedImages.removeAt(index);
                                });
                              },
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Product Description (Overview)
          TextField(
            controller: _descriptionController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Product Description (Overview)',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          // NEW: Feature Description (Features)
          TextField(
            controller: _featuresController,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Feature Description (Key Specs/Bullet Points)',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),

          // Upload Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: brandColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: _isUploading ? null : _addNewProduct,
              child: _isUploading
                  ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
                  : const Text(
                'Upload Product',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}