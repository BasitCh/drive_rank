import 'package:drive_rank/core/constants/app_colors.dart';
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
    (AppStrings.paywallFeature2Title, AppStrings.paywallFeature2Body),
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
            if (state.status == PaywallStatus.success) {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/home');
              }
            }
            if (state.status == PaywallStatus.error &&
                state.errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.errorMessage!)),
              );
            }
          },
          builder: (context, state) {
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
                  onIndex: (i) => context
                      .read<PaywallBloc>()
                      .add(PaywallFeatureScrolled(i)),
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
                  onTap: () => context
                      .read<PaywallBloc>()
                      .add(const PaywallPurchaseRequested()),
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
                    onPressed: () => context
                        .read<PaywallBloc>()
                        .add(const PaywallRestoreRequested()),
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
    final limit = snapshot?.freeTripLimit ?? 10;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.teal.withValues(alpha: 0.05),
            Colors.transparent,
          ],
        ),
        border: const Border(
          bottom: BorderSide(color: AppColors.border),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
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
                    borderRadius: BorderRadius.circular(
                      AppSpacing.radiusLg,
                    ),
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
    final crossed = package.crossedOutPriceString;
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
                  if (crossed != null)
                    Text(
                      crossed,
                      style: AppTextStyles.bodySmall.copyWith(
                        fontSize: 12,
                        color: AppColors.textTertiary,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
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
