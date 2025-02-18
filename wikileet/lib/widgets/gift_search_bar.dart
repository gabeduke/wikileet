import 'package:flutter/material.dart';

class GiftSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onChanged;

  const GiftSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: 'Search gifts...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          filled: true,
          fillColor: Theme.of(context).cardColor,
        ),
      ),
    );
  }
}