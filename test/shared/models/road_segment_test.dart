import 'package:drive_rank/shared/models/road_segment.dart';
import 'package:flutter_test/flutter_test.dart';

const _nurburgring = RoadSegment(
  id: 'nurburgring',
  name: 'Nürburgring Nordschleife',
  country: 'DE',
  minLat: 50.32,
  maxLat: 50.38,
  minLng: 6.91,
  maxLng: 6.97,
);

void main() {
  group('RoadSegment.contains', () {
    test('point inside the bbox returns true', () {
      expect(_nurburgring.contains(50.35, 6.94), isTrue);
    });

    test('point outside the bbox returns false', () {
      expect(_nurburgring.contains(48.85, 2.35), isFalse);
    });

    test('point on the bbox edge counts as inside', () {
      expect(_nurburgring.contains(50.32, 6.91), isTrue);
      expect(_nurburgring.contains(50.38, 6.97), isTrue);
    });
  });

  group('RoadSegment.overlapsBbox', () {
    test('trip fully inside segment overlaps', () {
      expect(
        _nurburgring.overlapsBbox(
          minLat: 50.34,
          maxLat: 50.36,
          minLng: 6.93,
          maxLng: 6.95,
        ),
        isTrue,
      );
    });

    test('trip clipping segment from the north overlaps', () {
      expect(
        _nurburgring.overlapsBbox(
          minLat: 50.37,
          maxLat: 50.40,
          minLng: 6.92,
          maxLng: 6.96,
        ),
        isTrue,
      );
    });

    test('trip completely separate from segment does not overlap', () {
      expect(
        _nurburgring.overlapsBbox(
          minLat: 48.80,
          maxLat: 48.90,
          minLng: 2.30,
          maxLng: 2.40,
        ),
        isFalse,
      );
    });
  });

  test('fromJson parses bbox', () {
    final s = RoadSegment.fromJson(const {
      'id': 's1',
      'name': 'Segment 1',
      'country': 'PK',
      'bbox': {'minLat': 33.0, 'maxLat': 34.0, 'minLng': 72.0, 'maxLng': 73.0},
    });
    expect(s.id, 's1');
    expect(s.country, 'PK');
    expect(s.minLat, 33.0);
    expect(s.maxLng, 73.0);
  });

  test('equality is by id', () {
    const a = RoadSegment(
      id: 'x',
      name: 'X1',
      country: 'US',
      minLat: 0,
      maxLat: 1,
      minLng: 0,
      maxLng: 1,
    );
    const b = RoadSegment(
      id: 'x',
      name: 'X2',
      country: 'CA',
      minLat: 10,
      maxLat: 11,
      minLng: 10,
      maxLng: 11,
    );
    expect(a, equals(b));
    expect(a.hashCode, equals(b.hashCode));
  });
}
