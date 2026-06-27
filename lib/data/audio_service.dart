import 'package:just_audio/just_audio.dart';

class AudioService {
  final AudioPlayer _player = AudioPlayer();

  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  Future<void> play(String url) async {
    if (url.startsWith('/') || url.startsWith('file://')) {
      final path = url.startsWith('file://') ? url.substring(7) : url;
      await _player.setFilePath(path);
    } else {
      // YouTube CDN requires a matching user-agent or returns 403
      await _player.setUrl(url, headers: {
        'user-agent': 'com.google.android.youtube/20.10.38 (Linux; U; Android 11) gzip',
      });
    }
    await _player.play();
  }

  Future<void> pause() => _player.pause();
  Future<void> resume() => _player.play();
  Future<void> seek(Duration position) => _player.seek(position);
  Future<void> setVolume(double v) => _player.setVolume(v);
  void dispose() => _player.dispose();
}
