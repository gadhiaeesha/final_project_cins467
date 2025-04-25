import 'package:cleanstreak/models/chore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class ChoreStorage {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final String choresCollection = 'chores';

  ChoreStorage();

  Future<List<Chore>> readChoreList() async {
    try {
      final QuerySnapshot snapshot = await firestore.collection('chores').get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs
            .where((doc) => doc.data() != null)
            .map((doc) => Chore.fromJson(doc.data() as Map<String, dynamic>))
            .toList();
      } else {
        debugPrint('No documents found in the houses collection.');
        return [];
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error reading house list from Firestore: $e');
      }
      return [];
    }
  }

  Future<void> writeChoreList(List<Chore> chores) async {
    try {
      final CollectionReference choreCollection = firestore.collection('chores');

      // Clear the existing collection (optional, based on your requirements)
      final QuerySnapshot existingChores = await choreCollection.get();
      for (final doc in existingChores.docs) {
        await doc.reference.delete();
      }

      // Add the new list of households
      for (final chore in chores) {
        await choreCollection.add(chore.toJson());
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error writing house list to Firestore: $e');
      }
    }
  }

  Future<void> resetAll() async {
    try {
      final QuerySnapshot snapshot = await firestore.collection('chores').get();
      for (final doc in snapshot.docs) {
        await doc.reference.delete();
      }
      debugPrint('All chore data reset.');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error resetting chore data in Firestore: $e');
      }
    }
  }
}