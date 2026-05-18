import 'package:drive_rank/core/constants/app_colors.dart';
import 'package:drive_rank/core/constants/app_spacing.dart';
import 'package:drive_rank/core/constants/app_strings.dart';
import 'package:drive_rank/core/constants/app_text_styles.dart';
import 'package:drive_rank/features/friends/presentation/bloc/friends_bloc.dart';
import 'package:drive_rank/shared/models/friend_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Bottom-sheet that lets the user search the public users collection
/// by username prefix and fire off friend requests. Reused from the
/// profile screen + the leaderboard's Friends empty state.
class AddFriendSheet extends StatelessWidget {
  const AddFriendSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bg2,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => BlocProvider.value(
        value: context.read<FriendsBloc>(),
        child: const AddFriendSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.72,
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.sm),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border2,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const Text(
                AppStrings.friendsAddTitle,
                style: AppTextStyles.headingMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: _SearchField(),
              ),
              const SizedBox(height: AppSpacing.md),
              const Expanded(child: _Results()),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchField extends StatefulWidget {
  const _SearchField();

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: context.read<FriendsBloc>().state.searchQuery,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      autofocus: true,
      autocorrect: false,
      enableSuggestions: false,
      decoration: const InputDecoration(
        hintText: AppStrings.friendsSearchHint,
        prefixIcon: Icon(Icons.search, color: AppColors.textTertiary),
      ),
      onChanged: (v) =>
          context.read<FriendsBloc>().add(FriendsSearchChanged(v)),
    );
  }
}

class _Results extends StatelessWidget {
  const _Results();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FriendsBloc, FriendsState>(
      buildWhen: (a, b) =>
          a.searchState != b.searchState ||
          a.searchResults != b.searchResults,
      builder: (context, state) {
        switch (state.searchState) {
          case FriendsSearchState.idle:
            return const SizedBox.shrink();
          case FriendsSearchState.tooShort:
            return const Padding(
              padding: EdgeInsets.all(AppSpacing.xl),
              child: Center(
                child: Text(
                  AppStrings.friendsSearchTooShort,
                  style: AppTextStyles.body,
                ),
              ),
            );
          case FriendsSearchState.searching:
            return const Center(
              child: CircularProgressIndicator(color: AppColors.teal),
            );
          case FriendsSearchState.empty:
            return const Padding(
              padding: EdgeInsets.all(AppSpacing.xl),
              child: Center(
                child: Text(
                  AppStrings.friendsSearchNoResults,
                  style: AppTextStyles.body,
                ),
              ),
            );
          case FriendsSearchState.error:
            return const SizedBox.shrink();
          case FriendsSearchState.ready:
            return ListView.separated(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
              ),
              itemCount: state.searchResults.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.sm),
              itemBuilder: (_, i) => _ResultRow(entry: state.searchResults[i]),
            );
        }
      },
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.entry});

  final FriendSearchResult entry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.card2,
              shape: BoxShape.circle,
            ),
            child: Text(
              entry.username.isEmpty
                  ? '?'
                  : entry.username[0].toUpperCase(),
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '@${entry.username}',
                  style: AppTextStyles.title.copyWith(fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (entry.carName.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    entry.carName,
                    style: AppTextStyles.bodySmall.copyWith(fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          _AddButton(entry: entry),
        ],
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.entry});

  final FriendSearchResult entry;

  @override
  Widget build(BuildContext context) {
    if (entry.alreadyFriend) {
      return const _Chip(
        icon: Icons.check_rounded,
        label: AppStrings.friendsAddedButton,
        color: AppColors.green,
      );
    }
    if (entry.requestSent) {
      return const _Chip(
        icon: Icons.check_rounded,
        label: AppStrings.friendsSentButton,
        color: AppColors.textSecondary,
      );
    }
    return TextButton(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.bg,
        backgroundColor: AppColors.teal,
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xs + 2,
        ),
      ),
      onPressed: () => context
          .read<FriendsBloc>()
          .add(FriendsSendRequest(entry.uid)),
      child: const Text(
        AppStrings.friendsAddButton,
        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs + 1,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
