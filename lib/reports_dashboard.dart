import 'package:flutter/material.dart';
import 'main.dart';

class ReportsDashboard extends StatelessWidget {
  const ReportsDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF030305),
      appBar: AppBar(backgroundColor: Colors.transparent, title: const Text('Reports Dashboard', style: TextStyle(fontWeight: FontWeight.bold))),
      body: Stack(
        children: [
          const AmbientBackground(),
          GridView.builder(
            padding: const EdgeInsets.all(24),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 1.0),
            itemCount: reportData.length,
            itemBuilder: (context, i) {
              final item = reportData[i];
              return InkWell(
                onTap: () => Navigator.pushNamed(context, item.route),
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  decoration: BoxDecoration(color: const Color(0xFF151A25), borderRadius: BorderRadius.circular(24), border: Border.all(color: item.color.withValues(alpha: 0.2))),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(width: 56, height: 56, decoration: BoxDecoration(color: item.color.withValues(alpha: 0.1), shape: BoxShape.circle), child: Icon(item.icon, color: item.color, size: 28)),
                      const SizedBox(height: 16),
                      Text(item.text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
