import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:metadata_god/metadata_god.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MetadataGod.initialize();
  runApp(
    const ProviderScope(
      child: MyMusicApp(),
    ),
  );
}
