import 'package:flutter/material.dart';
import 'package:cleanstreak/models/chore.dart';
import 'package:cleanstreak/widgets/chore_container.dart';

class ChoreDetailsWidget extends StatelessWidget {
  final Chore selectedChore;
  final Function(int, bool) onToggleComplete;

  const ChoreDetailsWidget({
    super.key,
    required this.selectedChore,
    required this.onToggleComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      height: MediaQuery.of(context).size.height / 2,
      decoration: BoxDecoration(
        border: Border.all(),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.inversePrimary,
              border: const Border(bottom: BorderSide(width: 1)),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(7.0),
                topRight: Radius.circular(7.0),
              ),
            ),
            child: Text(
              'Chore Details: ${selectedChore.name}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Description:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  selectedChore.description,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Completion Status:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                CheckboxListTile(
                  title: const Text('Completed'),
                  value: selectedChore.isCompleted,
                  onChanged: (bool? value) {
                    if (value != null) {
                      onToggleComplete(selectedChore.id, value);
                    }
                  },
                ),
                if (selectedChore.completeBy != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Complete By: ${selectedChore.completeBy!.day}/${selectedChore.completeBy!.month}/${selectedChore.completeBy!.year}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
                if (selectedChore.completionDate != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Completed On: ${selectedChore.completionDate!.day}/${selectedChore.completionDate!.month}/${selectedChore.completionDate!.year}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MasterChoresListWidget extends StatelessWidget {
  final List<Chore> chores;
  final Chore? selectedChore;
  final Function(Chore) onSelect;
  final Function(Chore) onDelete;
  final Function(Chore, bool) onToggleComplete;
  final VoidCallback onAddChore;

  const MasterChoresListWidget({
    super.key,
    required this.chores,
    required this.selectedChore,
    required this.onSelect,
    required this.onDelete,
    required this.onToggleComplete,
    required this.onAddChore,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width / 3,
      height: MediaQuery.of(context).size.height / 2,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.cleaning_services,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 8),
                Text(
                  'Master Chores List',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: chores.length,
              itemBuilder: (context, index) {
                final chore = chores[index];
                return Dismissible(
                  key: Key(chore.id.toString()),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20.0),
                    child: const Icon(
                      Icons.delete,
                      color: Colors.white,
                    ),
                  ),
                  onDismissed: (direction) {
                    onDelete(chore);
                  },
                  child: ChoreContainer(
                    key: ValueKey(chore.id),
                    chore: chore,
                    onSelect: onSelect,
                    onDelete: onDelete,
                    onToggleComplete: onToggleComplete,
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('All Chores: ${chores.length}'),
                SizedBox(
                  width: 45,
                  height: 45,
                  child: FloatingActionButton(
                    onPressed: onAddChore,
                    child: const Icon(
                      Icons.add,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 