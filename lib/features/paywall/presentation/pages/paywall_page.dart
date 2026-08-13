import 'dart:io' show Platform;

import 'package:drive_rank/core/constants/app_colors.dart';
import 'package:drive_rank/core/constants/app_constants.dart';
import 'package:drive_rank/core/constants/app_spacing.dart';
import 'package:drive_rank/core/constants/app_strings.dart';
import 'package:drive_rank/core/constants/app_text_styles.dart';
import 'package:drive_rank/core/di/injection.dart';
import 'package:drive_rank/core/services/locale_service.dart';
import 'package:drive_rank/features/paywall/domain/entities/paywall_offering.dart';
import 'package:drive_rank/features/paywall/presentation/bloc/paywall_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class PaywallPage extends StatelessWidget {
  const PaywallPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PaywallBloc>(
      create: (_) => getIt<PaywallBloc>()..add(const PaywallStarted()),
      child: const _PaywallBody(),
    );
  }
}

class _PaywallBody extends StatelessWidget {
  const _PaywallBody();

  static const _features = <(String, String)>[
    (AppStrings.paywallFeature1Title, AppStrings.paywallFeature1Body),
    // (AppStrings.paywallFeature2Title, AppStrings.paywallFeature2Body),
    (AppStrings.paywallFeature3Title, AppStrings.paywallFeature3Body),
    (AppStrings.paywallFeature4Title, AppStrings.paywallFeature4Body),
  ];

  @override
  Widget build(BuildContext context) {
    final locale = getIt<LocaleService>();
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: BlocConsumer<PaywallBloc, PaywallState>(
          listenWhen: (a, b) => a.status != b.status,
          listener: (context, state) {
            // No auto-pop on success anymore — `_SuccessView` below owns
            // dismissal via its own Done button, so the purchase (or
            // restore) gets an actual confirmation moment instead of the
            // paywall just vanishing.
            if (state.status == PaywallStatus.error &&
                state.errorMessage != null) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
            }
          },
          builder: (context, state) {
            if (state.status == PaywallStatus.success) {
              return const _SuccessView();
            }
            if (state.status == PaywallStatus.loading) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.teal),
              );
            }
            final offering = state.offering;
            if (offering == null) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.xxl),
                  child: Text(
                    AppStrings.paywallUnavailable,
                    style: AppTextStyles.body,
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            return _Loaded(
              state: state,
              offering: offering,
              features: _features,
              locale: locale,
            );
          },
        ),
      ),
    );
  }
}

class _Loaded extends StatelessWidget {
  const _Loaded({
    required this.state,
    required this.offering,
    required this.features,
    required this.locale,
  });

