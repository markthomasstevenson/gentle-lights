import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../auth/auth_service.dart';
import '../../../../data/repositories/family_repository.dart';
import '../../../../domain/models/user_role.dart';

class RecoveryRestoreScreen extends StatefulWidget {
  final UserRole? role;

  const RecoveryRestoreScreen({super.key, this.role});

  @override
  State<RecoveryRestoreScreen> createState() => _RecoveryRestoreScreenState();
}

class _RecoveryRestoreScreenState extends State<RecoveryRestoreScreen> {
  final _recoveryCodeController = TextEditingController();
  final _displayNameController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _recoveryCodeController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _restoreAccess() async {
    final recoveryCode = _recoveryCodeController.text.trim().toUpperCase();
    final displayName = _displayNameController.text.trim();

    if (recoveryCode.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a recovery code';
      });
      return;
    }

    if (displayName.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your name';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authService = Provider.of<AuthService>(context, listen: false);
    final familyRepository =
        Provider.of<FamilyRepository>(context, listen: false);

    // Ensure user is signed in
    if (!authService.isAuthenticated) {
      await authService.signInAnonymously();
    }

    final user = authService.currentUser;
    if (user == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to sign in. Please try again.';
      });
      return;
    }

    // Restore family with recovery code
    final role = widget.role ?? UserRole.user;
    final family = await familyRepository.restoreFamilyWithRecoveryCode(
      recoveryCode: recoveryCode,
      userId: user.uid,
      displayName: displayName,
      role: role,
    );

    if (family == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Invalid recovery code. Please check and try again.';
      });
      return;
    }

    // Success - navigate based on role
    if (mounted) {
      if (role == UserRole.caregiver) {
        context.go('/caregiver-timeline');
      } else {
        context.go('/user-house');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Restore Access'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Restore access with recovery code',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Enter your recovery code to restore access to your family.',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              TextField(
                controller: _displayNameController,
                decoration: const InputDecoration(
                  labelText: 'Your name',
                  hintText: 'Enter your name',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _recoveryCodeController,
                decoration: const InputDecoration(
                  labelText: 'Recovery Code',
                  hintText: 'Enter recovery code',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.characters,
                maxLength: 16,
                buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              const Spacer(),
              ElevatedButton(
                onPressed: _isLoading ? null : _restoreAccess,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 48,
                    vertical: 16,
                  ),
                  minimumSize: const Size(double.infinity, 56),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'Restore Access',
                        style: TextStyle(fontSize: 18),
                      ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

