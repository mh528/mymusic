import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Timeout guards against AudioService binding hanging forever (black screen).
  // If init completes in time, _audioHandler is set and playback works normally.
  // If it times out, the app still launches — playback will error but won't hang.
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.mymusic.audio',
    androidNotificationChannelName: 'My Music',
    androidNotificationOngoing: true,
  ).timeout(const Duration(seconds: 5), onTimeout: () {});
  runApp(
    const ProviderScope(
      child: MyMusicApp(),
    ),
  );
}
