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
            color: isHovered
                ? Theme.of(context).colorScheme.primary.withAlpha((0.1 * 255).round())
                : Colors.transparent,
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
              Row(
                children: [
                  Checkbox(
                    value: widget.chore.isCompleted,
                    onChanged: (bool? newValue) {
                      if (newValue != null) {
                        widget.onToggleComplete(widget.chore, newValue);
                      }
                    },
                  ),
                  Text(
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
                ],
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