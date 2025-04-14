import 'package:flutter/material.dart';

class ThirdTab extends StatelessWidget {
  const ThirdTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Api keys'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: Text('3'),
    );
  }
}
