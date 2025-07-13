// lib/screens/add_edit_gift_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:wikileet/models/gift.dart';
import 'package:wikileet/providers/gift_provider.dart';
import 'package:wikileet/providers/user_provider.dart';

class AddEditGiftScreen extends StatefulWidget {
  final String userId;
  final Gift? gift;

  const AddEditGiftScreen({
    super.key,
    required this.userId,
    this.gift,
  });

  @override
  _AddEditGiftScreenState createState() => _AddEditGiftScreenState();
}

class _AddEditGiftScreenState extends State<AddEditGiftScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _urlController;
  late TextEditingController _categoryController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.gift?.name ?? '');
    _descriptionController = TextEditingController(text: widget.gift?.description ?? '');
    _urlController = TextEditingController(text: widget.gift?.url ?? '');
    _categoryController = TextEditingController(text: widget.gift?.categories.join(', ') ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _urlController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _saveGift() async {
    if (!_formKey.currentState!.validate()) return;

    final categories = _categoryController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    try {
      // Get the familyGroupId first
      final userProvider = context.read<UserProvider>();
      final userData = await userProvider.getUserData(widget.userId);
      final familyGroupId = userData?.familyGroupId;
      
      if (familyGroupId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error: No family group found')),
          );
        }
        return;
      }

      final giftData = {
        'id': widget.gift?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        'name': _nameController.text,
        'description': _descriptionController.text,
        'url': _urlController.text.isNotEmpty ? _urlController.text : null,
        'categories': categories,
        'visibility': true,
        'purchased': false,
        'createdAt': Timestamp.now(),
        'familyGroupId': familyGroupId,  // Add the familyGroupId
      };

      final giftProvider = context.read<GiftProvider>();
      if (widget.gift == null) {
        await giftProvider.addGift(giftData);
      } else {
        await giftProvider.updateGift(widget.gift!.id, giftData);
      }
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      print("Error saving gift: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save gift: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.gift == null ? 'Add Gift' : 'Edit Gift'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Gift Name'),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter a name' : null,
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              TextFormField(
                controller: _urlController,
                decoration: const InputDecoration(labelText: 'URL'),
                keyboardType: TextInputType.url,
              ),
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(labelText: 'Category'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveGift,
                child: Text(widget.gift == null ? 'Add Gift' : 'Update Gift'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
