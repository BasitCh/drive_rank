import 'package:drive_rank/shared/models/country.dart';

/// How one account is described to somebody who is deciding whether it
/// is the right person.
///
/// Usernames are unique going forward, but that is not enough on its
/// own: accounts that predate the reservation can share a name, and
/// "Ali" in Pakistan and "Ali" in Austria look identical in a list. So
/// a result carries three things — the name, where they drive, and a
/// short fingerprint of the account itself.
///
/// The fingerprint is the *invite code*, not a slice of the raw uid.
/// Both identify the account, but the code is already the thing users
/// read aloud and type, it uses an alphabet chosen so it can't be
/// misread, and it is the same string on every device. A uid prefix
/// would be a second, uglier identifier for the same thing.
class AccountLabel {
  const AccountLabel._();

  /// `🇵🇰 Pakistan · BMW M3 · 56Z8ZTMQ`
  ///
  /// Every part is omitted when unknown rather than padded — a driver
  /// who hasn't set a car should read as having no car, not as having a
  /// blank one.
  static String describe({
    required String countryCode,
    required String carMake,
    required String carModel,
    required String inviteCode,
    bool includeCode = true,
  }) {
    final country = countryFromCode(countryCode);
    final car = [carMake, carModel].where((s) => s.trim().isNotEmpty).join(' ');
    return [
      if (country != null) '${country.flag} ${country.name}',
      if (car.isNotEmpty) car,
      if (includeCode && inviteCode.isNotEmpty) inviteCode,
    ].join('  ·  ');
  }
}
