import 'package:flutter/material.dart';

class HouseholdSettingsDialog extends StatefulWidget {
  final String householdName;
  final String householdId;

  const HouseholdSettingsDialog({
    Key? key,
    required this.householdName,
    required this.householdId,
  }) : super(key: key);

  @override
  State<HouseholdSettingsDialog> createState() => _HouseholdSettingsDialogState();
}

class _HouseholdSettingsDialogState extends State<HouseholdSettingsDialog> {
  String _selectedIcon = 'home_work';
  Color _selectedColor = Colors.blue;
  bool _useBackgroundColor = false; // Toggle between icon and background color

  final List<Map<String, dynamic>> _iconOptions = [
    {'name': 'Home', 'icon': 'home_work', 'color': Colors.blue},
    {'name': 'Family', 'icon': 'family_restroom', 'color': Colors.green},
    {'name': 'Team', 'icon': 'groups', 'color': Colors.orange},
    {'name': 'Community', 'icon': 'public', 'color': Colors.purple},
    {'name': 'Building', 'icon': 'apartment', 'color': Colors.red},
    {'name': 'Star', 'icon': 'star', 'color': Colors.amber},
  ];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.5,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.settings,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Household Settings',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              widget.householdName,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Visual Style',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                Switch(
                  value: _useBackgroundColor,
                  onChanged: (value) {
                    setState(() {
                      _useBackgroundColor = value;
                    });
                  },
                ),
                Text(
                  _useBackgroundColor ? 'Background Color' : 'Icon Only',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _useBackgroundColor 
                  ? 'Household chores will have a colored background'
                  : 'Choose the icon that appears next to household chores:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
            ),
            if (!_useBackgroundColor) ...[
              const SizedBox(height: 16),
              Text(
                'Household Chore Icon',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              'Choose the icon that appears next to household chores:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
            ),
            if (!_useBackgroundColor) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _iconOptions.map((option) {
                final isSelected = _selectedIcon == option['icon'] && 
                                 _selectedColor == option['color'];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedIcon = option['icon'];
                      _selectedColor = option['color'];
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected 
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.outline.withOpacity(0.3),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                                         child: Column(
                       children: [
                         Icon(
                           _getIconData(option['icon']),
                           size: 32,
                           color: option['color'],
                         ),
                         const SizedBox(height: 8),
                         Text(
                           option['name'],
                           style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                 fontWeight: FontWeight.w500,
                               ),
                         ),
                       ],
                     ),
                  ),
                );
              }).toList(),
            ),
            ],
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Save settings to database
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Household settings saved'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.save),
                  label: const Text('Save Settings'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'home_work':
        return Icons.home_work;
      case 'family_restroom':
        return Icons.family_restroom;
      case 'groups':
        return Icons.groups;
      case 'public':
        return Icons.public;
      case 'apartment':
        return Icons.apartment;
      case 'star':
        return Icons.star;
      default:
        return Icons.home_work;
    }
  }
} 