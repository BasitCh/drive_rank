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
  static const String onboardSafetyTitle = 'Before you drive';
  static const String onboardSafetySub = 'Important safety reminders';
  static const String onboardSafetyItem1 =
      'Obey local traffic laws and speed limits. Never drive recklessly.';
  static const String onboardSafetyItem2 =
      'Start and stop recording only while safely parked.';
  static const String onboardSafetyItem3 =
      'Use a phone holder. Never touch your phone while driving.';
  static const String onboardSafetyAccept =
      'I acknowledge these guidelines and agree to drive responsibly';
  static const String onboardSafetyCta = 'I Agree & Continue';

  // Onboarding — community popup numbers (computed at runtime).
  static const String onboardCommunityMostPopularPrefix = '#';
  static const String onboardCommunityMostPopularSuffix =
      ' most popular on DriveRank';

  // Onboarding — map theme labels.
  static const String mapThemePixel = 'Pixel';
  static const String mapThemeCyber = 'Cyber';
  static const String mapThemeGta = 'GTA';
  static const String mapThemeRegular = 'Classic';
  static const String mapThemeWest = 'West';
  static const String mapThemeDark = 'Dark';

  // Onboarding — reviews seed (English-only v1, generic and global).
  static const String reviewerOneName = 'hassan_drives';
  static const String reviewerOneText =
      'Finally an app that gets car people. The stat cards are insane to '
      'post on TikTok, everyone asks what app I use.';
  static const String reviewerTwoName = 'karachispeeds';
  static const String reviewerTwoText =
      'Love the GTA map style lol. Global leaderboard is actually '
      'competitive. Using it every single drive now.';
  static const String reviewsAppStoreSource = 'App Store';

  // Tracking screen.
  static const String trackingLive = 'LIVE';
  static const String trackingEndTrip = 'End Trip';
  static const String trackingCurrentSpeedSuffix = ' — CURRENT SPEED';
  static const String trackingTopSpeed = 'TOP SPEED';
  static const String trackingAvgSpeed = 'AVG';
  static const String trackingMaxSpeed = 'MAX';
  static const String trackingDistance = 'DISTANCE';
  static const String trackingDuration = 'DURATION';
  static const String trackingGForce = 'G-FORCE';
  static const String trackingFuelCost = 'FUEL COST';
  static const String trackingFuelNotConfigured = '—';
  static const String trackingFuelTapToConfigure =
      'Set fuel price in settings to see trip cost';
  static const String trackingWaitingForGps = 'WAITING FOR GPS…';
  static const String trackingPermissionDenied =
      'Location permission is required to track trips.';
  static const String trackingOpenSettings = 'Open Settings';
  static const String trackingGrantPermission = 'Grant Permission';

  // Trip summary.
  static const String tripSummaryTitle = 'Trip Summary';
  static const String tripSummaryShare = 'Share';
  static const String tripSummarySave = 'Save to Gallery';
  static const String tripSummaryDelete = 'Delete trip';
  static const String tripSummaryDeleteConfirm =
      'Delete this trip? This cannot be undone.';
  static const String tripSummaryRankBadgePrefix = '#';
  static const String tripSummaryDriveAnalytics = 'DRIVE ANALYTICS';
  static const String tripSummaryHardCorners = 'Hard Corners';
  static const String tripSummaryHardBrakes = 'Hard Brakes';
  static const String tripSummaryYourRank = 'Your Rank';
  static const String tripSummaryGforcePeakSuffix = 'g peak';
  static const String tripSummaryNoRouteYet = 'No GPS fix recorded';
  static const String tripSummaryShareSubject = 'My DriveRank trip';

  // History.
  static const String historyTitle = 'History';
  static const String historyFilterAll = 'All';
  static const String historyFilterWeek = 'This Week';
  static const String historyFilterNight = 'Night Drives';
  static const String historyFilterBest = 'Personal Best';
  static const String historyEmpty = 'No trips yet — go for a drive';
  static const String historyTripFallbackName = 'Trip';

  // Monthly report.
  static const String monthlyReportTitle = 'Your Driving Month';
  static const String monthlyReportCta = 'See your month →';
  static const String monthlyReportEmpty =
      'No drives this month — your report will appear after your first trip';
  static const String monthlyReportTotalKm = 'TOTAL DISTANCE';
  static const String monthlyReportTotalTrips = 'TRIPS';
  static const String monthlyReportTopSpeed = 'TOP SPEED';
  static const String monthlyReportTotalDuration = 'TOTAL TIME';
  static const String monthlyReportMostActiveDay = 'MOST ACTIVE DAY';
  static const String monthlyReportBestGforce = 'BEST G-FORCE';

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
