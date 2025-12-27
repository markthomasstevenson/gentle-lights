import 'package:flutter/material.dart';

class CaregiverTimelineScreen extends StatelessWidget {
  const CaregiverTimelineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Caregiver Timeline'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Caregiver Timeline',
              style: TextStyle(fontSize: 24),
            ),
            SizedBox(height: 32),
            Text('Timeline view will be displayed here'),
          ],
        ),
      ),
    );
  }
}


