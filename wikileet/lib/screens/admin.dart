import 'package:flutter/material.dart';

import '../models/family_group.dart';
import '../models/family_member.dart';
import '../models/house.dart';
import '../viewmodels/family_viewmodel.dart';

class AdminInterfaceScreen extends StatelessWidget {
  final FamilyViewModel viewModel;

  AdminInterfaceScreen({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<FamilyGroup>>(
        future: viewModel.getFamilyGroups(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text("No family groups found"));
          }

          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final familyGroup = snapshot.data![index];
              return ExpansionTile(
                title: Text(familyGroup.name),
                children: [
                  // Inline editable form for Houses
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        Text("Houses", style: TextStyle(fontWeight: FontWeight.bold)),
                        FutureBuilder<List<House>>(
                          future: viewModel.getHouses(familyGroup.id),
                          builder: (context, houseSnapshot) {
                            if (!houseSnapshot.hasData) return CircularProgressIndicator();
                            return Column(
                              children: [
                                ...houseSnapshot.data!.map((house) => ListTile(
                                  title: TextFormField(
                                    initialValue: house.name,
                                    decoration: InputDecoration(labelText: "House Name"),
                                    onFieldSubmitted: (newName) {
                                      viewModel.updateHouse(familyGroup.id, house.id, newName);
                                    },
                                  ),
                                  trailing: IconButton(
                                    icon: Icon(Icons.delete),
                                    onPressed: () => viewModel.deleteHouse(familyGroup.id, house.id),
                                  ),
                                )),
                                ElevatedButton(
                                  onPressed: () => _showAddDialog(context, "House", (name) {
                                    viewModel.addHouse(familyGroup.id, name);
                                  }),
                                  child: Text("Add House"),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  // Inline editable form for Family Members
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () {
          // Show dialog to add a new Family Group
          _showAddDialog(context, "Family Group", (name) {
            viewModel.addFamilyGroup(name);
          });
        },
      ),
    );
  }

  void _showAddDialog(BuildContext context, String entityType, Function(String) onAdd) {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Add $entityType"),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(labelText: "$entityType Name"),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onAdd(controller.text);
            },
            child: Text("Add"),
          ),
        ],
      ),
    );
  }
}
