import 'package:flutter/foundation.dart';

/// Subscription period of a paywall package.
enum PaywallPeriod { monthly, annual }

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
    this.crossedOutPriceString,
    this.perWeekPriceString,
  });

  final String id;
  final PaywallPeriod period;
  final String priceString;

  /// The price in micros of the currency's smallest unit (e.g. 2599000000
  /// for ₨2,599.00). Comparison-only — never displayed.
  final int priceMicros;

  final String currencyCode;

  final String? introPriceString;

  /// Optional "was" price shown crossed-out next to [priceString]. Only set
  /// when the offering itself defines a comparison price — never synthesised
  /// to fake a discount.
  final String? crossedOutPriceString;

  /// Optional "${price}/week" derived value the store provides for annual
  /// packages so users can compare across cadences without doing math.
  final String? perWeekPriceString;
}

@immutable
class PaywallOffering {
  const PaywallOffering({
    required this.identifier,
    required this.annual,
    required this.monthly,
  });

  final String identifier;
  final PaywallPackage annual;
  final PaywallPackage monthly;
}
