import 'package:drive_rank/core/constants/app_colors.dart';
import 'package:drive_rank/core/constants/app_spacing.dart';
import 'package:drive_rank/core/constants/app_strings.dart';
import 'package:drive_rank/core/constants/app_text_styles.dart';
import 'package:drive_rank/core/di/injection.dart';
import 'package:drive_rank/features/onboarding/presentation/bloc/onboarding_bloc.dart';
import 'package:drive_rank/features/onboarding/presentation/bloc/onboarding_event.dart';
import 'package:drive_rank/features/onboarding/presentation/bloc/onboarding_state.dart';
import 'package:drive_rank/features/onboarding/presentation/widgets/teal_button.dart';
import 'package:drive_rank/shared/models/car_category.dart';
import 'package:drive_rank/shared/models/vehicle_type.dart';
import 'package:drive_rank/shared/services/car_photo_service.dart';
import 'package:drive_rank/shared/widgets/car_silhouette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

/// Step between car-picker and community — optional car-photo upload.
///
/// Renders the CarSilhouette (SVG fallback or the user's chosen image)
/// in a 45%-screen-width white circle, with an Upload Photo button and
/// a Skip option. Photo source selection lives in a bottom sheet so it
/// works the same on phone and tablet.
///
/// The path is written to `UserSettings.carPhotoPath` so subsequent
/// surfaces (stat card, profile, leaderboard avatar) read the same
/// photo without any prop-drilling.
class OnboardingCarPhotoStep extends StatelessWidget {
  const OnboardingCarPhotoStep({super.key});

  Future<void> _pickFrom(BuildContext context, ImageSource source) async {
    final path = await getIt<CarPhotoService>().pickAndStore(source);
    if (path == null) return; // user cancelled / picker errored
    if (!context.mounted) return;
    context.read<OnboardingBloc>().add(OnboardingCarPhotoSelected(path));
  }

  Future<void> _openSourceSheet(BuildContext context) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.bg2,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border2,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                ListTile(
                  leading: const Icon(
                    Icons.photo_camera_outlined,
                    color: AppColors.teal,
                  ),
                  title: const Text(
                    AppStrings.onboardCarPhotoCamera,
                    style: AppTextStyles.title,
                  ),
                  onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.photo_library_outlined,
                    color: AppColors.teal,
                  ),
                  title: const Text(
                    AppStrings.onboardCarPhotoGallery,
                    style: AppTextStyles.title,
                  ),
                  onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
                ),
                const SizedBox(height: AppSpacing.sm),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text(AppStrings.onboardCarPhotoCancel),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
            ),
          ),
        );
      },
    );
    if (source != null && context.mounted) {
      await _pickFrom(context, source);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OnboardingBloc, OnboardingState>(
      buildWhen: (a, b) =>
          a.carPhotoPath != b.carPhotoPath ||
          a.carMake != b.carMake ||
          a.vehicleType != b.vehicleType,
      builder: (context, state) {
        final hasPhoto =
            state.carPhotoPath != null && state.carPhotoPath!.isNotEmpty;
        final category =
            state.carMake?.category ??
            (state.vehicleType == VehicleType.motorbike
                ? CarCategory.motorbike
                : CarCategory.defaultCategory);

        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Column(
                  children: [
                    const SizedBox(height: AppSpacing.lg),
                    const Text(
                      AppStrings.onboardCarPhotoTitle,
                      style: AppTextStyles.headingLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                      ),
                      child: Text(
                        AppStrings.onboardCarPhotoSub,
                        style: AppTextStyles.body.copyWith(
                          color: Colors.white.withValues(alpha: 0.45),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        // Better practice: Use the maximum available width from constraints
                        // instead of reaching out to MediaQuery, defaulting to a responsive size.
                        final size = constraints.maxWidth * 0.45;

                        return Container(
                          width: size,
                          height: size,
                          alignment: Alignment.center,
                          padding: EdgeInsets.all(hasPhoto ? 0 : size * 0.12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.teal, width: 3),
                          ),
                          child: ClipOval(
                            child: AspectRatio(
                              aspectRatio:
                                  1, // <-- Forces the child to be a perfect square before clipping
                              child: CarSilhouette(
                                category: category,
                                photoPath: state.carPhotoPath,
                                fit: BoxFit
                                    .contain, // <-- Now this will crop without stretching
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _openSourceSheet(context),
                icon: Icon(
                  hasPhoto
                      ? Icons.swap_horiz_rounded
                      : Icons.add_a_photo_outlined,
                ),
                label: Text(
                  hasPhoto
                      ? AppStrings.onboardCarPhotoChange
                      : AppStrings.onboardCarPhotoUpload,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TealButton(
              label: hasPhoto
                  ? AppStrings.continueAction
                  : AppStrings.onboardCarPhotoSkip,
              onPressed: () {
                if (!hasPhoto) {
                  context.read<OnboardingBloc>().add(
                    const OnboardingCarPhotoSkipped(),
                  );
                }
                context.read<OnboardingBloc>().add(const OnboardingStepNext());
              },
            ),
          ],
        );
      },
    );
  }
}
