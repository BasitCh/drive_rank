import 'package:flutter/foundation.dart';

/// A country option in the onboarding country picker.
///
/// `code` is ISO 3166-1 alpha-2 ("PK", "US"). The flag is rendered from the
/// regional indicator symbol pair — we don't ship flag images.
@immutable
class Country {
  const Country({required this.code, required this.name});

  final String code;
  final String name;

  /// 🇵🇰 / 🇺🇸 / … built from the two regional-indicator codepoints that
  /// correspond to the country code. The OS renders these as flag glyphs.
  String get flag {
    if (code.length != 2) return '🏳️';
    final base = 0x1F1E6 - 'A'.codeUnitAt(0);
    final first = code.codeUnitAt(0) + base;
    final second = code.codeUnitAt(1) + base;
    return String.fromCharCodes(<int>[first, second]);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Country && other.code == code && other.name == name);

  @override
  int get hashCode => Object.hash(code, name);
}

/// A static, alphabetised list of countries supported in the onboarding
/// picker. ISO 3166-1 alpha-2 codes — name strings are English-only for v1.
const List<Country> kCountries = <Country>[
  Country(code: 'AE', name: 'United Arab Emirates'),
  Country(code: 'AR', name: 'Argentina'),
  Country(code: 'AT', name: 'Austria'),
  Country(code: 'AU', name: 'Australia'),
  Country(code: 'BD', name: 'Bangladesh'),
  Country(code: 'BE', name: 'Belgium'),
  Country(code: 'BR', name: 'Brazil'),
  Country(code: 'CA', name: 'Canada'),
  Country(code: 'CH', name: 'Switzerland'),
  Country(code: 'CL', name: 'Chile'),
  Country(code: 'CN', name: 'China'),
  Country(code: 'CO', name: 'Colombia'),
  Country(code: 'CZ', name: 'Czechia'),
  Country(code: 'DE', name: 'Germany'),
  Country(code: 'DK', name: 'Denmark'),
  Country(code: 'EG', name: 'Egypt'),
  Country(code: 'ES', name: 'Spain'),
  Country(code: 'FI', name: 'Finland'),
  Country(code: 'FR', name: 'France'),
  Country(code: 'GB', name: 'United Kingdom'),
  Country(code: 'HK', name: 'Hong Kong'),
  Country(code: 'HU', name: 'Hungary'),
  Country(code: 'ID', name: 'Indonesia'),
  Country(code: 'IE', name: 'Ireland'),
  Country(code: 'IL', name: 'Israel'),
  Country(code: 'IN', name: 'India'),
  Country(code: 'IS', name: 'Iceland'),
  Country(code: 'IT', name: 'Italy'),
  Country(code: 'JP', name: 'Japan'),
  Country(code: 'KE', name: 'Kenya'),
  Country(code: 'KR', name: 'South Korea'),
  Country(code: 'LK', name: 'Sri Lanka'),
  Country(code: 'LR', name: 'Liberia'),
  Country(code: 'MM', name: 'Myanmar'),
  Country(code: 'MX', name: 'Mexico'),
  Country(code: 'MY', name: 'Malaysia'),
  Country(code: 'NG', name: 'Nigeria'),
  Country(code: 'NL', name: 'Netherlands'),
  Country(code: 'NO', name: 'Norway'),
  Country(code: 'NZ', name: 'New Zealand'),
  Country(code: 'PE', name: 'Peru'),
  Country(code: 'PH', name: 'Philippines'),
  Country(code: 'PK', name: 'Pakistan'),
  Country(code: 'PL', name: 'Poland'),
  Country(code: 'PT', name: 'Portugal'),
  Country(code: 'RO', name: 'Romania'),
  Country(code: 'RU', name: 'Russia'),
  Country(code: 'SA', name: 'Saudi Arabia'),
  Country(code: 'SE', name: 'Sweden'),
  Country(code: 'SG', name: 'Singapore'),
  Country(code: 'TH', name: 'Thailand'),
  Country(code: 'TR', name: 'Türkiye'),
  Country(code: 'TW', name: 'Taiwan'),
  Country(code: 'UA', name: 'Ukraine'),
  Country(code: 'US', name: 'United States'),
  Country(code: 'VN', name: 'Vietnam'),
  Country(code: 'ZA', name: 'South Africa'),
];

/// Lookup helper. Returns `null` if the code is unknown.
Country? countryFromCode(String code) {
  for (final c in kCountries) {
    if (c.code == code) return c;
  }
  return null;
}
