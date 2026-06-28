/// Centralised English strings for v1.
///
/// All UI text lives here — never inline a string literal in a widget.
/// Once i18n is enabled, swap this class for generated `AppLocalizations`
/// without touching widget code.
class AppStrings {
  const AppStrings._();

  // App identity.
  static const String appName = 'Drive Rank';
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
  static const String navPersonalBests = 'Bests';
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

  // Onboarding — username.
  static const String onboardUsernameTitle = 'Pick a username';
  static const String onboardUsernameSub =
      "It's what shows on the leaderboard. You can't change it later.";
  static const String onboardUsernameHint = 'username';
  static const String onboardUsernameAvailableSuffix = ' is available';
  static const String onboardUsernameTaken = 'Username already taken';
  static const String onboardUsernameTooShort = 'Minimum 3 characters';
  static const String onboardUsernameInvalid =
      'Letters, numbers and underscore only';
  static const String onboardUsernameChecking = 'Checking availability…';
  static const String onboardUsernameError =
      "Couldn't check availability — try again";

  // Onboarding — car photo.
  static const String onboardCarPhotoTitle = 'Show off your ride';
  static const String onboardCarPhotoSub =
      'Add a photo of your car. It appears on your stat card and profile.';
  static const String onboardCarPhotoUpload = 'Upload Photo';
  static const String onboardCarPhotoChange = 'Change Photo';
  static const String onboardCarPhotoSkip = 'Skip';
  static const String onboardCarPhotoCamera = 'Take a photo';
  static const String onboardCarPhotoGallery = 'Choose from gallery';
  static const String onboardCarPhotoCancel = 'Cancel';

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

  // Onboarding — background location Prominent Disclosure.
  //
  // Wording locked to the Google Play User Data policy: identifies the
  // data type (location), the feature (trip tracking), and explicitly
  // that the access continues in the background / while the screen is
  // off. Don't soften without re-checking the policy text — vague
  // disclosure copy is exactly what got the app rejected the first time.
  static const String locationDisclosureTitle =
      'DriveRank needs your location';
  static const String locationDisclosureSub =
      'So we can track your trips accurately';
  static const String locationDisclosureItem1 =
      'Records your route, distance, and speed while you drive.';
  static const String locationDisclosureItem2 =
      'Continues recording when the screen is off or the app is in the '
      "background — that's what keeps the live stats moving on long drives.";
  static const String locationDisclosureItem3 =
      'Stays on your device. Your location is never uploaded, sold, '
      'or shared with anyone.';
  static const String locationDisclosureRevoke =
      "You can revoke access any time from your phone's settings.";
  static const String locationDisclosureCta = 'Allow location access';
  static const String locationDisclosureSkip = 'Skip for now';
  static const String locationDisclosureDeniedHelp =
      'Location access is needed to record trips. You can grant it from '
      "your phone's app settings.";

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
  static const String trackingPausedBadge = 'PAUSED';
  static const String trackingEndTrip = 'End Trip';
  static const String trackingPause = 'Pause';
  static const String trackingResume = 'Resume';
  static const String trackingPausedSpeedLabel = 'TRIP PAUSED';
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
  // Idle / Start-Trip surface.
  static const String homeReadyToDrive = 'Ready to drive?';
  static const String homeReadyToDriveSub =
      'Tap below to start recording. GPS is off until you start.';

  /// Shown under the big "0" on the idle hero — mirrors the
  /// "KM/H — CURRENT SPEED" copy on the live screen.
  static const String homeReadyToDriveTagline = 'READY TO DRIVE';
  static const String homeStartTrip = 'Start Trip';
  static const String homeStartTripDisabled = 'Free trips used up';
  static const String homeStartingTrip = 'Starting…';
  static const String homeStoppingTrip = 'Saving trip…';
  static const String homeUpgradeToContinue = 'Upgrade to keep tracking';
  static const String homeLastFreeTripWarning =
      'Last free trip — upgrade to keep tracking unlimited.';
  static const String homeProMember = 'Pro · unlimited trips';
  static const String homeRetry = 'Retry';
  // Free-trip counter — formatted with sprintf-style placeholders.
  static String homeFreeTripsRemaining(int remaining, int total) {
    if (remaining <= 0) return 'No free trips remaining';
    if (remaining == 1) return '1 of $total free trips left';
    return '$remaining of $total free trips left';
  }

  // End Trip confirmation dialog.
  static const String endTripConfirmTitle = 'End this trip?';
  static const String endTripConfirmBody =
      "We'll save your route and stats. You can't add more after this.";
  static const String endTripConfirmKeepDriving = 'Keep driving';
  static const String endTripConfirmEnd = 'End trip';

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

  // Social share cards — Performance.
  static const String performanceCardTitle = 'Performance';
  static const String performanceCardCta = 'Performance';
  static const String performanceCardCtaSub = 'Speed flex card';
  static const String performanceCardShareCta = 'Share Performance';
  static const String performanceCardShareSubject =
      'My DriveRank performance card';
  static const String performanceCardLoadError =
      'Could not build the performance card for this trip.';

  // Social share cards — Journey.
  static const String journeyCardTitle = 'Journey';
  static const String journeyCardCta = 'Journey';
  static const String journeyCardCtaSub = 'Route story card';
  static const String journeyCardShareCta = 'Share Journey';
  static const String journeyCardShareSubject =
      'My DriveRank journey card';
  static const String journeyCardLoadError =
      'Could not build the journey card for this trip.';

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
  static const String leaderboardFriendsEmptyTitle = 'No friends yet';
  static const String leaderboardFriendsEmptyBody =
      'Invite friends to see how you stack up against them on every drive.';
  static const String leaderboardFriendsCta = 'Invite Friends';

