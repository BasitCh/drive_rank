import 'package:drive_rank/core/services/paywall_service.dart';
import 'package:drive_rank/features/paywall/domain/entities/paywall_offering.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show PlatformException;
// Hide RevenueCat's PurchaseResult — we expose our own (paywall_service.dart)
// so the UI layer doesn't import purchases_flutter.
import 'package:purchases_flutter/purchases_flutter.dart' hide PurchaseResult;

/// Production [PaywallService] backed by RevenueCat (`purchases_flutter`).
///
/// Registered by `bootstrap.dart` when the appropriate platform API key
/// is available via `--dart-define=REVENUECAT_API_KEY_ANDROID=...` /
/// `REVENUECAT_API_KEY_IOS=...`. If neither key is present at startup
/// the `PreviewPaywallService` stays registered and the paywall renders
/// with locale-priced previews (no real charge).
///
/// Setup expectations (see `SETUP.md`):
///   - RevenueCat dashboard project with an entitlement named `pro`.
///   - A `default` offering with `monthly` and `annual` packages
///     attached to your store products.
///   - Products configured in App Store Connect / Play Console with
///     the IDs declared in [annualProductId] / [monthlyProductId]
///     and priced at $14.99 / yr and $2.99 / mo (deliberately cheaper
///     than the TripRank ~$21/yr benchmark — DriveRank's positioning
///     is "honest pricing, no dark patterns").
///
/// The string `priceString` we return is RevenueCat's already-localised
/// store string — we never reformat it ourselves. That's what
/// guarantees the right currency and decimal grouping for every user's
/// store country. Never hardcode a price in the UI; always read from
/// `package.priceString`.
class RevenueCatPaywallService implements PaywallService {
  RevenueCatPaywallService._();

  /// Entitlement identifier configured in the RevenueCat dashboard.
  static const String entitlementId = 'pro';

  /// Offering identifier — must match the dashboard's offering name.
  static const String offeringId = 'default';

  /// Annual product identifier (App Store Connect + Play Console must
  /// have a product with exactly this id, priced at $14.99 / yr).
  static const String annualProductId = 'driverank_pro_annual';

  /// Monthly product identifier (App Store Connect + Play Console
  /// must have a product with exactly this id, priced at $2.99 / mo).
  static const String monthlyProductId = 'driverank_pro_monthly';

  /// Initialise the RevenueCat SDK and return a service ready to be
  /// registered in the DI container. Returns `null` if configuration is
  /// missing — the caller falls back to the preview service.
  static Future<RevenueCatPaywallService?> init({
    required String androidApiKey,
    required String iosApiKey,
    String? appUserId,
  }) async {
    if (androidApiKey.isEmpty && iosApiKey.isEmpty) return null;
    try {
      await Purchases.setLogLevel(
        kDebugMode ? LogLevel.info : LogLevel.error,
      );
      final config = PurchasesConfiguration(
        defaultTargetPlatform == TargetPlatform.iOS
            ? iosApiKey
            : androidApiKey,
      );
      if (appUserId != null && appUserId.isNotEmpty) {
        config.appUserID = appUserId;
      }
      await Purchases.configure(config);
      return RevenueCatPaywallService._();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[RevenueCat] init failed: $e');
      }
      return null;
    }
  }

  /// Identify the RevenueCat customer once the local user signs in / is
  /// linked to a Firebase UID. Safe to call multiple times.
  Future<void> identify(String appUserId) async {
    if (appUserId.isEmpty) return;
    try {
      await Purchases.logIn(appUserId);
    } catch (e) {
      if (kDebugMode) debugPrint('[RevenueCat] identify failed: $e');
    }
  }

  @override
  Future<PaywallOffering?> loadOffering() async {
    try {
      final offerings = await Purchases.getOfferings();
      final current = offerings.current;
      if (current == null) return null;

      final annual = current.annual ?? _fallback(current.availablePackages,
          PackageType.annual);
      final monthly = current.monthly ?? _fallback(current.availablePackages,
          PackageType.monthly);
      if (annual == null || monthly == null) return null;

      return PaywallOffering(
        identifier: current.identifier,
        annual: _mapPackage(annual, PaywallPeriod.annual),
        monthly: _mapPackage(monthly, PaywallPeriod.monthly),
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[RevenueCat] loadOffering failed: $e');
      return null;
    }
  }

  @override
  Future<PurchaseResult> purchase(PaywallPackage package) async {
    try {
      // Look up the live Package by id — we don't keep a reference around
      // because RevenueCat caches them internally and the dashboard's
      // packages can change at runtime.
      final offerings = await Purchases.getOfferings();
      final all = offerings.current?.availablePackages ?? <Package>[];
      final match = all
          .where((p) => p.storeProduct.identifier == package.id)
          .firstOrNull;
      if (match == null) return PurchaseResult.failed;

      // New API: Purchases.purchase(PurchaseParams.package(...)) returns a
      // `PurchaseResult` (hidden from our import to avoid the name clash
      // with our own enum) — type inference lets us drill into its
      // `customerInfo.entitlements.active` map without naming the type.
      final result = await Purchases.purchase(PurchaseParams.package(match));
      final isActive =
          result.customerInfo.entitlements.active.containsKey(entitlementId);
      return isActive ? PurchaseResult.granted : PurchaseResult.failed;
    } on PlatformException catch (e) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      if (code == PurchasesErrorCode.purchaseCancelledError) {
        return PurchaseResult.cancelled;
      }
      if (kDebugMode) debugPrint('[RevenueCat] purchase failed: $code');
      return PurchaseResult.failed;
    } catch (e) {
      if (kDebugMode) debugPrint('[RevenueCat] purchase failed: $e');
      return PurchaseResult.failed;
    }
  }

  @override
  Future<bool> restorePurchases() async {
    try {
      final customer = await Purchases.restorePurchases();
      return customer.entitlements.active.containsKey(entitlementId);
    } catch (e) {
      if (kDebugMode) debugPrint('[RevenueCat] restore failed: $e');
      return false;
    }
  }

  /// True if the user currently holds the `pro` entitlement.
  Future<bool> isPro() async {
    try {
      final customer = await Purchases.getCustomerInfo();
      return customer.entitlements.active.containsKey(entitlementId);
    } catch (_) {
      return false;
    }
  }

  Package? _fallback(List<Package> all, PackageType type) {
    for (final p in all) {
      if (p.packageType == type) return p;
    }
    return null;
  }

  PaywallPackage _mapPackage(Package p, PaywallPeriod period) {
    final product = p.storeProduct;
    return PaywallPackage(
      id: product.identifier,
      period: period,
      priceString: product.priceString,
      priceMicros: (product.price * 1000000).round(),
      currencyCode: product.currencyCode,
      introPriceString: product.introductoryPrice?.priceString,
    );
  }
}
