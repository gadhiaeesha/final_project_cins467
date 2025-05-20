import 'package:cleanstreak/models/chore.dart';
import 'package:cleanstreak/firestore_db/firebase_storage.dart';

class ChoreManagement {
  final ChoreStorage storage;

  ChoreManagement(this.storage);

  Future<List<Chore>> loadChores() async {
    return await storage.readChoreList();
  }

  Future<void> saveChores(List<Chore> chores) async {
    await storage.writeChoreList(chores);
  }

  Chore addChore(String name, String description, DateTime? completeBy, List<Chore> existingChores) {
    Chore newChore = Chore(
      id: existingChores.length,
      name: name,
      description: description,
      isCompleted: false,
      completeBy: completeBy,
      completionDate: null,
    );
    return newChore;
  }

  void deleteChore(int id, List<Chore> chores) {
    chores.removeWhere((chore) => chore.id == id);
  }

  void toggleCompletion(int id, bool isCompleted, List<Chore> chores) {
    for (var chore in chores) {
      if (chore.id == id) {
        chore.isCompleted = isCompleted;
        if (isCompleted) {
          chore.completionDate = DateTime.now();
        } else {
          chore.completionDate = null;
        }
        break;
      }
    }
  }

  int getUnfinishedChoresCount(List<Chore> chores) {
    return chores.where((chore) => !chore.isCompleted).length;
  }
} 