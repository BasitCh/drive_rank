/// Centralised English strings for v1.
///
/// All UI text lives here — never inline a string literal in a widget.
/// Once i18n is enabled, swap this class for generated `AppLocalizations`
/// without touching widget code.
class AppStrings {
  const AppStrings._();

  // App identity.
  static const String appName = 'DriveRank';
  static const String appTagline = 'Track your trips. Flex your stats.';

  // Common actions.
  static const String next = 'Next';
  static const String back = 'Back';
  static const String continueAction = 'Continue';
  static const String skip = 'Skip';
  static const String save = 'Save';
  static const String cancel = 'Cancel';
  static const String delete = 'Delete';
  static const String done = 'Done';
  static const String retry = 'Retry';

  // Bottom navigation.
  static const String navDrive = 'Drive';
  static const String navHistory = 'History';
  static const String navRankings = 'Rankings';
  static const String navProfile = 'Profile';

  // Onboarding — splash.
  static const String splashTitleSlide1 = 'Track Your Trips';
  static const String splashSubSlide1 =
      'Trip Recaps, Leaderboards, and smart features for everyday drives';
  static const String splashTitleSlide2 = 'Built for Drivers';
  static const String splashSubSlide2 =
      'Real-time stats, route history, and a community of car people';
  static const String splashTitleSlide3 = 'Beat Your Friends';
  static const String splashSubSlide3 =
      'Climb the leaderboards on every road you drive';

  // Onboarding — country + vehicle.
  static const String onboardCountryTitle = 'Select your country';
  static const String onboardCountrySub = 'Determines your leaderboard region';
  static const String onboardVehicleTitle = 'What do you drive?';
  static const String vehicleCar = 'Car';
  static const String vehicleMotorbike = 'Motorbike';

  // Onboarding — car picker.
  static const String onboardCarTitle = 'Choose your main ride';
  static const String onboardCarSub = 'Select the car you drive most';
  static const String onboardCarMissingModel = "don't see your model?";

  // Onboarding — community.
  static const String onboardCommunityCountSuffix = 'drivers on DriveRank';
  static const String onboardCommunityShareSuffix =
      'of all DriveRank drivers in your region';

  // Onboarding — map theme.
  static const String onboardMapThemeTitle = 'Your navigation, your way';
  static const String onboardMapThemeSub = "Pick a map style that's you";

  // Onboarding — reviews.
  static const String onboardReviewsTitle =
      'DriveRank was made for people like you';
  static const String onboardReviewsRatingSuffix = 'ratings';

  // Onboarding — safety.
  static const String onboardSafetyTitle = 'Drive safe, always';
  static const String onboardSafetyAccept =
      "I won't use the app while driving and "
      'will only check stats when stopped.';

  // Tracking screen.
  static const String trackingLive = 'LIVE';
  static const String trackingEndTrip = 'End Trip';
  static const String trackingTopSpeed = 'TOP SPEED';
  static const String trackingAvgSpeed = 'AVG';
  static const String trackingDistance = 'DISTANCE';
  static const String trackingDuration = 'DURATION';
  static const String trackingGForce = 'G-FORCE';
  static const String trackingFuelCost = 'FUEL COST';
  static const String trackingFuelNotConfigured = '—';
  static const String trackingFuelTapToConfigure =
      'Set fuel price in settings to see trip cost';

  // Trip summary.
  static const String tripSummaryShare = 'Share';
  static const String tripSummarySave = 'Save to Gallery';
  static const String tripSummaryRankBadgePrefix = '#';

  // History.
  static const String historyTitle = 'History';
  static const String historyFilterAll = 'All';
  static const String historyFilterWeek = 'This Week';
  static const String historyFilterNight = 'Night Drives';
  static const String historyFilterBest = 'Personal Best';
  static const String historyEmpty = 'No trips yet — go for a drive';

  // Monthly report.
  static const String monthlyReportTitle = 'Your Driving Month';
  static const String monthlyReportCta = 'See your month →';

  // Leaderboard.
  static const String leaderboardTitle = 'RANKINGS';
  static const String leaderboardSubGlobal =
      'How you stack up vs the world this week';
  static const String leaderboardTabFriends = 'Friends';
  static const String leaderboardTabGlobal = 'Global';
  static const String leaderboardYou = 'YOU';

  // Profile.
  static const String profileTitle = 'Profile';
  static const String profileGoPro = 'Go Pro';
  static const String profileSignOut = 'Sign out';
  static const String profileDeleteAccount = 'Delete account';

  // Paywall.
  static const String paywallTitle = 'Free trip limit reached';
  static const String paywallPlanAnnual = 'Annual';
  static const String paywallPlanMonthly = 'Monthly';
  static const String paywallBadgeBestValue = 'BEST VALUE';
  static const String paywallContinue = 'Continue →';
  static const String paywallFooter =
      'No tricks. Cancel anytime. Restore purchases.';
  static const String paywallRestore = 'Restore purchases';

  // Settings.
  static const String settingsTitle = 'Settings';
  static const String settingsCarProfile = 'Car Profile';
  static const String settingsUnits = 'Units';
  static const String settingsFuel = 'Fuel';
  static const String settingsMapTheme = 'Map Theme';
  static const String settingsAccount = 'Account';
  static const String settingsUnitSystemMetric = 'Metric (km, km/h, L/100km)';
  static const String settingsUnitSystemImperial = 'Imperial (mi, mph, mpg)';

  // Errors.
  static const String errorNoInternet =
      'No internet connection. Some features may be limited.';
  static const String errorGpsUnavailable =
      "Couldn't get a GPS signal. Try moving to an open area.";
  static const String errorLocationPermission =
      'DriveRank needs location permission to track trips.';
  static const String errorStorage = "Couldn't save trip data";
  static const String errorUnknown = 'Something went wrong. Please try again.';
}
