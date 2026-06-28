import 'package:flutter_test/flutter_test.dart';
import 'package:mymusic/data/youtube_music_service.dart';

void main() {
  late YouTubeMusicService svc;

  setUp(() => svc = YouTubeMusicService());
  tearDown(() => svc.dispose());

  group('parseDuration', () {
    test('MM:SS', () {
      expect(svc.parseDuration('3:45'), const Duration(minutes: 3, seconds: 45));
    });

    test('HH:MM:SS', () {
      expect(svc.parseDuration('1:03:07'),
          const Duration(hours: 1, minutes: 3, seconds: 7));
    });

    test('null returns default', () {
      expect(svc.parseDuration(null), const Duration(minutes: 3, seconds: 30));
    });

    test('empty string returns default', () {
      expect(svc.parseDuration(''), const Duration(minutes: 3, seconds: 30));
    });

    test('non-numeric returns default', () {
      expect(svc.parseDuration('invalid'), const Duration(minutes: 3, seconds: 30));
    });

    test('single segment returns default', () {
      expect(svc.parseDuration('45'), const Duration(minutes: 3, seconds: 30));
    });

    test('zero duration', () {
      expect(svc.parseDuration('0:00'), Duration.zero);
    });
  });
}
