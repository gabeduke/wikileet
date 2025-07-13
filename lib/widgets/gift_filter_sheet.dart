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
  final List<String> pinnedCategories;
  final Function(String, bool) onPinChanged;

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
    this.pinnedCategories = const [],
    required this.onPinChanged,
  });

  List<String> _getOrderedCategories() {
    final ordered = <String>[];
    ordered.addAll(pinnedCategories.where((c) => availableCategories.contains(c)));
    ordered.addAll(availableCategories.where((c) => !pinnedCategories.contains(c)));
    return ordered;
  }

  @override
  Widget build(BuildContext context) {
    final orderedCategories = _getOrderedCategories();
    final theme = Theme.of(context);
    
    return SizedBox(
      width: 280,
      child: IntrinsicHeight(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Sort by:', style: theme.textTheme.titleSmall),
                ],
              ),
            ),
            for (var option in GiftSortOption.values)
              RadioListTile<GiftSortOption>(
                title: Text(
                  switch (option) {
                    GiftSortOption.dateAdded => 'Date Added',
                    GiftSortOption.name => 'Name',
                    GiftSortOption.price => 'Price',
                  },
                  style: theme.textTheme.bodyMedium,
                ),
                value: option,
                groupValue: sortOption,
                onChanged: (value) => onSortOptionChanged(value!),
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                dense: true,
              ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('View:', style: theme.textTheme.titleSmall),
                  Switch(
                    value: groupByCategory,
                    onChanged: onGroupingChanged,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                groupByCategory ? 'Grouped by tags' : 'List view',
                style: theme.textTheme.bodySmall,
              ),
            ),
            if (availableCategories.isNotEmpty) ...[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Filter by tag:', style: theme.textTheme.titleSmall),
                    if (isCurrentUser)
                      Text(
                        'Long press to pin',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: theme.hintColor,
                        ),
                      ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                  child: Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      FilterChip(
                        label: const Text('All'),
                        selected: selectedCategory == null,
                        onSelected: (_) => onCategoryChanged(null),
                        showCheckmark: false,
                      ),
                      ...orderedCategories.map((category) {
                        final isPinned = pinnedCategories.contains(category);
                        return GestureDetector(
                          onLongPress: isCurrentUser ? () {
                            onPinChanged(category, !isPinned);
                          } : null,
                          child: FilterChip(
                            label: Text(category),
                            selected: category == selectedCategory,
                            onSelected: (_) => onCategoryChanged(category),
                            avatar: isPinned ? const Icon(Icons.push_pin, size: 14) : null,
                            showCheckmark: false,
                            backgroundColor: isPinned ? Colors.blue.shade50 : null,
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
