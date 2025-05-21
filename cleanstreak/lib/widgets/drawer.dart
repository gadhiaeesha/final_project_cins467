import 'package:flutter/material.dart';
import '../models/household.dart';
import '../firestore_db/household_storage.dart';
import '../firestore_db/member_storage.dart';
import '../dialogs/create_house.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HouseholdDrawer extends StatefulWidget {
  const HouseholdDrawer({super.key});

  @override
  State<HouseholdDrawer> createState() => _HouseholdDrawerState();
}

class _HouseholdDrawerState extends State<HouseholdDrawer> {
  final HouseholdStorage _storage = HouseholdStorage();
  final MemberStorage _memberStorage = MemberStorage();
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
              children: [
                Icon(
                  Icons.home_work,
                  size: 32,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 16),
                Text(
                  'Household Management',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
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
                            Text(
                              _currentHousehold!.name,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Members: ${_currentHousehold!.members.length}',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
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