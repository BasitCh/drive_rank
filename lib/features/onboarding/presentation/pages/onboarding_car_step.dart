import 'package:drive_rank/core/constants/app_colors.dart';
import 'package:drive_rank/core/constants/app_spacing.dart';
import 'package:drive_rank/core/constants/app_strings.dart';
import 'package:drive_rank/core/constants/app_text_styles.dart';
import 'package:drive_rank/features/onboarding/domain/entities/car_make.dart';
import 'package:drive_rank/features/onboarding/presentation/bloc/onboarding_bloc.dart';
import 'package:drive_rank/features/onboarding/presentation/bloc/onboarding_event.dart';
import 'package:drive_rank/features/onboarding/presentation/bloc/onboarding_state.dart';
import 'package:drive_rank/features/onboarding/presentation/widgets/teal_button.dart';
import 'package:drive_rank/features/onboarding/presentation/widgets/white_select.dart';
import 'package:drive_rank/shared/models/car_category.dart';
import 'package:drive_rank/shared/models/vehicle_type.dart';
import 'package:drive_rank/shared/widgets/car_silhouette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Step 3 — pick make and model. White-circle silhouette at the top with
/// the vehicle glyph, two dropdowns below.
class OnboardingCarStep extends StatelessWidget {
  const OnboardingCarStep({super.key});

  Future<void> _pickMake(BuildContext context, OnboardingState state) async {
    final picked = await showModalBottomSheet<CarMake>(
      context: context,
      backgroundColor: AppColors.bg2,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _CarMakeSheet(
        makes: state.availableMakes,
        selected: state.carMake,
        countryCode: state.country?.code ?? '',
      ),
    );
    if (picked != null && context.mounted) {
      context.read<OnboardingBloc>().add(OnboardingCarMakeSelected(picked));
    }
  }

