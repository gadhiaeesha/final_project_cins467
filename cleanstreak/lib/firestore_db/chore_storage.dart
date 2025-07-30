import 'package:cleanstreak/models/chore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class ChoreStorage {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final String choresCollection = 'chores';

  ChoreStorage();

  Future<List<Chore>> readChoreList(String userId) async {
    try {
      final QuerySnapshot snapshot = await firestore
          .collection(choresCollection)
          .where('createdBy', isEqualTo: userId)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs
            .where((doc) => doc.data() != null)
            .map((doc) => Chore.fromJson(doc.data() as Map<String, dynamic>))
            .toList();
      } else {
        debugPrint('No chores found for user: $userId');
        return [];
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
      
      // Get existing chores for this user
      final QuerySnapshot existingChores = await choreCollection
          .where('createdBy', isEqualTo: userId)
          .get();
      
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
}