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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving pinned categories: $e')),
        );
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
          ? const SizedBox(
              height: 100,
              child: Center(child: CircularProgressIndicator()),
            )
          : SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pin your most used categories to keep them at the top of filters and suggestions.',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  if (widget.allCategories.isEmpty)
                    const Text(
                      'No categories available yet. Categories will appear here as you add them to gifts.',
                      style: TextStyle(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                    )
                  else
                    Flexible(
                      child: SingleChildScrollView(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: widget.allCategories.map((category) {
                            final isPinned = _pinnedCategories.contains(category);
                            return FilterChip(
                              label: Text(category),
                              selected: isPinned,
                              avatar: isPinned ? const Icon(Icons.push_pin, size: 16) : null,
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    _pinnedCategories.add(category);
                                  } else {
                                    _pinnedCategories.remove(category);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                ],
              ),
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _savePinnedCategories,
          child: const Text('Save'),
        ),
      ],
    );
  }
}