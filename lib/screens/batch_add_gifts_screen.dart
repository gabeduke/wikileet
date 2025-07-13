// lib/screens/batch_add_gifts_screen.dart

import 'package:flutter/material.dart';
import 'package:wikileet/models/gift.dart';
import 'package:wikileet/services/gift_service.dart';

class BatchAddGiftsScreen extends StatefulWidget {
  final String userId;
  final GiftService giftService;
  final String familyGroupId;

  BatchAddGiftsScreen({
    super.key,
    required this.userId,
    required this.familyGroupId,
    GiftService? giftService,
  }) : giftService = giftService ?? GiftService();

  @override
  _BatchAddGiftsScreenState createState() => _BatchAddGiftsScreenState();
}

class _BatchAddGiftsScreenState extends State<BatchAddGiftsScreen> {
  final List<TextEditingController> _nameControllers = [];
  final List<TextEditingController> _descriptionControllers = [];
  final List<TextEditingController> _urlControllers = [];
  final List<TextEditingController> _categoryControllers = [];
  final List<List<String>> _categories = [];

  @override
  void initState() {
    super.initState();
    _addGiftField();
  }

  void _addGiftField() {
    setState(() {
      _nameControllers.add(TextEditingController());
      _descriptionControllers.add(TextEditingController());
      _urlControllers.add(TextEditingController());
      _categoryControllers.add(TextEditingController());
      _categories.add([]);
    });
  }

  void _updateCategories(int index, String value) {
    final newCategories = value
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();

    setState(() {
      _categories[index] = newCategories;
    });
  }

  Future<void> _saveGifts() async {
    final gifts = <Gift>[];

    for (var i = 0; i < _nameControllers.length; i++) {
      final name = _nameControllers[i].text.trim();
      final description = _descriptionControllers[i].text.trim();
      final url = _urlControllers[i].text.trim();

      if (name.isNotEmpty) {
        gifts.add(Gift(
          id: DateTime.now().millisecondsSinceEpoch.toString() + i.toString(),
          name: name,
          description: description,
          familyGroupId: widget.familyGroupId,
          url: url.isNotEmpty ? url : null,
          categories: _categories[i],
          visibility: true,
          purchased: false,
          createdAt: widget.giftService.getCurrentTimestamp(),
        ));
      }
    }

    try {
      await widget.giftService.batchAddGifts(widget.userId, gifts);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save gifts: $e')),
        );
      }
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
    }
    for (var controller in _categoryControllers) {
      controller.dispose();
    }
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            controller: _nameControllers[index],
                            decoration: const InputDecoration(
                              labelText: 'Gift Name*',
                              hintText: 'Enter gift name',
                            ),
                          ),
                          TextFormField(
                            controller: _descriptionControllers[index],
                            decoration: const InputDecoration(
                              labelText: 'Description',
                              hintText: 'Enter description',
                            ),
                            maxLines: 3,
                          ),
                          TextFormField(
                            controller: _urlControllers[index],
                            decoration: const InputDecoration(
                              labelText: 'URL',
                              hintText: 'Enter product URL',
                            ),
                            keyboardType: TextInputType.url,
                          ),
                          TextFormField(
                            controller: _categoryControllers[index],
                            decoration: const InputDecoration(
                              labelText: 'Categories',
                              hintText: 'Enter comma-separated categories',
                            ),
                            onChanged: (value) => _updateCategories(index, value),
                          ),
                          if (_categories[index].isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: _categories[index].map((category) => Chip(
                                label: Text(category),
                                deleteIcon: const Icon(Icons.close, size: 18),
                                onDeleted: () {
                                  setState(() {
                                    _categories[index].remove(category);
                                    _categoryControllers[index].text =
                                      _categories[index].join(', ');
                                  });
                                },
                              )).toList(),
                            ),
                          ],
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
