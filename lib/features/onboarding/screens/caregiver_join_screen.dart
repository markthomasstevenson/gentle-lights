import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../auth/auth_service.dart';
import '../../../../data/repositories/family_repository.dart';
import '../../../../domain/models/user_role.dart';

class CaregiverJoinScreen extends StatefulWidget {
  const CaregiverJoinScreen({super.key});

  @override
  State<CaregiverJoinScreen> createState() => _CaregiverJoinScreenState();
}

class _CaregiverJoinScreenState extends State<CaregiverJoinScreen> {
  final _pairingCodeController = TextEditingController();
  final _displayNameController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _pairingCodeController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _joinFamily() async {
    final pairingCode = _pairingCodeController.text.trim().toUpperCase();
    final displayName = _displayNameController.text.trim();

    if (pairingCode.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a pairing code';
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

    // Join family with pairing code
    final family = await familyRepository.joinFamilyWithCode(
      pairingCode: pairingCode,
      userId: user.uid,
      displayName: displayName,
      role: UserRole.caregiver,
    );

    if (family == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Invalid pairing code. Please check and try again.';
      });
      return;
    }

    // Success - navigate to caregiver timeline
    if (mounted) {
      context.go('/caregiver-timeline');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Join Family'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "I'm helping someone",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                ),
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
              // QR Code scan placeholder
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.qr_code_scanner,
                      size: 64,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Scan QR Code',
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '(Optional)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'or',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _pairingCodeController,
                decoration: const InputDecoration(
                  labelText: 'Pairing Code',
                  hintText: 'Enter pairing code',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.characters,
                maxLength: 8,
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
                onPressed: _isLoading ? null : _joinFamily,
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
                        'Join',
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

