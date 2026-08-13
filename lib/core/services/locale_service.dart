import 'dart:ui';

import 'package:drive_rank/core/constants/app_constants.dart';
import 'package:flutter/widgets.dart';
import 'package:injectable/injectable.dart';
import 'package:intl/intl.dart';

/// Unit system in use for display. Storage is always metric — see the
/// `Trips` table for the canonical units.
enum UnitSystem { metric, imperial }

/// Single source of truth for locale-derived display behaviour: which unit
/// system to use, what currency to format with, what the device's country is.
///
/// The user can override `unitSystem` in settings — pass `override` to
/// construct an override-aware instance via [withOverride]. The default
/// instance always reflects the device locale.
@lazySingleton
class LocaleService {
  LocaleService() : this._(PlatformDispatcher.instance.locale, null);

  LocaleService._(this._locale, this._overrideUnitSystem);

  /// Test seam — allows constructing a service with an arbitrary locale.
  @visibleForTesting
  LocaleService.forLocale(Locale locale, {UnitSystem? override})
    : _locale = locale,
      _overrideUnitSystem = override;

  final Locale _locale;
  final UnitSystem? _overrideUnitSystem;

  /// Returns a copy of this service with the user's unit-system override
  /// applied. Construct one of these whenever the user changes the setting
  /// and re-register it in the DI container.
  LocaleService withOverride(UnitSystem? override) =>
      LocaleService._(_locale, override);

  /// ISO 3166-1 alpha-2 country code from the device. Falls back to `US`.
  String get countryCode => _locale.countryCode ?? 'US';

  /// The active unit system: user override if set, else derived from
  /// country. When the device locale doesn't include a country code at
  /// all (common for English without a region), default to metric — most
  /// of the world is metric and an imperial fallback shows mph to users
  /// who would never expect it. The four imperial-system countries
  /// (US, GB, MM, LR) all set their country in the locale string.
  UnitSystem get unitSystem {
    final override = _overrideUnitSystem;
    if (override != null) return override;
    final rawCountry = _locale.countryCode;
    if (rawCountry == null || rawCountry.isEmpty) return UnitSystem.metric;
    return AppConstants.imperialCountryCodes.contains(rawCountry)
        ? UnitSystem.imperial
        : UnitSystem.metric;
  }

  /// "km/h" or "mph" — for labels that don't include the number.
  String get speedUnitLabel =>
      unitSystem == UnitSystem.imperial ? 'mph' : 'km/h';

  /// "km" or "mi" — for labels that don't include the number.
  String get distanceUnitLabel =>
      unitSystem == UnitSystem.imperial ? 'mi' : 'km';

  /// Format a speed for display. Input is always km/h (canonical storage).
  String formatSpeed(double kmh, {int fractionDigits = 0}) {
    final value = unitSystem == UnitSystem.imperial
        ? kmh * AppConstants.kmToMiles
        : kmh;
    return '${value.toStringAsFixed(fractionDigits)} $speedUnitLabel';
  }

  /// Format a speed *number only* — useful when the unit label is separate
  /// (e.g. the live speed hero, where unit sits below the number).
  String formatSpeedValue(double kmh, {int fractionDigits = 0}) {
    final value = unitSystem == UnitSystem.imperial
        ? kmh * AppConstants.kmToMiles
        : kmh;
    return value.toStringAsFixed(fractionDigits);
  }

  /// Format a distance for display. Input is always km (canonical storage).
  String formatDistance(double km, {int fractionDigits = 1}) {
    final value = unitSystem == UnitSystem.imperial
        ? km * AppConstants.kmToMiles
        : km;
    return '${value.toStringAsFixed(fractionDigits)} $distanceUnitLabel';
  }

  /// Format a currency amount using the device locale.
  ///
  /// `currencyCode` is an ISO 4217 code (e.g. `USD`, `PKR`, `EUR`). The
  /// symbol is looked up via `NumberFormat.simpleCurrency` so we never
  /// hardcode glyphs.
  String formatCurrency(double amount, String currencyCode) {
    final symbol = NumberFormat.simpleCurrency(
      name: currencyCode,
    ).currencySymbol;
    return NumberFormat.currency(
      locale: _locale.toLanguageTag(),
      symbol: symbol,
    ).format(amount);
  }

  /// Best-guess ISO 4217 currency code from the device locale. Used as a
  /// default when the user first opens fuel settings — they can change it.
  String get defaultCurrencyCode =>
      NumberFormat.simpleCurrency(
        locale: _locale.toLanguageTag(),
      ).currencyName ??
      'USD';

  /// Format a duration in seconds as `Hh Mm` or `Mm Ss`.
  String formatDuration(int totalSeconds) {
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    final s = totalSeconds % 60;
    if (h > 0) return '${h}h ${m}m';
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }
}
