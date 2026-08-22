import 'package:drive_rank/core/services/locale_service.dart';
import 'package:drive_rank/features/paywall/domain/entities/paywall_offering.dart';
import 'package:injectable/injectable.dart';
import 'package:intl/intl.dart';

/// Result of a purchase attempt.
enum PurchaseResult {
  /// User completed the purchase and the entitlement is now active.
  granted,

  /// User cancelled the platform purchase dialog.
  cancelled,

  /// Purchase failed (network, declined card, …). The caller surfaces a
  /// retryable toast.
  failed,
}

/// Result of checking whether the current identity holds an active Pro
/// entitlement — used at sign-in (see `CloudSyncService`/the sign-in
/// sequence), where a plain bool can't safely drive the local `isPro`
/// flag: "confirmed no entitlement" and "couldn't check" must be handled
/// differently (the former should downgrade a stale `isPro = true` from a
/// previous account; the latter must never downgrade a paying user on a
/// transient network blip).
enum ProEntitlementCheck {
  /// Entitlement confirmed active — set local `isPro = true`.
  active,

  /// Successfully checked with the provider; no active entitlement —
  /// set local `isPro = false`. This is the case a plain
  /// `restorePurchases() == false` can't distinguish from [unknown].
  inactive,

  /// Network/API error — the provider couldn't be reached. Leave the
  /// local `isPro` state exactly as it was; never guess.
  unknown,
}

/// Wraps the store layer (RevenueCat in production) so the paywall UI never
/// touches purchases_flutter directly. The interface is small on purpose —
/// load offering, purchase, restore — so swapping in a different store SDK
/// later is local to this file.
abstract class PaywallService {
  Future<PaywallOffering?> loadOffering();
  Future<PurchaseResult> purchase(PaywallPackage package);
  Future<bool> restorePurchases();

  /// Associates the store's notion of "who is this" with [appUserId]
  /// (the Firebase Auth uid) — call after a sign-in identity change, so
  /// entitlements follow the account rather than the device/install. A
  /// no-op default lets `PreviewPaywallService` skip it harmlessly.
  Future<void> identify(String appUserId) async {}

  /// Explicit three-way entitlement check — see [ProEntitlementCheck]. A
  /// no-op default (`unknown`) lets `PreviewPaywallService` skip it
  /// harmlessly (the sign-in sequence then correctly leaves local
  /// `isPro` untouched rather than granting/revoking Pro from a preview
  /// build).
  Future<ProEntitlementCheck> checkEntitlement() async =>
      ProEntitlementCheck.unknown;
}

/// Development implementation that synthesises a locale-priced offering so
/// the paywall UI renders before a RevenueCat account is configured.
///
/// Prices are deliberately rounded to "feels like a real store price" tiers
/// per currency so the screen doesn't look fake — these are previews only,
/// no purchase actually happens. Session 5 replaces this with a real
/// `RevenueCatPaywallService`.
@LazySingleton(as: PaywallService)
class PreviewPaywallService extends PaywallService {
  PreviewPaywallService(this._locale);

  final LocaleService _locale;

  @override
  Future<PaywallOffering?> loadOffering() async {
    final code = _locale.defaultCurrencyCode;
    final (annual, monthly) = _previewPricesFor(code);

    final symbol = NumberFormat.simpleCurrency(name: code).currencySymbol;
    String fmt(double v) {
      // Whole-number prices look more like real store prices than ".00".
      final hasFraction = v != v.roundToDouble();
      return NumberFormat.currency(
        symbol: symbol,
        decimalDigits: hasFraction ? 2 : 0,
      ).format(v);
    }

    final perWeek = annual / 52;

    return PaywallOffering(
      identifier: 'preview_default',
      annual: PaywallPackage(
        id: 'driverank_pro_annual_preview',
        period: PaywallPeriod.annual,
        priceString: '${fmt(annual)}/yr',
        priceMicros: (annual * 1000000).round(),
        currencyCode: code,
        // No crossed-out / "was" price — DriveRank's paywall has zero
        // dark patterns. Don't reintroduce one in the preview impl
        // either; the field has been dropped from the model.
        perWeekPriceString: '${fmt(perWeek)}/week',
      ),
      monthly: PaywallPackage(
        id: 'driverank_pro_monthly_preview',
        period: PaywallPeriod.monthly,
        priceString: '${fmt(monthly)}/mo',
        priceMicros: (monthly * 1000000).round(),
        currencyCode: code,
      ),
    );
  }

  @override
  Future<PurchaseResult> purchase(PaywallPackage package) async {
    // Preview can't actually charge — succeed silently so we can flow-test
    // the post-purchase navigation. Replaced with real flow in Session 5.
    return PurchaseResult.granted;
  }

  @override
  Future<bool> restorePurchases() async => false;

  /// Currency-aware tier table. Numbers are illustrative and meant to look
  /// reasonable next to real store pricing for each market — not used to
  /// charge users (the preview service never charges).
  (double annual, double monthly) _previewPricesFor(String code) {
    switch (code.toUpperCase()) {
      case 'USD':
        return (29.99, 4.99);
      case 'GBP':
        return (24.99, 3.99);
      case 'EUR':
        return (27.99, 4.49);
      case 'CAD':
        return (39.99, 5.99);
      case 'AUD':
        return (44.99, 6.99);
      case 'PKR':
        return (2599, 649);
      case 'INR':
        return (1999, 299);
      case 'BDT':
        return (1499, 249);
      case 'AED':
        return (109, 19);
      case 'SAR':
        return (109, 19);
      case 'JPY':
        return (3000, 500);
      case 'KRW':
        return (29000, 5500);
      case 'CNY':
        return (199, 29);
      case 'BRL':
        return (149, 24.9);
      case 'MXN':
        return (599, 99);
      case 'ZAR':
        return (549, 89);
      case 'TRY':
        return (599, 99);
      case 'IDR':
        return (459000, 79000);
      case 'THB':
        return (1099, 179);
      case 'PHP':
        return (1499, 249);
      case 'VND':
        return (749000, 129000);
      default:
        return (29.99, 4.99);
    }
  }
}
