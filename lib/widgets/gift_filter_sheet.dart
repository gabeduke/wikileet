import 'package:flutter/material.dart';
import '../models/gift_sort_option.dart';

class GiftFilterSheet extends StatelessWidget {
  final GiftSortOption sortOption;
  final Function(GiftSortOption) onSortOptionChanged;
  final String? selectedCategory;
  final Function(String?) onCategoryChanged;
  final List<String> availableCategories;
  final bool groupByCategory;
  final Function(bool) onGroupingChanged;
  final bool isCurrentUser;
  final Function()? onManageCategories;
  final List<String> pinnedCategories;

  const GiftFilterSheet({
    super.key,
    required this.sortOption,
    required this.onSortOptionChanged,
    this.selectedCategory,
    required this.onCategoryChanged,
    this.availableCategories = const [],
    required this.groupByCategory,
    required this.onGroupingChanged,
    this.isCurrentUser = false,
    this.onManageCategories,
    this.pinnedCategories = const [],
  });

  List<String> _getOrderedCategories() {
    final ordered = <String>[];
    ordered.addAll(pinnedCategories);
    ordered.addAll(availableCategories.where((c) => !pinnedCategories.contains(c)));
    return ordered;
  }

  @override
  Widget build(BuildContext context) {
    final orderedCategories = _getOrderedCategories();

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
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: FilterChip(
                  label: Text(_getSortOptionLabel(option)),
                  selected: sortOption == option,
                  onSelected: (selected) {
                    if (selected) {
                      onSortOptionChanged(option);
                    }
                  },
                  backgroundColor: Colors.blue.shade50,
                  selectedColor: Colors.blue.shade100,
                  checkmarkColor: Colors.blue.shade700,
                  labelStyle: TextStyle(
                    color: sortOption == option ? Colors.blue.shade700 : Colors.blue.shade900,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                'View Options',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => onGroupingChanged(!groupByCategory),
                icon: Icon(
                  groupByCategory ? Icons.grid_view : Icons.list,
                  size: 20,
                ),
                label: Text(
                  groupByCategory ? 'Show as List' : 'Group by Category',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                'Filter by Category',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              if (isCurrentUser && onManageCategories != null)
                TextButton.icon(
                  onPressed: onManageCategories,
                  icon: const Icon(Icons.settings, size: 20),
                  label: const Text('Manage'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8.0,
            children: [
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: FilterChip(
                  label: const Text('All'),
                  selected: selectedCategory == null,
                  onSelected: (selected) {
                    if (selected) {
                      onCategoryChanged(null);
                    }
                  },
                  backgroundColor: Colors.blue.shade50,
                  selectedColor: Colors.blue.shade100,
                  checkmarkColor: Colors.blue.shade700,
                  labelStyle: TextStyle(
                    color: selectedCategory == null ? Colors.blue.shade700 : Colors.blue.shade900,
                  ),
                ),
              ),
              ...orderedCategories.map((category) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: FilterChip(
                  label: Text(category),
                  selected: selectedCategory == category,
                  onSelected: (selected) {
                    if (selected) {
                      onCategoryChanged(category);
                    }
                  },
                  avatar: pinnedCategories.contains(category) ? 
                    Icon(Icons.push_pin, size: 16, color: Colors.blue.shade700) : null,
                  backgroundColor: Colors.blue.shade50,
                  selectedColor: Colors.blue.shade100,
                  checkmarkColor: Colors.blue.shade700,
                  labelStyle: TextStyle(
                    color: selectedCategory == category ? Colors.blue.shade700 : Colors.blue.shade900,
                  ),
                ),
              )),
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
