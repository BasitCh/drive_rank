import 'package:drive_rank/core/constants/app_colors.dart';
import 'package:drive_rank/core/constants/app_spacing.dart';
import 'package:drive_rank/core/constants/app_strings.dart';
import 'package:drive_rank/core/constants/app_text_styles.dart';
import 'package:drive_rank/features/friends/presentation/bloc/friends_bloc.dart';
import 'package:drive_rank/shared/models/friend_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Profile-screen block that lists incoming pending requests with
/// Accept / Decline buttons. Renders nothing when the inbox is empty.
class IncomingRequestsSection extends StatelessWidget {
  const IncomingRequestsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FriendsBloc, FriendsState>(
      buildWhen: (a, b) => a.incoming != b.incoming,
      builder: (context, state) {
        if (state.incoming.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.md),
              Text(
                AppStrings.friendsIncomingTitle.toUpperCase(),
                style: AppTextStyles.label.copyWith(fontSize: 10),
              ),
              const SizedBox(height: AppSpacing.sm),
              for (final req in state.incoming) ...[
                _RequestRow(request: req),
                const SizedBox(height: AppSpacing.sm),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _RequestRow extends StatelessWidget {
  const _RequestRow({required this.request});

  final IncomingFriendRequest request;

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
            decoration: BoxDecoration(
              color: AppColors.teal.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Text(
              request.fromUsername.isEmpty
                  ? '?'
                  : request.fromUsername[0].toUpperCase(),
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.teal,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              '${AppStrings.friendsRequestPrefix}${request.fromUsername}'
              '${AppStrings.friendsRequestSuffix}',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textPrimary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            tooltip: AppStrings.friendsDecline,
            onPressed: () => context
                .read<FriendsBloc>()
                .add(FriendsDeclineRequest(request.id)),
            icon: const Icon(
              Icons.close_rounded,
              color: AppColors.textSecondary,
              size: 20,
            ),
          ),
          IconButton(
            tooltip: AppStrings.friendsAccept,
            onPressed: () => context
                .read<FriendsBloc>()
                .add(FriendsAcceptRequest(request.id)),
            icon: const Icon(
              Icons.check_circle_rounded,
              color: AppColors.green,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }
}
