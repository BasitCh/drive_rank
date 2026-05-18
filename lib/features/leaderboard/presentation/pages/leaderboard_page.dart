import 'package:drive_rank/core/constants/app_colors.dart';
import 'package:drive_rank/core/constants/app_spacing.dart';
import 'package:drive_rank/core/constants/app_strings.dart';
import 'package:drive_rank/core/constants/app_text_styles.dart';
import 'package:drive_rank/core/di/injection.dart';
import 'package:drive_rank/core/services/locale_service.dart';
import 'package:drive_rank/features/friends/presentation/widgets/add_friend_sheet.dart';
import 'package:drive_rank/features/leaderboard/presentation/bloc/leaderboard_bloc.dart';
import 'package:drive_rank/features/leaderboard/presentation/widgets/leaderboard_row.dart';
import 'package:drive_rank/features/leaderboard/presentation/widgets/podium.dart';
import 'package:drive_rank/shared/models/leaderboard_entry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LeaderboardPage extends StatelessWidget {
  const LeaderboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<LeaderboardBloc>(
      create: (_) =>
          getIt<LeaderboardBloc>()..add(const LeaderboardStarted()),
      child: const _LeaderboardBody(),
    );
  }
}

class _LeaderboardBody extends StatelessWidget {
  const _LeaderboardBody();

  @override
  Widget build(BuildContext context) {
    final locale = getIt<LocaleService>();
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: BlocBuilder<LeaderboardBloc, LeaderboardState>(
          builder: (context, state) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Header(activeScope: state.activeScope),
                _ScopeTabs(
                  scopes: state.availableScopes,
                  active: state.activeScope,
                  onTap: (s) => context
                      .read<LeaderboardBloc>()
                      .add(LeaderboardScopeSelected(s)),
                ),
                const SizedBox(height: AppSpacing.md),
                Expanded(child: _List(state: state, locale: locale)),
                if (state.currentUserEntry != null)
                  _StickyUserFooter(
                    entry: state.currentUserEntry!,
                    locale: locale,
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.activeScope});

  final LeaderboardScope activeScope;

  @override
  Widget build(BuildContext context) {
    final sub = switch (activeScope) {
      LeaderboardScopeFriends _ =>
        AppStrings.leaderboardFriendsEmptyTitle,
      LeaderboardScopeGlobal _ =>
        '${AppStrings.leaderboardTabGlobal} · '
            '${AppStrings.leaderboardSubThisWeek}',
      final LeaderboardScopeCountry s =>
        '${s.countryCode} · ${AppStrings.leaderboardSubThisWeek}',
      final LeaderboardScopeSegment s =>
        '${s.segmentName} · ${AppStrings.leaderboardSubThisWeek}',
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '${AppStrings.leaderboardTitle} 🏆',
            style: AppTextStyles.sectionTitle,
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            style: AppTextStyles.bodySmall.copyWith(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScopeTabs extends StatelessWidget {
  const _ScopeTabs({
    required this.scopes,
    required this.active,
    required this.onTap,
  });

  final List<LeaderboardScope> scopes;
  final LeaderboardScope active;
  final ValueChanged<LeaderboardScope> onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 28,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        itemCount: scopes.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (_, i) {
          final s = scopes[i];
          final on = s.id == active.id;
          return Material(
            color: on ? AppColors.card2 : Colors.transparent,
            shape: StadiumBorder(
              side: BorderSide(
                color: on ? AppColors.border2 : AppColors.border,
              ),
            ),
            child: InkWell(
              customBorder: const StadiumBorder(),
              onTap: () => onTap(s),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                child: Text(
                  _label(s).toUpperCase(),
                  style: AppTextStyles.microLabel.copyWith(
                    fontSize: 9,
                    color: on
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _label(LeaderboardScope s) => switch (s) {
    LeaderboardScopeFriends _ => AppStrings.leaderboardTabFriends,
    LeaderboardScopeGlobal _ => '${AppStrings.leaderboardTabGlobal} 🌍',
    final LeaderboardScopeCountry sc => sc.countryCode,
    final LeaderboardScopeSegment sc => sc.segmentName,
  };
}

class _List extends StatelessWidget {
  const _List({required this.state, required this.locale});

  final LeaderboardState state;
  final LocaleService locale;

  @override
  Widget build(BuildContext context) {
    if (state.status == LeaderboardStatus.loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.teal),
      );
    }
    if (state.activeScope is LeaderboardScopeFriends &&
        state.entries.isEmpty) {
      return const _FriendsEmpty();
    }
    if (state.entries.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.xxl),
        child: Center(
          child: Text(
            AppStrings.leaderboardEmpty,
            style: AppTextStyles.body,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    final top = state.entries.take(3).toList();
    final first = top.isNotEmpty ? top[0] : null;
    final second = top.length > 1 ? top[1] : null;
    final third = top.length > 2 ? top[2] : null;
    final rest = state.entries.skip(3).toList();
    return ListView(
      padding: const EdgeInsets.only(bottom: 16),
      children: [
        Podium(
          first: first,
          second: second,
          third: third,
          locale: locale,
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Column(
            children: [
              for (final e in rest)
                Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: LeaderboardRow(entry: e, locale: locale),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FriendsEmpty extends StatelessWidget {
  const _FriendsEmpty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.people_outline_rounded,
              color: AppColors.teal,
              size: 36,
            ),
            const SizedBox(height: AppSpacing.md),
            const Text(
              AppStrings.leaderboardFriendsEmptyTitle,
              style: AppTextStyles.headingMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              AppStrings.leaderboardFriendsEmptyBody,
              style: AppTextStyles.body,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            ElevatedButton(
              onPressed: () => AddFriendSheet.show(context),
              child: const Text(AppStrings.leaderboardFriendsCta),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pinned at the bottom of the leaderboard when the user has an entry
/// but isn't in the visible top-N. Always teal-bordered + flagged as
/// "you" so it visually mirrors the inline row.
class _StickyUserFooter extends StatelessWidget {
  const _StickyUserFooter({required this.entry, required this.locale});

  final LeaderboardEntry entry;
  final LocaleService locale;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bg,
        border: Border(
          top: BorderSide(color: AppColors.border),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md + 2,
        AppSpacing.sm,
        AppSpacing.md + 2,
        AppSpacing.md,
      ),
      child: LeaderboardRow(entry: entry, locale: locale),
    );
  }
}
