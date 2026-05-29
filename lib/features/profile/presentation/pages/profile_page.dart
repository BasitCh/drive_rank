import 'package:drive_rank/core/constants/app_colors.dart';
import 'package:drive_rank/core/constants/app_spacing.dart';
import 'package:drive_rank/core/constants/app_strings.dart';
import 'package:drive_rank/core/constants/app_text_styles.dart';
import 'package:drive_rank/core/database/app_database.dart';
import 'package:drive_rank/core/di/injection.dart';
import 'package:drive_rank/core/router/route_names.dart';
import 'package:drive_rank/core/services/auth_service.dart';
import 'package:drive_rank/core/services/locale_service.dart';
import 'package:drive_rank/features/monthly_report/presentation/widgets/monthly_report_card.dart';
import 'package:drive_rank/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:drive_rank/shared/models/country.dart';
import 'package:drive_rank/shared/models/monthly_report.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ProfileBloc>(
      create: (_) => getIt<ProfileBloc>()..add(const ProfileLoaded()),
      child: const _ProfileBody(),
    );
  }
}

class _ProfileBody extends StatelessWidget {
  const _ProfileBody();

  @override
  Widget build(BuildContext context) {
    final locale = getIt<LocaleService>();
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: BlocBuilder<ProfileBloc, ProfileState>(
          builder: (context, state) {
            if (state.status == ProfileStatus.loading ||
                state.settings == null) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.teal),
              );
            }
            return _Loaded(
              settings: state.settings!,
              lifetime: state.lifetime,
              monthly: state.currentMonth,
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
    required this.settings,
    required this.lifetime,
    required this.monthly,
    required this.locale,
  });

  final UserSettingsRow settings;
  final LifetimeStats lifetime;
  final MonthlyReport monthly;
  final LocaleService locale;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        _Header(settings: settings),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: MonthlyReportCard(
            report: monthly,
            locale: locale,
            onTap: () => context.push(RouteNames.monthlyReport),
          ),
        ),
        const SizedBox(height: 14),
        _StatsGrid(lifetime: lifetime, locale: locale),
        const SizedBox(height: 14),
        // (Friends section + "Add friend" row removed for MVP — see
        // CHANGELOG / git history for the social-feature feature flag.)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: _ActionRow(
            label: AppStrings.profileEditSettings,
            icon: Icons.tune_rounded,
            onTap: () => context.push(RouteNames.settings),
          ),
        ),
        const SizedBox(height: 10),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 14),
          child: _AuthRow(),
        ),
      ],
    );
  }
}

class _AuthRow extends StatelessWidget {
  const _AuthRow();

  @override
  Widget build(BuildContext context) {
    final auth = getIt<AuthService>();
    return StreamBuilder<AuthUser>(
      stream: auth.userChanges,
      initialData: auth.currentUser,
      builder: (context, snap) {
        final user = snap.data ?? auth.currentUser;
        final isSignedIn = !user.isAnonymous;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isSignedIn) ...[
              _ActionRow(
                label: '${AppStrings.profileSignedInAs} '
                    '${user.displayName ?? user.email ?? user.uid}',
                icon: Icons.verified_user_rounded,
                onTap: () {},
              ),
              const SizedBox(height: 8),
              _ActionRow(
                label: AppStrings.profileSignOut,
                icon: Icons.logout_rounded,
                onTap: () async {
                  await auth.signOut();
                },
              ),
            ] else ...[
              _ActionRow(
                label: AppStrings.profileSignInGoogle,
                icon: Icons.login_rounded,
                onTap: () async {
                  final result = await auth.signInWithGoogle();
                  if (!context.mounted) return;
                  if (result == SignInResult.failed) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(AppStrings.profileSignedOut),
                      ),
                    );
                  }
                },
              ),
            ],
          ],
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.settings});

  final UserSettingsRow settings;

  @override
  Widget build(BuildContext context) {
    final country = countryFromCode(settings.country ?? 'US');
    final username = settings.username.isEmpty
        ? AppStrings.profileUsernamePlaceholder
        : settings.username;
    final carLabel = [
      if (settings.carMake.isNotEmpty) settings.carMake,
      if (settings.carModel.isNotEmpty) settings.carModel,
      if (settings.carYear != null) settings.carYear.toString(),
    ].join(' ');
    final meta = [
      if (country != null) '${country.flag} ${country.name}',
      if (carLabel.isNotEmpty) carLabel,
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 16),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.card,
              border: Border.all(color: AppColors.teal, width: 2),
            ),
            alignment: Alignment.center,
            child: const Text('🚗', style: TextStyle(fontSize: 24)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username,
                  style: AppTextStyles.headingMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  meta,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.lifetime, required this.locale});

  final LifetimeStats lifetime;
  final LocaleService locale;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: '⚡',
                  value: locale.formatSpeedValue(lifetime.topSpeedKmh),
                  unit: locale.speedUnitLabel,
                  label: AppStrings.profileStatTopSpeed,
                  valueColor: AppColors.teal,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatCard(
                  icon: '🏁',
                  value: lifetime.tripCount.toString(),
                  label: AppStrings.profileStatTotalTrips,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: '🛣️',
                  value: locale.formatDistance(
                    lifetime.totalDistanceKm,
                    fractionDigits: 0,
                  ),
                  label: AppStrings.profileStatTotalDistance,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatCard(
                  icon: '⚡',
                  value: '${lifetime.bestGforce.toStringAsFixed(1)}g',
                  label: AppStrings.profileStatBestGforce,
                  valueColor: AppColors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    this.unit,
    this.valueColor,
  });

  final String icon;
  final String value;
  final String? unit;
  final String label;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: valueColor ?? AppColors.textPrimary,
                ),
              ),
              if (unit != null) ...[
                const SizedBox(width: 4),
                Text(
                  unit!,
                  style: AppTextStyles.microLabel.copyWith(fontSize: 10),
                ),
              ],
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.microLabel.copyWith(fontSize: 9),
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.textSecondary, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textTertiary,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
