import 'package:flutter/material.dart';

class MilkBillScreen extends StatelessWidget {
  const MilkBillScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _ComingSoonScreen(title: 'Milk Bill');
  }
}

class _ComingSoonScreen extends StatelessWidget {
  const _ComingSoonScreen({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text('$title module is not yet migrated',
            style: const TextStyle(fontSize: 16)),
      ),
    );
  }
}
