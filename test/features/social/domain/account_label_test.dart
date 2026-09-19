import 'package:drive_rank/features/social/domain/entities/account_label.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('names the country, the car and the account code — two people can '
      'legitimately share a username, and a list of identical names is '
      'worse than no search', () {
    expect(
      AccountLabel.describe(
        countryCode: 'PK',
        carMake: 'BMW',
        carModel: 'M3',
        inviteCode: '56Z8ZTMQ',
      ),
      '🇵🇰 Pakistan  ·  BMW M3  ·  56Z8ZTMQ',
    );
  });

  test('distinguishes the same name in two countries, which is the whole '
      'point', () {
    final pk = AccountLabel.describe(
      countryCode: 'PK',
      carMake: '',
      carModel: '',
      inviteCode: 'AAAA1111',
    );
    final at = AccountLabel.describe(
      countryCode: 'AT',
      carMake: '',
      carModel: '',
      inviteCode: 'BBBB2222',
    );
    expect(pk, isNot(at));
    expect(pk, contains('Pakistan'));
    expect(at, contains('Austria'));
  });

  test('omits what it does not know rather than padding it — a driver '
      'with no car reads as having none, not a blank one', () {
    expect(
      AccountLabel.describe(
        countryCode: '',
        carMake: '',
        carModel: '',
        inviteCode: 'AAAA1111',
      ),
      'AAAA1111',
    );
    expect(
      AccountLabel.describe(
        countryCode: 'PK',
        carMake: 'BMW',
        carModel: '',
        inviteCode: '',
      ),
      '🇵🇰 Pakistan  ·  BMW',
    );
    expect(
      AccountLabel.describe(
        countryCode: '',
        carMake: '',
        carModel: '',
        inviteCode: '',
      ),
      isEmpty,
    );
  });

  test('an unknown country code is dropped, not rendered as a blank flag',
      () {
    expect(
      AccountLabel.describe(
        countryCode: 'ZZ',
        carMake: 'BMW',
        carModel: 'M3',
        inviteCode: 'AAAA1111',
      ),
      'BMW M3  ·  AAAA1111',
    );
  });

  test('the code can be withheld where the row is already unambiguous', () {
    expect(
      AccountLabel.describe(
        countryCode: 'PK',
        carMake: 'BMW',
        carModel: 'M3',
        inviteCode: '56Z8ZTMQ',
        includeCode: false,
      ),
      '🇵🇰 Pakistan  ·  BMW M3',
    );
  });
}
