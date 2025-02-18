import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/family_group.dart';

class ShareGroupCodeScreen extends StatelessWidget {
  final FamilyGroup familyGroup;

  const ShareGroupCodeScreen({
    super.key,
    required this.familyGroup,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Share Family Group'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Share this code with family members',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).primaryColor),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                familyGroup.id,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: familyGroup.id));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Group code copied to clipboard')),
                );
              },
              icon: const Icon(Icons.copy),
              label: const Text('Copy Code'),
            ),
            const SizedBox(height: 32),
            const Text(
              'Instructions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  Text('1. Share this code with your family members'),
                  SizedBox(height: 8),
                  Text('2. They should select "Join Existing Group" on their app'),
                  SizedBox(height: 8),
                  Text('3. They can enter this code to join your family group'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}