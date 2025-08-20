import 'package:cleanstreak/models/chore.dart';
import 'package:flutter/material.dart';

class ChoreContainer extends StatefulWidget {
  final Chore chore;
  final Function(Chore) onSelect;
  final Function(Chore) onDelete;
  final Function(Chore, bool) onToggleComplete;

  const ChoreContainer({
    Key? key,
    required this.chore,
    required this.onSelect,
    required this.onDelete,
    required this.onToggleComplete,
  }) : super(key: key);

  @override
  _ChoreContainerState createState() => _ChoreContainerState();
}

class _ChoreContainerState extends State<ChoreContainer> {
  bool isHovered = false;

  Color _getBackgroundColor() {
    if (isHovered) {
      return Theme.of(context).colorScheme.primary.withAlpha((0.1 * 255).round());
    }
    
    // For now, use simple background color differentiation
    // TODO: Get this from household settings
    if (widget.chore.householdId != null) {
      return Theme.of(context).colorScheme.primaryContainer.withOpacity(0.1);
    }
    
    return Colors.transparent;
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: GestureDetector(
        onTap: () => widget.onSelect(widget.chore),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
          margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
          decoration: BoxDecoration(
            color: _getBackgroundColor(),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
            border: const Border(
              bottom: BorderSide(width: 1),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Checkbox(
                      value: widget.chore.isCompleted,
                      onChanged: (bool? newValue) {
                        if (newValue != null) {
                          widget.onToggleComplete(widget.chore, newValue);
                        }
                      },
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          // Simple icon indicator for household vs personal chores
                          if (widget.chore.householdId != null) ...[
                            Icon(
                              Icons.home_work,
                              size: 16,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                          ] else ...[
                            Icon(
                              Icons.person,
                              size: 16,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Expanded(
                            child: Text(
                              widget.chore.name,
                              style: TextStyle(
                                fontSize: 16,
                                decoration: widget.chore.isCompleted
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                                color: widget.chore.isCompleted
                                    ? Colors.grey
                                    : Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (isHovered)
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => widget.onDelete(widget.chore),
                ),
            ],
          ),
        ),
      ),
    );
  }
}