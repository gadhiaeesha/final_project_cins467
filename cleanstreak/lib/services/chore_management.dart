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

  // Load chores from storage (handles mode changes)
  Future<void> loadChores() async {
    if (_currentUserId != null) {
      _chores = await storage.readChoreList(_currentUserId!);
    } else {
      _chores = [];
    }
    _updateUnfinishedCount();
    notifyListeners();
  }

  // Reload chores when user mode changes (e.g., joins/leaves household)
  Future<void> reloadChores() async {
    await loadChores();
  }

  // Save chores to storage (deprecated - use individual CRUD operations instead)
  Future<void> saveChores() async {
    // This method is deprecated. Use individual CRUD operations instead.
    debugPrint('Warning: saveChores() is deprecated. Use individual CRUD operations.');
  }

  // Add a new chore (handles both single-user and household modes)
  Future<void> addChore(String name, String description, DateTime? completeBy, {bool isHouseholdChore = false}) async {
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

    // Determine the householdId for the chore based on user choice
    String? choreHouseholdId;
    if (isHouseholdChore && householdId != null) {
      choreHouseholdId = householdId;
    } else {
      choreHouseholdId = null; // Personal chore
    }

    // Generate unique ID for the new chore
    final uniqueId = await storage.generateUniqueId();

    // Create the new chore with appropriate householdId
    Chore newChore = Chore(
      id: uniqueId,
      name: name,
      description: description,
      isCompleted: false,
      completeBy: completeBy,
      completionDate: null,
      householdId: choreHouseholdId, // null for personal, householdId for household chore
      assignedTo: null,
      createdBy: currentUser.uid,
    );

    // Create the chore in the database and get it back with document ID
    final createdChore = await storage.createChore(newChore);

    // Add to chores list with document ID
    _chores.add(createdChore);
    _updateUnfinishedCount();

    // If the chore belongs to a household, add it to the household's list
    if (choreHouseholdId != null) {
      final household = await householdStorage.getHousehold(choreHouseholdId);
      if (household != null) {
        final updatedChoreIds = List<String>.from(household.choreIds)..add(createdChore.id.toString());
        await householdStorage.updateHousehold(
          choreHouseholdId,
          {'choreIds': updatedChoreIds},
        );
      }
    }

    notifyListeners();
  }

  // Delete a chore
  Future<void> deleteChore(int id) async {
    final choreToDelete = _chores.firstWhere((chore) => chore.id == id);
    final householdId = choreToDelete.householdId;
    final documentId = choreToDelete.documentId;

    if (documentId == null) {
      throw Exception('Cannot delete chore without document ID');
    }

    // Remove from chores list
    _chores.removeWhere((chore) => chore.id == id);
    if (_selectedChore != null && _selectedChore!.id == id) {
      _selectedChore = null;
    }
    _updateUnfinishedCount();

    // Delete from database
    await storage.deleteChore(documentId);

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
        
        // Update in database
        await storage.updateChore(chore);
        break;
      }
    }
    _updateUnfinishedCount();
    notifyListeners();
  }

  // Assign a chore to a member
  Future<void> assignChore(int choreId, String memberId) async {
    for (var chore in _chores) {
      if (chore.id == choreId) {
        chore.assignedTo = memberId;
        // Update in database
        await storage.updateChore(chore);
        break;
      }
    }
    notifyListeners();
  }

  // Unassign a chore
  Future<void> unassignChore(int choreId) async {
    for (var chore in _chores) {
      if (chore.id == choreId) {
        chore.assignedTo = null;
        // Update in database
        await storage.updateChore(chore);
        break;
      }
    }
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