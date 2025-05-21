class Member {
  final String userId;
  String? name;
  final String email;
  String? role; // 'admin' or 'member'
  final DateTime joinedAt;
  String? householdId;

  Member({
    required this.userId,
    this.name,
    required this.email,
    this.role,
    required this.joinedAt,
    this.householdId,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': name,
      'email': email,
      'role': role,
      'joinedAt': joinedAt.toIso8601String(),
      'householdId': householdId,
    };
  }

  factory Member.fromJson(Map<String, dynamic> data) {
    return Member(
      userId: data['userId'],
      name: data['name'] ?? '',
      email: data['email'],
      role: data['role'] ?? 'member',
      joinedAt: DateTime.parse(data['joinedAt']),
      householdId: data['householdId'],
    );
  }
}