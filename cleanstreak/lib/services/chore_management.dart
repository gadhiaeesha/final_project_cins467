import 'package:cleanstreak/models/chore.dart';
import 'package:cleanstreak/firestore_db/chore_storage.dart';
import 'package:flutter/foundation.dart';

class ChoreManagement extends ChangeNotifier {
  final ChoreStorage storage;
  List<Chore> _chores = [];
  Chore? _selectedChore;
  int _unfinishedChoresCount = 0;

  ChoreManagement(this.storage);

  // Getters
  List<Chore> get chores => _chores;
  Chore? get selectedChore => _selectedChore;
  int get unfinishedChoresCount => _unfinishedChoresCount;

  // Load chores from storage
  Future<void> loadChores() async {
    _chores = await storage.readChoreList();
    _updateUnfinishedCount();
    notifyListeners();
  }

  // Save chores to storage
  Future<void> saveChores() async {
    await storage.writeChoreList(_chores);
  }

  // Add a new chore
  Future<void> addChore(String name, String description, DateTime? completeBy) async {
    Chore newChore = Chore(
      id: _chores.length,
      name: name,
      description: description,
      isCompleted: false,
      completeBy: completeBy,
      completionDate: null,
    );
    _chores.add(newChore);
    _updateUnfinishedCount();
    await saveChores();
    notifyListeners();
  }

  // Delete a chore
  Future<void> deleteChore(int id) async {
    _chores.removeWhere((chore) => chore.id == id);
    if (_selectedChore != null && _selectedChore!.id == id) {
      _selectedChore = null;
    }
    _updateUnfinishedCount();
    await saveChores();
    notifyListeners();
  }

  // Toggle chore completion
  Future<void> toggleCompletion(int id, bool isCompleted) async {
    for (var chore in _chores) {
      if (chore.id == id) {
        chore.isCompleted = isCompleted;
        if (isCompleted) {
          chore.completionDate = DateTime.now();
        } else {
          chore.completionDate = null;
        }
        break;
      }
    }
    _updateUnfinishedCount();
    await saveChores();
    notifyListeners();
  }

  // Select a chore
  void selectChore(Chore? chore) {
    _selectedChore = chore;
    notifyListeners();
  }

  // Update unfinished chores count
  void _updateUnfinishedCount() {
    _unfinishedChoresCount = _chores.where((chore) => !chore.isCompleted).length;
  }
} 