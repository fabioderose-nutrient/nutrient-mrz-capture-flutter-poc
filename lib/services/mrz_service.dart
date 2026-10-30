import 'package:flutter/services.dart';
import '../models/mrz_data.dart';
import 'mrz_parser.dart';

/// Bridge to the Nutrient Android SDK OCR engine.
///
/// Workflow: image path → native OCR (Nutrient `nutrient-ocr` module) →
/// raw page text → Dart MRZ parser → structured MRZ data.
/// All in-process, all offline.
class MrzService {
  static const MethodChannel _channel =
      MethodChannel('io.nutrient.poc.mrzcapture/nutrient_ocr');

  Future<({MrzData? mrz, String rawText})> recognizeFromPath(String path) async {
    final text = await _channel.invokeMethod<String>(
      'ocrImage',
      {'path': path},
    ) ?? '';
    return (mrz: MrzParser.parse(text), rawText: text);
  }
}
