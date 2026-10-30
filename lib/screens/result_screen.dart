import 'dart:io';
import 'package:flutter/material.dart';
import '../models/mrz_data.dart';
import 'document_gen_screen.dart';

class ResultScreen extends StatelessWidget {
  final MrzData mrz;
  final String? capturedPath;
  const ResultScreen({super.key, required this.mrz, this.capturedPath});

  @override
  Widget build(BuildContext context) {
    final rows = <_Row>[
      _Row('Document type', mrz.documentType),
      _Row('Issuing country', mrz.issuingCountry),
      _Row('Surname', mrz.surname),
      _Row('Given names', mrz.givenNames),
      _Row('Document number', mrz.documentNumber),
      _Row('Nationality', mrz.nationality),
      _Row('Date of birth', mrz.dateOfBirth),
      _Row('Sex', mrz.sex),
      _Row('Date of expiry', mrz.dateOfExpiry),
      _Row('Personal number', mrz.personalNumber),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Extracted data'),
        leading: const BackButton(),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Center(
              child: Chip(
                avatar: Icon(
                  mrz.checksumValid ? Icons.verified : Icons.error_outline,
                  size: 16,
                  color: mrz.checksumValid ? Colors.green : Colors.red,
                ),
                label: Text(
                    mrz.checksumValid ? 'Checksum OK' : 'Checksum FAILED'),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (capturedPath != null)
                  Image.file(File(capturedPath!), fit: BoxFit.cover)
                else
                  Image.asset('assets/samples/specimen_passport.jpg',
                      fit: BoxFit.cover),
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text('Scanned page',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Raw MRZ',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  SelectableText(
                    [mrz.rawLine1, mrz.rawLine2, if (mrz.rawLine3 != null) mrz.rawLine3!]
                        .join('\n'),
                    style: const TextStyle(
                        fontFamily: 'monospace', fontSize: 14, letterSpacing: 1),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                for (final r in rows)
                  ListTile(
                    dense: true,
                    title: Text(r.label,
                        style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    subtitle: Text(r.value.isEmpty ? '—' : r.value,
                        style: const TextStyle(
                            fontSize: 16, color: Colors.black)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            icon: const Icon(Icons.description),
            label: const Text('Generate document'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => DocumentGenScreen(mrz: mrz),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Row {
  final String label;
  final String value;
  _Row(this.label, this.value);
}
