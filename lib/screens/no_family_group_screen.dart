import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/family_group_provider.dart';
import '../providers/user_provider.dart';

class NoFamilyGroupScreen extends StatelessWidget {
  const NoFamilyGroupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    print('Building NoFamilyGroupScreen');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome to WikiLeet'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              print('Sign out button pressed');
              await Provider.of<UserProvider>(context, listen: false).signOut();
            },
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,  // Make buttons full width
            children: [
              const Text(
                'You\'re not part of any family group yet!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                ),
                onPressed: () {
                  print('Create group button pressed');
                  _showCreateGroupDialog(context);
                },
                child: const Text('Create New Family Group'),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                ),
                onPressed: () {
                  print('Join group button pressed');
                  _showJoinGroupDialog(context);
                },
                child: const Text('Join Existing Group'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showCreateGroupDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userId = userProvider.userId;

    if (userId == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in first')),
        );
      }
      return;
    }

    return showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing while creating
      builder: (context) => AlertDialog(
        title: const Text('Create Family Group'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Create a new family group and your first house.\nOthers can join using the family group code.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Family Group Name',
                hintText: 'Enter your family group name',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a group name')),
                );
                return;
              }

              try {
                // Show progress indicator
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Creating family group...')),
                  );
                }

                final familyGroupProvider = Provider.of<FamilyGroupProvider>(context, listen: false);
                await familyGroupProvider.createFamilyGroup(nameController.text.trim(), userId);
                
                // Wait for Firestore to update and reload user data
                if (context.mounted) {
                  await Provider.of<UserProvider>(context, listen: false).getUserData(userId);
                }
                
                if (context.mounted) {
                  Navigator.pop(context); // Close dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Family group created successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error creating group: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _showJoinGroupDialog(BuildContext context) async {
    final TextEditingController codeController = TextEditingController();
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userId = userProvider.userId;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in first')),
      );
      return;
    }

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Join Family Group'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter the family group code provided by your family member',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: codeController,
              decoration: const InputDecoration(
                labelText: 'Group Code',
                hintText: 'Enter the group code',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final groupId = codeController.text.trim();
              if (groupId.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a group code')),
                );
                return;
              }

              try {
                await Provider.of<FamilyGroupProvider>(context, listen: false)
                    .joinFamilyGroup(groupId, userId);
                
                if (context.mounted) {
                  Navigator.pop(context); // Close dialog
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error joining group: $e')),
                  );
                }
              }
            },
            child: const Text('Join'),
          ),
        ],
      ),
    );
  }
}