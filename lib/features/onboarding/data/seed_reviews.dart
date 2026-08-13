import 'dart:math' show Random;

import 'package:drive_rank/shared/models/country.dart';

/// A single seeded review shown in the onboarding social-proof step.
class SeedReview {
  const SeedReview({
    required this.name,
    required this.text,
    required this.avatar,
  });
  final String name;
  final String text;
  final String avatar;
}

/// Picks two reviews to display for the given country.
///
/// The reviewer names come from a country-specific pool so the social
/// proof feels native to the user (Pakistani users see Pakistani names,
/// not the same two American names everyone else gets). The review
/// text pool is universal English — translating each blurb per country
/// is overkill for v1.
///
/// Selection is deterministic from `country?.code` so the same country
/// always shows the same two reviewers (no shuffling on rebuild — that
/// would make them feel fake).
List<SeedReview> pickReviewsForCountry(Country? country) {
  final names = _namePool[country?.code] ?? _defaultNamePool;
  final seed = (country?.code ?? 'INTL').hashCode;
  final rand = Random(seed);

  final nameIndices = _twoDistinctIndices(rand, names.length);
  final textIndices = _twoDistinctIndices(rand, _reviewTexts.length);
  final avatarIndices = _twoDistinctIndices(rand, _avatars.length);

  return [
    SeedReview(
      name: names[nameIndices[0]],
      text: _reviewTexts[textIndices[0]],
      avatar: _avatars[avatarIndices[0]],
    ),
    SeedReview(
      name: names[nameIndices[1]],
      text: _reviewTexts[textIndices[1]],
      avatar: _avatars[avatarIndices[1]],
    ),
  ];
}

List<int> _twoDistinctIndices(Random rand, int bound) {
  final a = rand.nextInt(bound);
  var b = rand.nextInt(bound);
  if (b == a) b = (b + 1) % bound;
  return [a, b];
}

// ---------- Universal review text pool ----------
//
// Six short blurbs that reference features that actually shipped in
// v1: trip tracking, pause, personal bests, smooth speedometer, low
// battery use, shareable stat cards. Adding more is fine; the random
// picker just samples two each render.
// ignore_for_file: no_adjacent_strings_in_list
const List<String> _reviewTexts = [
  "Finally a driving tracker that doesn't bury the actual stats under ads. Top-speed and best-trip cards look great when I post them.",
  "The Pause button is gold for stop-and-go traffic — my averages aren't ruined by sitting at lights any more.",
  'Setup took less than a minute and the speedometer is smooth as butter. Feels premium.',
  'Personal Bests page is my favourite. Watching my longest trip grow week by week is weirdly addictive.',
  "Battery hit is minimal even on long road trips. Most GPS apps melt my phone — this one doesn't.",
  'Stat cards I share with friends actually get reactions. The design is clean and the numbers are honest.',
];

const List<String> _avatars = ['🚗', '🏎️', '🏁', '🛣️', '🚙', '⛽'];

