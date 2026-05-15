import 'package:drive_rank/core/constants/app_strings.dart';
import 'package:drive_rank/shared/widgets/placeholder_page.dart';
import 'package:flutter/material.dart';

class LeaderboardPage extends StatelessWidget {
  const LeaderboardPage({super.key});

  @override
  Widget build(BuildContext context) => const PlaceholderPage(
    title: AppStrings.leaderboardTitle,
    subtitle: AppStrings.leaderboardSubGlobal,
  );
}
