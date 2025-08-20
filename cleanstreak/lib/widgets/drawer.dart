import 'package:flutter/material.dart';
import '../models/household.dart';
import '../firestore_db/household_storage.dart';
import '../firestore_db/member_storage.dart';
import '../services/household_management.dart';
import '../dialogs/create_house.dart';
import '../dialogs/send_invite.dart';
import '../dialogs/household_settings.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HouseholdDrawer extends StatefulWidget {
  final VoidCallback? onHouseholdLeft;
  
  const HouseholdDrawer({super.key, this.onHouseholdLeft});

  @override
  State<HouseholdDrawer> createState() => _HouseholdDrawerState();
}

class _HouseholdDrawerState extends State<HouseholdDrawer> {
  final HouseholdStorage _storage = HouseholdStorage();
  final MemberStorage _memberStorage = MemberStorage();
  final HouseholdManagement _householdManagement = HouseholdManagement();
  Household? _currentHousehold;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserHousehold();
  }

  Future<void> _loadUserHousehold() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        // Get the member's profile
        final member = await _memberStorage.getMember(currentUser.uid);
        if (member != null && member.householdId != null) {
          // Get the household using the member's householdId
          final household = await _storage.getHousehold(member.householdId!);
          if (household != null) {
            setState(() {
              _currentHousehold = household;
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading household: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showCreateHouseDialog() {
    showDialog(
      context: context,
      builder: (context) => CreateHouseDialog(
        storage: _storage,
        onHouseholdCreated: (household) {
          setState(() {
            _currentHousehold = household;
          });
        },
      ),
    );
  }

  void _showSendInviteDialog() {
    if (_currentHousehold != null) {
      showDialog(
        context: context,
        builder: (context) => SendInviteDialog(
          householdId: _currentHousehold!.id,
          householdName: _currentHousehold!.name,
        ),
      );
    }
  }

  void _showHouseholdSettingsDialog() {
    if (_currentHousehold != null) {
      showDialog(
        context: context,
        builder: (context) => HouseholdSettingsDialog(
          householdId: _currentHousehold!.id,
          householdName: _currentHousehold!.name,
        ),
      );
    }
  }

  void _showLeaveConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Household'),
        content: const Text('Are you sure you want to leave this household? You will no longer have access to household chores.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _leaveHousehold();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Household'),
        content: const Text('Are you sure you want to delete this household? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _deleteHousehold();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _leaveHousehold() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      await _householdManagement.leaveHousehold(currentUser.uid);
      
      if (mounted) {
        setState(() {
          _currentHousehold = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully left the household'),
          ),
        );
        
        // Notify parent widget
        widget.onHouseholdLeft?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error leaving household: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _deleteHousehold() async {
    if (_currentHousehold == null) return;

    try {
      await _storage.deleteHousehold(_currentHousehold!.id);
      if (mounted) {
        setState(() {
          _currentHousehold = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Household deleted successfully'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting household: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.33,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 25),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.home_work,
                  size: 32,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Household\nManagement',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _currentHousehold == null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.home_outlined,
                                size: 64,
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'You are not part of any household',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                ),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: _showCreateHouseDialog,
                                icon: const Icon(Icons.add_home),
                                label: const Text('Create a Household'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _currentHousehold!.name,
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.people,
                                        size: 16,
                                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${_currentHousehold!.members.length}',
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Members',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                            const SizedBox(height: 8),
                            ..._currentHousehold!.members.map((member) => Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                    child: Text(
                                      member.name?[0].toUpperCase() ?? '?',
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          member.name ?? 'Unnamed Member',
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          member.email,
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.surfaceVariant,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'member',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )).toList(),
                            const Spacer(),
                            ElevatedButton.icon(
                              onPressed: _showHouseholdSettingsDialog,
                              icon: const Icon(Icons.settings),
                              label: const Text('Settings'),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: _showSendInviteDialog,
                              icon: const Icon(Icons.person_add),
                              label: const Text('Invite Member'),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: _showLeaveConfirmationDialog,
                              icon: const Icon(Icons.exit_to_app),
                              label: const Text('Leave Household'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: () => _showDeleteConfirmationDialog(),
                              icon: const Icon(Icons.delete_forever),
                              label: const Text('Delete Household'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.error,
                                foregroundColor: Theme.of(context).colorScheme.onError,
                              ),
                            ),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }
} 