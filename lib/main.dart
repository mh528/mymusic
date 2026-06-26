import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'data/mock_music_repository.dart';
import 'providers/library_provider.dart';

void main() {
  runApp(
    ProviderScope(
      overrides: [
        musicRepositoryProvider.overrideWithValue(MockMusicRepository()),
      ],
      child: const MyMusicApp(),
    ),
  );
}
