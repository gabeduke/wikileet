import 'package:flutter/material.dart';
import '../models/gift_sort_option.dart';

class GiftFilterSheet extends StatelessWidget {
  final String? selectedCategory;
  final GiftSortOption sortOption;
  final Function(String?) onCategoryChanged;
  final Function(GiftSortOption) onSortOptionChanged;

  const GiftFilterSheet({
    super.key,
    required this.selectedCategory,
    required this.sortOption,
    required this.onCategoryChanged,
    required this.onSortOptionChanged,
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
            'Category Filter',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
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
              ..._getCommonCategories().map((category) {
                return ChoiceChip(
                  label: Text(category),
                  selected: selectedCategory == category,
                  onSelected: (selected) {
                    if (selected) {
                      onCategoryChanged(category);
                    }
                  },
                );
              }),
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

  List<String> _getCommonCategories() {
    return [
      'Electronics',
      'Books',
      'Clothing',
      'Home',
      'Toys',
      'Other',
    ];
  }
}