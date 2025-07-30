class Chore {
  int id;
  String name;
  String description;
  bool isCompleted;
  DateTime? completionDate;  // When the chore was actually completed
  DateTime? completeBy;      // When the chore needs to be completed by
  String? householdId;
  String? assignedTo;
  String? createdBy;        // The user ID of who created the chore

  Chore({
    required this.id,
    required this.name,
    required this.description,
    this.isCompleted = false,
    this.completionDate,
    this.completeBy,
    this.householdId,
    this.assignedTo,
    this.createdBy,
  });

  // Method to serialize the object to JSON format
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'isCompleted': isCompleted,
      'completionDate': completionDate?.toIso8601String(),
      'completeBy': completeBy?.toIso8601String(),
      'householdId': householdId,
      'assignedTo': assignedTo,
      'createdBy': createdBy,
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
      completeBy: data['completeBy'] != null 
          ? DateTime.parse(data['completeBy']) 
          : null,
      householdId: data['householdId'],
      assignedTo: data['assignedTo'],
      createdBy: data['createdBy'],
    );
  }
}