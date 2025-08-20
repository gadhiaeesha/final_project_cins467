import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/invite.dart';
import '../models/member.dart';
import '../firestore_db/invite_storage.dart';
import '../firestore_db/member_storage.dart';
import '../firestore_db/household_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

class InviteManagement {
  final InviteStorage _inviteStorage = InviteStorage();
  final MemberStorage _memberStorage = MemberStorage();
  final HouseholdStorage _householdStorage = HouseholdStorage();

  // Send invite to a user by email
  Future<void> sendInvite(String email, String householdId, String invitedBy) async {
    try {
      // First, check if the user exists in the members database
      final member = await _findMemberByEmail(email);
      if (member == null) {
        throw Exception('User with email $email needs to sign up and create a member profile before they can be invited to a household.');
      }

      // Check if user is already in a household
      if (member.householdId != null) {
        throw Exception('User is already part of a household.');
      }

      // Check if there's already a pending invite for this user to this household
      final existingInvites = await _inviteStorage.getInvitesReceivedByUser(member.userId);
      final hasPendingInvite = existingInvites.any((invite) => 
        invite.householdId == householdId && invite.status == 'pending');
      
      if (hasPendingInvite) {
        throw Exception('User already has a pending invite to this household.');
      }

      // Create the invite
      final invite = Invite(
        inviteFrom: invitedBy,
        inviteTo: member.userId,
        householdId: householdId,
        status: 'pending',
        createdAt: DateTime.now(),
      );

      await _inviteStorage.createInvite(invite);
    } catch (e) {
      rethrow;
    }
  }

  // Accept an invite
  Future<void> acceptInvite(String inviteId, String userId) async {
    try {
      // Get the invite
      final invite = await _inviteStorage.getInvite(inviteId);
      if (invite == null) {
        throw Exception('Invite not found.');
      }

      if (invite.inviteTo != userId) {
        throw Exception('You can only accept invites sent to you.');
      }

      if (invite.status != 'pending') {
        throw Exception('This invite is no longer pending.');
      }

      // Get the member and household
      final member = await _memberStorage.getMember(userId);
      final household = await _householdStorage.getHousehold(invite.householdId);
      
      if (member == null || household == null) {
        throw Exception('Member or household not found.');
      }

      // Update the invite status
      await _inviteStorage.updateInviteStatus(inviteId, 'accepted');

      // Update the member's householdId
      final updatedMember = Member(
        userId: member.userId,
        email: member.email,
        name: member.name,
        role: member.role,
        joinedAt: member.joinedAt,
        householdId: invite.householdId,
      );
      await _memberStorage.saveMember(updatedMember);

      // Add member to household
      await _householdStorage.addMember(invite.householdId, updatedMember);
    } catch (e) {
      rethrow;
    }
  }

  // Decline an invite
  Future<void> declineInvite(String inviteId, String userId) async {
    try {
      // Get the invite
      final invite = await _inviteStorage.getInvite(inviteId);
      if (invite == null) {
        throw Exception('Invite not found.');
      }

      if (invite.inviteTo != userId) {
        throw Exception('You can only decline invites sent to you.');
      }

      if (invite.status != 'pending') {
        throw Exception('This invite is no longer pending.');
      }

      // Update the invite status
      await _inviteStorage.updateInviteStatus(inviteId, 'declined');
    } catch (e) {
      rethrow;
    }
  }

  // Get pending invites for a user
  Future<List<Invite>> getPendingInvites(String userId) async {
    try {
      return await _inviteStorage.getPendingInvites(userId);
    } catch (e) {
      rethrow;
    }
  }

  // Get all invites for a user (sent and received)
  Future<Map<String, List<Invite>>> getUserInvites(String userId) async {
    try {
      final sentInvites = await _inviteStorage.getInvitesSentByUser(userId);
      final receivedInvites = await _inviteStorage.getInvitesReceivedByUser(userId);
      
      return {
        'sent': sentInvites,
        'received': receivedInvites,
      };
    } catch (e) {
      rethrow;
    }
  }

  // Helper method to find member by email
  Future<Member?> _findMemberByEmail(String email) async {
    try {
      // Query members collection by email
      final querySnapshot = await FirebaseFirestore.instance
          .collection('members')
          .where('email', isEqualTo: email)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return Member.fromJson(querySnapshot.docs.first.data());
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Delete an invite (for cleanup)
  Future<void> deleteInvite(String inviteId) async {
    try {
      await _inviteStorage.deleteInvite(inviteId);
    } catch (e) {
      rethrow;
    }
  }
}
