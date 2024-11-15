import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/family_group.dart';
import '../viewmodels/family_viewmodel.dart';

class AdminInterfaceScreen extends StatefulWidget {
  @override
  _AdminInterfaceScreenState createState() => _AdminInterfaceScreenState();
}

class _AdminInterfaceScreenState extends State<AdminInterfaceScreen> {
  @override
  void initState() {
    super.initState();
    final familyViewModel =
        Provider.of<FamilyViewModel>(context, listen: false);

    if (!familyViewModel.isLoading) {
      familyViewModel.getFamilyGroups();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Admin Interface")),
      body: Consumer<FamilyViewModel>(
        builder: (context, familyViewModel, child) {
          if (familyViewModel.isLoading) {
            return Center(child: CircularProgressIndicator());
          }
          if (familyViewModel.errorMessage != null) {
            return Center(child: Text(familyViewModel.errorMessage!));
          }
          if (familyViewModel.familyGroups.isEmpty) {
            return Center(child: Text("No family groups found"));
          }

          return ListView.builder(
            itemCount: familyViewModel.familyGroups.length,
            itemBuilder: (context, index) {
              final familyGroup = familyViewModel.familyGroups[index];
              return ExpansionTile(
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(familyGroup.name),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () =>
                          _deleteFamilyGroup(context, familyGroup.id),
                    ),
                  ],
                ),
                children: [_buildHousesSection(context, familyGroup)],
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () => _showAddDialog(context, "Family Group", (name) {
          Provider.of<FamilyViewModel>(context, listen: false)
              .addFamilyGroup(name);
        }),
      ),
    );
  }

  Widget _buildHousesSection(BuildContext context, FamilyGroup familyGroup) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Text("Houses", style: TextStyle(fontWeight: FontWeight.bold)),
          ...familyGroup.houses.map((house) {
            return ListTile(
              title: TextFormField(
                initialValue: house.name,
                decoration: InputDecoration(labelText: "House Name"),
                onFieldSubmitted: (newName) {
                  Provider.of<FamilyViewModel>(context, listen: false)
                      .updateHouse(familyGroup.id, house.id, newName);
                },
              ),
              trailing: IconButton(
                icon: Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  Provider.of<FamilyViewModel>(context, listen: false)
                      .deleteHouse(familyGroup.id, house.id);
                },
              ),
            );
          }).toList(),
          ElevatedButton(
            onPressed: () => _showAddDialog(context, "House", (name) {
              Provider.of<FamilyViewModel>(context, listen: false)
                  .addHouse(familyGroup.id, name);
            }),
            child: Text("Add House"),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteFamilyGroup(
      BuildContext context, String familyGroupId) async {
    await Provider.of<FamilyViewModel>(context, listen: false)
        .deleteFamilyGroup(familyGroupId);
  }

  void _showAddDialog(
      BuildContext context, String entityType, Function(String) onAdd) {
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
              if (controller.text.isNotEmpty) {
                onAdd(controller.text);
              }
            },
            child: Text("Add"),
          ),
        ],
      ),
    );
  }
}
