import 'package:drive_rank/core/constants/app_strings.dart';
import 'package:drive_rank/shared/widgets/placeholder_page.dart';
import 'package:flutter/material.dart';

class PaywallPage extends StatelessWidget {
  const PaywallPage({super.key});

  @override
  Widget build(BuildContext context) => const PlaceholderPage(
    title: AppStrings.paywallTitle,
    subtitle: 'RevenueCat-driven paywall lands here in Session 4',
  );
}
