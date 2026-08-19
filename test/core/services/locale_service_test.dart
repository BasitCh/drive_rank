import 'dart:ui';

import 'package:drive_rank/core/services/locale_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LocaleService — unit system', () {
    test('US locale uses imperial', () {
      final svc = LocaleService.forLocale(const Locale('en', 'US'));
      expect(svc.unitSystem, UnitSystem.imperial);
      expect(svc.speedUnitLabel, 'mph');
      expect(svc.distanceUnitLabel, 'mi');
    });

    test('GB locale uses imperial (per spec — US/GB/MM/LR)', () {
      final svc = LocaleService.forLocale(const Locale('en', 'GB'));
      expect(svc.unitSystem, UnitSystem.imperial);
      expect(svc.speedUnitLabel, 'mph');
    });

    test('PK locale uses metric', () {
      final svc = LocaleService.forLocale(const Locale('ur', 'PK'));
      expect(svc.unitSystem, UnitSystem.metric);
    });

    test('Myanmar (MM) uses imperial', () {
      final svc = LocaleService.forLocale(const Locale('my', 'MM'));
      expect(svc.unitSystem, UnitSystem.imperial);
    });

    test('Liberia (LR) uses imperial', () {
      final svc = LocaleService.forLocale(const Locale('en', 'LR'));
      expect(svc.unitSystem, UnitSystem.imperial);
    });

    test('Locale with no country falls back to metric', () {
      // countryCode itself still falls back to 'US' as a display default,
      // but unitSystem deliberately defaults to metric when the locale
      // carries no country at all — see LocaleService.unitSystem's doc:
      // most of the world is metric, and guessing imperial for a
      // region-less locale would show mph to users who'd never expect it.
      final svc = LocaleService.forLocale(const Locale('en'));
      expect(svc.countryCode, 'US');
      expect(svc.unitSystem, UnitSystem.metric);
    });

    test('user override beats locale default', () {
      final svc = LocaleService.forLocale(
        const Locale('en', 'US'),
        override: UnitSystem.metric,
      );
      expect(svc.unitSystem, UnitSystem.metric);
    });
  });

  group('LocaleService — formatting', () {
    test('formatSpeed converts km/h → mph for imperial locales', () {
      final us = LocaleService.forLocale(const Locale('en', 'US'));
      expect(us.formatSpeed(100), '62 mph');
    });

    test('formatSpeed leaves km/h alone for metric locales', () {
      final de = LocaleService.forLocale(const Locale('de', 'DE'));
      expect(de.formatSpeed(100), '100 km/h');
    });

    test('formatDistance converts km → mi for imperial', () {
      final us = LocaleService.forLocale(const Locale('en', 'US'));
      expect(us.formatDistance(10), '6.2 mi');
    });

    test('formatDuration handles seconds, minutes, hours', () {
      final svc = LocaleService.forLocale(const Locale('en', 'US'));
      expect(svc.formatDuration(45), '45s');
      expect(svc.formatDuration(125), '2m 5s');
      expect(svc.formatDuration(3725), '1h 2m');
    });

    test('formatCurrency renders the requested currency symbol', () {
      final svc = LocaleService.forLocale(const Locale('en', 'US'));
      final out = svc.formatCurrency(12.5, 'USD');
      // We don't pin an exact string because intl's formatter varies subtly
      // by ICU version — but USD symbol $ and the value 12.50 must appear.
      expect(out, contains(r'$'));
      expect(out, contains('12.50'));
    });
  });
}
