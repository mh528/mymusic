import 'package:flutter/material.dart';
import '../../theme.dart';

void showCreatePlaylistDialog(
  BuildContext context, {
  required void Function(String name) onCreate,
}) {
  showDialog(
    context: context,
    builder: (_) => _CreatePlaylistDialog(onCreate: onCreate),
  );
}

class _CreatePlaylistDialog extends StatefulWidget {
  final void Function(String name) onCreate;

  const _CreatePlaylistDialog({required this.onCreate});

  @override
  State<_CreatePlaylistDialog> createState() => _CreatePlaylistDialogState();
}

class _CreatePlaylistDialogState extends State<_CreatePlaylistDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _controller.text.trim();
    if (name.isNotEmpty) {
      widget.onCreate(name);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Playlist'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _submit(),
        style: const TextStyle(color: AppColors.white),
        decoration: const InputDecoration(
          hintText: 'Playlist name',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
        ),
        TextButton(
          onPressed: _submit,
          child: const Text('Create', style: TextStyle(color: AppColors.white)),
        ),
      ],
    );
  }
}