// ---------- Country-specific reviewer name pools ----------
//
// Keys are ISO-3166 alpha-2 codes (same as `Country.code`). When a
// country isn't covered, `_defaultNamePool` is used — neutral
// international names that don't feel out of place anywhere.
const Map<String, List<String>> _namePool = {
  'US': ['Mike R.', 'Jake T.', 'Sarah L.', 'Ryan B.', 'Tyler K.', 'Emma D.'],
  'GB': [
    'Oliver T.',
    'Harry K.',
    'Charlie M.',
    'Sophie W.',
    'Ben P.',
    'Lucy R.',
  ],
  'CA': ['Liam J.', 'Owen M.', 'Hailey K.', 'Mason R.', 'Avery T.', 'Noah B.'],
  'AU': ['Liam K.', 'Noah B.', 'Charlie W.', 'Mia S.', 'Riley H.', 'Jack P.'],
  'IN': [
    'Arjun K.',
    'Rohan S.',
    'Vikram J.',
    'Priya M.',
    'Aditya N.',
    'Neha R.',
  ],
  'PK': ['Ali S.', 'Hamza R.', 'Bilal A.', 'Imran K.', 'Saad M.', 'Ayesha T.'],
  'BD': [
    'Rafi I.',
    'Tanvir A.',
    'Sajid R.',
    'Mehedi H.',
    'Nadia K.',
    'Anika S.',
  ],
  'AE': [
    'Khalid A.',
    'Omar R.',
    'Faisal M.',
    'Mohammed S.',
    'Layla H.',
    'Hassan T.',
  ],
  'SA': [
    'Abdullah K.',
    'Yasser A.',
    'Sultan B.',
    'Fahad M.',
    'Noor R.',
    'Tariq S.',
  ],
  'TR': ['Mehmet Y.', 'Emre K.', 'Burak D.', 'Selim A.', 'Ayla T.', 'Can O.'],
  'DE': [
    'Lukas W.',
    'Stefan M.',
    'Tobias K.',
    'Felix B.',
    'Anna H.',
    'Jonas R.',
  ],
  'FR': [
    'Mathieu D.',
    'Antoine L.',
    'Lucas R.',
    'Camille B.',
    'Hugo T.',
    'Léa M.',
  ],
  'ES': [
    'Carlos R.',
    'Diego M.',
    'Javier S.',
    'Pablo G.',
    'Lucía M.',
    'Marta C.',
  ],
  'MX': [
    'Carlos H.',
    'Diego R.',
    'Javier M.',
    'Sofía G.',
    'Andrés L.',
    'Valeria T.',
  ],
  'AR': [
    'Mateo S.',
    'Lucas P.',
    'Joaquín R.',
    'Tomás B.',
    'Martina K.',
    'Camila D.',
  ],
  'BR': [
    'Lucas R.',
    'Felipe C.',
    'Mateus S.',
    'Gabriel B.',
    'Beatriz M.',
    'Bruno T.',
  ],
  'IT': [
    'Marco R.',
    'Luca G.',
    'Matteo F.',
    'Alessandro D.',
    'Giulia P.',
    'Sara M.',
  ],
  'JP': [
    'Hiroshi T.',
    'Kenji M.',
    'Takashi S.',
    'Yuki N.',
    'Ryo K.',
    'Sora H.',
  ],
  'ID': ['Adi P.', 'Faris A.', 'Bagus W.', 'Eko S.', 'Citra R.', 'Putri H.'],
  'MY': ['Faris A.', 'Aiman R.', 'Hafiz M.', 'Iqbal S.', 'Nurul K.', 'Zara T.'],
  'NG': [
    'Tunde A.',
    'Chinedu O.',
    'Adaeze N.',
    'Kemi R.',
    'Femi B.',
    'Zainab S.',
  ],
  'ZA': [
    'Sipho M.',
    'Themba D.',
    'Nomvula K.',
    'Aaliyah P.',
    'Nathan W.',
    'Lerato N.',
  ],
  'NL': ['Daan V.', 'Sven K.', 'Lotte B.', 'Tim H.', 'Sanne M.', 'Bram D.'],
  'PL': ['Jakub W.', 'Kacper M.', 'Zofia K.', 'Antoni P.', 'Lena R.'],
  'EG': ['Youssef A.', 'Karim H.', 'Mariam S.', 'Hassan R.', 'Dina M.'],
  'PH': ['JM Santos', 'Mark R.', 'Patricia L.', 'Joshua A.', 'Bea C.'],
  'TH': ['Somchai P.', 'Niran S.', 'Kanya T.', 'Anan W.'],
  'VN': ['Minh T.', 'Anh K.', 'Lan H.', 'Phuc D.'],
};

const List<String> _defaultNamePool = [
  'Alex M.',
  'Jordan T.',
  'Sam K.',
  'Riley B.',
  'Casey D.',
  'Morgan H.',
];
