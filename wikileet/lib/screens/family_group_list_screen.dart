import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/family_group_provider.dart';
import '../providers/gift_provider.dart';
import '../models/family_group.dart';
import 'family_group_detail_screen.dart';

class FamilyGroupListScreen extends StatelessWidget {
  const FamilyGroupListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Family Groups'),
      ),
      body: Consumer<FamilyGroupProvider>(
        builder: (context, familyGroupProvider, child) {
          return StreamBuilder<List<FamilyGroup>>(
            stream: familyGroupProvider.familyGroups,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('No family groups found'));
              }

              return ListView.builder(
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final group = snapshot.data![index];
                  return Card(
                    margin: const EdgeInsets.all(8.0),
                    child: ListTile(
                      title: Text(group.name),
                      subtitle: Text('Members: ${group.members.length}'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        // Initialize gift stream for this group
                        Provider.of<GiftProvider>(context, listen: false)
                            .initializeStream(group.id);
                        
                        // Navigate to group details
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FamilyGroupDetailScreen(
                              familyGroup: group,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // We'll implement add family group functionality later
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}