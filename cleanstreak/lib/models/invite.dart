class Invite {
  final String? id;         // Document ID from Firestore
  final String inviteFrom;  // User ID of the person sending the invite
  final String inviteTo;    // User ID of the person receiving the invite
  final String householdId; // ID of the household they're being invited to
  final String status;      // 'pending', 'accepted', 'declined', 'left household'
  final DateTime createdAt;

  Invite({
    this.id,
    required this.inviteFrom,
    required this.inviteTo,
    required this.householdId,
    required this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'inviteFrom': inviteFrom,
      'inviteTo': inviteTo,
      'householdId': householdId,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Invite.fromJson(Map<String, dynamic> data, {String? id}) {
    return Invite(
      id: id,
      inviteFrom: data['inviteFrom'],
      inviteTo: data['inviteTo'],
      householdId: data['householdId'],
      status: data['status'],
      createdAt: DateTime.parse(data['createdAt']),
    );
  }
} 