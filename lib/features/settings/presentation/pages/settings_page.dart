import 'dart:io' show Platform;

import 'package:drift/drift.dart' show Value;
import 'package:drive_rank/core/constants/app_colors.dart';
import 'package:drive_rank/core/constants/app_constants.dart';
import 'package:drive_rank/core/constants/app_spacing.dart';
import 'package:drive_rank/core/constants/app_strings.dart';
import 'package:drive_rank/core/constants/app_text_styles.dart';
import 'package:drive_rank/core/database/app_database.dart';
import 'package:drive_rank/core/di/injection.dart';
import 'package:drive_rank/core/router/route_names.dart';
import 'package:drive_rank/core/services/account_deletion_service.dart';
import 'package:drive_rank/core/services/debug_seed_service.dart';
import 'package:drive_rank/core/services/locale_service.dart' show UnitSystem;
import 'package:drive_rank/core/services/paywall_service.dart';
import 'package:drive_rank/shared/models/car_category.dart';
import 'package:drive_rank/shared/models/country.dart';
import 'package:drive_rank/shared/models/map_theme.dart';
import 'package:drive_rank/shared/models/vehicle_type.dart';
import 'package:drive_rank/shared/repositories/user_settings_repository.dart';
import 'package:drive_rank/shared/services/car_photo_service.dart';
import 'package:drive_rank/shared/widgets/car_silhouette.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart' show NumberFormat;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

const String _kPlayStoreSubscriptionUrl =
    'https://play.google.com/store/account/subscriptions'
    '?sku=driverank_pro_annual&package=com.bytse.drive_rank';
const String _kAppleSubscriptionUrl =
    'https://apps.apple.com/account/subscriptions';
const String _kPrivacyUrl =
    'https://doc-hosting.flycricket.io/drive-rank-privacy-policy/3a6ae044-e764-43cd-98f8-fd96a55555b0/privacy';

