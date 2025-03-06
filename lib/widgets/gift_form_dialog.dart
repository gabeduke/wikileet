import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:async';  // Add for Timer
import '../models/gift.dart';
import '../services/gift_service.dart';
import '../providers/gift_provider.dart';

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
  Timer? _categoryAutoSaveTimer;
  List<String> _allCategories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.gift?.name);
    _descriptionController = TextEditingController(text: widget.gift?.description);
    _priceController = TextEditingController(
      text: widget.gift?.price?.toStringAsFixed(2),
    );
    _urlController = TextEditingController(text: widget.gift?.url);
    _categoryController = TextEditingController(
      text: widget.gift?.categories.join(', ')
    );
    _categories = widget.gift?.categories ?? [];
    _visibility = widget.gift?.visibility ?? true;
    
    _loadExistingCategories();
  }

  Future<void> _loadExistingCategories() async {
    final giftService = GiftService();
    _allCategories = await giftService.getAllCategories(widget.userId);
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _updateCategories(String value) {
    _categoryAutoSaveTimer?.cancel();
    final newCategories = value
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();
    
    setState(() {
      _categories = newCategories;
    });

    // Only auto-save the categories after a delay
    _categoryAutoSaveTimer = Timer(const Duration(seconds: 1), () {
      if (widget.gift != null && mounted) {
        final data = {
          ...widget.gift!.toFirestore(),
          'categories': _categories,
        };
        context.read<GiftProvider>().updateGift(widget.gift!.id, data);
      }
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
              const SizedBox(height: 16),
              Text(
                'Categories',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              if (!_isLoading && _allCategories.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: _allCategories.map((category) => ActionChip(
                    label: Text(category),
                    backgroundColor: _categories.contains(category) 
                      ? Colors.blue.shade100 
                      : Colors.grey.shade100,
                    onPressed: () {
                      setState(() {
                        if (_categories.contains(category)) {
                          _categories.remove(category);
                        } else {
                          _categories.add(category);
                        }
                        _categoryController.text = _categories.join(', ');
                      });
                    },
                  )).toList(),
                ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(
                  labelText: 'Add Categories',
                  hintText: 'Enter comma-separated categories',
                ),
                onChanged: (value) {
                  _updateCategories(value);
                  // Don't trigger form validation or updates for other fields
                },
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _categories.map((category) => Chip(
                  label: Text(category),
                  deleteIcon: const Icon(Icons.close, size: 18),
                  onDeleted: () {
                    setState(() {
                      _categories.remove(category);
                      _categoryController.text = _categories.join(', ');
                    });
                  },
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
              final price = double.tryParse(_priceController.text);
              final data = {
                'name': _nameController.text.trim(),
                'description': _descriptionController.text.trim(),
                'familyGroupId': widget.familyGroupId,
                if (price != null) 'price': price,
                if (_urlController.text.isNotEmpty)
                  'url': _urlController.text.trim(),
                'categories': _categories,
                'visibility': _visibility,
                if (widget.gift != null) ...{
                  'purchased': widget.gift!.purchased,
                  'purchasedBy': widget.gift!.purchasedBy,
                  'createdAt': widget.gift!.createdAt,
                }
              };
              Navigator.pop(context, data);
            }
          },
          child: Text(widget.gift == null ? 'Add' : 'Save'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _categoryAutoSaveTimer?.cancel();
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _urlController.dispose();
    _categoryController.dispose();
    super.dispose();
  }
}