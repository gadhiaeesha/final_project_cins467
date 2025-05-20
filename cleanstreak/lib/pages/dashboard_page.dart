import 'package:cleanstreak/dialogs/add_chore.dart';
import 'package:cleanstreak/firestore_db/firebase_storage.dart';
import 'package:cleanstreak/models/chore.dart';
import 'package:cleanstreak/widgets/chore_container.dart';
import 'package:flutter/material.dart';
import '../auth/firebase_auth.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DashboardPage extends StatefulWidget {
  final FirebaseAuthService auth;
  final ChoreStorage storage = ChoreStorage();
  
  DashboardPage({super.key, required this.auth});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  List<Chore> chores = [];
  Chore? selectedChore;
  int _unfinishedChoresCount = 0;
  int _finishedChoresCount = 0;

  /// ************************************************************************************************
  /// Displays Master List of Chores
  /// ************************************************************************************************
  Widget _buildMasterChoresList(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.33, // 1/3 of screen width
      height: MediaQuery.of(context).size.height * 0.67, // 2/3 of screen height
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.cleaning_services,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 8),
                Text(
                  'Master Chores List',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: chores.length,
              itemBuilder: (context, index) {
                final chore = chores[index];
                return Dismissible(
                  key: Key(chore.id.toString()),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20.0),
                    child: const Icon(
                      Icons.delete,
                      color: Colors.white,
                    ),
                  ),
                  onDismissed: (direction) {
                    _deleteChore(chore.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${chore.name} deleted')),
                    );
                  },
                  child: ChoreContainer(
                    chore: chore,
                    onSelect: (selectedChore) {
                      setState(() {
                        this.selectedChore = selectedChore;
                      });
                    },
                    onDelete: (chore) {
                      _deleteChore(chore.id);
                    },
                    onToggleComplete: (chore, isCompleted) {
                      _toggleCompletion(chore.id, isCompleted);
                    },
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('All Chores: ${chores.length}'),
                SizedBox(
                  width: 45, // Adjust button size
                  height: 45,
                  child: FloatingActionButton(
                    onPressed: () {
                      _showAddChoreDialog();
                    },
                    child: const Icon(
                      Icons.add,
                      size: 20, // Adjust icon size
                    ),
                  ),
                ),
              ],
            ),
          ),

        ],
      ),
    );
  }

  /// ************************************************************************************************
  /// Displays Details of the selected Chore
  /// ************************************************************************************************
  Widget _buildChoreDetails() {
    if (selectedChore == null) return const SizedBox();

    return Container(
      width: 300,
      height: MediaQuery.of(context).size.height / 2,
      decoration: BoxDecoration(
        border: Border.all(),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.inversePrimary,
              border: const Border(bottom: BorderSide(width: 1)),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(7.0),
                topRight: Radius.circular(7.0),
              ),
            ),
            child: Text(
              'Chore Details: ${selectedChore!.name}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Description:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4), // Add a small space
                Text(
                  selectedChore!.description,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Completion Status:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                CheckboxListTile(
                  title: const Text('Completed'),
                  value: selectedChore!.isCompleted,
                  onChanged: (bool? value) {
                    if (value != null && selectedChore != null) {
                      _toggleCompletion(selectedChore!.id, value);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddChoreDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddChoreDialog(
          onChoreAdded: (String name, String description) {
            _addChore(name, description);
          },
        );
      },
    );
  }


  void _addChore(String name, String description) {
    Chore newChore = Chore(
      id: chores.length, 
      name: name, 
      description: description, 
      isCompleted: false
    );
    chores.add(newChore);
    setState(() {
      _unfinishedChoresCount = chores.where((chore) => !chore.isCompleted).length;
      _finishedChoresCount = chores.where((chore) => chore.isCompleted).length;
      _saveChores();
    });
  }

  void _deleteChore(int id) {
    for (int i = 0; i < chores.length; i++) {
      if (chores[i].id == id) {
        if (selectedChore != null && selectedChore!.id == id) {
          selectedChore = null; // Clear the details panel
        }
        chores.removeAt(i);
        _unfinishedChoresCount = chores.where((chore) => !chore.isCompleted).length;
        _finishedChoresCount = chores.where((chore) => chore.isCompleted).length;
        break;
      }
    }
    setState(() {
      _saveChores();
    });
  }


  void _toggleCompletion(int id, bool isCompleted) {
    setState(() {
      for (var chore in chores) {
        if (chore.id == id) {
          chore.isCompleted = isCompleted;
          break;
        }
      }
      _unfinishedChoresCount = chores.where((chore) => !chore.isCompleted).length;
      _finishedChoresCount = chores.where((chore) => chore.isCompleted).length;
      _saveChores();
    });
  }


  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: Text(
        'Dashboard',
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
      ),
      elevation: 0,
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      actions: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Center(
            child: Text(
              FirebaseAuth.instance.currentUser?.email ?? '',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ),
        IconButton(
          icon: Icon(
            Icons.logout,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
          tooltip: 'Sign Out',
          onPressed: () async {
            await widget.auth.signOut();
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Future<void> _loadChores() async {
    List<Chore> loadedChores = await widget.storage.readChoreList();
    setState(() {
      chores = loadedChores;
      _unfinishedChoresCount = chores.where((chore) => !chore.isCompleted).length;
      _finishedChoresCount = chores.where((chore) => chore.isCompleted).length;
    });
  }

  Future<void> _saveChores() async {
    await widget.storage.writeChoreList(chores);
  }

  @override
  void initState() {
    super.initState();
    _loadChores();
    _unfinishedChoresCount = chores.where((chore) => !chore.isCompleted).length;
    _finishedChoresCount = chores.where((chore) => chore.isCompleted).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _buildMasterChoresList(context),
      ),
    );
  }
}