/// Support inbox used by both Contact Us and Leave Feedback — same
/// address, different pre-filled subject line.
const String _kSupportEmail = 'basit.saleem13@gmail.com';

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
            _CarPhotoRow(settings: settings, repo: repo),
            _TextFieldRow(
              label: AppStrings.settingsCarMake,
              value: settings.carMake,
              onChanged: (v) => repo.setCar(
                make: v,
                model: settings.carModel,
                year: settings.carYear,
              ),
            ),
            _TextFieldRow(
              label: AppStrings.settingsCarModel,
              value: settings.carModel,
              onChanged: (v) => repo.setCar(
                make: settings.carMake,
                model: v,
                year: settings.carYear,
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
                UserSettingsCompanion(carColour: Value(v.isEmpty ? null : v)),
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
              valueText: countryFromCode(settings.country ?? 'US')?.name ?? '—',
              leading: countryFromCode(settings.country ?? 'US')?.flag ?? '🏳️',
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
          title: AppStrings.settingsPreferences,
          children: [_MinTripLengthRow(settings: settings, repo: repo)],
        ),
        _Section(
          title: AppStrings.settingsFuel,
          children: [
            _FuelTypeRow(
              current: settings.fuelType,
              onChanged: (type) =>
                  repo.patch(UserSettingsCompanion(fuelType: Value(type))),
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
            Builder(
              builder: (context) {
                final code = settings.currencyCode ?? '';
                final entry = _kCurrencies.firstWhere(
                  (c) => c.code == code,
                  orElse: () => const _Currency(
                    code: '',
                    name: 'Pick a currency',
                    symbol: '',
                  ),
                );
                return _PickerRow(
                  label: AppStrings.settingsFuelCurrency,
                  leading: entry.symbol.isEmpty ? null : entry.symbol,
                  valueText: entry.code.isEmpty
                      ? entry.name
                      : '${entry.code} · ${entry.name}',
                  onTap: () => _pickCurrency(context, repo, entry.code),
                );
              },
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
        _Section(
          title: 'Subscription',
          children: [
            _LinkRow(
              label: 'Manage subscription',
              icon: Icons.subscriptions_outlined,
              onTap: () => _openManageSubscription(context),
            ),
            _LinkRow(
              label: 'Restore purchases',
              icon: Icons.restore_rounded,
              onTap: () => _restorePurchases(context),
            ),
          ],
        ),
        _Section(
          title: 'Legal',
          children: [
            _LinkRow(
              label: 'Privacy policy',
              icon: Icons.lock_outline_rounded,
              onTap: () => _openExternal(context, _kPrivacyUrl),
            ),
          ],
        ),
        _Section(
          title: AppStrings.settingsSupport,
          children: [
            _LinkRow(
              label: AppStrings.settingsContactUs,
              icon: Icons.mail_outline_rounded,
              onTap: () => _openMailto(
                context,
                subject: AppStrings.settingsContactSubject,
              ),
            ),
            _LinkRow(
              label: AppStrings.settingsLeaveFeedback,
              icon: Icons.chat_bubble_outline_rounded,
              onTap: () => _openMailto(
                context,
                subject: AppStrings.settingsFeedbackSubject,
              ),
            ),
          ],
        ),
        if (kDebugMode) ...[
          _Section(
            title: 'Developer',
            children: [
              _LinkRow(
                label: 'Seed test trips + enable Pro',
                icon: Icons.science_outlined,
                onTap: () => _seedMockData(context),
              ),
              _LinkRow(
                label: 'Reset to free tier',
                icon: Icons.restart_alt_rounded,
                onTap: () => _resetFreeTier(context),
              ),
            ],
          ),
        ],
        const SizedBox(height: 12),
        const _AppVersionLabel(),
        const SizedBox(height: 4),
        _DestructiveAction(
          label: AppStrings.profileDeleteAccount,
          onTap: () => _confirmDelete(context, repo, settings),
        ),
      ],
    );
  }

  Future<void> _openMailto(BuildContext context, {required String subject}) async {
    final uri = Uri(
      scheme: 'mailto',
      path: _kSupportEmail,
      query: 'subject=${Uri.encodeComponent(subject)}',
    );
    final ok = await launchUrl(uri);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't open your email app.")),
      );
    }
  }

  /// Deep-link into the platform's subscription management page. We
  /// never cancel via API — Google Play and Apple both require the
  /// user to manage subs through their store account UI, and this is
  /// the link Play / Apple sanction.
  Future<void> _openManageSubscription(BuildContext context) async {
    final url = Platform.isIOS
        ? _kAppleSubscriptionUrl
        : _kPlayStoreSubscriptionUrl;
    await _openExternal(context, url);
  }

  /// Asks RevenueCat to re-check this account's entitlements (e.g. if
  /// the user paid on another device, reinstalled, or switched
  /// accounts). Surfaces a snackbar with the result either way.
  Future<void> _restorePurchases(BuildContext context) async {
    final paywall = getIt<PaywallService>();
    var restored = false;
    try {
      restored = await paywall.restorePurchases();
    } catch (_) {
      restored = false;
    }
    // Side-effect: when the real RC service returns true, the bloc /
    // bootstrap layer flips the local isPro flag. Here we just tell
    // the user what happened.
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          restored
              ? 'Pro restored — thanks for being a subscriber.'
              : "We couldn't find an active subscription on this account.",
        ),
      ),
    );
  }

  /// Opens [url] in the platform's external browser (or store app, for
  /// the play/apple subscription URLs). Falls back to a snackbar if
  /// no handler is available — common on emulators without a browser.
  Future<void> _openExternal(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Couldn't open the link.")));
    }
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
    if (!(ok ?? false)) return;
    try {
      await getIt<AccountDeletionService>().deleteEverything();
      if (context.mounted) context.go(RouteNames.splash);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppStrings.settingsAccountDeletionFailed),
          ),
        );
      }
    }
  }

  /// Debug-only test-data button. `DebugSeedService` itself also
  /// checks `kDebugMode` and no-ops in release, so this is doubly
  /// guarded — but the button is only ever built inside the
  /// `if (kDebugMode)` block above regardless.
  Future<void> _seedMockData(BuildContext context) async {
    final count = await getIt<DebugSeedService>().seedMockTrips();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Seeded $count test trips + enabled Pro.')),
    );
  }

  Future<void> _resetFreeTier(BuildContext context) async {
    await getIt<DebugSeedService>().resetToFreeTier();
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Back to free tier.')));
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
              color: i == selectedIndex ? AppColors.teal : Colors.transparent,
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

/// Minimum-trip-length input under Settings → Preferences. Stored in
/// the DB as metres always; displayed/edited in the user's unit
/// system (m or ft) so an imperial user isn't typing metric numbers.
class _MinTripLengthRow extends StatefulWidget {
  const _MinTripLengthRow({required this.settings, required this.repo});

  final UserSettingsRow settings;
  final UserSettingsRepository repo;

  @override
  State<_MinTripLengthRow> createState() => _MinTripLengthRowState();
}

class _MinTripLengthRowState extends State<_MinTripLengthRow> {
  late final TextEditingController _controller;
  bool _focused = false;

  bool get _isImperial => widget.settings.unitSystem == 'imperial';
  String get _unitLabel => _isImperial ? 'ft' : 'm';

  double _toDisplay(double metres) =>
      _isImperial ? metres * AppConstants.metresToFeet : metres;

  double _toMetres(double display) =>
      _isImperial ? display / AppConstants.metresToFeet : display;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _displayText());
  }

  @override
  void didUpdateWidget(covariant _MinTripLengthRow old) {
    super.didUpdateWidget(old);
    // External writes (e.g. the unit-system toggle) shouldn't fight a
    // focused field — same guard as `_TextFieldRow`.
    if (!_focused &&
        (old.settings.minTripLengthMeters !=
                widget.settings.minTripLengthMeters ||
            old.settings.unitSystem != widget.settings.unitSystem)) {
      _controller.text = _displayText();
    }
  }

  String _displayText() =>
      _toDisplay(widget.settings.minTripLengthMeters).round().toString();

  void _commit() {
    final parsed = double.tryParse(_controller.text);
    if (parsed != null && parsed >= 0) {
      widget.repo.setMinTripLengthMeters(_toMetres(parsed));
    } else {
      _controller.text = _displayText();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  AppStrings.settingsMinTripLength,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              SizedBox(
                width: 70,
                child: Focus(
                  onFocusChange: (f) {
                    _focused = f;
                    if (!f) _commit();
                  },
                  child: TextField(
                    controller: _controller,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.right,
                    onSubmitted: (_) => _commit(),
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      suffixText: _unitLabel,
                      suffixStyle: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
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
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
          child: Text(
            AppStrings.settingsMinTripLengthSub,
            style: AppTextStyles.microLabel.copyWith(fontSize: 10),
          ),
        ),
      ],
    );
  }
}

