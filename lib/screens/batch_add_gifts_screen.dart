// lib/screens/batch_add_gifts_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wikileet/models/gift.dart';
import 'package:wikileet/services/gift_service.dart';

class BatchAddGiftsScreen extends StatefulWidget {
  final String userId;
  final GiftService giftService;

  BatchAddGiftsScreen({super.key, required this.userId, GiftService? giftService})
      : giftService = giftService ?? GiftService();

  @override
  _BatchAddGiftsScreenState createState() => _BatchAddGiftsScreenState();
}

class _BatchAddGiftsScreenState extends State<BatchAddGiftsScreen> {
  final List<TextEditingController> _nameControllers = [];
  final List<TextEditingController> _descriptionControllers = [];
  final List<TextEditingController> _urlControllers = []; // New
  final List<TextEditingController> _categoryControllers = []; // New

  void _addGiftField() {
    setState(() {
      _nameControllers.add(TextEditingController());
      _descriptionControllers.add(TextEditingController());
      _urlControllers.add(TextEditingController()); // New
      _categoryControllers.add(TextEditingController()); // New
    });
  }

  Future<void> _saveGifts() async {
    final gifts = <Gift>[];

    for (var i = 0; i < _nameControllers.length; i++) {
      final name = _nameControllers[i].text;
      final description = _descriptionControllers[i].text;
      final url = _urlControllers[i].text;
      final category = _categoryControllers[i].text;
      if (name.isNotEmpty) {
        gifts.add(Gift(
          id: DateTime.now().millisecondsSinceEpoch.toString() + i.toString(),
          name: name,
          description: description,
          url: url.isNotEmpty ? url : null,
          category: category.isNotEmpty ? category : null,
          visibility: true,
          purchased: false,
          createdAt: Timestamp.now(),
        ));
      }
    }

    try {
      await widget.giftService.batchAddGifts(widget.userId, gifts);
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save gifts: $e')),
      );
    }
  }

  @override
  void dispose() {
    for (var controller in _nameControllers) {
      controller.dispose();
    }
    for (var controller in _descriptionControllers) {
      controller.dispose();
    }
    for (var controller in _urlControllers) {
      controller.dispose();
    } // New
    for (var controller in _categoryControllers) {
      controller.dispose();
    } // New
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Multiple Gifts'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: _nameControllers.length,
                itemBuilder: (context, index) {
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _nameControllers[index],
                            decoration: const InputDecoration(labelText: 'Gift Name'),
                            validator: (value) =>
                                value!.isEmpty ? 'Please enter a name' : null,
                          ),
                          TextFormField(
                            controller: _descriptionControllers[index],
                            decoration:
                                const InputDecoration(labelText: 'Description'),
                          ),
                          TextFormField(
                            controller: _urlControllers[index],
                            decoration: const InputDecoration(labelText: 'URL'),
                            keyboardType: TextInputType.url,
                          ),
                          TextFormField(
                            controller: _categoryControllers[index],
                            decoration: const InputDecoration(labelText: 'Category'),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: _addGiftField,
                  child: const Text('Add Another Gift'),
                ),
                ElevatedButton(
                  onPressed: _saveGifts,
                  child: const Text('Save All Gifts'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
