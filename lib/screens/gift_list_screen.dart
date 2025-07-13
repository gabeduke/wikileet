import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';  // Add this import for kDebugMode
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
  bool _isInitializing = false;
  bool _groupByCategory = true;
  List<String> _pinnedCategories = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    if (_isInitialized || _isInitializing) return;
    
    setState(() {
      _isInitializing = true;
      _error = null;
    });
    
    try {
      final userProvider = context.read<UserProvider>();
      final giftProvider = context.read<GiftProvider>();
      
      // First get the user data to ensure we have the family group ID
      final userData = await userProvider.getUserData(widget.userId);
      if (userData?.familyGroupId == null) {
        throw Exception('No family group found');
      }

      // Now initialize the gift stream with the user's family group
      if (mounted) {
        await giftProvider.initializeGiftStreamForUser(widget.userId);
        await _loadPinnedCategories();
        setState(() {
          _isInitialized = true;
          _isInitializing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isInitializing = false;
        });
      }
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
    if (kDebugMode) {
      print('Filtering gifts - total count: ${gifts.length}');
      print('Selected category: $_selectedCategory');
      print('Search query: $_searchQuery');
    }

    return gifts
        .where((gift) {
          if (_selectedCategory == null) return true;
          if (gift.categories.isEmpty) return _selectedCategory == 'Uncategorized';
          return gift.categories.any((category) => 
            category.toLowerCase() == _selectedCategory?.toLowerCase());
        })
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
    if (kDebugMode) {
      print('Grouping gifts by category - total gifts: ${gifts.length}');
    }
    
    final groupedGifts = <String, List<Gift>>{};
    for (var gift in gifts) {
      if (gift.categories.isEmpty) {
        const category = 'Uncategorized';
        groupedGifts.putIfAbsent(category, () => []).add(gift);
        if (kDebugMode) {
          print('Added uncategorized gift: ${gift.name}');
        }
      } else {
        for (var category in gift.categories) {
          groupedGifts.putIfAbsent(category, () => []).add(gift);
          if (kDebugMode) {
            print('Added gift ${gift.name} to category $category');
          }
        }
      }
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
    if (kDebugMode) {
      print('Building gift list - received ${gifts.length} gifts');
      for (var gift in gifts) {
        print('Gift: ${gift.name}, Categories: ${gift.categories.join(", ")}');
      }
    }

    final filteredGifts = _filterAndSortGifts(gifts);
    if (kDebugMode) {
      print('After filtering - ${filteredGifts.length} gifts remain');
    }

    if (filteredGifts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              gifts.isEmpty ? 'No gifts found' : 'No gifts match your filters',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (widget.isCurrentUser && gifts.isEmpty) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _showAddOptions(context),
                child: const Text('Add Your First Gift'),
              ),
            ]
          ],
        ),
      );
    }

    if (!_groupByCategory) {
      return ListView.builder(
        itemCount: filteredGifts.length,
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemBuilder: (context, index) {
          final gift = filteredGifts[index];
          if (kDebugMode) {
            print('Rendering gift at index $index: ${gift.name}');
          }
          return _buildGiftCard(context, gift);
        },
      );
    }

    // Grouped view logic remains the same
    final groupedGifts = _groupGiftsByCategory(filteredGifts);
    final sortedCategories = groupedGifts.keys.toList()..sort();

    return ListView.builder(
      itemCount: sortedCategories.length,
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemBuilder: (context, index) {
        final category = sortedCategories[index];
        final categoryGifts = groupedGifts[category]!;

        if (kDebugMode) {
          print('Rendering category $category with ${categoryGifts.length} gifts');
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
              child: Row(
                children: [
                  Text(
                    category,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${categoryGifts.length}',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 11,
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

  void _showFilterSheet(BuildContext context, RenderBox? button) {
    if (button == null) return;
    
    final giftProvider = context.read<GiftProvider>();
    final position = button.localToGlobal(Offset.zero);
    final size = button.size;
    
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy + size.height,
        position.dx + size.width,
        position.dy + size.height,
      ),
      items: [
        PopupMenuItem(
          enabled: false,
          padding: EdgeInsets.zero,
          child: StreamBuilder<List<Gift>>(
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
                  Navigator.pop(context);
                },
                onSortOptionChanged: (option) {
                  setState(() {
                    _sortOption = option;
                  });
                  Navigator.pop(context);
                },
                groupByCategory: _groupByCategory,
                onGroupingChanged: (value) {
                  setState(() {
                    _groupByCategory = value;
                  });
                  Navigator.pop(context);
                },
                onPinChanged: (tag, isPinned) {
                  setState(() {
                    if (isPinned) {
                      _pinnedCategories.add(tag);
                    } else {
                      _pinnedCategories.remove(tag);
                    }
                  });
                  _savePinnedCategories();
                },
                availableCategories: allCategories,
                isCurrentUser: widget.isCurrentUser,
                pinnedCategories: _pinnedCategories,
              );
            },
          ),
        ),
      ],
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  Future<void> _savePinnedCategories() async {
    if (!widget.isCurrentUser) return;
    
    try {
      final giftService = GiftService();
      await giftService.updatePinnedCategories(widget.userId, _pinnedCategories);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving pinned tags: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<UserProvider, GiftProvider>(
      builder: (context, userProvider, giftProvider, _) {
        if (_error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_error!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _initializeScreen,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (_isInitializing) {
          return const Center(child: CircularProgressIndicator());
        }

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
                          onPressed: () {
                            final RenderBox button = context.findRenderObject() as RenderBox;
                            _showFilterSheet(context, button);
                          },
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
                      onPressed: () {
                        final RenderBox button = context.findRenderObject() as RenderBox;
                        _showFilterSheet(context, button);
                      },
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
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    gift.name,
                    style: TextStyle(
                      fontSize: 14,
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
                        icon: const Icon(Icons.link, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => _openGiftUrl(gift.url!),
                        tooltip: 'Open product link',
                      ),
                    const SizedBox(width: 8),
                    if (canPurchase || isPurchaser)
                      IconButton(
                        icon: Icon(
                          gift.purchased ? Icons.check_circle : Icons.check_circle_outline,
                          color: gift.purchased ? Colors.green : null,
                          size: 20,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => _togglePurchaseStatus(gift),
                        tooltip: gift.purchased ? 'Mark as unpurchased' : 'Mark as purchased',
                      ),
                    if (widget.isCurrentUser) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => _showEditGiftDialog(context, gift),
                        tooltip: 'Edit gift',
                      ),
                    ],
                  ],
                ),
              ],
            ),
            if (gift.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                gift.description,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (gift.price != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '\$${gift.price!.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ...gift.categories.map((category) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    category,
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontSize: 12,
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
