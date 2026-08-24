import 'package:flutter/foundation.dart';

/// Subscription period of a paywall package — covers every RevenueCat
/// `PackageType` that could realistically appear in the `default`
/// offering, so a new plan added on the dashboard (e.g. weekly) renders
/// correctly without a code change here.
enum PaywallPeriod {
  annual,
  sixMonth,
  threeMonth,
  twoMonth,
  monthly,
  weekly,
  lifetime,
  other;

  /// Approximate length in months — used only to compute the
  /// "effective monthly cost" comparison, never displayed directly.
  /// Null for [lifetime]/[other], which have no meaningful monthly
  /// equivalent.
  double? get approxMonths => switch (this) {
    annual => 12,
    sixMonth => 6,
    threeMonth => 3,
    twoMonth => 2,
    monthly => 1,
    weekly => 12 / 52, // ≈0.23 — matches a 52-week year, not 4×.
    lifetime || other => null,
  };
}

/// One purchasable subscription package displayed on the paywall.
///
/// `priceString` is the *pre-formatted* string from the store (RevenueCat
/// returns this as `Package.storeProduct.priceString` — already localised
/// to the user's App Store / Play Store country). We never reformat or
/// reconstruct this client-side; doing so risks showing a US-dollar string
/// to a user whose store is set to a different currency.
@immutable
class PaywallPackage {
  const PaywallPackage({
    required this.id,
    required this.period,
    required this.priceString,
    required this.priceMicros,
    required this.currencyCode,
    this.introPriceString,
    this.perWeekPriceString,
  });

  final String id;
  final PaywallPeriod period;
  final String priceString;

  /// The price in micros of the currency's smallest unit (e.g. 2599000000
  /// for ₨2,599.00). Comparison/math only — never displayed directly;
  /// the *effective monthly cost* derived from it for display is
  /// formatted via `NumberFormat.currency`, not string-built.
  final int priceMicros;

  final String currencyCode;

  /// Genuine intro-offer price from the store (e.g. "First month $0.99").
  /// Only surfaced when RevenueCat reports one — we never synthesise it.
  final String? introPriceString;

  /// Optional "${price}/week" derived value the store provides for annual
  /// packages so users can compare across cadences without doing math.
  final String? perWeekPriceString;

  // Note: `crossedOutPriceString` was removed — DriveRank's paywall has
  // zero dark patterns. Real discounts surface as [introPriceString];
  // there is no path for a fake "was" price to make it into the UI.
}

@immutable
class PaywallOffering {
  const PaywallOffering({required this.identifier, required this.packages});

  final String identifier;

  /// Every purchasable package in this offering — rendered dynamically,
  /// not assumed to be exactly annual+monthly. Order is whatever the
  /// store/service returned (RevenueCat lists a dashboard's packages in
  /// the order configured there).
  final List<PaywallPackage> packages;

  PaywallPackage? get annual => _firstOfPeriod(PaywallPeriod.annual);
  PaywallPackage? get monthly => _firstOfPeriod(PaywallPeriod.monthly);

  PaywallPackage? _firstOfPeriod(PaywallPeriod period) {
    for (final p in packages) {
      if (p.period == period) return p;
    }
    return null;
  }
}
