class MrzData {
  final String documentType;
  final String issuingCountry;
  final String surname;
  final String givenNames;
  final String documentNumber;
  final String nationality;
  final String dateOfBirth;
  final String sex;
  final String dateOfExpiry;
  final String personalNumber;
  final bool checksumValid;
  final String rawLine1;
  final String rawLine2;
  final String? rawLine3;

  const MrzData({
    required this.documentType,
    required this.issuingCountry,
    required this.surname,
    required this.givenNames,
    required this.documentNumber,
    required this.nationality,
    required this.dateOfBirth,
    required this.sex,
    required this.dateOfExpiry,
    required this.personalNumber,
    required this.checksumValid,
    required this.rawLine1,
    required this.rawLine2,
    this.rawLine3,
  });

  factory MrzData.fromMap(Map<dynamic, dynamic> m) => MrzData(
        documentType: m['documentType'] as String? ?? '',
        issuingCountry: m['issuingCountry'] as String? ?? '',
        surname: m['surname'] as String? ?? '',
        givenNames: m['givenNames'] as String? ?? '',
        documentNumber: m['documentNumber'] as String? ?? '',
        nationality: m['nationality'] as String? ?? '',
        dateOfBirth: m['dateOfBirth'] as String? ?? '',
        sex: m['sex'] as String? ?? '',
        dateOfExpiry: m['dateOfExpiry'] as String? ?? '',
        personalNumber: m['personalNumber'] as String? ?? '',
        checksumValid: m['checksumValid'] as bool? ?? false,
        rawLine1: m['rawLine1'] as String? ?? '',
        rawLine2: m['rawLine2'] as String? ?? '',
        rawLine3: m['rawLine3'] as String?,
      );

  Map<String, String> toTemplateValues() => {
        'surname': surname,
        'given_names': givenNames,
        'document_number': documentNumber,
        'nationality': nationality,
        'date_of_birth': dateOfBirth,
        'sex': sex,
        'date_of_expiry': dateOfExpiry,
        'issuing_country': issuingCountry,
        'personal_number': personalNumber,
      };
}
