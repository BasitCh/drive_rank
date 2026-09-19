import 'package:drive_rank/core/constants/app_colors.dart';
import 'package:drive_rank/core/constants/app_strings.dart';
import 'package:drive_rank/core/constants/app_text_styles.dart';
import 'package:drive_rank/core/database/app_database.dart' show UserSettingsRow;
import 'package:drive_rank/core/di/injection.dart';
import 'package:drive_rank/features/onboarding/presentation/widgets/teal_button.dart';
import 'package:drive_rank/features/social/data/services/competition_visibility.dart';
import 'package:drive_rank/shared/repositories/user_settings_repository.dart';
import 'package:flutter/material.dart';

/// The "Join the Competition" notice. Pops `true` for join, `false` for
/// not now. Not dismissible by tapping outside: it is asked once, so it
/// needs an answer.
class JoinCompetitionDialog extends StatelessWidget {
  const JoinCompetitionDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.bg2,
      title: const Text(AppStrings.competitionJoinTitle),
      content: Text(
        AppStrings.competitionJoinBody,
        style: AppTextStyles.bodySmall.copyWith(
          color: AppColors.textSecondary,
          height: 1.45,
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TealButton(
              label: AppStrings.competitionJoinAction,
              onPressed: () => Navigator.of(context).pop(true),
            ),
            const SizedBox(height: 4),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(AppStrings.competitionNotNow),
            ),
          ],
        ),
      ],
    );
  }
}

/// Shows [JoinCompetitionDialog] and acts on the answer. Returns whether
/// the user joined.
Future<bool> askToJoinCompetition(BuildContext context) async {
  final joined = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const JoinCompetitionDialog(),
  );
  final visibility = getIt<CompetitionVisibility>();
  if (joined ?? false) {
    await visibility.join();
    return true;
  }
  await visibility.leave();
  return false;
}

/// Asks once, the first time the main screens show for somebody who has
/// finished onboarding and hasn't answered yet — existing users on their
/// first launch after the update, and new users once onboarding is done.
/// Not while the rankings kill switch is off: there is nothing to join.
class CompetitionInvite extends StatefulWidget {
  const CompetitionInvite({required this.child, super.key});

  final Widget child;

  @override
  State<CompetitionInvite> createState() => _CompetitionInviteState();
}

class _CompetitionInviteState extends State<CompetitionInvite> {
  bool _asking = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UserSettingsRow>(
      stream: getIt<UserSettingsRepository>().watch(),
      builder: (context, snapshot) {
        final row = snapshot.data;
        if (row != null &&
            !_asking &&
            row.onboardingComplete &&
            row.rankingsEnabled &&
            row.competitionOptIn == null) {
          _asking = true;
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            if (!mounted) return;
            await askToJoinCompetition(context);
          });
        }
        return widget.child;
      },
    );
  }
}
