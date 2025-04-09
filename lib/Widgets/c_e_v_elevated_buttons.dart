import 'package:flutter/material.dart';

class CreateElementElevatedButtons extends StatefulWidget {
  const CreateElementElevatedButtons({super.key});

  @override
  State<CreateElementElevatedButtons> createState() =>
      _CreateElementElevatedButtonsState();
}

class _CreateElementElevatedButtonsState
    extends State<CreateElementElevatedButtons> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.yellow, // Matches your app's theme
                foregroundColor: Colors.black,
              ),
              child: Text('Generate Password'),
            ),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.yellow, // Matches your app's theme
                foregroundColor: Colors.black,
              ),
              child: Text('Generate Password'),
            ),
          ],
        ),
      ],
    );
  }
}
