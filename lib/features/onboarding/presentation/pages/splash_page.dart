import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:drive_rank/core/constants/app_colors.dart';
import 'package:drive_rank/core/constants/app_strings.dart';
import 'package:drive_rank/core/router/route_names.dart';
import 'package:drive_rank/core/services/app_update_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemNavigator;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

/// Cold-start splash. Plays the engine-start sound, runs a sequenced
/// scale/glow animation on the brand wordmark, then routes to onboarding.
/// The router's redirect rule decides where the user actually lands.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  // Tuned to outlast the wordmark sequence (~1700ms) plus a short hold so
  // the engine-start sound can settle before the route transition steals
  // focus. Keep under ~3s total — anything longer feels like a hang.
  static const Duration _routeDelay = Duration(milliseconds: 2600);

  final AudioPlayer _player = AudioPlayer();
  Timer? _routeTimer;

  /// Set to true if the Play Store reports an update is available AND
  /// the user declined the immediate-update prompt (or it failed).
  /// While true, the splash renders [_UpdateGate] instead of the
  /// animation and the route timer is cancelled — the user can't reach
  /// onboarding/home without updating.
  bool _blockedByUpdate = false;

  @override
  void initState() {
    super.initState();
    _playStartupSound();
    // Stored on a field so dispose() can cancel it — otherwise widget tests
    // (and any teardown before the timer fires) leak a pending timer.
    _routeTimer = Timer(_routeDelay, _goNext);
    // Fire the update check in parallel with the splash animation. If
    // an update is available and the user takes the immediate flow,
    // Play Store covers the screen and the route timer becomes moot;
    // if they decline, we cancel the timer and show the gate.
    unawaited(_checkForRequiredUpdate());
  }

  Future<void> _playStartupSound() async {
    try {
      debugPrint('Splash audio starting');
      await _player.setReleaseMode(ReleaseMode.stop);
      await _player.play(AssetSource('sound/sound.mp3'));
      debugPrint('Splash audio started');
    } catch (e) {
      debugPrint('Splash audio error: $e');
    }
  }

  Future<void> _checkForRequiredUpdate() async {
    final outcome = await const AppUpdateService().promptIfAvailable();
    if (!mounted) return;
    if (outcome == AppUpdateOutcome.blocked) {
      _routeTimer?.cancel();
      setState(() => _blockedByUpdate = true);
    }
  }

  Future<void> _retryUpdate() async {
    final outcome = await const AppUpdateService().retryImmediate();
    if (!mounted) return;
    if (outcome == AppUpdateOutcome.notRequired) {
      // Play Services just told us no update is needed any more —
      // probably the user updated out-of-band via Play Store. Let them
      // through to the app.
      setState(() => _blockedByUpdate = false);
      _goNext();
    }
    // Anything else: stay on the gate. blocked → user declined again;
    // updated → app will be relaunched by Play and we won't see it.
  }

  Future<void> _openPlayStoreListing() async {
    // market:// opens the Play Store app directly; the https fallback
    // covers devices without the Play Store app installed (web Play).
    const pkg = 'com.bytse.drive_rank';
    final marketUri = Uri.parse('market://details?id=$pkg');
    final webUri = Uri.parse('https://play.google.com/store/apps/details?id=$pkg');
    final ok = await launchUrl(marketUri, mode: LaunchMode.externalApplication);
    if (!ok) {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    }
  }

  void _exitApp() => SystemNavigator.pop();

  void _goNext() {
    if (!mounted) return;
    context.go(RouteNames.onboarding);
  }

  @override
  void dispose() {
    _routeTimer?.cancel();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: _blockedByUpdate
            ? _UpdateGate(
                onUpdate: _retryUpdate,
                onOpenPlayStore: _openPlayStoreListing,
                onExit: _exitApp,
              )
            : const Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    _RadialGlow(),
                    _PulseRing(),
                    _WordmarkAndTagline(),
                  ],
                ),
              ),
      ),
    );
  }
}

/// Blocking surface shown when an update is available and the user
/// declined / Play Services errored. No path forward except updating
/// or exiting the app — there's no "Skip for now" by design.
class _UpdateGate extends StatelessWidget {
  const _UpdateGate({
    required this.onUpdate,
    required this.onOpenPlayStore,
    required this.onExit,
  });

