import 'package:cloud_firestore/cloud_firestore.dart';
import 'member.dart';

class Household {
  final String id;
  final String name;
  final List<Member> members;
  final DateTime createdAt;
  final List<String> choreIds;

  Household({
    required this.id,
    required this.name,
    required this.members,
    required this.createdAt,
    List<String>? choreIds,
  }) : choreIds = choreIds ?? [];

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'members': members.map((member) => member.toJson()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'choreIds': choreIds,
    };
  }

  factory Household.fromJson(Map<String, dynamic> json, {String? docId}) {
    return Household(
      id: docId ?? json['id'] as String,
      name: json['name'] as String,
      members: (json['members'] as List)
          .map((memberJson) => Member.fromJson(memberJson as Map<String, dynamic>))
          .toList(),
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      choreIds: (json['choreIds'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }
}
