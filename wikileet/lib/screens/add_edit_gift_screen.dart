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

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.gift?.name ?? '');
    _descriptionController = TextEditingController(text: widget.gift?.description ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveGift() async {
    if (!_formKey.currentState!.validate()) return;

    final newGift = Gift(
      id: widget.gift?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text,
      description: _descriptionController.text,
      price: null,
      link: null,
      reservedBy: null,
      visibility: true,
      purchased: false,
      createdAt: Timestamp.now(), // Ensure createdAt is set
    );

    try {
      if (widget.gift == null) {
        await widget.giftService.addGift(widget.userId, newGift);
      } else {
        await widget.giftService.updateGift(widget.userId, newGift.id, newGift.toFirestore());
      }
      Navigator.of(context).pop();
    } catch (e) {
      print("Error saving gift: $e"); // Log the error for troubleshooting
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save gift: $e')), // Show error message
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
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Gift Name'),
                validator: (value) => value!.isEmpty ? 'Please enter a name' : null,
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: 'Description'),
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
