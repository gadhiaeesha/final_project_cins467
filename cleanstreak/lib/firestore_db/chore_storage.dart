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
        // Household Mode: Load all household chores
        debugPrint('Loading household chores for household: $householdId');
        final QuerySnapshot snapshot = await firestore
            .collection(choresCollection)
            .where('householdId', isEqualTo: householdId)
            .get();

        if (snapshot.docs.isNotEmpty) {
          return snapshot.docs
              .where((doc) => doc.data() != null)
              .map((doc) => Chore.fromJson(doc.data() as Map<String, dynamic>))
              .toList();
        } else {
          debugPrint('No household chores found for household: $householdId');
          return [];
        }
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
              .map((doc) => Chore.fromJson(doc.data() as Map<String, dynamic>))
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

  Future<void> writeChoreList(List<Chore> chores, String userId) async {
    try {
      final CollectionReference choreCollection = firestore.collection(choresCollection);
      
      // Get the user's member profile to determine mode
      final memberDoc = await firestore.collection('members').doc(userId).get();
      if (!memberDoc.exists) {
        debugPrint('Member not found for user: $userId');
        return;
      }

      final memberData = memberDoc.data() as Map<String, dynamic>;
      final householdId = memberData['householdId'];

      QuerySnapshot existingChores;
      
      if (householdId != null) {
        // Household Mode: Get existing household chores
        existingChores = await choreCollection
            .where('householdId', isEqualTo: householdId)
            .get();
      } else {
        // Single User Mode: Get existing personal chores
        existingChores = await choreCollection
            .where('createdBy', isEqualTo: userId)
            .where('householdId', isNull: true)
            .get();
      }
      
      // Create a map of existing chores by their ID
      final Map<int, DocumentSnapshot> existingChoresMap = {
        for (var doc in existingChores.docs)
          (doc.data() as Map<String, dynamic>)['id'] as int: doc
      };
      
      // Update or create chores
      for (final chore in chores) {
        if (existingChoresMap.containsKey(chore.id)) {
          // Update existing chore
          await existingChoresMap[chore.id]!.reference.update(chore.toJson());
        } else {
          // Create new chore with random ID
          await choreCollection.add(chore.toJson());
        }
      }
      
      // Delete chores that are no longer in the list
      for (final doc in existingChores.docs) {
        final choreId = (doc.data() as Map<String, dynamic>)['id'] as int;
        if (!chores.any((chore) => chore.id == choreId)) {
          await doc.reference.delete();
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error writing chores list to Firestore: $e');
      }
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