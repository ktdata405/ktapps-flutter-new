import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  static const _routes = <(String, String)>[
    ('Cashew', '/report/cashew'),
    ('Rent', '/report/rent'),
    ('MSI', '/report/msi'),
    ('Debts', '/report/debts'),
    ('Denominations', '/report/denominations'),
    ('Loan', '/report/loan'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reports Dashboard')),
      body: ListView.separated(
        padding: const EdgeInsets.all(14),
        itemCount: _routes.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final (label, route) = _routes[index];
          return ListTile(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            tileColor: Theme.of(context).colorScheme.surface,
            title: Text(label),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => Navigator.pushNamed(context, route),
          );
        },
      ),
    );
  }
}
