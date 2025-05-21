import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/member.dart';

class MemberStorage {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final String membersCollection = 'members';

  MemberStorage();

  // Get a member by user ID
  Future<Member?> getMember(String userId) async {
    try {
      final doc = await firestore.collection(membersCollection).doc(userId.toString()).get();
      if (doc.exists) {
        return Member.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting member: $e');
      }
      return null;
    }
  }

  // Create or update a member
  Future<void> saveMember(Member member) async {
    try {
      await firestore.collection(membersCollection).doc(member.userId).set(member.toJson());
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error saving member: $e');
      }
      rethrow;
    }
  }

  // Get all members in a household
  Future<List<Member>> getHouseholdMembers(String householdId) async {
    try {
      final querySnapshot = await firestore
          .collection(membersCollection)
          .where('householdId', isEqualTo: householdId)
          .get();

      return querySnapshot.docs
          .map((doc) => Member.fromJson(doc.data()))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting household members: $e');
      }
      return [];
    }
  }

  // Update member role
  Future<void> updateMemberRole(String userId, String newRole) async {
    try {
      await firestore.collection(membersCollection).doc(userId.toString()).update({
        'role': newRole
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error updating member role: $e');
      }
      rethrow;
    }
  }

  // Delete a member
  Future<void> deleteMember(String userId) async {
    try {
      await firestore.collection(membersCollection).doc(userId.toString()).delete();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error deleting member: $e');
      }
      rethrow;
    }
  }
}
