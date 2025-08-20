import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/household.dart';
import '../models/member.dart';
import '../models/chore.dart';
import '../firestore_db/household_storage.dart';
import '../firestore_db/member_storage.dart';
import '../firestore_db/chore_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HouseholdManagement {
  final HouseholdStorage _householdStorage = HouseholdStorage();
  final MemberStorage _memberStorage = MemberStorage();
  final ChoreStorage _choreStorage = ChoreStorage();

  // Leave household functionality
  Future<void> leaveHousehold(String userId) async {
    try {
      // Get the current member
      final member = await _memberStorage.getMember(userId);
      if (member == null) {
        throw Exception('Member not found');
      }

      if (member.householdId == null) {
        throw Exception('User is not part of any household');
      }

      final householdId = member.householdId!;

      // Get the household
      final household = await _householdStorage.getHousehold(householdId);
      if (household == null) {
        throw Exception('Household not found');
      }

      // Check if this is the last member
      if (household.members.length <= 1) {
        // Delete the household if it's the last member
        await _householdStorage.deleteHousehold(householdId);
      } else {
        // Remove the member from the household
        await _householdStorage.removeMember(householdId, userId);
      }

      // Update member's householdId to null
      final updatedMember = Member(
        userId: member.userId,
        email: member.email,
        name: member.name,
        role: member.role,
        joinedAt: member.joinedAt,
        householdId: null, // Remove from household
      );
      await _memberStorage.saveMember(updatedMember);

      // Update chores assigned to this user (set assignedTo to null)
      await _updateAssignedChores(userId, householdId);

    } catch (e) {
      rethrow;
    }
  }

  // Update chores assigned to the leaving user
  Future<void> _updateAssignedChores(String userId, String householdId) async {
    try {
      // Get all household chores
      final householdChores = await _choreStorage.readChoreList(userId);
      
      // Update chores assigned to the leaving user
      for (final chore in householdChores) {
        if (chore.householdId == householdId && chore.assignedTo == userId) {
          // Create updated chore with assignedTo = null
          final updatedChore = Chore(
            id: chore.id,
            name: chore.name,
            description: chore.description,
            isCompleted: chore.isCompleted,
            completeBy: chore.completeBy,
            completionDate: chore.completionDate,
            householdId: chore.householdId,
            assignedTo: null, // Remove assignment
            createdBy: chore.createdBy,
          );
          
          // Update the chore in the database
          await _choreStorage.updateChore(updatedChore);
        }
      }
    } catch (e) {
      // Log error but don't fail the leave process
      print('Error updating assigned chores: $e');
    }
  }
}
