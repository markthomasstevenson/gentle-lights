import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PairingScreen extends StatelessWidget {
  const PairingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pairing'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Pairing Flow',
              style: TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 32),
            const Text('Pairing code will be displayed here'),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                // TODO: Handle pairing logic
                context.go('/caregiver-timeline');
              },
              child: const Text('Complete Pairing'),
            ),
          ],
        ),
      ),
    );
  }
}



