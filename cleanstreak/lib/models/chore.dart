class Chore {
  int id;
  String name;
  String description;
  bool isCompleted;
  DateTime? completionDate;

  Chore({
    required this.id,
    required this.name,
    required this.description,
    this.isCompleted = false,
    this.completionDate,
  });

  // Method to serialize the object to JSON format
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'isCompleted': isCompleted,
      'completionDate': completionDate?.toIso8601String(),
    };
  }

  // Factory constructor to deserialize JSON format to object
  factory Chore.fromJson(Map<String, dynamic> data) {
    return Chore(
      id: data['id'],
      name: data['name'],
      description: data['description'],
      isCompleted: data['isCompleted'] ?? false,
      completionDate: data['completionDate'] != null
          ? DateTime.parse(data['completionDate'])
          : null,
    );
  }
}