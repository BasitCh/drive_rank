import 'dart:convert';

import 'package:crypto/crypto.dart';

/// The short code a driver shares to be added as a friend.
///
/// Derived from the uid rather than stored: the same account produces
/// the same code on every device, there is no generation step to get
/// wrong, no schema column, and nothing to sync. It exists because a
/// username only works for accounts that hold one — anybody whose name
/// collided on upgrade is unsearchable, and a code lets them be added
/// anyway.
///
/// **It cannot be rotated.** A code shared publicly is public for good,
/// because there is nowhere to record that it changed. That trade-off is
/// accepted knowingly at this stage; rotation needs stored state, and a
/// stored code is the change to make if it is ever wanted.
///
/// The code is *not* a secret in the security sense — knowing it lets
/// you send a friend request, which the recipient still has to accept.
/// It is an address, not a password.
String inviteCodeFor(String uid) {
  if (uid.isEmpty) return '';
  final digest = sha256.convert(utf8.encode(uid));
  return _base32(digest.bytes.take(_rawBytes).toList());
}

/// Five bytes → exactly eight base32 characters, no padding.
const int _rawBytes = 5;

/// Crockford base32 without the letters that get misread aloud or
/// mistyped: no I, L, O or U. A code gets read off a screen and typed by
/// somebody else, so the alphabet matters more than the density.
const String _alphabet = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';

String _base32(List<int> bytes) {
  final buffer = StringBuffer();
  var bits = 0;
  var value = 0;
  for (final byte in bytes) {
    value = (value << 8) | byte;
    bits += 8;
    while (bits >= 5) {
      buffer.write(_alphabet[(value >> (bits - 5)) & 31]);
      bits -= 5;
    }
  }
  if (bits > 0) {
    buffer.write(_alphabet[(value << (5 - bits)) & 31]);
  }
  return buffer.toString();
}

/// Accepts a code the way a human typed it — trimmed, upper-cased, and
/// with the characters the alphabet deliberately excludes mapped to what
/// the writer almost certainly meant.
String normaliseInviteCode(String input) {
  final upper = input.trim().toUpperCase().replaceAll(RegExp(r'[\s-]'), '');
  return upper
      .replaceAll('I', '1')
      .replaceAll('L', '1')
      .replaceAll('O', '0')
      .replaceAll('U', 'V');
}
