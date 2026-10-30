import '../models/mrz_data.dart';

/// ICAO 9303 MRZ parser. Handles TD3 (passport, 2×44), TD2 (2×36) and TD1
/// (3×30) layouts. Validates per-field check digits and the composite
/// check digit. Works on the raw text returned by Nutrient OCR.
class MrzParser {
  static MrzData? parse(String ocrText) {
    final candidate = _findMrzLines(ocrText);
    if (candidate == null) return null;

    return switch (candidate.length) {
      2 when candidate[0].length == 44 => _parseTd3(candidate[0], candidate[1]),
      2 when candidate[0].length == 36 => _parseTd2(candidate[0], candidate[1]),
      3 => _parseTd1(candidate[0], candidate[1], candidate[2]),
      _ => null,
    };
  }

  /// Maps Cyrillic, Greek and common visual lookalikes back to the Latin/digit
  /// glyph the MRZ actually carries. Then strips anything still not in the
  /// MRZ alphabet.
  static String _normalizeOcr(String raw) {
    final cleaned = raw
        .toUpperCase()
        .replaceAll(RegExp(r'\s+'), '')
        // Cyrillic look-alikes the OCR confuses with Latin letters.
        .replaceAll('А', 'A')
        .replaceAll('В', 'B')
        .replaceAll('С', 'C')
        .replaceAll('Е', 'E')
        .replaceAll('Н', 'H')
        .replaceAll('К', 'K')
        .replaceAll('М', 'M')
        .replaceAll('О', 'O')
        .replaceAll('Р', 'P')
        .replaceAll('Т', 'T')
        .replaceAll('Х', 'X');
    // Drop any glyph still outside the MRZ alphabet.
    return cleaned.replaceAll(RegExp(r'[^A-Z0-9<]'), '');
  }

  /// Heuristic: scan all lines, normalize OCR confusions, fix fillers, and
  /// pick the lines whose length (after cleanup) is close to a valid MRZ row.
  static List<String>? _findMrzLines(String text) {
    final lines = text
        .split(RegExp(r'[\r\n]+'))
        .map(_normalizeOcr)
        .map(_fixFillers)
        .where((l) => l.length >= 28)
        .toList();

    String pad(String l, int target) {
      if (l.length == target) return l;
      if (l.length > target) return l.substring(0, target);
      return l + ('<' * (target - l.length));
    }

    // A row may be a few characters off, and a run of fillers may be read
    // longer than it is: only the part before the trailing fillers counts.
    int targetFor(String l) {
      final core = l.replaceAll(RegExp(r'<+$'), '');
      for (final t in const [44, 36, 30]) {
        if (l.length >= t - 3 && core.length <= t + 3) return t;
      }
      return -1;
    }

    final raw = <String>[];
    final targets = <int>[];
    for (final l in lines) {
      final t = targetFor(l);
      if (t > 0) {
        raw.add(l);
        targets.add(t);
      }
    }
    final n = raw.length;
    if (n < 2) return null;
    if (n >= 3 && targets[n - 3] == 30) {
      return [for (var i = n - 3; i < n; i++) pad(raw[i], 30)];
    }
    final l1 = pad(raw[n - 2], targets[n - 2]);
    final l2 = targets[n - 1] == 44 ? _alignTd3Line2(raw[n - 1]) : pad(raw[n - 1], targets[n - 1]);
    return [l1, l2];
  }

  /// Fillers read as K or L: a run that starts with '<' and holds only '<',
  /// 'K' and 'L' up to the end of the line is all fillers, and a single K or
  /// L between two fillers is a filler too.
  static String _fixFillers(String l) {
    var s = l.replaceAllMapped(RegExp(r'<[<KL]*$'), (m) => '<' * m[0]!.length);
    for (var i = 0; i < 3; i++) {
      s = s.replaceAll(RegExp(r'(?<=<)[KL](?=<)'), '<');
    }
    return s;
  }

