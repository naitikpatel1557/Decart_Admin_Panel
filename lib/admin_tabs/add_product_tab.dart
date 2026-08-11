import 'dart:typed_data';
import 'dart:ui' as ui;
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

  Uint8List? _selectedImageBytes;
  String? _selectedImageName;
  int? _imageWidth;
  int? _imageHeight;
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
    super.dispose();
  }

  Future<void> _pickAndValidateImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? file = await picker.pickImage(source: ImageSource.gallery);

      if (file == null) return;

      final Uint8List bytes = await file.readAsBytes();

      // Decode image to check resolution
      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      final int width = frameInfo.image.width;
      final int height = frameInfo.image.height;

      if (width != 1024 || height != 1024) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              title: const Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Invalid Image Resolution', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              content: Text(
                'Selected image is ${width}x${height} px.\n\nProduct images must be strictly 1024x1024 pixels. Please resize or select an image with exact 1024x1024 dimensions.',
                style: const TextStyle(fontSize: 14, height: 1.4),
              ),
              actions: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: brandColor),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('OK', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          );
        }
        return;
      }

      setState(() {
        _selectedImageBytes = bytes;
        _selectedImageName = file.name;
        _imageWidth = width;
        _imageHeight = height;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image validated successfully (1024x1024 px)!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e'), backgroundColor: Colors.red),
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
        _selectedImageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields and select a valid 1024x1024 image!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final double price = double.tryParse(_priceController.text.trim()) ?? 0.0;
      final int stock = int.tryParse(_stockController.text.trim()) ?? 0;

      // 1. Upload image to Firebase Storage with explicit metadata
      final String fileName = 'prod_${DateTime.now().millisecondsSinceEpoch}.png';
      final Reference storageRef = FirebaseStorage.instance
          .ref()
          .child('product_images')
          .child(fileName);

      final SettableMetadata metadata = SettableMetadata(
        contentType: 'image/png',
      );

      final UploadTask uploadTask = storageRef.putData(_selectedImageBytes!, metadata);

      // Await completion with a 20-second timeout safeguard
      final TaskSnapshot snapshot = await uploadTask.timeout(
        const Duration(seconds: 20),
        onTimeout: () {
          uploadTask.cancel();
          throw Exception('Image upload timed out. Check your network or Firebase Storage rules.');
        },
      );

      final String downloadUrl = await snapshot.ref.getDownloadURL();

      // 2. Save document to Firestore
      await FirebaseFirestore.instance.collection('products').add({
        'title': _titleController.text.trim(),
        'name': _titleController.text.trim(),
        'price': price,
        'stock': stock,
        'category': finalCategory,
        'imageUrl': downloadUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'description': _descriptionController.text.trim(),
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

      setState(() {
        _selectedImageBytes = null;
        _selectedImageName = null;
        _imageWidth = null;
        _imageHeight = null;
        _selectedCategory = _categories.first;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product and 1024x1024 image uploaded successfully!'),
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
            duration: const Duration(seconds: 4),
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

          // Local Image Picker & Preview Container
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _selectedImageBytes != null ? Colors.green : Colors.grey.shade300,
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Product Image', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        SizedBox(height: 2),
                        Text('Requirement: Exactly 1024 x 1024 pixels', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: brandColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      onPressed: _isUploading ? null : _pickAndValidateImage,
                      icon: const Icon(Icons.photo_library, size: 18),
                      label: Text(_selectedImageBytes == null ? 'Choose File' : 'Change File'),
                    ),
                  ],
                ),
                if (_selectedImageBytes != null) ...[
                  const Divider(height: 24),
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          _selectedImageBytes!,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedImageName ?? 'selected_image.png',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.check_circle, color: Colors.green, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  'Resolution: ${_imageWidth}x${_imageHeight} px (Valid)',
                                  style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        tooltip: 'Remove Image',
                        onPressed: () => setState(() {
                          _selectedImageBytes = null;
                          _selectedImageName = null;
                          _imageWidth = null;
                          _imageHeight = null;
                        }),
                      )
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Product Description
          TextField(
            controller: _descriptionController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Product Description',
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