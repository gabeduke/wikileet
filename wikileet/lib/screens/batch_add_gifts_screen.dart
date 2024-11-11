// lib/screens/batch_add_gifts_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wikileet/models/gift.dart';
import 'package:wikileet/services/gift_service.dart';

class BatchAddGiftsScreen extends StatefulWidget {
  final String userId;
  final GiftService giftService;

  BatchAddGiftsScreen({required this.userId, GiftService? giftService})
      : giftService = giftService ?? GiftService();

  @override
  _BatchAddGiftsScreenState createState() => _BatchAddGiftsScreenState();
}

class _BatchAddGiftsScreenState extends State<BatchAddGiftsScreen> {
  final List<TextEditingController> _nameControllers = [];
  final List<TextEditingController> _descriptionControllers = [];

  // Function to add a new gift input field
  void _addGiftField() {
    setState(() {
      _nameControllers.add(TextEditingController());
      _descriptionControllers.add(TextEditingController());
    });
  }

  // Function to save all gifts at once
  Future<void> _saveGifts() async {
    final gifts = <Gift>[];

    for (var i = 0; i < _nameControllers.length; i++) {
      final name = _nameControllers[i].text;
      final description = _descriptionControllers[i].text;
      if (name.isNotEmpty) {
        gifts.add(Gift(
          id: DateTime.now().millisecondsSinceEpoch.toString() + i.toString(),
          name: name,
          description: description,
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
    _nameControllers.forEach((controller) => controller.dispose());
    _descriptionControllers.forEach((controller) => controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Multiple Gifts'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: _nameControllers.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _nameControllers[index],
                          decoration: InputDecoration(labelText: 'Gift Name'),
                        ),
                        TextFormField(
                          controller: _descriptionControllers[index],
                          decoration: InputDecoration(labelText: 'Description'),
                        ),
                      ],
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
                  child: Text('Add Another Gift'),
                ),
                ElevatedButton(
                  onPressed: _saveGifts,
                  child: Text('Save All Gifts'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
