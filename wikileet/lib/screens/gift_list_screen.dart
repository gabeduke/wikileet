// gift_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wikileet/screens/add_edit_gift_screen.dart';
import 'package:wikileet/screens/batch_add_gifts_screen.dart';
import 'package:wikileet/services/gift_service.dart';
import 'package:wikileet/viewmodels/gift_list_viewmodel.dart';

class GiftListScreen extends StatelessWidget {
  final String userId;

  GiftListScreen({required this.userId});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final currentUserId = currentUser?.uid ?? '';

  return ChangeNotifierProvider(
    create: (_) => GiftListViewModel(
      giftService: GiftService(),
      giftListOwnerId: userId,
      currentUserId: currentUserId,
    ),
    child: Consumer<GiftListViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.gifts.isEmpty) {
          return Scaffold(
            body: viewModel.giftsByCategory.isEmpty
                ? Center(child: Text('No gifts found.'))
                : ListView(
                    children: viewModel.giftsByCategory.entries.map((entry) {
                      final category = entry.key;
                      final gifts = entry.value;
                      return ExpansionTile(
                        title: Text(category),
                        children: gifts.map((gift) {
                          return ListTile(
                            title: Text(
                              gift.name,
                              style: gift.purchasedBy != null
                                  ? TextStyle(
                                      decoration: TextDecoration.lineThrough,
                                      color: Colors.grey,
                                    )
                                  : null,
                            ),
                            subtitle: Text(
                              gift.description,
                              style: gift.purchasedBy != null
                                  ? TextStyle(
                                      decoration: TextDecoration.lineThrough,
                                      color: Colors.grey,
                                    )
                                  : null,
                            ),
                            onTap: gift.url != null
                                ? () async {
                                    if (await canLaunchUrl(gift.url! as Uri)) {
                                      await launchUrl(gift.url! as Uri);
                                    } else {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                            content: Text('Could not open URL')),
                                      );
                                    }
                                  }
                                : null,
                            trailing: viewModel.isOwner
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.edit),
                                        onPressed: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  AddEditGiftScreen(
                                                userId:
                                                    viewModel.currentUserId,
                                                gift: gift,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.delete),
                                        onPressed: () async {
                                          await viewModel.deleteGift(gift);
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                                content:
                                                    Text('Gift deleted')),
                                          );
                                        },
                                      ),
                                    ],
                                  )
                                : viewModel.canTogglePurchasedStatus(gift)
                                    ? IconButton(
                                        icon: Icon(
                                          gift.purchasedBy ==
                                                  viewModel.currentUserId
                                              ? Icons.undo
                                              : Icons
                                                  .shopping_cart_checkout,
                                        ),
                                        onPressed: () async {
                                          await viewModel
                                              .togglePurchasedStatus(gift);
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                gift.purchasedBy ==
                                                        viewModel
                                                            .currentUserId
                                                    ? 'Gift unmarked as purchased'
                                                    : 'Gift marked as purchased',
                                              ),
                                            ),
                                          );
                                        },
                                      )
                                    : null,
                          );
                        }).toList(),
                      );
                    }).toList(),
                  ),
            floatingActionButton: viewModel.isOwner
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      FloatingActionButton(
                        heroTag: 'addSingle',
                        child: Icon(Icons.add),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => AddEditGiftScreen(
                                  userId: viewModel.currentUserId),
                            ),
                          );
                        },
                      ),
                      SizedBox(height: 10),
                      FloatingActionButton(
                        heroTag: 'addBatch',
                        child: Icon(Icons.add_to_photos),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => BatchAddGiftsScreen(
                                  userId: viewModel.currentUserId),
                            ),
                          );
                        },
                      ),
                    ],
                  )
                : null,
          );
        } else {
          return Scaffold(
            body: ListView(
              children: viewModel.giftsByCategory.entries.map((entry) {
                final category = entry.key;
                final gifts = entry.value;
                return ExpansionTile(
                  title: Text(category),
                  children: gifts.map((gift) {
                    return ListTile(
                      title: Text(
                        gift.name,
                        style: gift.purchasedBy != null
                            ? TextStyle(
                                decoration: TextDecoration.lineThrough,
                                color: Colors.grey,
                              )
                            : null,
                      ),
                      subtitle: Text(
                        gift.description,
                        style: gift.purchasedBy != null
                            ? TextStyle(
                                decoration: TextDecoration.lineThrough,
                                color: Colors.grey,
                              )
                            : null,
                      ),
                      onTap: gift.url != null
                          ? () async {
                              if (await canLaunchUrl(gift.url! as Uri)) {
                                await launchUrl(gift.url! as Uri);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text('Could not open URL')),
                                );
                              }
                            }
                          : null,
                      trailing: viewModel.isOwner
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit),
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            AddEditGiftScreen(
                                          userId: viewModel.currentUserId,
                                          gift: gift,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete),
                                  onPressed: () async {
                                    await viewModel.deleteGift(gift);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text('Gift deleted')),
                                    );
                                  },
                                ),
                              ],
                            )
                          : viewModel.canTogglePurchasedStatus(gift)
                              ? IconButton(
                                  icon: Icon(
                                    gift.purchasedBy ==
                                            viewModel.currentUserId
                                        ? Icons.undo
                                        : Icons.shopping_cart_checkout,
                                  ),
                                  onPressed: () async {
                                    await viewModel
                                        .togglePurchasedStatus(gift);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          gift.purchasedBy ==
                                                  viewModel.currentUserId
                                              ? 'Gift unmarked as purchased'
                                              : 'Gift marked as purchased',
                                        ),
                                      ),
                                    );
                                  },
                                )
                              : null,
                    );
                  }).toList(),
                );
              }).toList(),
            ),
            floatingActionButton: viewModel.isOwner
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      FloatingActionButton(
                        heroTag: 'addSingle',
                        child: Icon(Icons.add),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => AddEditGiftScreen(
                                  userId: viewModel.currentUserId),
                            ),
                          );
                        },
                      ),
                      SizedBox(height: 10),
                      FloatingActionButton(
                        heroTag: 'addBatch',
                        child: Icon(Icons.add_to_photos),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => BatchAddGiftsScreen(
                                  userId: viewModel.currentUserId),
                            ),
                          );
                        },
                      ),
                    ],
                  )
                : null,
          );
        }
      },
    ),
  );
}}
