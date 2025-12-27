import 'package:flutter/material.dart';

class UserHouseScreen extends StatelessWidget {
  const UserHouseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your House'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'House Screen',
              style: TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 32),
            const Text('House visualization will be displayed here'),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                // TODO: Handle "Turn the lights on" action
              },
              child: const Text('Turn the lights on'),
            ),
          ],
        ),
      ),
    );
  }
}



