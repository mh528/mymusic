import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'pages/library_page.dart';
import 'pages/queue_page.dart';
import 'pages/settings_page.dart';
import 'pages/album_page.dart';
import 'pages/artist_page.dart';
import 'pages/playlist_page.dart';
import 'providers/local_library_provider.dart';
import 'providers/settings_provider.dart';
import 'theme.dart';

final _router = GoRouter(
  initialLocation: '/library',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return AppShell(shell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/library',
              builder: (context, state) => const LibraryPage(),
              routes: [
                GoRoute(
                  path: 'album/:id',
                  builder: (context, state) => AlbumPage(
                    albumId: state.pathParameters['id']!,
                  ),
                ),
                GoRoute(
                  path: 'artist/:id',
                  builder: (context, state) => ArtistPage(
                    artistId: state.pathParameters['id']!,
                  ),
                ),
                GoRoute(
                  path: 'playlist/:id',
                  builder: (context, state) => PlaylistPage(
                    playlistId: state.pathParameters['id']!,
                  ),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/queue',
              builder: (context, state) => const QueuePage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsPage(),
            ),
          ],
        ),
      ],
    ),
  ],
);

class AppShell extends ConsumerWidget {
  final StatefulNavigationShell shell;

  const AppShell({super.key, required this.shell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(settingsProvider);
    // On cold launch, restore local library cache once settings are available
    ref.listen(settingsProvider, (_, next) {
      next.whenData((s) => ref.read(localLibraryProvider.notifier).initFromSettings(s));
    });

    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (index) {
          shell.goBranch(
            index,
            initialLocation: index == shell.currentIndex,
          );
        },
        backgroundColor: AppColors.black,
        height: 64,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.music_note_outlined),
            selectedIcon: Icon(Icons.music_note),
            label: 'Music',
          ),
          NavigationDestination(
            icon: Icon(Icons.queue_music_outlined),
            selectedIcon: Icon(Icons.queue_music),
            label: 'Queue',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class MyMusicApp extends ConsumerWidget {
  const MyMusicApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      routerConfig: _router,
      theme: appTheme,
      title: 'My Music',
      debugShowCheckedModeBanner: false,
    );
  }
}
