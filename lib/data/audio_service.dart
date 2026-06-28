import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

class AudioService {
  final AudioPlayer _player = AudioPlayer();

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
    final tag = MediaItem(
      id: id.isEmpty ? url : id,
      title: title.isEmpty ? 'Unknown' : title,
      artist: artist.isEmpty ? 'Unknown' : artist,
      artUri: artUri != null ? Uri.tryParse(artUri) : null,
    );

    final AudioSource source;
    if (url.startsWith('/') || url.startsWith('file://')) {
      final path = url.startsWith('file://') ? url.substring(7) : url;
      source = AudioSource.file(path, tag: tag);
    } else {
      // No custom headers: passing headers forces just_audio onto its localhost
      // HTTP proxy on Android, which mishandles range requests on seek
      // ("source error 0"). The CDN URL from youtube_explode_dart is already
      // signed and needs no user-agent. Let ExoPlayer fetch it directly.
      source = AudioSource.uri(Uri.parse(url), tag: tag);
    }

    await _player.setAudioSource(source);
    await _player.play();
  }

  Future<void> pause() => _player.pause();
  Future<void> resume() => _player.play();
  Future<void> seek(Duration position) => _player.seek(position);
  Future<void> setVolume(double v) => _player.setVolume(v);
  void dispose() => _player.dispose();
}
