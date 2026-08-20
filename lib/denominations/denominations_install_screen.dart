import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

const _bg = Color(0xFF080C14);
const _card = Color(0xC00F1423);
const _border = Color(0x1FFFFFFF);
const _text = Color(0xFFF1F5F9);
const _muted = Color(0xFF64748B);
const _primary = Color(0xFF6366F1);

class DenominationsInstallScreen extends StatelessWidget {
  const DenominationsInstallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        title: const Text('Install Denom\'s',
            style: TextStyle(color: _text, fontWeight: FontWeight.w800)),
        iconTheme: const IconThemeData(color: _text),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: _border),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 82,
                      height: 82,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        gradient: const LinearGradient(
                            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
                      ),
                      child: const Icon(Icons.currency_rupee,
                          color: Colors.white, size: 38),
                    ),
                    const SizedBox(height: 12),
                    const Text('Denom\'s',
                        style: TextStyle(
                            color: _text,
                            fontSize: 28,
                            fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    const Text('Denomination Manager · Cash Counter',
                        style: TextStyle(color: _muted, fontSize: 12)),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: _primary.withValues(alpha: 0.16),
                        border:
                            Border.all(color: _primary.withValues(alpha: 0.45)),
                      ),
                      child: Text(
                        kIsWeb
                            ? 'Install from browser menu (PWA)'
                            : 'Already running as app on this device',
                        style: const TextStyle(
                            color: Color(0xFFA5B4FC),
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const _InstallSteps(),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.pushReplacementNamed(
                            context, '/denominations'),
                        icon: const Icon(Icons.open_in_new),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        label: const Text('Open Denom\'s App'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InstallSteps extends StatelessWidget {
  const _InstallSteps();

  @override
  Widget build(BuildContext context) {
    const android = [
      'Open in Chrome or Edge.',
      'Tap the three-dot menu.',
      'Choose "Install app" or "Add to Home screen".',
      'Confirm installation.',
      'Launch from your home screen/app drawer.',
    ];

    const ios = [
      'Open in Safari.',
      'Tap Share.',
      'Select "Add to Home Screen".',
      'Tap Add.',
      'Launch from your home screen.',
    ];

    Widget block(String title, List<String> steps, IconData icon) {
      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFFA5B4FC), size: 16),
                const SizedBox(width: 6),
                Text(title,
                    style: const TextStyle(
                        color: _text, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 8),
            for (var i = 0; i < steps.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('${i + 1}. ${steps[i]}',
                    style: const TextStyle(color: _muted, fontSize: 12)),
              ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Install Steps',
            style: TextStyle(
                color: _muted, fontSize: 11, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        block('Android / PC', android, Icons.android),
        block('iPhone / iPad', ios, Icons.phone_iphone),
      ],
    );
  }
}