  final PaywallState state;
  final PaywallOffering offering;
  final List<(String, String)> features;
  final LocaleService locale;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _CloseBar(),
        _TripPreview(snapshot: state.snapshot, locale: locale),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _FeatureSwiper(
                  features: features,
                  activeIndex: state.featureIndex,
                  onIndex: (i) => context.read<PaywallBloc>().add(
                    PaywallFeatureScrolled(i),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                _PlanRow(
                  package: offering.annual,
                  isSelected: state.selected == PaywallPeriod.annual,
                  showBadge: true,
                  onTap: () => context.read<PaywallBloc>().add(
                    const PaywallPackageSelected(PaywallPeriod.annual),
                  ),
                ),
                const SizedBox(height: 8),
                _PlanRow(
                  package: offering.monthly,
                  isSelected: state.selected == PaywallPeriod.monthly,
                  showBadge: false,
                  onTap: () => context.read<PaywallBloc>().add(
                    const PaywallPackageSelected(PaywallPeriod.monthly),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                _ContinueButton(
                  isLoading: state.status == PaywallStatus.purchasing,
                  onTap: () => context.read<PaywallBloc>().add(
                    const PaywallPurchaseRequested(),
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: Text(
                    AppStrings.paywallFooter,
                    style: AppTextStyles.microLabel.copyWith(fontSize: 10),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 6),
                Center(
                  child: TextButton(
                    onPressed: () => context.read<PaywallBloc>().add(
                      const PaywallRestoreRequested(),
                    ),
                    child: const Text(AppStrings.paywallRestore),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TripPreview extends StatelessWidget {
  const _TripPreview({required this.snapshot, required this.locale});

  final PaywallSnapshot? snapshot;
  final LocaleService locale;

  @override
  Widget build(BuildContext context) {
    final speed = snapshot?.bestTopSpeedKmh ?? 0;
    final used = snapshot?.freeTripsUsed ?? 0;
    final limit = snapshot?.freeTripLimit ?? AppConstants.freeTripLimit;
    // The paywall is only reachable after `limit` trips, so a real best
    // speed always exists here — unless local trip history was wiped by
    // a reinstall (the free-trial counter survives it; trip records
    // don't). Swap the readout for an explanation instead of a
    // confusing "0 km/h" next to "limit reached."
    final isReinstall = used >= limit && speed <= 0;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.teal.withValues(alpha: 0.05), Colors.transparent],
        ),
        border: const Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: isReinstall
                ? Padding(
                    padding: const EdgeInsets.only(top: 2, right: 8),
                    child: Text(
                      AppStrings.paywallDeviceRecognized,
                      style: AppTextStyles.body.copyWith(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.paywallYourBestTrip,
                        style: AppTextStyles.microLabel.copyWith(
                          fontSize: 10,
                          color: AppColors.teal,
                          letterSpacing: 0.8,
                        ),
                      ),
                      Text(
                        locale.formatSpeed(speed),
                        style: const TextStyle(
                          fontFamily: 'BebasNeue',
                          fontSize: 48,
                          color: Colors.white,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        AppStrings.appName,
                        style: AppTextStyles.bodySmall.copyWith(
                          fontSize: 11,
                          color: AppColors.teal,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Trip $used ${AppStrings.paywallTripCountSuffix} $limit',
                style: AppTextStyles.microLabel.copyWith(fontSize: 10),
              ),
              const SizedBox(height: 2),
              Text(
                AppStrings.paywallTripLimitReached,
                style: AppTextStyles.microLabel.copyWith(
                  fontSize: 10,
                  color: AppColors.teal,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeatureSwiper extends StatefulWidget {
  const _FeatureSwiper({
    required this.features,
    required this.activeIndex,
    required this.onIndex,
  });

  final List<(String, String)> features;
  final int activeIndex;
  final ValueChanged<int> onIndex;

  @override
  State<_FeatureSwiper> createState() => _FeatureSwiperState();
}

class _FeatureSwiperState extends State<_FeatureSwiper> {
  late final PageController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PageController(
      initialPage: widget.activeIndex,
      viewportFraction: 0.92,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 140,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.features.length,
            onPageChanged: widget.onIndex,
            itemBuilder: (_, i) {
              final (title, body) = widget.features[i];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        body,
                        style: AppTextStyles.bodySmall.copyWith(
                          fontSize: 11,
                          height: 1.8,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < widget.features.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: i == widget.activeIndex ? 28 : 20,
                  height: 3,
                  decoration: BoxDecoration(
                    color: i == widget.activeIndex
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _PlanRow extends StatelessWidget {
  const _PlanRow({
    required this.package,
    required this.isSelected,
    required this.showBadge,
    required this.onTap,
  });

  final PaywallPackage package;
  final bool isSelected;
  final bool showBadge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // No crossed-out "was" price displayed anywhere — DriveRank's paywall
    // is explicitly free of dark patterns (no spin wheels, no countdowns,
    // no fake discounts). Real intro-offer prices from RevenueCat surface
    // through `introPriceString` on the package, never as a was-now diff.
    final perWeek = package.perWeekPriceString;
    final periodLabel = package.period == PaywallPeriod.annual
        ? AppStrings.paywallPlanAnnual
        : AppStrings.paywallPlanMonthly;
    return Material(
      color: isSelected
          ? AppColors.teal.withValues(alpha: 0.05)
          : AppColors.card,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(
              color: isSelected ? AppColors.teal : AppColors.border,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          periodLabel,
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (showBadge) ...[
                          const SizedBox(width: 6),
                          _BestValueBadge(),
                        ],
                      ],
                    ),
                    if (perWeek != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        perWeek,
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 11,
                          color: AppColors.teal,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    package.priceString,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BestValueBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.teal,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Text(
        AppStrings.paywallBadgeBestValue,
        style: TextStyle(
          fontFamily: 'JetBrainsMono',
          fontSize: 8,
          color: AppColors.bg,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ContinueButton extends StatelessWidget {
  const _ContinueButton({required this.isLoading, required this.onTap});

  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: Material(
        color: AppColors.teal,
        borderRadius: BorderRadius.circular(50),
        child: InkWell(
          borderRadius: BorderRadius.circular(50),
          onTap: isLoading ? null : onTap,
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: AppColors.bg,
                      strokeWidth: 2.5,
                    ),
                  )
                : const Text(
                    AppStrings.paywallContinue,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.bg,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

/// Top-of-paywall row with a close button. Lets the user dismiss the
/// paywall without scrolling for the system back gesture — important
/// because the page is presented on top of the trip summary route and
/// not all users discover the swipe-back gesture on Android.
///
/// Routes the close to `context.pop()` when there's a back stack, and
/// falls back to `/home` when the paywall was reached as a deep link.
class _CloseBar extends StatelessWidget {
  const _CloseBar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/home');
              }
            },
            tooltip: AppStrings.cancel,
            icon: const Icon(
              Icons.close_rounded,
              color: AppColors.textSecondary,
              size: 24,
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

/// Purchase (or restore) confirmation — replaces `_Loaded` once
/// `PaywallStatus.success` lands, instead of the paywall just popping
/// itself with zero acknowledgment. Reuses the same three feature
/// blurbs as `_FeatureSwiper` so the "what you unlocked" list matches
/// what was actually pitched a moment ago.
class _SuccessView extends StatelessWidget {
  const _SuccessView();

  static const _features = <(String, String)>[
    (AppStrings.paywallFeature1Title, AppStrings.paywallFeature1Body),
    (AppStrings.paywallFeature3Title, AppStrings.paywallFeature3Body),
    (AppStrings.paywallFeature4Title, AppStrings.paywallFeature4Body),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _CloseBar(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 84,
                    height: 84,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.tealDim,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.teal.withValues(alpha: 0.4),
                      ),
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: AppColors.teal,
                      size: 42,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.tealDim,
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusFull,
                      ),
                    ),
                    child: const Text(
                      AppStrings.paywallSuccessTag,
                      style: TextStyle(
                        fontFamily: 'JetBrainsMono',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.teal,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                const Text(
                  AppStrings.paywallSuccessTitle,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.headingLarge,
                ),
                const SizedBox(height: 6),
                Text(
                  AppStrings.paywallSuccessSubtitle,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                for (final (title, body) in _features) ...[
                  _SuccessFeatureRow(title: title, body: body),
                  const SizedBox(height: 12),
                ],
                const SizedBox(height: AppSpacing.md),
                const _ManageSubscriptionButton(),
                const SizedBox(height: 10),
                const _DoneButton(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SuccessFeatureRow extends StatelessWidget {
  const _SuccessFeatureRow({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 2),
          child: Icon(
            Icons.check_circle_rounded,
            color: AppColors.teal,
            size: 18,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                // First line only — the swiper's full body is 2-3 lines
                // meant for a standalone card; here it's a compact
                // checklist so one line per item is enough.
                body.split('\n').first,
                style: AppTextStyles.bodySmall.copyWith(fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Opens the platform's native subscription-management screen. Mirrors
/// `settings_page.dart`'s identical button — duplicated rather than
/// shared since it's two URL literals, not worth a service for.
class _ManageSubscriptionButton extends StatelessWidget {
  const _ManageSubscriptionButton();

  static const _playStoreUrl =
      'https://play.google.com/store/account/subscriptions'
      '?sku=driverank_pro_annual&package=com.bytse.drive_rank';
  static const _appleUrl = 'https://apps.apple.com/account/subscriptions';

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(50),
        child: InkWell(
          borderRadius: BorderRadius.circular(50),
          onTap: () => _open(context),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(50),
              border: Border.all(color: AppColors.border2),
            ),
            child: const Center(
              child: Text(
                AppStrings.paywallSuccessManage,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _open(BuildContext context) async {
    final url = Platform.isIOS ? _appleUrl : _playStoreUrl;
    final ok = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Couldn't open the link.")));
    }
  }
}

class _DoneButton extends StatelessWidget {
  const _DoneButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: Material(
        color: AppColors.teal,
        borderRadius: BorderRadius.circular(50),
        child: InkWell(
          borderRadius: BorderRadius.circular(50),
          onTap: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
          child: const Center(
            child: Text(
              AppStrings.paywallSuccessDone,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.bg,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
