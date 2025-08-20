import 'package:cleanstreak/models/chore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class ChoreStorage {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final String choresCollection = 'chores';

  ChoreStorage();

  // Load chores for a user (handles both single-user and household modes)
  Future<List<Chore>> readChoreList(String userId) async {
    try {
      // First, get the user's member profile to determine mode
      final memberDoc = await firestore.collection('members').doc(userId).get();
      if (!memberDoc.exists) {
        debugPrint('Member not found for user: $userId');
        return [];
      }

      final memberData = memberDoc.data() as Map<String, dynamic>;
      final householdId = memberData['householdId'];

      if (householdId != null) {
        // Household Mode: Load both household chores AND personal chores
        debugPrint('Loading household and personal chores for user: $userId in household: $householdId');
        
        List<Chore> allChores = [];
        
        // Load household chores
        final householdSnapshot = await firestore
            .collection(choresCollection)
            .where('householdId', isEqualTo: householdId)
            .get();

        if (householdSnapshot.docs.isNotEmpty) {
          final householdChores = householdSnapshot.docs
              .where((doc) => doc.data() != null)
              .map((doc) => Chore.fromJson(
                doc.data() as Map<String, dynamic>,
                documentId: doc.id,
              ))
              .toList();
          allChores.addAll(householdChores);
          debugPrint('Loaded ${householdChores.length} household chores');
        }

        // Load personal chores (householdId = null)
        final personalSnapshot = await firestore
            .collection(choresCollection)
            .where('createdBy', isEqualTo: userId)
            .where('householdId', isNull: true)
            .get();

        if (personalSnapshot.docs.isNotEmpty) {
          final personalChores = personalSnapshot.docs
              .where((doc) => doc.data() != null)
              .map((doc) => Chore.fromJson(
                doc.data() as Map<String, dynamic>,
                documentId: doc.id,
              ))
              .toList();
          allChores.addAll(personalChores);
          debugPrint('Loaded ${personalChores.length} personal chores');
        }

        debugPrint('Total chores loaded: ${allChores.length}');
        return allChores;
      } else {
        // Single User Mode: Load only user's personal chores
        debugPrint('Loading personal chores for user: $userId');
        final QuerySnapshot snapshot = await firestore
            .collection(choresCollection)
            .where('createdBy', isEqualTo: userId)
            .where('householdId', isNull: true)
            .get();

        if (snapshot.docs.isNotEmpty) {
          return snapshot.docs
              .where((doc) => doc.data() != null)
              .map((doc) => Chore.fromJson(
                doc.data() as Map<String, dynamic>,
                documentId: doc.id,
              ))
              .toList();
        } else {
          debugPrint('No personal chores found for user: $userId');
          return [];
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error reading chores list from Firestore: $e');
      }
      return [];
    }
  }

  // Create a new chore
  Future<Chore> createChore(Chore chore) async {
    try {
      final docRef = await firestore.collection(choresCollection).add(chore.toJson());
      // Return the chore with the document ID
      return Chore(
        id: chore.id,
        documentId: docRef.id,
        name: chore.name,
        description: chore.description,
        isCompleted: chore.isCompleted,
        completionDate: chore.completionDate,
        completeBy: chore.completeBy,
        householdId: chore.householdId,
        assignedTo: chore.assignedTo,
        createdBy: chore.createdBy,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error creating chore: $e');
      }
      rethrow;
    }
  }

  // Update an existing chore
  Future<void> updateChore(Chore chore) async {
    try {
      if (chore.documentId == null) {
        throw Exception('Cannot update chore without document ID');
      }
      
      await firestore
          .collection(choresCollection)
          .doc(chore.documentId)
          .update(chore.toJson());
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error updating chore: $e');
      }
      rethrow;
    }
  }

  // Delete a chore
  Future<void> deleteChore(String documentId) async {
    try {
      await firestore
          .collection(choresCollection)
          .doc(documentId)
          .delete();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error deleting chore: $e');
      }
      rethrow;
    }
  }

  Future<void> resetAll() async {
    try {
      final QuerySnapshot snapshot = await firestore.collection(choresCollection).get();
      for (final doc in snapshot.docs) {
        await doc.reference.delete();
      }
      debugPrint('All chore data reset.');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error resetting chores data in Firestore: $e');
      }
    }
  }



  // Generate a unique ID for new chores
  Future<int> generateUniqueId() async {
    try {
      final snapshot = await firestore.collection(choresCollection).get();
      int maxId = 0;
      
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final id = data['id'] as int? ?? 0;
        if (id > maxId) {
          maxId = id;
        }
      }
      
      return maxId + 1;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error generating unique ID: $e');
      }
      // Fallback: use timestamp as ID
      return DateTime.now().millisecondsSinceEpoch;
    }
  }

  // Debug method to check current chores in database
  Future<void> debugChores(String userId) async {
    try {
      final memberDoc = await firestore.collection('members').doc(userId).get();
      if (!memberDoc.exists) {
        debugPrint('Member not found for user: $userId');
        return;
      }

      final memberData = memberDoc.data() as Map<String, dynamic>;
      final householdId = memberData['householdId'];

      debugPrint('=== DEBUG CHORES ===');
      debugPrint('User: $userId');
      debugPrint('Household ID: $householdId');
      debugPrint('Mode: ${householdId != null ? 'Household' : 'Single User'}');

      // Get all chores for this user/household
      QuerySnapshot snapshot;
      if (householdId != null) {
        snapshot = await firestore
            .collection(choresCollection)
            .where('householdId', isEqualTo: householdId)
            .get();
      } else {
        snapshot = await firestore
            .collection(choresCollection)
            .where('createdBy', isEqualTo: userId)
            .get();
      }

      debugPrint('Total chores found: ${snapshot.docs.length}');
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        debugPrint('Chore: ${data['name']} | ID: ${data['id']} | CreatedBy: ${data['createdBy']} | HouseholdId: ${data['householdId']}');
      }
      debugPrint('=== END DEBUG ===');
    } catch (e) {
      debugPrint('Error debugging chores: $e');
    }
  }
}