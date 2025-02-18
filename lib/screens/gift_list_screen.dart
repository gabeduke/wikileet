import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/gift.dart';
import '../models/user.dart';
import '../models/gift_sort_option.dart';
import '../providers/gift_provider.dart';
import '../providers/user_provider.dart';
import '../widgets/gift_form_dialog.dart';
import '../widgets/gift_search_bar.dart';
import '../widgets/gift_filter_sheet.dart';

class GiftListScreen extends StatefulWidget {
  final String userId;
  final bool isCurrentUser;

  const GiftListScreen({
    super.key,
    required this.userId,
    required this.isCurrentUser,
  });

  @override
  State<GiftListScreen> createState() => _GiftListScreenState();
}

class _GiftListScreenState extends State<GiftListScreen> {
  String _searchQuery = '';
  String? _selectedCategory;
  GiftSortOption _sortOption = GiftSortOption.dateAdded;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize gift stream for this user
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GiftProvider>().initializeGiftStreamForUser(widget.userId);
    });
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
            gift.category?.toLowerCase() == _selectedCategory?.toLowerCase())
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

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => GiftFilterSheet(
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
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final user = userSnapshot.data!;

            return Scaffold(
              appBar: AppBar(
                title: Text(
                  widget.isCurrentUser
                      ? 'My Wish List'
                      : '${user.displayName}\'s Wish List',
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.filter_list),
                    onPressed: _showFilterSheet,
                    tooltip: 'Filter and sort',
                  ),
                  if (widget.isCurrentUser)
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () => _showAddGiftDialog(context),
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
              body: StreamBuilder<List<Gift>>(
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
                              onPressed: () => _showAddGiftDialog(context),
                              child: const Text('Add Your First Gift'),
                            ),
                        ],
                      ),
                    );
                  }

                  final filteredGifts = _filterAndSortGifts(snapshot.data!);

                  if (filteredGifts.isEmpty) {
                    return const Center(
                      child: Text('No gifts match your search'),
                    );
                  }

                  return ListView.builder(
                    itemCount: filteredGifts.length,
                    itemBuilder: (context, index) {
                      final gift = filteredGifts[index];
                      return _buildGiftCard(context, gift);
                    },
                  );
                },
              ),
              floatingActionButton: widget.isCurrentUser
                  ? FloatingActionButton(
                      onPressed: () => _showAddGiftDialog(context),
                      child: const Icon(Icons.add),
                    )
                  : null,
            );
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
      child: ListTile(
        title: Text(
          gift.name,
          style: TextStyle(
            decoration: gift.purchased ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(gift.description),
            if (gift.price != null)
              Text(
                'Price: \$${gift.price!.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            if (gift.category != null)
              Text(
                'Category: ${gift.category}',
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
          ],
        ),
        trailing: Row(
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
}
