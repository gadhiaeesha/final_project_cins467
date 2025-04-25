class Chore {
  int id;
  String name;
  String description;
  bool isCompleted;

  Chore({
    required this.id,
    required this.name,
    required this.description,
    this.isCompleted = false, // Default to false if not provided
  });

  // Method to serialize the object to JSON format
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'isCompleted': isCompleted,
    };
  }

  // Factory constructor to deserialize JSON format to object
  factory Chore.fromJson(Map<String, dynamic> data) {
    return Chore(
      id: data['id'],
      name: data['name'],
      description: data['description'],
      isCompleted: data['isCompleted'] ?? false, // Ensure backward compatibility
    );
  }
}