  Future<void> _pickModel(BuildContext context, OnboardingState state) async {
    final make = state.carMake;
    if (make == null) return;
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.bg2,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) =>
          _CarModelSheet(models: make.models, selected: state.carModel),
    );
    if (picked != null && context.mounted) {
      context.read<OnboardingBloc>().add(OnboardingCarModelSelected(picked));
    }
  }

  Future<void> _customModel(
    BuildContext context,
    OnboardingState state,
  ) async {
    final make = state.carMake;
    if (make == null) return;
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.bg2,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _CustomModelSheet(
        makeName: make.name,
        initialValue: state.carModel ?? '',
      ),
    );
    if (result != null && result.isNotEmpty && context.mounted) {
      context.read<OnboardingBloc>().add(OnboardingCarModelSelected(result));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OnboardingBloc, OnboardingState>(
      buildWhen: (a, b) =>
          a.carMake != b.carMake ||
          a.carModel != b.carModel ||
          a.vehicleType != b.vehicleType ||
          a.availableMakes != b.availableMakes,
      builder: (context, state) {
        return Column(
          children: [
            Expanded(
              // SingleChildScrollView + IntrinsicHeight pattern: the
              // Column stays vertically centered on tall phones (because
              // the IntrinsicHeight forces it to the viewport height
              // and mainAxisAlignment.center kicks in), but on short
              // phones where the contents exceed the viewport, the
              // user can scroll instead of hitting a RenderFlex
              // overflow. ClampingScrollPhysics avoids the iOS-style
              // bounce that would feel out of place on this screen.
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              AppStrings.onboardCarTitle,
                              style: AppTextStyles.headingLarge,
                            ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    AppStrings.onboardCarSub,
                    style: AppTextStyles.body.copyWith(
                      color: Colors.white.withValues(alpha: 0.45),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  // 45% of the screen's shorter side — same on a small
                  // phone as on a tablet, scales with rotation. Keeps
                  // the silhouette readable but never overflows.
                  Builder(
                    builder: (context) {
                      final size = MediaQuery.sizeOf(context).width * 0.45;
                      final hasPhoto = state.carPhotoPath != null &&
                          state.carPhotoPath!.isNotEmpty;
                      return Container(
                        width: size,
                        height: size,
                        alignment: Alignment.center,
                        // A photo fills the whole circle (BoxFit.cover);
                        // the SVG keeps a 12% inner breathing room so
                        // it doesn't crowd the teal ring.
                        padding: hasPhoto
                            ? EdgeInsets.zero
                            : EdgeInsets.all(size * 0.12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.teal,
                            width: 3,
                          ),
                        ),
                        child: ClipOval(
                          child: CarSilhouette(
                            category: state.carMake?.category ??
                                (state.vehicleType == VehicleType.motorbike
                                    ? CarCategory.motorbike
                                    : CarCategory.defaultCategory),
                            photoPath: state.carPhotoPath,
                            fit: hasPhoto ? BoxFit.cover : BoxFit.contain,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  WhiteSelect(
                    label: state.carMake?.name ?? '',
                    hint: 'Make',
                    onTap: () => _pickMake(context, state),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  IgnorePointer(
                    ignoring: state.carMake == null,
                    child: Opacity(
                      opacity: state.carMake == null ? 0.5 : 1.0,
                      child: WhiteSelect(
                        label: state.carModel ?? '',
                        hint: 'Model',
                        onTap: () => _pickModel(context, state),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  GestureDetector(
                    onTap: state.carMake == null
                        ? null
                        : () => _customModel(context, state),
                    child: Text(
                      AppStrings.onboardCarMissingModel,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textTertiary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            TealButton(
              label: AppStrings.continueAction,
              enabled: state.canAdvance,
              onPressed: () => context.read<OnboardingBloc>().add(
                const OnboardingStepNext(),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CarMakeSheet extends StatefulWidget {
  const _CarMakeSheet({
    required this.makes,
    required this.selected,
    required this.countryCode,
  });

  final List<CarMake> makes;
  final CarMake? selected;
  final String countryCode;

  @override
  State<_CarMakeSheet> createState() => _CarMakeSheetState();
}

class _CarMakeSheetState extends State<_CarMakeSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final filtered = _query.isEmpty
        ? widget.makes
        : widget.makes
              .where(
                (m) => m.name.toLowerCase().contains(_query.toLowerCase()),
              )
              .toList();
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.7,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border2,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
              ),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Search make',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (_, i) {
                  final m = filtered[i];
                  final isLocal = m.isPopularIn(widget.countryCode);
                  final isSelected = widget.selected?.id == m.id;
                  return ListTile(
                    title: Text(
                      m.name,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w400,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(
                            Icons.check_rounded,
                            color: AppColors.teal,
                          )
                        : isLocal
                            ? const Icon(
                                Icons.local_fire_department_rounded,
                                color: AppColors.orange,
                                size: 18,
                              )
                            : null,
                    onTap: () => Navigator.of(context).pop(m),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CarModelSheet extends StatelessWidget {
  const _CarModelSheet({required this.models, required this.selected});

  final List<String> models;
  final String? selected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.6,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border2,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Expanded(
              child: ListView.builder(
                itemCount: models.length,
                itemBuilder: (_, i) {
                  final m = models[i];
                  final isSelected = selected == m;
                  return ListTile(
                    title: Text(
                      m,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w400,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(
                            Icons.check_rounded,
                            color: AppColors.teal,
                          )
                        : null,
                    onTap: () => Navigator.of(context).pop(m),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom-sheet for the "don't see your model?" free-text fallback.
///
/// Stateful (rather than constructing the controller inline in the
/// caller) so the [TextEditingController] is owned by an element with
/// a proper lifecycle and disposed when the sheet closes. The earlier
/// inline form leaked a controller on every open, which Flutter
/// surfaces as a noisy "TextEditingController … was never disposed"
/// log line every time the sheet popped.
class _CustomModelSheet extends StatefulWidget {
  const _CustomModelSheet({
    required this.makeName,
    required this.initialValue,
  });

  final String makeName;
  final String initialValue;

  @override
  State<_CustomModelSheet> createState() => _CustomModelSheetState();
}

class _CustomModelSheetState extends State<_CustomModelSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    Navigator.of(context).pop(_controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Enter your ${widget.makeName} model',
                style: AppTextStyles.headingMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _controller,
                autofocus: true,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(hintText: 'Model name'),
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: AppSpacing.lg),
              TealButton(
                label: AppStrings.save,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
