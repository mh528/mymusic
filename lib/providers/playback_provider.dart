import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song.dart';
import '../models/settings.dart';
import '../data/audio_service.dart';
import 'library_provider.dart';
import 'settings_provider.dart';
import 'yt_library_provider.dart';

class PlaybackState {
  final Song? currentSong;
  final List<Song> queue;
  final bool isPlaying;
  final RepeatMode repeatMode;
  final Duration position;
  final Duration duration;
  final double volume;
  final String? lastError;

  const PlaybackState({
    this.currentSong,
    this.queue = const [],
    this.isPlaying = false,
    this.repeatMode = RepeatMode.off,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.volume = 1.0,
    this.lastError,
  });

  PlaybackState copyWith({
    Song? currentSong,
    bool clearCurrentSong = false,
    List<Song>? queue,
    bool? isPlaying,
    RepeatMode? repeatMode,
    Duration? position,
    Duration? duration,
    double? volume,
    String? lastError,
    bool clearError = false,
  }) {
    return PlaybackState(
      currentSong: clearCurrentSong ? null : (currentSong ?? this.currentSong),
      queue: queue ?? this.queue,
      isPlaying: isPlaying ?? this.isPlaying,
      repeatMode: repeatMode ?? this.repeatMode,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      volume: volume ?? this.volume,
      lastError: clearError ? null : (lastError ?? this.lastError),
    );
  }
}

final playbackProvider =
    NotifierProvider<PlaybackNotifier, PlaybackState>(PlaybackNotifier.new);

class PlaybackNotifier extends Notifier<PlaybackState> {
  final _audio = AudioService();
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;
  StreamSubscription<PlayerState>? _playerStateSub;

  @override
  PlaybackState build() {
    _positionSub = _audio.positionStream.listen((pos) {
      state = state.copyWith(position: pos);
    });
    _durationSub = _audio.durationStream.listen((dur) {
      if (dur != null) state = state.copyWith(duration: dur);
    });
    _playerStateSub = _audio.playerStateStream.listen((ps) {
      state = state.copyWith(isPlaying: ps.playing);
    });

    ref.onDispose(() {
      _positionSub?.cancel();
      _durationSub?.cancel();
      _playerStateSub?.cancel();
      _audio.dispose();
    });

    Future.microtask(_restoreQueue);
    return const PlaybackState();
  }

  static const _queueKey = 'queue_json';

