import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/gift.dart';
import '../models/user.dart';
import '../models/gift_sort_option.dart';
import '../providers/gift_provider.dart';
import '../providers/user_provider.dart';
import '../services/gift_service.dart';
import '../widgets/gift_form_dialog.dart';
import '../widgets/gift_search_bar.dart';
import '../widgets/gift_filter_sheet.dart';
import '../widgets/manage_categories_dialog.dart';
import '../screens/batch_add_gifts_screen.dart';  // Add this

class GiftListScreen extends StatefulWidget {
  final String userId;
  final bool isCurrentUser;
  final bool useInternalScaffold;  // Add this parameter

  const GiftListScreen({
    super.key,
    required this.userId,
    required this.isCurrentUser,
    this.useInternalScaffold = true,  // Default to true for backward compatibility
  });

  @override
  State<GiftListScreen> createState() => _GiftListScreenState();
}

class _GiftListScreenState extends State<GiftListScreen> {
  String _searchQuery = '';
  String? _selectedCategory;
  GiftSortOption _sortOption = GiftSortOption.dateAdded;
  final TextEditingController _searchController = TextEditingController();
  bool _isInitialized = false;
  bool _groupByCategory = true; // New state variable
  List<String> _pinnedCategories = [];

  @override
  void initState() {
    super.initState();
    // Initialize gift stream for this user only once
    if (!_isInitialized) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<GiftProvider>().initializeGiftStreamForUser(widget.userId);
          _loadPinnedCategories();
          _isInitialized = true;
        }
      });
    }
  }

  Future<void> _loadPinnedCategories() async {
    if (!widget.isCurrentUser) return;
    
    final giftService = GiftService();
    final pinnedCategories = await giftService.getPinnedCategories(widget.userId);
    if (mounted) {
      setState(() {
        _pinnedCategories = pinnedCategories;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Gift> _filterAndSortGifts(List<Gift> gifts) {
    return gifts
        .where((gift) =>
            _selectedCategory == null ||
            gift.categories.any((category) => 
              category.toLowerCase() == _selectedCategory?.toLowerCase()))
        .where((gift) =>
            _searchQuery.isEmpty ||
            gift.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            gift.description.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList()
      ..sort((a, b) {
        switch (_sortOption) {
          case GiftSortOption.name:
            return a.name.compareTo(b.name);
          case GiftSortOption.price:
            if (a.price == null) return 1;
            if (b.price == null) return -1;
            return a.price!.compareTo(b.price!);
          case GiftSortOption.dateAdded:
            return b.createdAt.compareTo(a.createdAt);
        }
      });
  }

  Map<String, List<Gift>> _groupGiftsByCategory(List<Gift> gifts) {
    final groupedGifts = <String, List<Gift>>{};
    for (var gift in gifts) {
      final category = gift.categories.isNotEmpty ? gift.categories[0] : 'Uncategorized';
      groupedGifts.putIfAbsent(category, () => []).add(gift);
    }
    return groupedGifts;
  }

  List<String> _getUniqueCategories(List<Gift> gifts) {
    final categories = gifts
        .expand((gift) => gift.categories)
        .toSet()
        .toList()
      ..sort();
    return categories;
  }

  Widget _buildGiftList(List<Gift> gifts) {
    final filteredGifts = _filterAndSortGifts(gifts);

    if (filteredGifts.isEmpty) {
      return const Center(
        child: Text('No gifts match your search'),
      );
    }

    if (!_groupByCategory) {
      return ListView.builder(
        itemCount: filteredGifts.length,
        itemBuilder: (context, index) {
          final gift = filteredGifts[index];
          return _buildGiftCard(context, gift);
        },
      );
    }

    // Grouped view
    final groupedGifts = _groupGiftsByCategory(filteredGifts);
    final sortedCategories = groupedGifts.keys.toList()..sort();

    return ListView.builder(
      itemCount: sortedCategories.length,
      itemBuilder: (context, index) {
        final category = sortedCategories[index];
        final categoryGifts = groupedGifts[category]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Text(
                    category,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${categoryGifts.length}',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ...categoryGifts.map((gift) => _buildGiftCard(context, gift)),
          ],
        );
      },
    );
  }

  Future<void> _showManageCategoriesDialog(List<String> allCategories) async {
    final result = await showDialog<List<String>>(
      context: context,
      builder: (context) => ManageCategoriesDialog(
        userId: widget.userId,
        allCategories: allCategories,
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _pinnedCategories = result;
      });
    }
  }

  void _showFilterSheet() {
    final giftProvider = context.read<GiftProvider>();
    
    showModalBottomSheet(
      context: context,
      builder: (context) => StreamBuilder<List<Gift>>(
        stream: giftProvider.giftsForUser,
        builder: (context, snapshot) {
          final gifts = snapshot.data ?? [];
          final allCategories = _getUniqueCategories(gifts);
          
          return GiftFilterSheet(
            selectedCategory: _selectedCategory,
            sortOption: _sortOption,
            onCategoryChanged: (category) {
              setState(() {
                _selectedCategory = category;
              });
            },
            onSortOptionChanged: (option) {
              setState(() {
                _sortOption = option;
              });
            },
            groupByCategory: _groupByCategory,
            onGroupingChanged: (value) {
              setState(() {
                _groupByCategory = value;
              });
            },
            availableCategories: allCategories,
            isCurrentUser: widget.isCurrentUser,
            pinnedCategories: _pinnedCategories,
            onManageCategories: widget.isCurrentUser 
              ? () => _showManageCategoriesDialog(allCategories)
              : null,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<UserProvider, GiftProvider>(
      builder: (context, userProvider, giftProvider, _) {
        return StreamBuilder<User?>(
          stream: userProvider.getUserStream(widget.userId),
          builder: (context, userSnapshot) {
            if (!userSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final user = userSnapshot.data!;
            final content = Column(
              children: [
                if (!widget.useInternalScaffold) ...[
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: GiftSearchBar(
                            controller: _searchController,
                            onChanged: (query) {
                              setState(() {
                                _searchQuery = query;
                              });
                            },
                          ),
                        ),
                        IconButton(
                          icon: Icon(_groupByCategory ? Icons.list : Icons.grid_view),
                          onPressed: () {
                            setState(() {
                              _groupByCategory = !_groupByCategory;
                            });
                          },
                          tooltip: _groupByCategory ? 'Show as list' : 'Group by category',
                        ),
                        IconButton(
                          icon: const Icon(Icons.filter_list),
                          onPressed: _showFilterSheet,
                          tooltip: 'Filter and sort',
                        ),
                        if (widget.isCurrentUser)
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () => _showAddOptions(context),
                            tooltip: 'Add gift',
                          ),
                      ],
                    ),
                  ),
                ],
                Expanded(
                  child: StreamBuilder<List<Gift>>(
                    stream: giftProvider.giftsForUser,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('No gifts found'),
                              if (widget.isCurrentUser)
                                ElevatedButton(
                                  onPressed: () => _showAddOptions(context),
                                  child: const Text('Add Your First Gift'),
                                ),
                            ],
                          ),
                        );
                      }

                      return _buildGiftList(snapshot.data!);
                    },
                  ),
                ),
              ],
            );

            if (widget.useInternalScaffold) {
              return Scaffold(
                appBar: AppBar(
                  title: Text(
                    widget.isCurrentUser
                        ? 'My Wish List'
                        : '${user.displayName}\'s Wish List',
                  ),
                  actions: [
                    IconButton(
                      icon: Icon(_groupByCategory ? Icons.list : Icons.grid_view),
                      onPressed: () {
                        setState(() {
                          _groupByCategory = !_groupByCategory;
                        });
                      },
                      tooltip: _groupByCategory ? 'Show as list' : 'Group by category',
                    ),
                    IconButton(
                      icon: const Icon(Icons.filter_list),
                      onPressed: _showFilterSheet,
                      tooltip: 'Filter and sort',
                    ),
                    if (widget.isCurrentUser)
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () => _showAddOptions(context),  // Updated
                        tooltip: 'Add gift',
                      ),
                  ],
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(60),
                    child: GiftSearchBar(
                      controller: _searchController,
                      onChanged: (query) {
                        setState(() {
                          _searchQuery = query;
                        });
                      },
                    ),
                  ),
                ),
                body: content,
                floatingActionButton: widget.isCurrentUser
                    ? FloatingActionButton(
                        onPressed: () => _showAddOptions(context),  // Updated
                        child: const Icon(Icons.add),
                      )
                    : null,
              );
            }

            return content;
          },
        );
      },
    );
  }

  Widget _buildGiftCard(BuildContext context, Gift gift) {
    final currentUserId = context.read<UserProvider>().userId;
    final canPurchase = !widget.isCurrentUser && !gift.purchased;
    final isPurchaser = gift.purchasedBy == currentUserId;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title and action buttons row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    gift.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      decoration: gift.purchased ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (gift.url != null)
                      IconButton(
                        icon: const Icon(Icons.link),
                        onPressed: () => _openGiftUrl(gift.url!),
                        tooltip: 'Open product link',
                      ),
                    if (canPurchase || isPurchaser)
                      IconButton(
                        icon: Icon(
                          gift.purchased ? Icons.check_circle : Icons.check_circle_outline,
                          color: gift.purchased ? Colors.green : null,
                        ),
                        onPressed: () => _togglePurchaseStatus(gift),
                        tooltip: gift.purchased ? 'Mark as unpurchased' : 'Mark as purchased',
                      ),
                    if (widget.isCurrentUser)
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showEditGiftDialog(context, gift),
                        tooltip: 'Edit gift',
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Description
            if (gift.description.isNotEmpty) ...[
              Text(
                gift.description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
            ],
            // Price and categories row
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (gift.price != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '\$${gift.price!.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ...gift.categories.map((category) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    category,
                    style: TextStyle(
                      color: Colors.blue.shade700,
                    ),
                  ),
                )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddGiftDialog(BuildContext context) async {
    final userProvider = context.read<UserProvider>();
    final familyGroupId = (await userProvider.getUserData(widget.userId))?.familyGroupId;
    
    if (familyGroupId == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: No family group found')),
        );
      }
      return;
    }

    if (!context.mounted) return;

    final result = await showDialog(
      context: context,
      builder: (context) => GiftFormDialog(
        userId: widget.userId,
        familyGroupId: familyGroupId,
      ),
    );

    if (result != null && context.mounted) {
      try {
        await context.read<GiftProvider>().addGift(result);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error adding gift: $e')),
          );
        }
      }
    }
  }

  Future<void> _showEditGiftDialog(BuildContext context, Gift gift) async {
    final userProvider = context.read<UserProvider>();
    final familyGroupId = (await userProvider.getUserData(widget.userId))?.familyGroupId;
    
    if (familyGroupId == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: No family group found')),
        );
      }
      return;
    }

    if (!context.mounted) return;

    final result = await showDialog(
      context: context,
      builder: (context) => GiftFormDialog(
        gift: gift,
        userId: widget.userId,
        familyGroupId: familyGroupId,
      ),
    );

    if (result != null && context.mounted) {
      try {
        await context.read<GiftProvider>().updateGift(gift.id, result);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating gift: $e')),
          );
        }
      }
    }
  }

  Future<void> _openGiftUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open URL: $url')),
        );
      }
    }
  }

  Future<void> _togglePurchaseStatus(Gift gift) async {
    final currentUserId = context.read<UserProvider>().userId;
    if (currentUserId == null) return;

    try {
      await context.read<GiftProvider>().updateGiftStatus(
        gift.id,
        !gift.purchased,
        gift.purchased ? null : currentUserId,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating gift status: $e')),
        );
      }
    }
  }

  void _showAddOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.add),
                title: const Text('Add Single Gift'),
                onTap: () {
                  Navigator.pop(context);
                  _showAddGiftDialog(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.playlist_add),
                title: const Text('Add Multiple Gifts'),
                onTap: () async {
                  Navigator.pop(context);
                  final userProvider = context.read<UserProvider>();
                  final familyGroupId = (await userProvider.getUserData(widget.userId))?.familyGroupId;
                  
                  if (familyGroupId == null) {
                    if (mounted && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Error: No family group found')),
                      );
                    }
                    return;
                  }

                  if (!mounted) return;

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BatchAddGiftsScreen(
                        userId: widget.userId,
                        familyGroupId: familyGroupId,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
