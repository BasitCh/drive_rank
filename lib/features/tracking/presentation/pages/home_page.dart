import 'package:drive_rank/core/constants/app_strings.dart';
import 'package:drive_rank/shared/widgets/placeholder_page.dart';
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) => const PlaceholderPage(
    title: AppStrings.navDrive,
    subtitle: 'Live tracking lands here in Session 2',
  );
}
