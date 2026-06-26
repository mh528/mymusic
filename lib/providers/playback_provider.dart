import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import '../models/song.dart';
import '../models/settings.dart';
import '../data/audio_service.dart';

class PlaybackState {
  final Song? currentSong;
  final List<Song> queue;
  final bool isPlaying;
  final RepeatMode repeatMode;
  final Duration position;
  final Duration duration;
  final double volume;

  const PlaybackState({
    this.currentSong,
    this.queue = const [],
    this.isPlaying = false,
    this.repeatMode = RepeatMode.off,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.volume = 1.0,
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
  }) {
    return PlaybackState(
      currentSong: clearCurrentSong ? null : (currentSong ?? this.currentSong),
      queue: queue ?? this.queue,
      isPlaying: isPlaying ?? this.isPlaying,
      repeatMode: repeatMode ?? this.repeatMode,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      volume: volume ?? this.volume,
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

    return const PlaybackState();
  }

  void playSong(Song song, {List<Song> queue = const []}) {
    state = state.copyWith(
      currentSong: song,
      queue: queue.isNotEmpty ? queue : state.queue,
      isPlaying: true,
      position: Duration.zero,
      duration: song.duration,
    );
    if (song.filePath != null) {
      _audio.play(song.filePath!);
    }
  }

  void playPause() {
    if (state.isPlaying) {
      _audio.pause();
    } else {
      _audio.resume();
    }
    state = state.copyWith(isPlaying: !state.isPlaying);
  }

  void skipNext() {
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
          isPlaying: true,
        );
        if (next.filePath != null) _audio.play(next.filePath!);
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
        isPlaying: true,
      );
      if (next.filePath != null) _audio.play(next.filePath!);
    }
  }

  void skipPrevious() {
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
        isPlaying: true,
      );
      if (prev.filePath != null) _audio.play(prev.filePath!);
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
    state = state.copyWith(queue: [...state.queue, song]);
  }

  void removeFromQueue(String songId) {
    final queue = state.queue.where((s) => s.id != songId).toList();
    state = state.copyWith(queue: queue);
  }

  void reorderQueue(int oldIndex, int newIndex) {
    final queue = List<Song>.from(state.queue);
    final item = queue.removeAt(oldIndex);
    final insertIndex = newIndex > oldIndex ? newIndex - 1 : newIndex;
    queue.insert(insertIndex, item);
    state = state.copyWith(queue: queue);
  }

  void clearQueue() {
    state = state.copyWith(queue: []);
  }
}
