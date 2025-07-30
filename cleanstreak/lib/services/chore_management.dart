import 'package:cleanstreak/models/chore.dart';
import 'package:cleanstreak/firestore_db/chore_storage.dart';
import 'package:cleanstreak/firestore_db/member_storage.dart';
import 'package:cleanstreak/firestore_db/household_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChoreManagement extends ChangeNotifier {
  final ChoreStorage storage;
  final MemberStorage memberStorage;
  final HouseholdStorage householdStorage;
  List<Chore> _chores = [];
  Chore? _selectedChore;
  int _unfinishedChoresCount = 0;
  String? _currentUserId;

  ChoreManagement(this.storage) 
    : memberStorage = MemberStorage(),
      householdStorage = HouseholdStorage();

  // Getters
  List<Chore> get chores => _chores;
  Chore? get selectedChore => _selectedChore;
  int get unfinishedChoresCount => _unfinishedChoresCount;
  String? get currentUserId => _currentUserId;

  // Set current user ID
  void setCurrentUserId(String? userId) {
    _currentUserId = userId;
    loadChores(); // Reload chores when user changes
  }

  // Load chores from storage
  Future<void> loadChores() async {
    if (_currentUserId != null) {
      _chores = await storage.readChoreList(_currentUserId!);
    } else {
      _chores = [];
    }
    _updateUnfinishedCount();
    notifyListeners();
  }

  // Save chores to storage
  Future<void> saveChores() async {
    if (_currentUserId != null) {
      await storage.writeChoreList(_chores, _currentUserId!);
    }
  }

  // Add a new chore
  Future<void> addChore(String name, String description, DateTime? completeBy) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw Exception('No user logged in');
    }

    // Get the current member's household ID
    String? householdId;
    final member = await memberStorage.getMember(currentUser.uid);
    if (member != null) {
      householdId = member.householdId;
    }

    // Create the new chore
    Chore newChore = Chore(
      id: _chores.length,
      name: name,
      description: description,
      isCompleted: false,
      completeBy: completeBy,
      completionDate: null,
      householdId: householdId,
      assignedTo: null,
      createdBy: currentUser.uid,
    );

    // Add to chores list
    _chores.add(newChore);
    _updateUnfinishedCount();

    // If the chore belongs to a household, add it to the household's list
    if (householdId != null) {
      final household = await householdStorage.getHousehold(householdId);
      if (household != null) {
        final updatedChoreIds = List<String>.from(household.choreIds)..add(newChore.id.toString());
        await householdStorage.updateHousehold(
          householdId,
          {'choreIds': updatedChoreIds},
        );
      }
    }

    await saveChores();
    notifyListeners();
  }

  // Delete a chore
  Future<void> deleteChore(int id) async {
    final choreToDelete = _chores.firstWhere((chore) => chore.id == id);
    final householdId = choreToDelete.householdId;

    // Remove from chores list
    _chores.removeWhere((chore) => chore.id == id);
    if (_selectedChore != null && _selectedChore!.id == id) {
      _selectedChore = null;
    }
    _updateUnfinishedCount();

    // If the chore belonged to a household, remove it from the household's list
    if (householdId != null) {
      final household = await householdStorage.getHousehold(householdId);
      if (household != null) {
        final updatedChoreIds = List<String>.from(household.choreIds)
          ..remove(id.toString());
        await householdStorage.updateHousehold(
          householdId,
          {'choreIds': updatedChoreIds},
        );
      }
    }

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

  // Assign a chore to a member
  Future<void> assignChore(int choreId, String memberId) async {
    for (var chore in _chores) {
      if (chore.id == choreId) {
        chore.assignedTo = memberId;
        break;
      }
    }
    await saveChores();
    notifyListeners();
  }

  // Unassign a chore
  Future<void> unassignChore(int choreId) async {
    for (var chore in _chores) {
      if (chore.id == choreId) {
        chore.assignedTo = null;
        break;
      }
    }
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