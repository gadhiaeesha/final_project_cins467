import 'package:cleanstreak/models/chore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class ChoreStorage {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final String choresCollection = 'chores';

  ChoreStorage();

  Future<List<Chore>> readChoreList(String householdId) async {
    try {
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
        debugPrint('No chores found for household: $householdId');
        return [];
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error reading chores list from Firestore: $e');
      }
      return [];
    }
  }

  Future<void> writeChoreList(List<Chore> chores, String householdId) async {
    try {
      final CollectionReference choreCollection = firestore.collection(choresCollection);

      // Delete existing chores for this household
      final QuerySnapshot existingChores = await choreCollection
          .where('householdId', isEqualTo: householdId)
          .get();
      
      for (final doc in existingChores.docs) {
        await doc.reference.delete();
      }

      // Add the new list of chores using their names as document IDs
      for (final chore in chores) {
        // Sanitize the chore name to be a valid document ID
        final docId = chore.name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
        await choreCollection.doc(docId).set(chore.toJson());
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