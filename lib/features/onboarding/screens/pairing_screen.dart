import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../auth/auth_service.dart';
import '../../../../data/repositories/family_repository.dart';
import '../../../../domain/models/family.dart';
import '../../../../domain/models/user_role.dart';

class PairingScreen extends StatefulWidget {
  const PairingScreen({super.key});

  @override
  State<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends State<PairingScreen> {
  Family? _family;
  bool _isLoading = true;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _initializeFamily();
  }

  Future<void> _initializeFamily() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final familyRepository =
        Provider.of<FamilyRepository>(context, listen: false);

    final user = authService.currentUser;
    if (user == null) {
      // Sign in anonymously first
      await authService.signInAnonymously();
      final newUser = authService.currentUser;
      if (newUser == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }
    }

    // Check if user already has a family
    final familyId = await familyRepository.getFamilyId(user!.uid);
    if (familyId != null) {
      final family = await familyRepository.getFamily(familyId);
      if (family != null) {
        setState(() {
          _family = family;
          _isLoading = false;
        });
        return;
      }
    }

    // Create new family
    setState(() {
      _isCreating = true;
    });

    final family = await familyRepository.createFamily(
      userId: user.uid,
      displayName: 'User',
      role: UserRole.user,
    );

    setState(() {
      _family = family;
      _isLoading = false;
      _isCreating = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              const Text(
                'Connect a family helper',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              if (_isLoading || _isCreating)
                const CircularProgressIndicator()
              else if (_family != null)
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Pairing Code',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _family!.pairingCode,
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 8,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: _family!.pairingCode));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Pairing code copied to clipboard'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                            icon: const Icon(Icons.copy),
                            label: const Text('Copy'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    // QR Code placeholder
                    Container(
                      width: 200,
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
                            Icons.qr_code,
                            size: 64,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'QR Code',
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              else
                const Text('Error creating family. Please try again.'),
              const Spacer(),
              ElevatedButton(
                onPressed: _isLoading || _isCreating
                    ? null
                    : () {
                        context.go('/onboarding/recovery');
                      },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 48,
                    vertical: 16,
                  ),
                  minimumSize: const Size(double.infinity, 56),
                ),
                child: const Text(
                  'Done',
                  style: TextStyle(fontSize: 18),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _isLoading || _isCreating
                    ? null
                    : () {
                        context.go('/caregiver/join');
                      },
                child: const Text(
                  'I am the family helper',
                  style: TextStyle(fontSize: 16),
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
