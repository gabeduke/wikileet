// lib/screens/gift_list_screen.dart

import 'package:flutter/material.dart';
import 'package:wikileet/models/gift.dart';
import 'package:wikileet/screens/add_edit_gift_screen.dart';
import 'package:wikileet/services/gift_service.dart';

import 'batch_add_gifts_screen.dart';

class GiftListScreen extends StatelessWidget {
  final String userId;
  final GiftService giftService;

  GiftListScreen({required this.userId, GiftService? giftService})
      : giftService = giftService ?? GiftService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Gift List'),
      ),
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
                trailing: IconButton(
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
              );
            },
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'addSingle',
            child: Icon(Icons.add),
            onPressed: () {
              // Single item addition
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
              // Batch addition
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => BatchAddGiftsScreen(userId: userId),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}