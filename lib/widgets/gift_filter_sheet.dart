import 'package:flutter/material.dart';
import '../models/gift_sort_option.dart';

class GiftFilterSheet extends StatelessWidget {
  final GiftSortOption sortOption;
  final Function(GiftSortOption) onSortOptionChanged;
  final String? selectedCategory;
  final Function(String?) onCategoryChanged;

  const GiftFilterSheet({
    super.key,
    required this.sortOption,
    required this.onSortOptionChanged,
    this.selectedCategory,
    required this.onCategoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sort By',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8.0,
            children: GiftSortOption.values.map((option) {
              return ChoiceChip(
                label: Text(_getSortOptionLabel(option)),
                selected: sortOption == option,
                onSelected: (selected) {
                  if (selected) {
                    onSortOptionChanged(option);
                  }
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Text(
            'Filter by Category',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          // Add category filter UI here
          Wrap(
            spacing: 8.0,
            children: [
              ChoiceChip(
                label: const Text('All'),
                selected: selectedCategory == null,
                onSelected: (selected) {
                  if (selected) {
                    onCategoryChanged(null);
                  }
                },
              ),
              // You might want to add more category options here
            ],
          ),
        ],
      ),
    );
  }

  String _getSortOptionLabel(GiftSortOption option) {
    switch (option) {
      case GiftSortOption.name:
        return 'Name';
      case GiftSortOption.price:
        return 'Price';
      case GiftSortOption.dateAdded:
        return 'Date Added';
    }
  }
}
