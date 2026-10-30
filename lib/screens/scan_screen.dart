import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../services/mrz_service.dart';
import 'result_screen.dart';

/// "Scan" screen: loads the bundled synthetic specimen passport, runs Nutrient
/// OCR on-device, parses the MRZ (ICAO 9303), and navigates to the result.
/// There is no camera capture in this demo: the image comes from the assets.
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  String _status = 'Loading passport image…';
  String? _error;
  String? _imagePath;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    try {
      final tmp = await getTemporaryDirectory();
      final out = File(p.join(tmp.path, 'specimen_passport.jpg'));
      final bytes = await rootBundle.load('assets/samples/specimen_passport.jpg');
      await out.writeAsBytes(
          bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes));
      setState(() {
        _imagePath = out.path;
        _status = 'Running Nutrient OCR on-device…';
      });

      final result = await MrzService().recognizeFromPath(out.path);
      if (!mounted) return;

      if (result.mrz == null) {
        setState(() {
          _error = result.rawText.isEmpty
              ? 'OCR returned no text.'
              : 'OCR ran, but no MRZ pattern was found in:\n\n${result.rawText}';
          _status = '';
        });
        return;
      }

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) =>
              ResultScreen(mrz: result.mrz!, capturedPath: out.path),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _status = '';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Read passport')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_imagePath != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(File(_imagePath!),
                    height: 240, fit: BoxFit.cover),
              )
            else
              const SizedBox(height: 240),
            const SizedBox(height: 24),
            if (_error == null) ...[
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(_status, textAlign: TextAlign.center),
            ] else ...[
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  setState(() {
                    _error = null;
                    _status = 'Retrying…';
                  });
                  _run();
                },
                child: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
