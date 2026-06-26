import 'package:flutter/material.dart';
import '../../models/playlist.dart';
import '../../theme.dart';

void showAddToPlaylistDialog(
  BuildContext context, {
  required List<Playlist> playlists,
  required void Function(String playlistId) onAdd,
}) {
  showDialog(
    context: context,
    builder: (_) => _AddToPlaylistDialog(playlists: playlists, onAdd: onAdd),
  );
}

class _AddToPlaylistDialog extends StatelessWidget {
  final List<Playlist> playlists;
  final void Function(String playlistId) onAdd;

  const _AddToPlaylistDialog({required this.playlists, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add to Playlist'),
      contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      content: playlists.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.xxl, vertical: AppSpacing.xl),
              child: Text(
                'No playlists yet.',
                style: TextStyle(color: AppColors.textMuted),
              ),
            )
          : SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: playlists.length,
                itemBuilder: (_, i) {
                  final playlist = playlists[i];
                  return ListTile(
                    title: Text(
                      playlist.name,
                      style: AppTextStyles.listTitle,
                    ),
                    subtitle: Text(
                      '${playlist.songCount} ${playlist.songCount == 1 ? 'song' : 'songs'}',
                      style: AppTextStyles.listSubtitle,
                    ),
                    onTap: () {
                      onAdd(playlist.id);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
        ),
      ],
    );
  }
}