  Future<void> _restoreQueue() async {
    final settings = ref.read(settingsProvider).valueOrNull;
    if (settings?.persistentQueue != true) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_queueKey);
    if (raw == null) return;
    try {
      final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      final songs = list.map(Song.fromJson).toList();
      if (songs.isNotEmpty) state = state.copyWith(queue: songs);
    } catch (_) {}
  }

  Future<void> _saveQueue(List<Song> queue) async {
    final settings = ref.read(settingsProvider).valueOrNull;
    if (settings?.persistentQueue != true) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_queueKey, jsonEncode(queue.map((s) => s.toJson()).toList()));
  }

  Future<void> playSong(Song song, {List<Song> queue = const []}) async {
    final newQueue = queue.isNotEmpty ? queue : state.queue;
    state = state.copyWith(
      currentSong: song,
      queue: newQueue,
      isPlaying: false,
      position: Duration.zero,
      duration: song.duration,
      clearError: true,
    );
    _saveQueue(newQueue);
    final (url, error) = await _resolveUrl(song);
    if (url == null) {
      state = state.copyWith(lastError: error ?? 'Could not load stream');
      return;
    }
    try {
      await _audio.play(
        url,
        id: song.id,
        title: song.title,
        artist: song.artist,
        artUri: song.thumbnailUrl,
      );
    } on PlayerException catch (_) {
      // CDN URLs expire after ~6 hours. Re-fetch once before giving up.
      if (song.videoId != null) {
        final (freshUrl, freshError) = await _resolveUrl(song);
        if (freshUrl != null && freshUrl != url) {
          try {
            await _audio.play(
              freshUrl,
              id: song.id,
              title: song.title,
              artist: song.artist,
              artUri: song.thumbnailUrl,
            );
            return;
          } catch (e2) {
            state = state.copyWith(lastError: 'Playback error after retry: $e2');
            return;
          }
        }
        state = state.copyWith(lastError: freshError ?? 'Could not reload stream');
      } else {
        state = state.copyWith(lastError: 'Playback error');
      }
    } catch (e) {
      state = state.copyWith(lastError: 'Playback error: $e');
    }
  }

  // Returns (url, errorMessage) — used by playSong to surface errors on screen.
  Future<(String?, String?)> _resolveUrl(Song song) async {
    try {
      if (song.videoId != null) {
        // Prefer local downloaded file — avoids fetching an expiring CDN URL.
        if (song.filePath != null) {
          final file = File(song.filePath!);
          if (file.existsSync()) return (song.filePath, null);
        }
        final quality = ref.read(settingsProvider).valueOrNull?.audioQuality ?? AudioQuality.auto;
        final url = await ref.read(youtubeMusicServiceProvider).getStreamUrl(song.videoId!, quality: quality);
        return (url, url == null ? 'getStreamUrl returned null for ${song.videoId}' : null);
      }
      final url = await ref.read(musicRepositoryProvider).getStreamUrl(song.id);
      return (url, url == null ? 'No stream URL for ${song.id}' : null);
    } catch (e) {
      return (null, 'Stream URL error: $e');
    }
  }

  // Silent version for skip — errors are swallowed since there's no UX to show them.
  Future<String?> _resolveUrlSilent(Song song) async {
    final (url, _) = await _resolveUrl(song);
    return url;
  }

  void playPause() {
    if (state.isPlaying) {
      _audio.pause();
    } else {
      _audio.resume();
    }
    state = state.copyWith(isPlaying: !state.isPlaying);
  }

  Future<void> skipNext() async {
    final queue = state.queue;
    if (queue.isEmpty) {
      if (state.repeatMode == RepeatMode.one && state.currentSong != null) {
        _audio.seek(Duration.zero);
        state = state.copyWith(position: Duration.zero, isPlaying: true);
      } else {
        _audio.pause();
        state = state.copyWith(isPlaying: false, position: Duration.zero);
      }
      return;
    }

    if (state.repeatMode == RepeatMode.one && state.currentSong != null) {
      _audio.seek(Duration.zero);
      state = state.copyWith(position: Duration.zero);
      return;
    }

    final currentId = state.currentSong?.id;
    final currentIndex = queue.indexWhere((s) => s.id == currentId);

    if (currentIndex == -1 || currentIndex == queue.length - 1) {
      if (state.repeatMode == RepeatMode.all) {
        final next = queue.first;
        state = state.copyWith(
          currentSong: next,
          position: Duration.zero,
          duration: next.duration,
          isPlaying: false,
        );
        final url = await _resolveUrlSilent(next);
        if (url != null) {
          try { await _audio.play(url); } on LateInitializationError { state = state.copyWith(lastError: 'Audio not ready — please try again'); }
        }
      } else {
        _audio.pause();
        state = state.copyWith(isPlaying: false, position: Duration.zero);
      }
    } else {
      final next = queue[currentIndex + 1];
      state = state.copyWith(
        currentSong: next,
        position: Duration.zero,
        duration: next.duration,
        isPlaying: false,
      );
      final url = await _resolveUrlSilent(next);
      if (url != null) await _audio.play(url);
    }
  }

  Future<void> skipPrevious() async {
    if (state.position > const Duration(seconds: 3)) {
      _audio.seek(Duration.zero);
      state = state.copyWith(position: Duration.zero);
      return;
    }

    final queue = state.queue;
    final currentId = state.currentSong?.id;
    final currentIndex = queue.indexWhere((s) => s.id == currentId);

    if (currentIndex <= 0) {
      _audio.seek(Duration.zero);
      state = state.copyWith(position: Duration.zero);
    } else {
      final prev = queue[currentIndex - 1];
      state = state.copyWith(
        currentSong: prev,
        position: Duration.zero,
        duration: prev.duration,
        isPlaying: false,
      );
      final url = await _resolveUrlSilent(prev);
      if (url != null) await _audio.play(url);
    }
  }

  void cycleRepeat() {
    final next = switch (state.repeatMode) {
      RepeatMode.off => RepeatMode.all,
      RepeatMode.all => RepeatMode.one,
      RepeatMode.one => RepeatMode.off,
    };
    state = state.copyWith(repeatMode: next);
  }

  void setPosition(Duration pos) {
    _audio.seek(pos);
    state = state.copyWith(position: pos);
  }

  void setVolume(double v) {
    final clamped = v.clamp(0.0, 1.0);
    _audio.setVolume(clamped);
    state = state.copyWith(volume: clamped);
  }

  void addToQueue(Song song) {
    final queue = [...state.queue, song];
    state = state.copyWith(queue: queue);
    _saveQueue(queue);
  }

  /// Inserts [song] immediately after the currently playing track.
  void playNext(Song song) {
    final queue = List<Song>.from(state.queue);
    final currentIndex = state.currentSong == null
        ? -1
        : queue.indexWhere((s) => s.id == state.currentSong!.id);
    queue.insert(currentIndex + 1, song);
    state = state.copyWith(queue: queue);
    _saveQueue(queue);
  }

  void removeFromQueue(String songId) {
    final queue = state.queue.where((s) => s.id != songId).toList();
    state = state.copyWith(queue: queue);
    _saveQueue(queue);
  }

  void reorderQueue(int oldIndex, int newIndex) {
    final queue = List<Song>.from(state.queue);
    final item = queue.removeAt(oldIndex);
    final insertIndex = newIndex > oldIndex ? newIndex - 1 : newIndex;
    queue.insert(insertIndex, item);
    state = state.copyWith(queue: queue);
    _saveQueue(queue);
  }

  void clearQueue() {
    state = state.copyWith(queue: []);
    _saveQueue([]);
  }

  void shuffleQueue() {
    final queue = List<Song>.from(state.queue)..shuffle();
    state = state.copyWith(queue: queue);
    _saveQueue(queue);
  }
}
