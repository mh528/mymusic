import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'app.dart';

void main() async {
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.mymusic.audio',
    androidNotificationChannelName: 'My Music',
    androidNotificationOngoing: true,
  );
  runApp(
    const ProviderScope(
      child: MyMusicApp(),
    ),
  );
}
