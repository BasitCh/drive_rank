/// Spacing and radius tokens, matched 1:1 to the HTML mock's px values.
class AppSpacing {
  const AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;

  static const double radiusSm = 12;
  static const double radiusMd = 16;
  static const double radiusLg = 20;

  /// Effectively a full pill — large enough to round any sane button height.
  static const double radiusFull = 100;
}
