import 'package:drift/drift.dart' show Value;
import 'package:drive_rank/core/constants/app_colors.dart';
import 'package:drive_rank/core/constants/app_spacing.dart';
import 'package:drive_rank/core/constants/app_strings.dart';
import 'package:drive_rank/core/constants/app_text_styles.dart';
import 'package:drive_rank/core/database/app_database.dart';
import 'package:drive_rank/core/di/injection.dart';
import 'package:drive_rank/core/router/route_names.dart';
import 'package:drive_rank/core/services/locale_service.dart' show UnitSystem;
import 'package:drive_rank/shared/models/country.dart';
import 'package:drive_rank/shared/models/map_theme.dart';
import 'package:drive_rank/shared/repositories/user_settings_repository.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = getIt<UserSettingsRepository>();
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: StreamBuilder<UserSettingsRow>(
          stream: repo.watch(),
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.teal),
              );
            }
            return _Body(settings: snap.data!, repo: repo);
          },
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.settings, required this.repo});

  final UserSettingsRow settings;
  final UserSettingsRepository repo;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 32),
      children: [
        _Header(),
        _Section(
          title: AppStrings.settingsCarProfile,
          children: [
            _TextFieldRow(
              label: AppStrings.settingsCarMake,
              value: settings.carMake,
              onChanged: (v) => repo.patch(
                UserSettingsCompanion(carMake: Value(v)),
              ),
            ),
            _TextFieldRow(
              label: AppStrings.settingsCarModel,
              value: settings.carModel,
              onChanged: (v) => repo.patch(
                UserSettingsCompanion(carModel: Value(v)),
              ),
            ),
            _TextFieldRow(
              label: AppStrings.settingsCarYear,
              value: settings.carYear?.toString() ?? '',
              keyboardType: TextInputType.number,
              onChanged: (v) {
                final n = int.tryParse(v);
                repo.patch(UserSettingsCompanion(carYear: Value(n)));
              },
            ),
            _TextFieldRow(
              label: AppStrings.settingsCarColour,
              value: settings.carColour ?? '',
              onChanged: (v) => repo.patch(
                UserSettingsCompanion(
                  carColour: Value(v.isEmpty ? null : v),
                ),
              ),
            ),
          ],
        ),
        _Section(
          title: AppStrings.settingsAccount,
          children: [
            _TextFieldRow(
              label: AppStrings.settingsUsername,
              value: settings.username,
              hint: AppStrings.profileUsernameHint,
              onChanged: (v) =>
                  repo.patch(UserSettingsCompanion(username: Value(v))),
            ),
            _PickerRow(
              label: AppStrings.settingsCountry,
              valueText:
                  countryFromCode(settings.country ?? 'US')?.name ?? '—',
              leading:
                  countryFromCode(settings.country ?? 'US')?.flag ?? '🏳️',
              onTap: () async {
                final picked = await _pickCountry(context);
                if (picked != null) await repo.setCountry(picked.code);
              },
            ),
          ],
        ),
        _Section(
          title: AppStrings.settingsUnits,
          children: [
            _ToggleRow(
              label: AppStrings.settingsUnitsSpeed,
              metricLabel: 'km/h',
              imperialLabel: 'mph',
              isImperial: settings.unitSystem == 'imperial',
              onChanged: (imperial) => repo.setUnitSystem(
                imperial ? UnitSystem.imperial : UnitSystem.metric,
              ),
            ),
          ],
        ),
        _Section(
          title: AppStrings.settingsFuel,
          children: [
            _FuelTypeRow(
              current: settings.fuelType,
              onChanged: (type) => repo.patch(
                UserSettingsCompanion(fuelType: Value(type)),
              ),
            ),
            _TextFieldRow(
              label: AppStrings.settingsFuelConsumption,
              value: settings.fuelConsumption?.toString() ?? '',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (v) => repo.patch(
                UserSettingsCompanion(
                  fuelConsumption: Value(double.tryParse(v)),
                ),
              ),
            ),
            _TextFieldRow(
              label: settings.unitSystem == 'imperial'
                  ? AppStrings.settingsFuelPriceImperial
                  : AppStrings.settingsFuelPrice,
              value: settings.fuelPricePerUnit?.toString() ?? '',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (v) => repo.patch(
                UserSettingsCompanion(
                  fuelPricePerUnit: Value(double.tryParse(v)),
                ),
              ),
            ),
            _TextFieldRow(
              label: AppStrings.settingsFuelCurrency,
              value: settings.currencyCode ?? '',
              hint: 'USD',
              onChanged: (v) => repo.patch(
                UserSettingsCompanion(
                  currencyCode: Value(v.isEmpty ? null : v.toUpperCase()),
                ),
              ),
            ),
          ],
        ),
        _Section(
          title: AppStrings.settingsMapTheme,
          children: [
            _MapThemeRow(
              selected: MapTheme.fromId(settings.selectedMapTheme),
              onSelected: repo.setMapTheme,
            ),
          ],
        ),
        const SizedBox(height: 12),
        _DestructiveAction(
          label: AppStrings.profileDeleteAccount,
          onTap: () => _confirmDelete(context, repo, settings),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    UserSettingsRepository repo,
    UserSettingsRow row,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bg2,
        title: const Text(AppStrings.profileDeleteAccount),
        content: const Text(AppStrings.settingsDeleteAccountConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(AppStrings.delete),
          ),
        ],
      ),
    );
    if (ok ?? false) {
      // Session 5 (auth) owns the real teardown — for now we reset
      // onboarding so the user lands back at the start of the flow.
      await repo.patch(
        const UserSettingsCompanion(
          onboardingComplete: Value(false),
        ),
      );
      if (context.mounted) context.go(RouteNames.splash);
    }
  }

  Future<Country?> _pickCountry(BuildContext context) async {
    return showModalBottomSheet<Country>(
      context: context,
      backgroundColor: AppColors.bg2,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(ctx).height * 0.7,
          child: ListView.builder(
            itemCount: kCountries.length,
            itemBuilder: (_, i) {
              final c = kCountries[i];
              return ListTile(
                leading: Text(c.flag, style: const TextStyle(fontSize: 22)),
                title: Text(c.name),
                onTap: () => Navigator.of(ctx).pop(c),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 10, 4, 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            color: AppColors.textPrimary,
            onPressed: () => context.canPop()
                ? context.pop()
                : context.go(RouteNames.profile),
          ),
          const SizedBox(width: 4),
          const Text(
            AppStrings.settingsTitle,
            style: AppTextStyles.sectionTitle,
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 14, 8, 8),
          child: Text(
            title.toUpperCase(),
            style: AppTextStyles.label.copyWith(fontSize: 10),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _TextFieldRow extends StatefulWidget {
  const _TextFieldRow({
    required this.label,
    required this.value,
    required this.onChanged,
    this.hint,
    this.keyboardType,
  });

  final String label;
  final String value;
  final String? hint;
  final TextInputType? keyboardType;
  final ValueChanged<String> onChanged;

  @override
  State<_TextFieldRow> createState() => _TextFieldRowState();
}

class _TextFieldRowState extends State<_TextFieldRow> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(_TextFieldRow old) {
    super.didUpdateWidget(old);
    // External writes (e.g. country picker) shouldn't fight a focused field.
    if (widget.value != _controller.text && !_focused) {
      _controller.text = widget.value;
    }
  }

  bool _focused = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 96,
            child: Text(
              widget.label,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Focus(
              onFocusChange: (f) => _focused = f,
              child: TextField(
                controller: _controller,
                onChanged: widget.onChanged,
                keyboardType: widget.keyboardType,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: widget.hint,
                  border: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  isCollapsed: true,
                  filled: false,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PickerRow extends StatelessWidget {
  const _PickerRow({
    required this.label,
    required this.valueText,
    required this.onTap,
    this.leading,
  });

  final String label;
  final String valueText;
  final String? leading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 96,
              child: Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (leading != null) ...[
                    Text(leading!, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 6),
                  ],
                  Flexible(
                    child: Text(
                      valueText,
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textTertiary,
                    size: 18,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.label,
    required this.metricLabel,
    required this.imperialLabel,
    required this.isImperial,
    required this.onChanged,
  });

  final String label;
  final String metricLabel;
  final String imperialLabel;
  final bool isImperial;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
          _Segmented(
            options: [metricLabel, imperialLabel],
            selectedIndex: isImperial ? 1 : 0,
            onChanged: (i) => onChanged(i == 1),
          ),
        ],
      ),
    );
  }
}

class _Segmented extends StatelessWidget {
  const _Segmented({
    required this.options,
    required this.selectedIndex,
    required this.onChanged,
  });

  final List<String> options;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bg2,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < options.length; i++)
            Material(
              color: i == selectedIndex
                  ? AppColors.teal
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(50),
              child: InkWell(
                borderRadius: BorderRadius.circular(50),
                onTap: () => onChanged(i),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: Text(
                    options[i],
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: i == selectedIndex
                          ? AppColors.bg
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FuelTypeRow extends StatelessWidget {
  const _FuelTypeRow({required this.current, required this.onChanged});

  final String? current;
  final ValueChanged<String?> onChanged;

  static const _options = <(String, String)>[
    ('petrol', AppStrings.settingsFuelTypePetrol),
    ('diesel', AppStrings.settingsFuelTypeDiesel),
    ('cng', AppStrings.settingsFuelTypeCng),
    ('electric', AppStrings.settingsFuelTypeElectric),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.settingsFuelType,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final (id, label) in _options)
                _Chip(
                  label: label,
                  isSelected: current == id,
                  onTap: () => onChanged(current == id ? null : id),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AppColors.teal : AppColors.bg2,
      shape: StadiumBorder(
        side: BorderSide(
          color: isSelected ? AppColors.teal : AppColors.border,
        ),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isSelected ? AppColors.bg : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _MapThemeRow extends StatelessWidget {
  const _MapThemeRow({required this.selected, required this.onSelected});

  final MapTheme selected;
  final ValueChanged<MapTheme> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: SizedBox(
        height: 70,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          itemCount: MapTheme.values.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final t = MapTheme.values[i];
            final on = t == selected;
            return Column(
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => onSelected(t),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: t.gradient,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: on ? AppColors.teal : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Text(
                        t.glyph,
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  t.label,
                  style: AppTextStyles.microLabel.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 9,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DestructiveAction extends StatelessWidget {
  const _DestructiveAction({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
      child: TextButton(
        style: TextButton.styleFrom(foregroundColor: AppColors.red),
        onPressed: onTap,
        child: Text(label),
      ),
    );
  }
}
