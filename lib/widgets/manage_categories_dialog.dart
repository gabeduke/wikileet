import 'package:flutter/material.dart';
import '../services/gift_service.dart';

class ManageCategoriesDialog extends StatefulWidget {
  final String userId;
  final List<String> allCategories;

  const ManageCategoriesDialog({
    super.key,
    required this.userId,
    required this.allCategories,
  });

  @override
  State<ManageCategoriesDialog> createState() => _ManageCategoriesDialogState();
}

class _ManageCategoriesDialogState extends State<ManageCategoriesDialog> {
  List<String> _pinnedCategories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPinnedCategories();
  }

  Future<void> _loadPinnedCategories() async {
    final giftService = GiftService();
    final pinnedCategories = await giftService.getPinnedCategories(widget.userId);
    if (mounted) {
      setState(() {
        _pinnedCategories = pinnedCategories;
        _isLoading = false;
      });
    }
  }

  Future<void> _savePinnedCategories() async {
    setState(() => _isLoading = true);
    try {
      final giftService = GiftService();
      await giftService.updatePinnedCategories(widget.userId, _pinnedCategories);
      if (mounted) {
        Navigator.of(context).pop(_pinnedCategories);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Manage Categories'),
      content: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pin your most used categories to keep them at the top of filters and suggestions.',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: widget.allCategories.map((category) {
                      final isPinned = _pinnedCategories.contains(category);
                      return FilterChip(
                        label: Text(category),
                        selected: isPinned,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _pinnedCategories.add(category);
                            } else {
                              _pinnedCategories.remove(category);
                            }
                          });
                        },
                        avatar: isPinned ? const Icon(Icons.push_pin, size: 18) : null,
                        backgroundColor: Colors.grey.shade100,
                        selectedColor: Colors.blue.shade100,
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _savePinnedCategories,
          child: const Text('Save'),
        ),
      ],
    );
  }
}