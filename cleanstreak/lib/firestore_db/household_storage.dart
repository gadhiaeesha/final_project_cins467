import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/household.dart';
import '../models/member.dart';
import '../models/invite.dart';

class HouseholdStorage {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'households';
  final String invitesCollection = 'household_invites';

  HouseholdStorage();

  // Create a new household
  Future<String> createHousehold(String name, Member creator) async {
    try {
      // Create the household with an auto-generated document ID
      DocumentReference docRef = await _firestore.collection(_collection).add({
        'name': name,
        'members': [creator.toJson()],
        'createdAt': FieldValue.serverTimestamp(),
        'choreIds': [],
      });
      
      return docRef.id;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error creating household: $e');
      }
      rethrow;
    }
  }

  // Get a household by ID
  Future<Household?> getHousehold(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      if (doc.exists) {
        return Household.fromJson(doc.data()!, docId: doc.id);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting household: $e');
      }
      return null;
    }
  }

  // Get all households for a user
  Future<List<Household>> getUserHouseholds(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('members', arrayContains: {'userId': userId})
          .get();

      return querySnapshot.docs
          .map((doc) => Household.fromJson(doc.data(), docId: doc.id))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting user households: $e');
      }
      return [];
    }
  }

  // Add a member to a household
  Future<void> addMember(String householdId, Member member) async {
    try {
      await _firestore.collection(_collection).doc(householdId).update({
        'members': FieldValue.arrayUnion([member.toJson()])
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error adding member to household: $e');
      }
      rethrow;
    }
  }

  // Remove a member from a household
  Future<void> removeMember(String householdId, String userId) async {
    try {
      final household = await getHousehold(householdId);
      if (household != null) {
        final updatedMembers = household.members
            .where((member) => member.userId != userId)
            .map((member) => member.toJson())
            .toList();
        
        await _firestore.collection(_collection).doc(householdId).update({
          'members': updatedMembers
        });
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error removing member from household: $e');
      }
      rethrow;
    }
  }

  // Create an invite
  Future<void> createInvite(Invite invite) async {
    try {
      await _firestore.collection(invitesCollection).add(invite.toJson());
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error creating invite: $e');
      }
      rethrow;
    }
  }

  // Get pending invites for a user
  Future<List<Invite>> getPendingInvites(String email) async {
    try {
      final querySnapshot = await _firestore
          .collection(invitesCollection)
          .where('email', isEqualTo: email)
          .where('status', isEqualTo: 'pending')
          .get();

      return querySnapshot.docs
          .map((doc) => Invite.fromJson(doc.data()))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting pending invites: $e');
      }
      return [];
    }
  }

  // Update invite status
  Future<void> updateInviteStatus(String inviteId, String status) async {
    try {
      await _firestore.collection(invitesCollection).doc(inviteId).update({
        'status': status
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error updating invite status: $e');
      }
      rethrow;
    }
  }

  // Delete a household
  Future<void> deleteHousehold(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error deleting household: $e');
      }
      rethrow;
    }
  }

  // Update a member in a household
  Future<void> updateMember(String householdId, Member member) async {
    try {
      final household = await getHousehold(householdId);
      if (household != null) {
        final updatedMembers = household.members.map((m) {
          if (m.userId == member.userId) {
            return member;
          }
          return m;
        }).toList();

        await _firestore.collection(_collection).doc(householdId).update({
          'members': updatedMembers.map((m) => m.toJson()).toList(),
        });
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error updating member in household: $e');
      }
      rethrow;
    }
  }

  // Update specific fields of a household
  Future<void> updateHousehold(String id, Map<String, dynamic> data) async {
    try {
      await _firestore.collection(_collection).doc(id).update(data);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error updating household: $e');
      }
      rethrow;
    }
  }

  // Get all households
  Future<List<Household>> getAllHouseholds() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection(_collection).get();
      return snapshot.docs
          .map((doc) => Household.fromJson(doc.data() as Map<String, dynamic>, docId: doc.id))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting all households: $e');
      }
      return [];
    }
  }
}