  /// TD3 data line: when the OCR adds a character, try each deletion and keep
  /// the variant with the most valid check digits. Digits and letters are
  /// also fixed by position (a date has digits, a nationality has letters).
  static String _alignTd3Line2(String raw) {
    final variants = <String>{};
    if (raw.length <= 44) {
      variants.add(raw.padRight(44, '<'));
    } else {
      variants.add(raw.substring(0, 44));
      for (var i = 0; i < raw.length; i++) {
        final v = raw.substring(0, i) + raw.substring(i + 1);
        variants.add(v.length > 44 ? v.substring(0, 44) : v.padRight(44, '<'));
      }
    }
    var best = _typeTd3Line2(variants.first);
    var bestScore = _td3Score(best);
    for (final v in variants.skip(1)) {
      final typed = _typeTd3Line2(v);
      final score = _td3Score(typed);
      if (score > bestScore) {
        best = typed;
        bestScore = score;
      }
    }
    return best;
  }

  static String _typeTd3Line2(String l) {
    const toDigit = {'O': '0', 'Q': '0', 'D': '0', 'I': '1', 'L': '1', 'Z': '2', 'S': '5', 'B': '8', 'G': '6'};
    const toLetter = {'0': 'O', '1': 'I', '2': 'Z', '5': 'S', '8': 'B', '6': 'G'};
    final c = l.split('');
    const digitPositions = [9, 13, 14, 15, 16, 17, 18, 19, 21, 22, 23, 24, 25, 26, 27, 43];
    for (final i in digitPositions) {
      c[i] = toDigit[c[i]] ?? c[i];
    }
    if (c[42] != '<') c[42] = toDigit[c[42]] ?? c[42];
    for (var i = 10; i < 13; i++) {
      c[i] = toLetter[c[i]] ?? c[i];
    }
    return c.join();
  }

  static int _td3Score(String l2) {
    var score = 0;
    if (_checkDigit(l2.substring(0, 9)) == l2[9]) score++;
    if (_checkDigit(l2.substring(13, 19)) == l2[19]) score++;
    if (_checkDigit(l2.substring(21, 27)) == l2[27]) score++;
    if (_checkDigit(l2.substring(28, 42)) == l2[42] || l2[42] == '<') score++;
    final composite = l2.substring(0, 10) + l2.substring(13, 20) + l2.substring(21, 43);
    if (_checkDigit(composite) == l2[43]) score++;
    return score;
  }

  static MrzData _parseTd3(String l1, String l2) {
    final documentType = _strip(l1.substring(0, 2));
    final issuingCountry = _strip(l1.substring(2, 5));
    final nameField = l1.substring(5);
    final (surname, givenNames) = _splitName(nameField);

    final documentNumber = _strip(l2.substring(0, 9));
    final documentNumberCheck = l2[9];
    final nationality = _strip(l2.substring(10, 13));
    final dobRaw = l2.substring(13, 19);
    final dobCheck = l2[19];
    final sex = _strip(l2.substring(20, 21));
    final expiryRaw = l2.substring(21, 27);
    final expiryCheck = l2[27];
    final personalNumber = _strip(l2.substring(28, 42));
    final personalCheck = l2[42];
    final compositeCheck = l2[43];

    final validDocNum = _checkDigit(l2.substring(0, 9)) == documentNumberCheck;
    final validDob = _checkDigit(dobRaw) == dobCheck;
    final validExpiry = _checkDigit(expiryRaw) == expiryCheck;
    final validPersonal =
        personalNumber.isEmpty || _checkDigit(l2.substring(28, 42)) == personalCheck;
    final compositeSrc = l2.substring(0, 10) +
        l2.substring(13, 20) +
        l2.substring(21, 28) +
        l2.substring(28, 43);
    final validComposite = _checkDigit(compositeSrc) == compositeCheck;

    return MrzData(
      documentType: documentType,
      issuingCountry: issuingCountry,
      surname: surname,
      givenNames: givenNames,
      documentNumber: documentNumber,
      nationality: nationality,
      dateOfBirth: _isoDate(dobRaw, futureCutoff: false),
      sex: sex,
      dateOfExpiry: _isoDate(expiryRaw, futureCutoff: true),
      personalNumber: personalNumber,
      checksumValid: validDocNum && validDob && validExpiry && validPersonal && validComposite,
      rawLine1: l1,
      rawLine2: l2,
    );
  }

