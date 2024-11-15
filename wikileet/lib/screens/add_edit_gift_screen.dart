// lib/screens/add_edit_gift_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wikileet/models/gift.dart';
import 'package:wikileet/services/gift_service.dart';

class AddEditGiftScreen extends StatefulWidget {
  final String userId;
  final GiftService giftService;
  final Gift? gift;

  AddEditGiftScreen({required this.userId, GiftService? giftService, this.gift})
      : giftService = giftService ?? GiftService();

  @override
  _AddEditGiftScreenState createState() => _AddEditGiftScreenState();
}

class _AddEditGiftScreenState extends State<AddEditGiftScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _urlController; // New controller
  late TextEditingController _categoryController; // New controller

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.gift?.name ?? '');
    _descriptionController =
        TextEditingController(text: widget.gift?.description ?? '');
    _urlController = TextEditingController(text: widget.gift?.url ?? '');
    _categoryController =
        TextEditingController(text: widget.gift?.category ?? '');
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

    final newGift = Gift(
      id: widget.gift?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text,
      description: _descriptionController.text,
      url: _urlController.text.isNotEmpty ? _urlController.text : null,
      category:
          _categoryController.text.isNotEmpty ? _categoryController.text : null,
      price: null,
      reservedBy: null,
      purchasedBy: null,
      visibility: true,
      purchased: false,
      createdAt: Timestamp.now(),
    );

    try {
      if (widget.gift == null) {
        await widget.giftService.addGift(widget.userId, newGift);
      } else {
        await widget.giftService
            .updateGift(widget.userId, newGift.id, newGift.toFirestore());
      }
      Navigator.of(context).pop();
    } catch (e) {
      print("Error saving gift: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save gift: $e')),
      );
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
            // Changed to ListView to prevent overflow
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Gift Name'),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter a name' : null,
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: 'Description'),
              ),
              TextFormField(
                controller: _urlController,
                decoration: InputDecoration(labelText: 'URL'),
                keyboardType: TextInputType.url,
              ),
              TextFormField(
                controller: _categoryController,
                decoration: InputDecoration(labelText: 'Category'),
              ),
              SizedBox(height: 20),
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
