import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/invite.dart';

class InviteStorage {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final String invitesCollection = 'household_invites';

  InviteStorage();

  // Create a new invite
  Future<String> createInvite(Invite invite) async {
    try {
      final docRef = await firestore.collection(invitesCollection).add(invite.toJson());
      return docRef.id;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error creating invite: $e');
      }
      rethrow;
    }
  }

  // Get an invite by ID
  Future<Invite?> getInvite(String inviteId) async {
    try {
      final doc = await firestore.collection(invitesCollection).doc(inviteId).get();
      if (doc.exists) {
        return Invite.fromJson(doc.data()!, id: doc.id);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting invite: $e');
      }
      return null;
    }
  }

  // Get all pending invites for a user
  Future<List<Invite>> getPendingInvites(String userId) async {
    try {
      final querySnapshot = await firestore
          .collection(invitesCollection)
          .where('inviteTo', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .get();

      return querySnapshot.docs
          .map((doc) => Invite.fromJson(doc.data(), id: doc.id))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting pending invites: $e');
      }
      return [];
    }
  }

  // Get all invites for a household
  Future<List<Invite>> getHouseholdInvites(String householdId) async {
    try {
      final querySnapshot = await firestore
          .collection(invitesCollection)
          .where('householdId', isEqualTo: householdId)
          .get();

      return querySnapshot.docs
          .map((doc) => Invite.fromJson(doc.data(), id: doc.id))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting household invites: $e');
      }
      return [];
    }
  }

  // Get all invites sent by a user
  Future<List<Invite>> getInvitesSentByUser(String userId) async {
    try {
      final querySnapshot = await firestore
          .collection(invitesCollection)
          .where('inviteFrom', isEqualTo: userId)
          .get();

      return querySnapshot.docs
          .map((doc) => Invite.fromJson(doc.data(), id: doc.id))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting invites sent by user: $e');
      }
      return [];
    }
  }

  // Get all invites received by a user
  Future<List<Invite>> getInvitesReceivedByUser(String userId) async {
    try {
      final querySnapshot = await firestore
          .collection(invitesCollection)
          .where('inviteTo', isEqualTo: userId)
          .get();

      return querySnapshot.docs
          .map((doc) => Invite.fromJson(doc.data(), id: doc.id))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting invites received by user: $e');
      }
      return [];
    }
  }

  // Update invite status
  Future<void> updateInviteStatus(String inviteId, String status) async {
    try {
      await firestore.collection(invitesCollection).doc(inviteId).update({
        'status': status
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error updating invite status: $e');
      }
      rethrow;
    }
  }

  // Delete an invite
  Future<void> deleteInvite(String inviteId) async {
    try {
      await firestore.collection(invitesCollection).doc(inviteId).delete();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error deleting invite: $e');
      }
      rethrow;
    }
  }
}
