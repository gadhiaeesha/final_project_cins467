import 'package:flutter/material.dart';
import '../services/invite_management.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SendInviteDialog extends StatefulWidget {
  final String householdId;
  final String householdName;

  const SendInviteDialog({
    Key? key,
    required this.householdId,
    required this.householdName,
  }) : super(key: key);

  @override
  State<SendInviteDialog> createState() => _SendInviteDialogState();
}

class _SendInviteDialogState extends State<SendInviteDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _inviteManagement = InviteManagement();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendInvite() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      try {
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser == null) {
          throw Exception('No user is signed in');
        }

        await _inviteManagement.sendInvite(
          _emailController.text.trim(),
          widget.householdId,
          currentUser.uid,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Invite sent successfully to ${_emailController.text.trim()}'),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
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
          setState(() => _isLoading = false);
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
                    Icons.person_add,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Invite Member to ${widget.householdName}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Enter the email address of the person you want to invite to your household. They must already have a CleanStreak account.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                  helperText: 'The person must have a CleanStreak account',
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter an email address';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
                    return 'Please enter a valid email address';
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
                    onPressed: _isLoading ? null : _sendInvite,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                    label: Text(_isLoading ? 'Sending...' : 'Send Invite'),
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