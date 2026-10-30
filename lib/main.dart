import 'package:flutter/material.dart';
import 'package:nutrient_flutter/nutrient_flutter.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Eval mode (no license keys) — viewer/editor work with a watermark.
  await Nutrient.initialize();
  runApp(const MrzCaptureApp());
}
