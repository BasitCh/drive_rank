import 'package:drive_rank/core/constants/app_colors.dart';
import 'package:drive_rank/core/constants/app_spacing.dart';
import 'package:drive_rank/core/constants/app_strings.dart';
import 'package:drive_rank/core/constants/app_text_styles.dart';
import 'package:drive_rank/core/di/injection.dart';
import 'package:drive_rank/features/social/domain/entities/competition_mirror.dart';
import 'package:drive_rank/features/social/domain/entities/friend.dart';
import 'package:drive_rank/features/social/domain/entities/friend_request.dart';
import 'package:drive_rank/features/social/presentation/bloc/friends_bloc.dart';
import 'package:drive_rank/features/social/presentation/widgets/add_friend_sheet.dart';
import 'package:drive_rank/shared/models/country.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';

/// Who you compete with.
///
/// Deliberately its own page rather than a Rankings tab: Rankings is for
/// competing, this is for deciding who you compete against. It is also
/// not behind the rankings kill switch — that switch hides global
/// standings, and the column's own doc scopes it that way.
class FriendsPage extends StatelessWidget {
  const FriendsPage({super.key}) : _providesBloc = true;

  /// Renders against a bloc the caller already provided, instead of
  /// resolving one from `getIt` — for widget tests, which drive states
  /// directly rather than standing up the whole dependency graph.
  const FriendsPage.forTesting({super.key}) : _providesBloc = false;

  final bool _providesBloc;

  @override
  Widget build(BuildContext context) {
    if (!_providesBloc) return const _FriendsBody();
    return BlocProvider<FriendsBloc>(
      create: (_) => getIt<FriendsBloc>()..add(const FriendsStarted()),
      child: const _FriendsBody(),
    );
  }
}

class _FriendsBody extends StatelessWidget {
  const _FriendsBody();

  Future<void> _add(BuildContext context) {
    final bloc = context.read<FriendsBloc>();
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.bg2,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      // The sheet reads and writes the same bloc as the page, so a
      // request sent inside it lands in the list behind it.
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: const AddFriendSheet(),
      ),
    ).whenComplete(() => bloc.add(const FriendsLookupCleared()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        title: const Text(AppStrings.friendsTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_rounded),
            color: AppColors.teal,
            onPressed: () => _add(context),
          ),
        ],
      ),
      body: BlocBuilder<FriendsBloc, FriendsState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.teal),
            );
          }

          return RefreshIndicator(
            color: AppColors.teal,
            backgroundColor: AppColors.card,
            onRefresh: () async =>
                context.read<FriendsBloc>().add(const FriendsRefreshed()),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
              children: [
                _InviteCard(state: state),
                if (state.incoming.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  const _SectionLabel(AppStrings.friendsIncomingTitle),
                  const SizedBox(height: AppSpacing.sm),
                  for (final request in state.incoming) ...[
                    _RequestRow(request: request),
                    const SizedBox(height: 6),
                  ],
                ],
                const SizedBox(height: AppSpacing.lg),
                const _SectionLabel(AppStrings.friendsSectionTitle),
                const SizedBox(height: AppSpacing.sm),
                if (state.friends.isEmpty)
                  const _Empty()
                else
                  for (final friend in state.friends) ...[
                    _FriendRow(
                      friend: friend,
                      profile: state.friendProfiles[friend.friendUid],
                    ),
                    const SizedBox(height: 6),
                  ],
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Your own code, and the way to send it.
class _InviteCard extends StatelessWidget {
  const _InviteCard({required this.state});

  final FriendsState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.teal.withValues(alpha: 0.10),
            AppColors.teal.withValues(alpha: 0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: AppColors.teal.withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.friendsYourCodeLabel,
            style: AppTextStyles.label.copyWith(
              fontSize: 10,
              color: AppColors.teal,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  state.inviteCode,
                  style: const TextStyle(
                    fontFamily: 'JetBrainsMono',
                    fontSize: 26,
                    letterSpacing: 3,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              _ShareButton(code: state.inviteCode),
            ],
          ),
          // Only shown when it is true and actionable: an account whose
          // username was never reserved cannot be found by name, and
          // saying so is more useful than letting them wonder why
          // nobody finds them.
          if (!state.canBeFoundByName) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              AppStrings.friendsUnsearchableNotice,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ShareButton extends StatelessWidget {
  const _ShareButton({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.teal,
      borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        onTap: code.isEmpty
            ? null
            : () {
                // The share sheet needs an anchor on iPad, or it has
                // nowhere to point and the call throws. Nothing else in
                // the app sets this yet.
                final box = context.findRenderObject() as RenderBox?;
                final origin = box == null
                    ? null
                    : box.localToGlobal(Offset.zero) & box.size;
                Share.share(
                  AppStrings.friendsShareMessage(code),
                  sharePositionOrigin: origin,
                );
              },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: Row(
            children: [
              const Icon(Icons.ios_share_rounded, size: 15, color: AppColors.bg),
              const SizedBox(width: 6),
              Text(
                AppStrings.friendsShareCode.toUpperCase(),
                style: AppTextStyles.microLabel.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.bg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RequestRow extends StatelessWidget {
  const _RequestRow({required this.request});

  final FriendRequest request;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<FriendsBloc>();
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.teal.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${AppStrings.friendsRequestPrefix}${request.fromUid}'
              '${AppStrings.friendsRequestSuffix}',
              maxLines: 2,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
          TextButton(
            onPressed: () =>
                bloc.add(FriendsRequestAnswered(request, accept: false)),
            child: const Text(
              AppStrings.friendsDecline,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () =>
                bloc.add(FriendsRequestAnswered(request, accept: true)),
            child: const Text(
              AppStrings.friendsAccept,
              style: TextStyle(color: AppColors.teal),
            ),
          ),
        ],
      ),
    );
  }
}

class _FriendRow extends StatelessWidget {
  const _FriendRow({required this.friend, this.profile});

  final Friend friend;

  /// Null when they've never published — a friend with no drives yet is
  /// still a friend, so the row renders from the local record.
  final CompetitionMirror? profile;

  Future<void> _confirmRemove(BuildContext context) async {
    final bloc = context.read<FriendsBloc>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.bg2,
        title: const Text(AppStrings.friendsRemove),
        content: const Text(AppStrings.friendsRemoveConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              AppStrings.delete,
              style: TextStyle(color: AppColors.red),
            ),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      bloc.add(FriendsRemoved(friend.friendUid));
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = profile?.username.isNotEmpty ?? false
        ? profile!.username
        : friend.friendUid;
    final flag = countryFromCode(profile?.countryCode ?? '')?.flag;
    final car = [
      profile?.carMake ?? '',
      profile?.carModel ?? '',
    ].where((s) => s.isNotEmpty).join(' ');
    final subtitle = [
      if (flag != null) flag,
      if (car.isNotEmpty) car,
    ].join('  ·  ');

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.microLabel.copyWith(fontSize: 10),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_horiz_rounded),
            color: AppColors.textTertiary,
            onPressed: () => _confirmRemove(context),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: AppTextStyles.label.copyWith(
      fontSize: 10,
      color: AppColors.textTertiary,
    ),
  );
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.friendsEmptyTitle,
            style: AppTextStyles.title.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            AppStrings.friendsEmptyBody,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
