import 'dart:io';
import 'package:nutrient_flutter/nutrient_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/mrz_data.dart';

/// Generates permits / certificates / receipts from MRZ-extracted data and
/// displays them in the Nutrient Flutter SDK viewer (view, annotate, sign).
///
/// PDF bytes are written by the open-source `pdf` Dart package. Viewing,
/// annotating, signing and exporting happen in the Nutrient viewer.
/// https://www.nutrient.io/sdk/flutter/
class DocumentService {
  static const String entryPermit = 'entry_permit';
  static const String receipt = 'receipt';
  static const String residenceCert = 'residence_cert';

  Future<String> generate({
    required String kind,
    required MrzData mrz,
  }) async {
    final pdf = pw.Document(title: _title(kind), author: 'Nutrient MRZ capture demo');
    pdf.addPage(_page(kind, mrz));

    final dir = await getApplicationDocumentsDirectory();
    final outPath = p.join(
      dir.path,
      '${kind}_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
    await File(outPath).writeAsBytes(await pdf.save(), flush: true);
    return outPath;
  }

  Future<void> presentInNutrient(String path) async {
    await Nutrient.present(path);
  }

  String _title(String kind) => switch (kind) {
        entryPermit => 'Entry Permit',
        receipt => 'Processing Receipt',
        residenceCert => 'Residence Certificate',
        _ => 'Document',
      };

  pw.Page _page(String kind, MrzData mrz) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(36),
      build: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          _header(kind),
          pw.SizedBox(height: 18),
          _holderBlock(mrz),
          pw.SizedBox(height: 18),
          _documentBlock(mrz),
          pw.SizedBox(height: 18),
          _mrzBlock(mrz),
          pw.Spacer(),
          _footer(),
        ],
      ),
    );
  }

  pw.Widget _header(String kind) => pw.Container(
        padding: const pw.EdgeInsets.all(14),
        decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF1E3A8A)),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(_title(kind).toUpperCase(),
                style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold)),
            pw.Text('SPECIMEN',
                style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 12,
                    letterSpacing: 2)),
          ],
        ),
      );

  pw.Widget _holderBlock(MrzData mrz) => _section(
        'Holder',
        [
          _kv('Surname', mrz.surname),
          _kv('Given names', mrz.givenNames),
          _kv('Date of birth', mrz.dateOfBirth),
          _kv('Sex', mrz.sex),
          _kv('Nationality', mrz.nationality),
        ],
      );

  pw.Widget _documentBlock(MrzData mrz) => _section(
        'Document',
        [
          _kv('Document type', mrz.documentType),
          _kv('Document number', mrz.documentNumber),
          _kv('Issuing country', mrz.issuingCountry),
          _kv('Date of expiry', mrz.dateOfExpiry),
          _kv('Personal number', mrz.personalNumber),
          _kv('Checksum', mrz.checksumValid ? 'Valid (ICAO)' : 'INVALID'),
        ],
      );

  pw.Widget _mrzBlock(MrzData mrz) => pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey400),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Machine-Readable Zone',
                style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey700)),
            pw.SizedBox(height: 6),
            pw.Text(mrz.rawLine1,
                style: const pw.TextStyle(
                    font: null, fontSize: 11, letterSpacing: 1)),
            pw.Text(mrz.rawLine2,
                style: const pw.TextStyle(
                    font: null, fontSize: 11, letterSpacing: 1)),
            if (mrz.rawLine3 != null)
              pw.Text(mrz.rawLine3!,
                  style: const pw.TextStyle(fontSize: 11, letterSpacing: 1)),
          ],
        ),
      );

  pw.Widget _section(String title, List<pw.Widget> rows) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title.toUpperCase(),
              style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey600,
                  letterSpacing: 1)),
          pw.Divider(color: PdfColors.grey400),
          ...rows,
        ],
      );

  pw.Widget _kv(String k, String v) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 3),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(
              width: 140,
              child: pw.Text(k,
                  style: const pw.TextStyle(
                      fontSize: 11, color: PdfColors.grey700)),
            ),
            pw.Expanded(
              child: pw.Text(v.isEmpty ? '—' : v,
                  style: const pw.TextStyle(fontSize: 12)),
            ),
          ],
        ),
      );

  pw.Widget _footer() => pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Generated ${DateTime.now().toIso8601String().substring(0, 19)} · '
            'Issued on-device · No data left the device',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
          pw.Text('Signature: ____________________',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
        ],
      );
}
