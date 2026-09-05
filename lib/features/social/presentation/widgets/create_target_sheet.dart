import 'package:drive_rank/core/constants/app_colors.dart';
import 'package:drive_rank/core/constants/app_spacing.dart';
import 'package:drive_rank/core/constants/app_strings.dart';
import 'package:drive_rank/core/constants/app_text_styles.dart';
import 'package:drive_rank/features/onboarding/presentation/widgets/teal_button.dart';
import 'package:drive_rank/features/social/domain/entities/challenge.dart';
import 'package:drive_rank/features/social/domain/entities/leaderboard_period.dart';
import 'package:drive_rank/features/social/presentation/widgets/ranking_pills.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// What the sheet hands back.
///
/// A period, not a date range. The window is derived by `CreateTarget`
/// from `CompetitionWindow` — the same factory the calculators and the
/// board use — so this sheet cannot invent its own idea of when a week
/// starts or drift by an hour across a DST boundary.
@immutable
class NewTargetRequest {
  const NewTargetRequest({
    required this.metric,
    required this.period,
    required this.value,
  });

  final CompetitionMetric metric;
  final LeaderboardPeriod period;
  final double value;
}

/// Bottom sheet for setting a personal target.
///
/// One sheet, three choices, no wizard — the app has no multi-step
/// picker anywhere and this doesn't need to be the first. Stateful so
/// the `TextEditingController` is owned by something with a lifecycle
/// and disposed on close, which is the lesson recorded on
/// `_CustomModelSheet` in the onboarding car step.
class CreateTargetSheet extends StatefulWidget {
  const CreateTargetSheet({required this.deadlineFor, super.key});

  /// Formats the deadline a given period would inherit, e.g.
  /// "Ends Sunday". Passed in so the sheet displays the window without
  /// computing it.
  final String Function(LeaderboardPeriod) deadlineFor;

  @override
  State<CreateTargetSheet> createState() => _CreateTargetSheetState();
}

class _CreateTargetSheetState extends State<CreateTargetSheet> {
  static const _metrics = <(CompetitionMetric, String)>[
    (CompetitionMetric.distance, AppStrings.rankingsMetricDistance),
    (CompetitionMetric.longestTrip, AppStrings.rankingsMetricLongestTrip),
    (CompetitionMetric.consistency, AppStrings.rankingsMetricConsistency),
  ];

  static const _periods = <(LeaderboardPeriod, String)>[
    (LeaderboardPeriod.weekly, AppStrings.rankingsPeriodWeek),
    (LeaderboardPeriod.monthly, AppStrings.rankingsPeriodMonth),
    (LeaderboardPeriod.allTime, AppStrings.rankingsPeriodAllTime),
  ];

  late final TextEditingController _value;
  CompetitionMetric _metric = CompetitionMetric.distance;
  LeaderboardPeriod _period = LeaderboardPeriod.weekly;
  bool _showError = false;

  @override
  void initState() {
    super.initState();
    _value = TextEditingController();
  }

  @override
  void dispose() {
    _value.dispose();
    super.dispose();
  }

  bool get _isDays => _metric == CompetitionMetric.consistency;

  double? get _parsed {
    final parsed = double.tryParse(_value.text.trim());
    if (parsed == null || parsed <= 0) return null;
    return parsed;
  }

  void _submit() {
    final value = _parsed;
    if (value == null) {
      setState(() => _showError = true);
      return;
    }
    Navigator.of(
      context,
    ).pop(NewTargetRequest(metric: _metric, period: _period, value: value));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border2,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const Text(
                AppStrings.createTargetTitle,
                style: AppTextStyles.headingMedium,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                AppStrings.createTargetMetricLabel,
                style: AppTextStyles.label.copyWith(fontSize: 10),
              ),
              const SizedBox(height: AppSpacing.sm),
              RankingPills<CompetitionMetric>(
                items: _metrics,
                active: _metric,
                onChanged: (m) => setState(() => _metric = m),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                AppStrings.createTargetPeriodLabel,
                style: AppTextStyles.label.copyWith(fontSize: 10),
              ),
              const SizedBox(height: AppSpacing.sm),
              RankingPills<LeaderboardPeriod>(
                items: _periods,
                active: _period,
                onChanged: (p) => setState(() => _period = p),
              ),
              const SizedBox(height: 6),
              // The deadline the chosen period carries. Shown so a
              // target set late on a Sunday doesn't quietly inherit a
              // window with minutes left in it.
              Text(
                widget.deadlineFor(_period),
                style: AppTextStyles.microLabel.copyWith(fontSize: 10),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                AppStrings.createTargetValueLabel,
                style: AppTextStyles.label.copyWith(fontSize: 10),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _value,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp('[0-9.]')),
                ],
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                onChanged: (_) {
                  if (_showError) setState(() => _showError = false);
                },
                decoration: InputDecoration(
                  hintText: _isDays
                      ? AppStrings.createTargetValueHintDays
                      : AppStrings.createTargetValueHintDistance,
                  errorText: _showError ? AppStrings.createTargetInvalid : null,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              TealButton(
                label: AppStrings.createTargetSave,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