/// App version + build number in Settings, sourced from the platform
/// package manifest — never hand-maintained, so it can't drift from
/// what's actually installed.
class _AppVersionLabel extends StatelessWidget {
  const _AppVersionLabel();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snap) {
        final info = snap.data;
        if (info == null) return const SizedBox.shrink();
        return Center(
          child: Text(
            '${AppStrings.settingsAppVersionLabel} ${info.version} '
            '(${info.buildNumber})',
            style: AppTextStyles.microLabel.copyWith(fontSize: 10),
          ),
        );
      },
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
        side: BorderSide(color: isSelected ? AppColors.teal : AppColors.border),
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

/// Row at the top of the Car Profile section that lets the user swap
/// out (or remove) the photo that appears on the stat card / profile.
///
/// Tapping the avatar opens the same camera/gallery bottom sheet used
/// in onboarding. The picked file is persisted to the documents dir
/// via `CarPhotoService` (so the OS temp-cache eviction doesn't blank
/// it on the next boot), then the new path is written to UserSettings.
/// Holding down on the avatar offers a Remove option.
class _CarPhotoRow extends StatelessWidget {
  const _CarPhotoRow({required this.settings, required this.repo});

  final UserSettingsRow settings;
  final UserSettingsRepository repo;

  CarCategory get _category {
    if (settings.vehicleType == VehicleType.motorbike.id) {
      return CarCategory.motorbike;
    }
    // The "category" lookup against car_makes.json happens in the
    // onboarding picker — here we just pick the broad fallback by
    // vehicle type so the SVG isn't blank when no photo exists.
    return CarCategory.defaultCategory;
  }

