import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';

class AudioService {
  final AudioPlayer _player = AudioPlayer();

  static const _channel = MethodChannel('com.mymusic/foreground');

  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  Future<void> play(
    String url, {
    String id = '',
    String title = '',
    String artist = '',
    String? artUri,
  }) async {
    final AudioSource source;
    if (url.startsWith('/') || url.startsWith('file://')) {
      final path = url.startsWith('file://') ? url.substring(7) : url;
      source = AudioSource.file(path);
    } else {
      // No custom headers: passing headers forces just_audio onto its localhost
      // HTTP proxy on Android, which mishandles range requests on seek.
      source = AudioSource.uri(Uri.parse(url));
    }

    await _player.setAudioSource(source);
    await _player.play();
    _startForeground(title, artist);
  }

  Future<void> pause() async {
    await _player.pause();
    _stopForeground();
  }

  Future<void> resume() async {
    await _player.play();
  }

  Future<void> seek(Duration position) => _player.seek(position);
  Future<void> setVolume(double v) => _player.setVolume(v);

  void dispose() {
    _stopForeground();
    _player.dispose();
  }

  void _startForeground(String title, String artist) {
    _channel.invokeMethod('startForeground', {'title': title, 'artist': artist})
        .catchError((_) {}); // no-op on non-Android platforms
  }

  void _stopForeground() {
    _channel.invokeMethod('stopForeground').catchError((_) {});
  }
}