  final VoidCallback onUpdate;
  final VoidCallback onOpenPlayStore;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
      child: Column(
        children: [
          const Spacer(),
          const Icon(
            Icons.system_update_alt_rounded,
            size: 56,
            color: AppColors.teal,
          ),
          const SizedBox(height: 18),
          const Text(
            'Update required',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'BebasNeue',
              fontSize: 34,
              color: Colors.white,
              letterSpacing: 2,
              height: 1,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'A new version of DriveRank is available. Update to keep '
            'your trips safe — older builds may lose data.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onUpdate,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.teal,
                foregroundColor: AppColors.bg,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: const Text(
                'Update now',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onOpenPlayStore,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: AppColors.border2),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: const Text(
                'Open in Play Store',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          TextButton(
            onPressed: onExit,
            child: const Text(
              'Exit app',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 13,
                color: AppColors.textTertiary,
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

/// Soft teal radial glow behind the wordmark — sets the brand atmosphere
/// from the first frame, scales outward as if the engine warms up.
class _RadialGlow extends StatelessWidget {
  const _RadialGlow();

  @override
  Widget build(BuildContext context) {
    return Container(
          width: 320,
          height: 320,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [Color(0x553ECFBF), Color(0x223ECFBF), Color(0x00050508)],
              stops: [0.0, 0.45, 1.0],
            ),
          ),
        )
        .animate()
        .scale(
          begin: const Offset(0.4, 0.4),
          end: const Offset(1, 1),
          duration: 1400.ms,
          curve: Curves.easeOutCubic,
        )
        .fadeIn(duration: 700.ms);
  }
}

/// Thin teal ring that scales in elastically — adds a sense of "ignition"
/// the moment the wordmark hits its final size.
class _PulseRing extends StatelessWidget {
  const _PulseRing();

  @override
  Widget build(BuildContext context) {
    return Container(
          width: 220,
          height: 220,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.teal.withValues(alpha: 0.6),
              width: 1.2,
            ),
          ),
        )
        .animate()
        .scale(
          begin: const Offset(0.2, 0.2),
          end: const Offset(1, 1),
          duration: 900.ms,
          curve: Curves.elasticOut,
          delay: 200.ms,
        )
        .fadeIn(duration: 500.ms, delay: 200.ms)
        // After the entrance, breathe outward and fade — keeps the splash
        // alive while the route timer counts down.
        .then(delay: 100.ms)
        .scaleXY(end: 1.25, duration: 1200.ms, curve: Curves.easeOut)
        .fadeOut(duration: 1200.ms, curve: Curves.easeOut);
  }
}

/// The brand wordmark + tagline, stacked. Wordmark scales up with a slight
/// overshoot; the tagline and underline fade in once it lands.
class _WordmarkAndTagline extends StatelessWidget {
  const _WordmarkAndTagline();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Wordmark(text: AppStrings.appName.toUpperCase())
            .animate()
            .scale(
              begin: const Offset(0.55, 0.55),
              end: const Offset(1, 1),
              duration: 800.ms,
              curve: Curves.easeOutBack,
              delay: 350.ms,
            )
            .fadeIn(duration: 500.ms, delay: 350.ms),
        const SizedBox(height: 12),
        Container(width: 84, height: 2, color: AppColors.teal)
            .animate()
            .scaleX(
              begin: 0,
              end: 1,
              duration: 500.ms,
              delay: 950.ms,
              curve: Curves.easeOutCubic,
            )
            .fadeIn(duration: 300.ms, delay: 950.ms),
        const SizedBox(height: 14),
        const Text(
              AppStrings.appTagline,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
                letterSpacing: 0.3,
              ),
            )
            .animate()
            .fadeIn(duration: 500.ms, delay: 1200.ms)
            .moveY(
              begin: 6,
              end: 0,
              duration: 500.ms,
              delay: 1200.ms,
              curve: Curves.easeOut,
            ),
      ],
    );
  }
}

class _Wordmark extends StatelessWidget {
  const _Wordmark({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'BebasNeue',
        fontSize: 64,
        height: 1,
        letterSpacing: 4,
        color: Colors.white,
        // Inlined for const-correctness — keep ~55% alpha of AppColors.teal.
        shadows: [Shadow(color: Color(0x8C3ECFBF), blurRadius: 28)],
      ),
    );
  }
}