  Future<void> _openSourceSheet(BuildContext context) async {
    final hasPhoto =
        settings.carPhotoPath != null && settings.carPhotoPath!.isNotEmpty;
    final source = await showModalBottomSheet<_PhotoSheetChoice>(
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
                  title: const Text(AppStrings.onboardCarPhotoCamera),
                  onTap: () => Navigator.of(ctx).pop(_PhotoSheetChoice.camera),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.photo_library_outlined,
                    color: AppColors.teal,
                  ),
                  title: const Text(AppStrings.onboardCarPhotoGallery),
                  onTap: () => Navigator.of(ctx).pop(_PhotoSheetChoice.gallery),
                ),
                if (hasPhoto)
                  ListTile(
                    leading: const Icon(
                      Icons.delete_outline,
                      color: AppColors.red,
                    ),
                    title: const Text(
                      AppStrings.delete,
                      style: TextStyle(color: AppColors.red),
                    ),
                    onTap: () =>
                        Navigator.of(ctx).pop(_PhotoSheetChoice.remove),
                  ),
                const SizedBox(height: AppSpacing.sm),
              ],
            ),
          ),
        );
      },
    );
    if (source == null) return;
    if (!context.mounted) return;

    final photoService = getIt<CarPhotoService>();
    if (source == _PhotoSheetChoice.remove) {
      // Best-effort clean-up of the on-disk file too.
      await photoService.tryDelete(settings.carPhotoPath);
      await repo.setCarPhotoPath(null);
      return;
    }

    final imageSource = source == _PhotoSheetChoice.camera
        ? ImageSource.camera
        : ImageSource.gallery;
    final newPath = await photoService.pickAndStore(imageSource);
    if (newPath == null) return;
    // Best-effort: clean up the previous file once the new one is saved.
    await photoService.tryDelete(settings.carPhotoPath);
    await repo.setCarPhotoPath(newPath);
  }

  @override
  Widget build(BuildContext context) {
    final hasPhoto =
        settings.carPhotoPath != null && settings.carPhotoPath!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        children: [
          // 88 × 88 avatar, teal-bordered, identical to the onboarding
          // car circle just smaller. SVG fills (with breathing room),
          // photo crops cover-fit through ClipOval.
          GestureDetector(
            onTap: () => _openSourceSheet(context),
            child: Container(
              width: 88,
              height: 88,
              padding: hasPhoto ? EdgeInsets.zero : const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.teal, width: 2),
              ),
              child: ClipOval(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: CarSilhouette(
                    category: _category,
                    photoPath: settings.carPhotoPath,
                    fit: hasPhoto ? BoxFit.cover : BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasPhoto
                      ? AppStrings.onboardCarPhotoChange
                      : AppStrings.onboardCarPhotoUpload,
                  style: AppTextStyles.title,
                ),
                const SizedBox(height: 2),
                const Text(
                  AppStrings.onboardCarPhotoSub,
                  style: AppTextStyles.bodySmall,
                ),
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton.icon(
                  onPressed: () => _openSourceSheet(context),
                  icon: Icon(
                    hasPhoto
                        ? Icons.swap_horiz_rounded
                        : Icons.add_a_photo_outlined,
                    size: 18,
                  ),
                  label: Text(
                    hasPhoto
                        ? AppStrings.onboardCarPhotoChange
                        : AppStrings.onboardCarPhotoUpload,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _PhotoSheetChoice { camera, gallery, remove }

/// Open the searchable currency picker and patch the user's settings
/// row to the chosen ISO 4217 code. Defined as a top-level fn rather
/// than a method on `_Body` so the `Builder` row can dispatch to it
/// without threading the repo through extra constructor params.
Future<void> _pickCurrency(
  BuildContext context,
  UserSettingsRepository repo,
  String currentCode,
) async {
  final picked = await showModalBottomSheet<_Currency>(
    context: context,
    backgroundColor: AppColors.bg2,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _CurrencyPickerSheet(selectedCode: currentCode),
  );
  if (picked == null) return;
  await repo.patch(UserSettingsCompanion(currencyCode: Value(picked.code)));
}

/// One ISO 4217 entry shown in the currency picker.
class _Currency {
  const _Currency({
    required this.code,
    required this.name,
    required this.symbol,
  });

  final String code;
  final String name;
  final String symbol;
}

/// Curated list of ~40 ISO 4217 currencies covering >99% of likely
/// users. Symbols come from `intl.NumberFormat.simpleCurrency` when
/// available so they match what RevenueCat / paywall prices render
/// elsewhere in the app. Sorted alphabetically by code.
final List<_Currency> _kCurrencies = () {
  String symbolFor(String code, String fallback) {
    try {
      final s = NumberFormat.simpleCurrency(name: code).currencySymbol;
      // `simpleCurrency` sometimes returns the code itself when ICU
      // doesn't have a glyph. Prefer our handwritten fallback in that
      // case so the leading slot doesn't look noisy.
      return s == code ? fallback : s;
    } catch (_) {
      return fallback;
    }
  }

  const entries = <(String, String, String)>[
    ('AED', 'UAE Dirham', 'د.إ'),
    ('ARS', 'Argentine Peso', r'$'),
    ('AUD', 'Australian Dollar', r'A$'),
    ('BDT', 'Bangladeshi Taka', '৳'),
    ('BRL', 'Brazilian Real', r'R$'),
    ('CAD', 'Canadian Dollar', r'C$'),
    ('CHF', 'Swiss Franc', 'CHF'),
    ('CLP', 'Chilean Peso', r'$'),
    ('CNY', 'Chinese Yuan', '¥'),
    ('COP', 'Colombian Peso', r'$'),
    ('CZK', 'Czech Koruna', 'Kč'),
    ('DKK', 'Danish Krone', 'kr'),
    ('EGP', 'Egyptian Pound', 'E£'),
    ('EUR', 'Euro', '€'),
    ('GBP', 'British Pound', '£'),
    ('HKD', 'Hong Kong Dollar', r'HK$'),
    ('HUF', 'Hungarian Forint', 'Ft'),
    ('IDR', 'Indonesian Rupiah', 'Rp'),
    ('ILS', 'Israeli Shekel', '₪'),
    ('INR', 'Indian Rupee', '₹'),
    ('JPY', 'Japanese Yen', '¥'),
    ('KES', 'Kenyan Shilling', 'KSh'),
    ('KRW', 'South Korean Won', '₩'),
    ('LKR', 'Sri Lankan Rupee', 'Rs'),
    ('MAD', 'Moroccan Dirham', 'د.م.'),
    ('MXN', 'Mexican Peso', r'$'),
    ('MYR', 'Malaysian Ringgit', 'RM'),
    ('NGN', 'Nigerian Naira', '₦'),
    ('NOK', 'Norwegian Krone', 'kr'),
    ('NZD', 'New Zealand Dollar', r'NZ$'),
    ('PHP', 'Philippine Peso', '₱'),
    ('PKR', 'Pakistani Rupee', '₨'),
    ('PLN', 'Polish Złoty', 'zł'),
    ('RON', 'Romanian Leu', 'lei'),
    ('RUB', 'Russian Ruble', '₽'),
    ('SAR', 'Saudi Riyal', '﷼'),
    ('SEK', 'Swedish Krona', 'kr'),
    ('SGD', 'Singapore Dollar', r'S$'),
    ('THB', 'Thai Baht', '฿'),
    ('TRY', 'Turkish Lira', '₺'),
    ('TWD', 'New Taiwan Dollar', r'NT$'),
    ('UAH', 'Ukrainian Hryvnia', '₴'),
    ('USD', 'US Dollar', r'$'),
    ('VND', 'Vietnamese Dong', '₫'),
    ('ZAR', 'South African Rand', 'R'),
  ];
  return [
    for (final e in entries)
      _Currency(code: e.$1, name: e.$2, symbol: symbolFor(e.$1, e.$3)),
  ];
}();

/// Bottom-sheet picker for [_kCurrencies]. Stateful because of the
/// search field; the TextEditingController lifecycle is owned here so
/// it disposes cleanly when the sheet closes.
class _CurrencyPickerSheet extends StatefulWidget {
  const _CurrencyPickerSheet({required this.selectedCode});

  final String selectedCode;

  @override
  State<_CurrencyPickerSheet> createState() => _CurrencyPickerSheetState();
}

class _CurrencyPickerSheetState extends State<_CurrencyPickerSheet> {
  late final TextEditingController _query;

  @override
  void initState() {
    super.initState();
    _query = TextEditingController();
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  List<_Currency> get _filtered {
    final q = _query.text.trim().toLowerCase();
    if (q.isEmpty) return _kCurrencies;
    return _kCurrencies.where((c) {
      return c.code.toLowerCase().contains(q) ||
          c.name.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height * 0.7;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: height,
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border2,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: TextField(
                  controller: _query,
                  autofocus: false,
                  decoration: const InputDecoration(
                    hintText: 'Search currency',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: ListView.builder(
                  itemCount: _filtered.length,
                  itemBuilder: (_, i) {
                    final c = _filtered[i];
                    final isSelected = c.code == widget.selectedCode;
                    return ListTile(
                      leading: SizedBox(
                        width: 32,
                        child: Text(
                          c.symbol,
                          style: const TextStyle(
                            fontSize: 18,
                            color: AppColors.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      title: Text(
                        '${c.code} · ${c.name}',
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
                      onTap: () => Navigator.of(context).pop(c),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A tappable settings row with a leading icon, a label, and the
/// standard trailing chevron. Used for Subscription + Legal links —
/// each one just fires a callback (`_openExternal`, `_restorePurchases`,
/// etc.) when tapped. Visual styling matches `_PickerRow` so the
/// sections feel uniform.
class _LinkRow extends StatelessWidget {
  const _LinkRow({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
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
            Icon(icon, color: AppColors.textSecondary, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textTertiary,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
