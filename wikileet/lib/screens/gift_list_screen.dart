// lib/screens/gift_list_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wikileet/screens/add_edit_gift_screen.dart';
import 'package:wikileet/screens/batch_add_gifts_screen.dart';
import 'package:wikileet/models/gift.dart';
import 'package:wikileet/services/gift_service.dart';

class GiftListScreen extends StatelessWidget {
  final String userId;
  final GiftService giftService;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  GiftListScreen({required this.userId, GiftService? giftService})
      : giftService = giftService ?? GiftService();

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;
    final isOwner = currentUser?.uid == userId; // Determine if current user is the owner

    return Scaffold(
      body: StreamBuilder<List<Gift>>(
        stream: giftService.getGiftListStream(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error loading gifts'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No gifts found. Add your first gift!'));
          }

          final gifts = snapshot.data!;
          return ListView.builder(
            itemCount: gifts.length,
            itemBuilder: (context, index) {
              final gift = gifts[index];

              return ListTile(
                title: Text(gift.name),
                subtitle: Text(gift.description),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isOwner)
                      IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => AddEditGiftScreen(
                                userId: userId,
                                gift: gift,
                              ),
                            ),
                          );
                        },
                      ),
                    if (!isOwner && gift.purchasedBy == null)
                      IconButton(
                        icon: Icon(Icons.check),
                        onPressed: () async {
                          try {
                            await giftService.updateGift(userId, gift.id, {
                              'purchasedBy': currentUser?.uid,
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Marked as purchased')),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to mark as purchased')),
                            );
                          }
                        },
                      ),
                    if (isOwner)
                      IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () async {
                          try {
                            await giftService.deleteGift(userId, gift.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Gift deleted')),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to delete gift')),
                            );
                          }
                        },
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: isOwner
          ? Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'addSingle',
            child: Icon(Icons.add),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => AddEditGiftScreen(userId: userId),
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
                  builder: (context) => BatchAddGiftsScreen(userId: userId),
                ),
              );
            },
          ),
        ],
      )
          : null,
    );
  }
}
