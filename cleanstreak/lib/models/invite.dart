class Invite {
  final String email;
  final String householdId;
  final String invitedBy;
  final String status; // 'pending', 'accepted', 'rejected'
  final DateTime createdAt;

  Invite({
    required this.email,
    required this.householdId,
    required this.invitedBy,
    required this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'householdId': householdId,
      'invitedBy': invitedBy,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Invite.fromJson(Map<String, dynamic> data) {
    return Invite(
      email: data['email'],
      householdId: data['householdId'],
      invitedBy: data['invitedBy'],
      status: data['status'],
      createdAt: DateTime.parse(data['createdAt']),
    );
  }
} 