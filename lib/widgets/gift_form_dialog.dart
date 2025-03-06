import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/gift.dart';

class GiftFormDialog extends StatefulWidget {
  final Gift? gift;
  final String userId;
  final String familyGroupId;

  const GiftFormDialog({
    super.key,
    this.gift,
    required this.userId,
    required this.familyGroupId,
  });

  @override
  State<GiftFormDialog> createState() => _GiftFormDialogState();
}

class _GiftFormDialogState extends State<GiftFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _urlController;
  late final TextEditingController _categoryController;
  List<String> _categories = [];
  bool _visibility = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.gift?.name);
    _descriptionController = TextEditingController(text: widget.gift?.description);
    _priceController = TextEditingController(
      text: widget.gift?.price?.toStringAsFixed(2),
    );
    _urlController = TextEditingController(text: widget.gift?.url);
    _categoryController = TextEditingController();
    _categories = widget.gift?.categories ?? [];
    _visibility = widget.gift?.visibility ?? true;
  }

  void _addCategory() {
    final category = _categoryController.text.trim();
    if (category.isNotEmpty && !_categories.contains(category)) {
      setState(() {
        _categories.add(category);
        _categoryController.clear();
      });
    }
  }

  void _removeCategory(String category) {
    setState(() {
      _categories.remove(category);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.gift == null ? 'Add Gift' : 'Edit Gift'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Gift Name*',
                  hintText: 'Enter gift name',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a gift name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description*',
                  hintText: 'Enter gift description',
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Price (optional)',
                  hintText: 'Enter price',
                  prefixText: '\$',
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _urlController,
                decoration: const InputDecoration(
                  labelText: 'URL (optional)',
                  hintText: 'Enter product URL',
                ),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _categoryController,
                      decoration: const InputDecoration(
                        labelText: 'Categories',
                        hintText: 'Add a category',
                      ),
                      onFieldSubmitted: (_) => _addCategory(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: _addCategory,
                    tooltip: 'Add category',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _categories.map((category) => Chip(
                  label: Text(category),
                  deleteIcon: const Icon(Icons.close, size: 18),
                  onDeleted: () => _removeCategory(category),
                )).toList(),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Visible to others'),
                  const Spacer(),
                  Switch(
                    value: _visibility,
                    onChanged: (value) {
                      setState(() {
                        _visibility = value;
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final giftData = {
                'name': _nameController.text.trim(),
                'description': _descriptionController.text.trim(),
                'price': _priceController.text.isNotEmpty
                    ? double.parse(_priceController.text)
                    : null,
                'url': _urlController.text.isNotEmpty
                    ? _urlController.text.trim()
                    : null,
                'categories': _categories,
                'visibility': _visibility,
                'userId': widget.userId,
                'familyGroupId': widget.familyGroupId,
                if (widget.gift != null) 'id': widget.gift!.id,
              };
              Navigator.pop(context, giftData);
            }
          },
          child: Text(widget.gift == null ? 'Add' : 'Save'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _urlController.dispose();
    _categoryController.dispose();
    super.dispose();
  }
}