  // Friends feature (Add Friend bottom sheet + profile section).
  static const String friendsAddTitle = 'Add Friend';
  static const String friendsSearchHint = 'Search by username';
  static const String friendsSearchTooShort = 'Type at least 3 characters';
  static const String friendsSearchNoResults = 'No matches';
  static const String friendsAddButton = 'Add';
  static const String friendsAddedButton = 'Friend';
  static const String friendsSentButton = 'Sent';
  static const String friendsSendFailed =
      "Couldn't send the request — try again";
  static const String friendsSectionTitle = 'Friends';
  static const String friendsIncomingTitle = 'Friend requests';
  static const String friendsAccept = 'Accept';
  static const String friendsDecline = 'Decline';
  static const String friendsRequestPrefix = '@';
  static const String friendsRequestSuffix = ' wants to be friends';
  static const String leaderboardSubThisWeek = 'This week';
  static const String leaderboardEmpty =
      'No drives recorded here yet — be the first to set a time.';

  // Profile.
  static const String profileTitle = 'Profile';
  static const String profileGoPro = 'Go Pro';
  static const String profileSignOut = 'Sign out';
  static const String profileSignInGoogle = 'Sign in with Google';
  static const String profileSignedInAs = 'Signed in as';
  static const String profileSignedOut =
      'Signed out — your trips are local only';
  static const String profileDeleteAccount = 'Delete account';
  static const String profileStatTopSpeed = 'TOP SPEED';
  static const String profileStatTotalTrips = 'TOTAL TRIPS';
  static const String profileStatTotalDistance = 'TOTAL DISTANCE';
  static const String profileStatFuelSpent = 'FUEL SPENT';
  static const String profileStatBestGforce = 'BEST G-FORCE';
  static const String profileEditSettings = 'Edit Settings';
  static const String profileSetUsernamePrompt = 'Set a username';
  static const String profileUsernameHint = 'username';
  static const String profileUsernamePlaceholder = 'driver';

  // Paywall.
  static const String paywallTitle = 'Free trip limit reached';
  static const String paywallYourBestTrip = 'YOUR BEST TRIP';
  static const String paywallTripCountSuffix = 'of';
  static const String paywallTripLimitReached = 'Free limit reached';
  static const String paywallPlanAnnual = 'Annual';
  static const String paywallPlanMonthly = 'Monthly';
  static const String paywallBadgeBestValue = 'BEST VALUE';
  static const String paywallPerWeekSuffix = '/week';
  static const String paywallContinue = 'Continue →';
  static const String paywallFooter =
      'No spin wheels. No fake discounts. Cancel anytime.';
  static const String paywallRestore = 'Restore purchases';
  static const String paywallLoadingPrices = 'Loading prices…';
  static const String paywallUnavailable =
      'Pricing is temporarily unavailable. Please try again later.';
  // Feature card titles (mock's swipeable cards).
  static const String paywallFeature1Title = '🏁 Unlimited Trip Recaps';
  static const String paywallFeature1Body =
      'Detailed breakdown of every drive\n'
      'Speed, distance and duration stats\n'
      'Never lose track of your journeys';
  static const String paywallFeature2Title = '🗺️ Animated Stat Cards';
  static const String paywallFeature2Body =
      'Route heat map on every card\n'
      'Animated countdown of your top stats\n'
      'Share-ready PNGs at 3× resolution';
  static const String paywallFeature3Title = '🏆 Global + Friend Leaderboards';
  static const String paywallFeature3Body =
      'Compete on famous driving roads\n'
      'Weekly + all-time rankings';
  static const String paywallFeature4Title = '⛽ Fuel Cost Tracking';
  static const String paywallFeature4Body =
      'Per-trip fuel spend in your currency\n'
      'Monthly fuel totals on your profile\n'
      'Calibrate for your exact consumption';

  // Settings.
  static const String settingsTitle = 'Settings';
  static const String settingsCarProfile = 'Car Profile';
  static const String settingsCarMake = 'Make';
  static const String settingsCarModel = 'Model';
  static const String settingsCarYear = 'Year';
  static const String settingsCarColour = 'Colour';
  static const String settingsUnits = 'Units';
  static const String settingsUnitsSpeed = 'Speed & distance';
  static const String settingsFuel = 'Fuel';
  static const String settingsFuelType = 'Fuel type';
  static const String settingsFuelConsumption = 'Consumption';
  static const String settingsFuelPrice = 'Price per litre';
  static const String settingsFuelPriceImperial = 'Price per gallon';
  static const String settingsFuelCurrency = 'Currency';
  static const String settingsFuelTypePetrol = 'Petrol';
  static const String settingsFuelTypeDiesel = 'Diesel';
  static const String settingsFuelTypeCng = 'CNG';
  static const String settingsFuelTypeElectric = 'Electric';
  static const String settingsMapTheme = 'Map Theme';
  static const String settingsAccount = 'Account';
  static const String settingsUsername = 'Username';
  static const String settingsCountry = 'Country';
  static const String settingsUnitSystemMetric = 'Metric (km, km/h, L/100km)';
  static const String settingsUnitSystemImperial = 'Imperial (mi, mph, mpg)';
  static const String settingsRestorePurchases = 'Restore Purchases';
  static const String settingsDeleteAccountConfirm =
      'This will delete your account and all trip history. This cannot be undone.';
  static const String settingsSavedToast = 'Saved';

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