  static MrzData _parseTd2(String l1, String l2) {
    final documentType = _strip(l1.substring(0, 2));
    final issuingCountry = _strip(l1.substring(2, 5));
    final (surname, givenNames) = _splitName(l1.substring(5, 36));

    final documentNumber = _strip(l2.substring(0, 9));
    final nationality = _strip(l2.substring(10, 13));
    final dobRaw = l2.substring(13, 19);
    final sex = _strip(l2.substring(20, 21));
    final expiryRaw = l2.substring(21, 27);

    return MrzData(
      documentType: documentType,
      issuingCountry: issuingCountry,
      surname: surname,
      givenNames: givenNames,
      documentNumber: documentNumber,
      nationality: nationality,
      dateOfBirth: _isoDate(dobRaw, futureCutoff: false),
      sex: sex,
      dateOfExpiry: _isoDate(expiryRaw, futureCutoff: true),
      personalNumber: '',
      checksumValid: _checkDigit(l2.substring(0, 9)) == l2[9] &&
          _checkDigit(dobRaw) == l2[19] &&
          _checkDigit(expiryRaw) == l2[27],
      rawLine1: l1,
      rawLine2: l2,
    );
  }

  static MrzData _parseTd1(String l1, String l2, String l3) {
    final documentType = _strip(l1.substring(0, 2));
    final issuingCountry = _strip(l1.substring(2, 5));
    final documentNumber = _strip(l1.substring(5, 14));

    final dobRaw = l2.substring(0, 6);
    final sex = _strip(l2.substring(7, 8));
    final expiryRaw = l2.substring(8, 14);
    final nationality = _strip(l2.substring(15, 18));

    final (surname, givenNames) = _splitName(l3);

    return MrzData(
      documentType: documentType,
      issuingCountry: issuingCountry,
      surname: surname,
      givenNames: givenNames,
      documentNumber: documentNumber,
      nationality: nationality,
      dateOfBirth: _isoDate(dobRaw, futureCutoff: false),
      sex: sex,
      dateOfExpiry: _isoDate(expiryRaw, futureCutoff: true),
      personalNumber: '',
      checksumValid: _checkDigit(l1.substring(5, 14)) == l1[14] &&
          _checkDigit(dobRaw) == l2[6] &&
          _checkDigit(expiryRaw) == l2[14],
      rawLine1: l1,
      rawLine2: l2,
      rawLine3: l3,
    );
  }

  static (String surname, String given) _splitName(String field) {
    final cleaned = field.replaceAll(RegExp(r'<+$'), '');
    final parts = cleaned.split('<<');
    final surname = parts.isNotEmpty ? parts[0].replaceAll('<', ' ').trim() : '';
    final given = parts.length > 1 ? parts[1].replaceAll('<', ' ').trim() : '';
    return (surname, given);
  }

  static String _strip(String s) => s.replaceAll('<', '').trim();

  /// YYMMDD → YYYY-MM-DD with century inferred.
  /// `futureCutoff: true` for expiry-style dates (20YY unless > 50y out).
  static String _isoDate(String yymmdd, {required bool futureCutoff}) {
    if (yymmdd.length != 6 || !RegExp(r'^\d{6}$').hasMatch(yymmdd)) return yymmdd;
    final yy = int.parse(yymmdd.substring(0, 2));
    final mm = yymmdd.substring(2, 4);
    final dd = yymmdd.substring(4, 6);
    final nowYy = DateTime.now().year % 100;
    final yyyy = futureCutoff
        ? (yy < nowYy + 50 ? 2000 + yy : 1900 + yy)
        : (yy <= nowYy ? 2000 + yy : 1900 + yy);
    return '$yyyy-$mm-$dd';
  }

  /// ICAO 9303 check digit: weights 7,3,1 over A=10..Z=35, '<'=0.
  static String _checkDigit(String s) {
    const weights = [7, 3, 1];
    var sum = 0;
    for (var i = 0; i < s.length; i++) {
      final c = s.codeUnitAt(i);
      final v = switch (c) {
        >= 0x30 && <= 0x39 => c - 0x30,
        >= 0x41 && <= 0x5A => c - 0x41 + 10,
        0x3C => 0,
        _ => 0,
      };
      sum += v * weights[i % 3];
    }
    return (sum % 10).toString();
  }
}
