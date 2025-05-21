import 'package:flutter/material.dart';
import '../models/household.dart';
import '../models/member.dart';
import '../firestore_db/household_storage.dart';
import '../firestore_db/member_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer' as developer;

class CreateHouseDialog extends StatefulWidget {
  final HouseholdStorage storage;
  final Function(Household) onHouseholdCreated;

  const CreateHouseDialog({
    super.key,
    required this.storage,
    required this.onHouseholdCreated,
  });

  @override
  State<CreateHouseDialog> createState() => _CreateHouseDialogState();
}

class _CreateHouseDialogState extends State<CreateHouseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _memberStorage = MemberStorage();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _createHousehold() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser == null) {
          throw Exception('No user is signed in');
        }

        developer.log('Creating household for user: ${currentUser.uid}');
        developer.log('User email: ${currentUser.email}');

        // Get the member's information
        final existingMember = await _memberStorage.getMember(currentUser.uid);
        if (existingMember == null) {
          throw Exception('Member profile not found. Please complete your profile first.');
        }

        // Create the creator member
        final creator = Member(
          userId: currentUser.uid,
          email: currentUser.email ?? '',
          name: existingMember.name,
          role: 'admin',
          joinedAt: DateTime.now(),
        );

        developer.log('Created member object: ${creator.toString()}');

        // Create the household
        final householdId = await widget.storage.createHousehold(
          _nameController.text.trim(),
          creator,
        );

        // Update the creator's householdId
        final updatedCreator = Member(
          userId: creator.userId,
          email: creator.email,
          name: creator.name,
          role: creator.role,
          joinedAt: creator.joinedAt,
          householdId: householdId,
        );

        // Update the member in the household
        await widget.storage.updateMember(householdId, updatedCreator);

        // Update the member's profile with the new householdId
        await _memberStorage.saveMember(updatedCreator);

        developer.log('Created household with ID: $householdId');

        // Get the created household
        final household = await widget.storage.getHousehold(householdId);
        if (household != null) {
          developer.log('Retrieved household: ${household.toString()}');
          widget.onHouseholdCreated(household);
          if (mounted) {
            Navigator.of(context).pop();
          }
        } else {
          throw Exception('Failed to retrieve created household');
        }
      } catch (e, stackTrace) {
        developer.log(
          'Error creating household',
          error: e,
          stackTrace: stackTrace,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
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
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.4,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.add_home,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Create New Household',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Household Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.home),
                  helperText: 'This name will be used as the unique identifier for your household',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a household name';
                  }
                  if (value.length < 3) {
                    return 'Household name must be at least 3 characters long';
                  }
                  if (value.length > 50) {
                    return 'Household name must be less than 50 characters';
                  }
                  if (!RegExp(r'^[a-zA-Z0-9\s\-_]+$').hasMatch(value)) {
                    return 'Household name can only contain letters, numbers, spaces, hyphens, and underscores';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _createHousehold,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.add),
                    label: const Text('Create Household'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
} 