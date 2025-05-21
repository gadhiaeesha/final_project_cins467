import 'member.dart';

class Household {
  final String id;
  final String name;
  final List<Member> members;

  Household({
    required this.id,
    required this.name,
    required this.members,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'members': members.map((member) => member.toJson()).toList(),
    };
  }

  factory Household.fromJson(Map<String, dynamic> data, {String? docId}) {
    return Household(
      id: docId ?? data['id'] ?? '',
      name: data['name'] ?? '',
      members: (data['members'] as List?)
          ?.map((memberData) => Member.fromJson(memberData))
          .toList() ?? [],
    );
  }
}
