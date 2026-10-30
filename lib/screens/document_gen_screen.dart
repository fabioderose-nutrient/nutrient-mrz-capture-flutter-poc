import 'package:flutter/material.dart';
import '../models/mrz_data.dart';
import '../services/document_service.dart';

class DocumentGenScreen extends StatefulWidget {
  final MrzData mrz;
  const DocumentGenScreen({super.key, required this.mrz});

  @override
  State<DocumentGenScreen> createState() => _DocumentGenScreenState();
}

class _DocumentGenScreenState extends State<DocumentGenScreen> {
  final _docs = DocumentService();
  bool _busy = false;

  Future<void> _generate(String kind, String label) async {
    setState(() => _busy = true);
    try {
      final path = await _docs.generate(kind: kind, mrz: widget.mrz);
      if (!mounted) return;
      await _docs.presentInNutrient(path);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$label failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Generate document')),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: const Padding(
                  padding: EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Auto-filled with extracted MRZ data',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      SizedBox(height: 4),
                      Text(
                          'PDF rendered on-device, presented in the Nutrient '
                          'Flutter SDK viewer for review, annotation and signing.'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _Tile(
                icon: Icons.airplane_ticket_outlined,
                title: 'Entry permit',
                subtitle: 'Generate + open in Nutrient viewer',
                onTap: () =>
                    _generate(DocumentService.entryPermit, 'Entry permit'),
              ),
              _Tile(
                icon: Icons.receipt_long_outlined,
                title: 'Processing receipt',
                subtitle: 'Payment / processing receipt',
                onTap: () => _generate(DocumentService.receipt, 'Receipt'),
              ),
              _Tile(
                icon: Icons.verified_user_outlined,
                title: 'Residence certificate',
                subtitle: 'Government residence proof',
                onTap: () => _generate(
                    DocumentService.residenceCert, 'Residence certificate'),
              ),
            ],
          ),
          if (_busy)
            const ColoredBox(
              color: Color(0x66000000),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _Tile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, size: 32),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
