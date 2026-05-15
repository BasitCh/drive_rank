import 'package:drive_rank/core/constants/app_colors.dart';
import 'package:drive_rank/core/constants/app_spacing.dart';
import 'package:drive_rank/core/constants/app_strings.dart';
import 'package:drive_rank/core/constants/app_text_styles.dart';
import 'package:drive_rank/core/di/injection.dart';
import 'package:drive_rank/core/router/route_names.dart';
import 'package:drive_rank/core/services/locale_service.dart';
import 'package:drive_rank/features/history/presentation/bloc/history_bloc.dart';
import 'package:drive_rank/features/history/presentation/widgets/filter_pills.dart';
import 'package:drive_rank/features/history/presentation/widgets/trip_list_item.dart';
import 'package:drive_rank/features/monthly_report/presentation/widgets/monthly_report_card.dart';
import 'package:drive_rank/shared/models/monthly_report.dart';
import 'package:drive_rank/shared/repositories/user_settings_repository.dart';
import 'package:drive_rank/shared/services/trip_stats_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<HistoryBloc>(
      create: (_) => getIt<HistoryBloc>()..add(const HistoryStarted()),
      child: const _HistoryBody(),
    );
  }
}

class _HistoryBody extends StatelessWidget {
  const _HistoryBody();

  @override
  Widget build(BuildContext context) {
    final locale = getIt<LocaleService>();
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: BlocBuilder<HistoryBloc, HistoryState>(
          builder: (context, state) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _Header(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    14,
                    0,
                    14,
                    AppSpacing.md,
                  ),
                  child: _MonthlyReportBanner(locale: locale),
                ),
                FilterPills(
                  active: state.filter,
                  onChanged: (f) => context
                      .read<HistoryBloc>()
                      .add(HistoryFilterChanged(f)),
                ),
                const SizedBox(height: AppSpacing.md),
                Expanded(child: _Body(state: state, locale: locale)),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(18, 10, 18, 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          AppStrings.historyTitle,
          style: AppTextStyles.sectionTitle,
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.state, required this.locale});

  final HistoryState state;
  final LocaleService locale;

  @override
  Widget build(BuildContext context) {
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.teal),
      );
    }
    final trips = state.visibleTrips;
    if (trips.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xxl),
          child: Text(
            AppStrings.historyEmpty,
            style: AppTextStyles.body,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
      itemCount: trips.length,
      separatorBuilder: (_, __) => const SizedBox(height: 5),
      itemBuilder: (_, i) {
        final t = trips[i];
        return Dismissible(
          key: ValueKey<int>(t.id),
          direction: DismissDirection.endToStart,
          background: const _DismissBackground(),
          confirmDismiss: (_) => _confirm(context),
          onDismissed: (_) =>
              context.read<HistoryBloc>().add(HistoryTripDeleted(t.id)),
          child: TripListItem(
            trip: t,
            locale: locale,
            onTap: () => context.push(RouteNames.tripSummaryFor(t.id)),
          ),
        );
      },
    );
  }

  Future<bool?> _confirm(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bg2,
        title: const Text(AppStrings.tripSummaryDelete),
        content: const Text(AppStrings.tripSummaryDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(AppStrings.delete),
          ),
        ],
      ),
    );
  }
}

class _DismissBackground extends StatelessWidget {
  const _DismissBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.red.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: const Icon(
        Icons.delete_outline_rounded,
        color: AppColors.red,
      ),
    );
  }
}

/// Loads the current month's report and renders the banner if there's data,
/// or shrinks to zero height if not — keeps the layout clean for new users.
class _MonthlyReportBanner extends StatefulWidget {
  const _MonthlyReportBanner({required this.locale});

  final LocaleService locale;

  @override
  State<_MonthlyReportBanner> createState() => _MonthlyReportBannerState();
}

class _MonthlyReportBannerState extends State<_MonthlyReportBanner> {
  late final Future<MonthlyReport> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<MonthlyReport> _load() async {
    final settings = await getIt<UserSettingsRepository>().read();
    final now = DateTime.now();
    return getIt<TripStatsService>().monthlyReport(
      uid: settings.uid,
      year: now.year,
      month: now.month,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<MonthlyReport>(
      future: _future,
      builder: (context, snap) {
        if (!snap.hasData || snap.data!.isEmpty) {
          return const SizedBox.shrink();
        }
        return MonthlyReportCard(
          report: snap.data!,
          locale: widget.locale,
          onTap: () => context.push(RouteNames.monthlyReport),
        );
      },
    );
  }
}
