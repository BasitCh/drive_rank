import 'package:drive_rank/shared/widgets/placeholder_page.dart';
import 'package:flutter/material.dart';

class TripSummaryPage extends StatelessWidget {
  const TripSummaryPage({required this.tripId, super.key});

  final int tripId;

  @override
  Widget build(BuildContext context) => PlaceholderPage(
    title: 'TRIP #$tripId',
    subtitle: 'Animated shareable stat card lands here in Session 3',
  );
}
