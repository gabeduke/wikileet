import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/family_group.dart';
import '../models/user.dart';
import '../providers/user_provider.dart';
import '../providers/family_group_provider.dart';
import 'share_group_code_screen.dart';
import 'gift_list_screen.dart';

class FamilyGroupDetailScreen extends StatefulWidget {
  final FamilyGroup familyGroup;

  const FamilyGroupDetailScreen({super.key, required this.familyGroup});

  @override
  State<FamilyGroupDetailScreen> createState() => _FamilyGroupDetailScreenState();
}

class _FamilyGroupDetailScreenState extends State<FamilyGroupDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().fetchUsers(widget.familyGroup.members);
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.watch<UserProvider>().userId;
    final isAdmin = currentUserId == widget.familyGroup.members.first; // Simple admin check

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.familyGroup.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ShareGroupCodeScreen(
                    familyGroup: widget.familyGroup,
                  ),
                ),
              );
            },
          ),
          if (isAdmin) // Only show settings for admin
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                // TODO: Implement group settings
              },
            ),
        ],
      ),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          return ListView.builder(
            itemCount: widget.familyGroup.members.length,
            itemBuilder: (context, index) {
              final userId = widget.familyGroup.members[index];
              final userData = userProvider.userCache[userId];

              if (userData == null) {
                return FutureBuilder<User?>(
                  future: userProvider.getUserData(userId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const ListTile(
                        leading: CircularProgressIndicator(),
                        title: Text('Loading...'),
                      );
                    }
                    
                    if (!snapshot.hasData) {
                      return ListTile(
                        leading: const Icon(Icons.error),
                        title: Text('User not found: $userId'),
                      );
                    }

                    return _buildUserListTile(snapshot.data!, isAdmin && userId != currentUserId);
                  },
                );
              }

              return _buildUserListTile(userData, isAdmin && userId != currentUserId);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GiftListScreen(
                userId: currentUserId!,
                isCurrentUser: true,
              ),
            ),
          );
        },
        icon: const Icon(Icons.card_giftcard),
        label: const Text('My Wish List'),
      ),
    );
  }

  Widget _buildUserListTile(User user, bool canRemove) {
    final currentUserId = context.read<UserProvider>().userId;
    final isCurrentUser = user.uid == currentUserId;

    return ListTile(
      leading: CircleAvatar(
        backgroundImage: user.profilePicUrl != null 
          ? NetworkImage(user.profilePicUrl!) 
          : null,
        child: user.profilePicUrl == null 
          ? Text(user.displayName[0].toUpperCase()) 
          : null,
      ),
      title: Text(user.displayName),
      subtitle: Text(user.email),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.card_giftcard),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GiftListScreen(
                    userId: user.uid,
                    isCurrentUser: isCurrentUser,
                  ),
                ),
              );
            },
            tooltip: 'View ${isCurrentUser ? 'my' : '${user.displayName}\'s'} wish list',
          ),
          if (canRemove)
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: () => _showRemoveUserDialog(context, user),
            ),
        ],
      ),
    );
  }

  Future<void> _showRemoveUserDialog(BuildContext context, User user) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Member'),
        content: Text('Are you sure you want to remove ${user.displayName} from the family group?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await context.read<FamilyGroupProvider>().removeMember(
                  widget.familyGroup.id,
                  user.uid,
                );
                if (context.mounted) {
                  Navigator.pop(context);
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error removing member: $e')),
                  );
                }
              }
            },
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}