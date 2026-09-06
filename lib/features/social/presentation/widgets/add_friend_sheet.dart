import 'package:drive_rank/core/constants/app_colors.dart';
import 'package:drive_rank/core/constants/app_spacing.dart';
import 'package:drive_rank/core/constants/app_strings.dart';
import 'package:drive_rank/core/constants/app_text_styles.dart';
import 'package:drive_rank/features/social/presentation/bloc/friends_bloc.dart';
import 'package:drive_rank/features/social/presentation/widgets/ranking_pills.dart';
import 'package:drive_rank/shared/models/country.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Find one person and ask to be their friend.
///
/// Two ways in, because they answer different situations: a username
/// works for anyone who reserved theirs, and a code works for everyone —
/// including accounts whose username collided on upgrade and are
/// therefore unsearchable.
///
/// Follows `CreateTargetSheet`'s conventions: the sheet owns its
/// controller, the grab handle and rounded top match, and submitting
/// from the keyboard does the same thing as the button.
class AddFriendSheet extends StatefulWidget {
  const AddFriendSheet({super.key});

  @override
  State<AddFriendSheet> createState() => _AddFriendSheetState();
}

enum _Mode { username, code }

class _AddFriendSheetState extends State<AddFriendSheet> {
  final _controller = TextEditingController();
  _Mode _mode = _Mode.code;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _search() {
    final query = _controller.text.trim();
    if (query.isEmpty) return;
    context.read<FriendsBloc>().add(
      FriendsLookupRequested(query, byCode: _mode == _Mode.code),
    );
  }

  void _switchMode(_Mode mode) {
    if (mode == _mode) return;
    setState(() => _mode = mode);
    _controller.clear();
    context.read<FriendsBloc>().add(const FriendsLookupCleared());
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Lifts the sheet clear of the keyboard, the same way the
      // currency picker does.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border2,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const Text(
                AppStrings.friendsAddTitle,
                style: AppTextStyles.headingMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              RankingPills<_Mode>(
                items: const [
                  (_Mode.code, AppStrings.friendsSearchByCode),
                  (_Mode.username, AppStrings.friendsSearchByUsername),
                ],
                active: _mode,
                onChanged: _switchMode,
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _controller,
                autocorrect: false,
                textCapitalization: _mode == _Mode.code
                    ? TextCapitalization.characters
                    : TextCapitalization.none,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(_mode == _Mode.code ? 12 : 24),
                  if (_mode == _Mode.username)
                    FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9_]')),
                ],
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 16,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: _mode == _Mode.code
                      ? AppStrings.friendsEnterCodeHint
                      : AppStrings.friendsSearchHint,
                  prefixText: _mode == _Mode.username
                      ? AppStrings.friendsRequestPrefix
                      : null,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search_rounded),
                    color: AppColors.teal,
                    onPressed: _search,
                  ),
                ),
                onSubmitted: (_) => _search(),
              ),
              const SizedBox(height: AppSpacing.md),
              BlocBuilder<FriendsBloc, FriendsState>(
                builder: (context, state) => _Result(state: state),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Result extends StatelessWidget {
  const _Result({required this.state});

  final FriendsState state;

  @override
  Widget build(BuildContext context) {
    final error = state.error;
    if (error != null) {
      return Text(
        error,
        style: AppTextStyles.bodySmall.copyWith(color: AppColors.red),
      );
    }

    switch (state.lookupStatus) {
      case LookupStatus.idle:
        return const SizedBox.shrink();
      case LookupStatus.searching:
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Center(
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.teal,
              ),
            ),
          ),
        );
      case LookupStatus.notFound:
        return Text(
          AppStrings.friendsSearchNoResults,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        );
      case LookupStatus.isSelf:
        return Text(
          AppStrings.friendsSelfCode,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        );
      case LookupStatus.alreadyFriend:
      case LookupStatus.found:
        final profile = state.lookupResult;
        if (profile == null) return const SizedBox.shrink();
        final already = state.lookupStatus == LookupStatus.alreadyFriend;
        final sent = state.sentTo.contains(profile.uid);
        final flag = countryFromCode(profile.countryCode)?.flag;
        final car = [profile.carMake, profile.carModel]
            .where((s) => s.isNotEmpty)
            .join(' ');

        return Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.card,
            border: Border.all(color: AppColors.border2),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.username.isEmpty ? profile.uid : profile.username,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (flag != null || car.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        [if (flag != null) flag, if (car.isNotEmpty) car]
                            .join('  ·  '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.microLabel.copyWith(fontSize: 10),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _ActionButton(
                label: already
                    ? AppStrings.friendsAddedButton
                    : sent
                    ? AppStrings.friendsSentButton
                    : AppStrings.friendsAddButton,
                // Nothing to do in either terminal state, and a live
                // button that no-ops is worse than an inert one.
                onPressed: already || sent
                    ? null
                    : () => context.read<FriendsBloc>().add(
                        FriendsRequestSent(profile.uid),
                      ),
              ),
            ],
          ),
        );
    }
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.label, this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Material(
      color: enabled ? AppColors.teal : AppColors.card2,
      borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          child: Text(
            label.toUpperCase(),
            style: AppTextStyles.microLabel.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: enabled ? AppColors.bg : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
