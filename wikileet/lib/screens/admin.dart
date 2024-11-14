import 'package:flutter/material.dart';
import '../models/family_group.dart';
import '../models/house.dart';
import '../viewmodels/family_viewmodel.dart';

class AdminInterfaceScreen extends StatefulWidget {
  final FamilyViewModel viewModel;

  AdminInterfaceScreen({required this.viewModel});

  @override
  _AdminInterfaceScreenState createState() => _AdminInterfaceScreenState();
}

class _AdminInterfaceScreenState extends State<AdminInterfaceScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthorization(); // Check if the user is authorized to view the page
  }

  Future<void> _checkAuthorization() async {
    final isAuthorized = await widget.viewModel.checkAdminAuthorization();
    if (!isAuthorized) {
      // Navigate back if the user is not authorized
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Admin Interface")),
      body: FutureBuilder<List<FamilyGroup>>(
        future: widget.viewModel.getFamilyGroups(),
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
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(familyGroup.name),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteFamilyGroup(familyGroup.id),
                    ),
                  ],
                ),
                children: [
                  _buildHousesSection(familyGroup),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () => _showAddDialog(context, "Family Group", (name) {
          widget.viewModel.addFamilyGroup(name);
          setState(() {}); // Trigger a UI update
        }),
      ),
    );
  }

  /// Builds the section to display and manage houses within a family group.
  Widget _buildHousesSection(FamilyGroup familyGroup) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Text("Houses", style: TextStyle(fontWeight: FontWeight.bold)),
          FutureBuilder<List<House>>(
            future: widget.viewModel.getHouses(familyGroup.id),
            builder: (context, houseSnapshot) {
              if (houseSnapshot.connectionState == ConnectionState.waiting) {
                return CircularProgressIndicator();
              }
              if (!houseSnapshot.hasData || houseSnapshot.data!.isEmpty) {
                return Text("No houses found");
              }

              return Column(
                children: [
                  ...houseSnapshot.data!.map((house) => ListTile(
                    title: TextFormField(
                      initialValue: house.name,
                      decoration: InputDecoration(labelText: "House Name"),
                      onFieldSubmitted: (newName) {
                        widget.viewModel.updateHouse(familyGroup.id, house.id, newName);
                        setState(() {}); // Trigger UI update after renaming
                      },
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        widget.viewModel.deleteHouse(familyGroup.id, house.id);
                        setState(() {}); // Trigger UI update after deletion
                      },
                    ),
                  )),
                  ElevatedButton(
                    onPressed: () => _showAddDialog(context, "House", (name) {
                      widget.viewModel.addHouse(familyGroup.id, name);
                      setState(() {}); // Trigger UI update after adding a new house
                    }),
                    child: Text("Add House"),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  /// Deletes the specified family group.
  Future<void> _deleteFamilyGroup(String familyGroupId) async {
    await widget.viewModel.deleteFamilyGroup(familyGroupId);
    setState(() {}); // Trigger UI update after deleting a family group
  }

  /// Shows a dialog to add a new entity (either Family Group or House).
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
