import 'package:flutter/material.dart';
import '../../theme.dart';

void showEditPlaylistDialog(
  BuildContext context, {
  required String currentName,
  required void Function(String name) onSave,
}) {
  showDialog(
    context: context,
    builder: (_) => _EditPlaylistDialog(currentName: currentName, onSave: onSave),
  );
}

class _EditPlaylistDialog extends StatefulWidget {
  final String currentName;
  final void Function(String name) onSave;

  const _EditPlaylistDialog({required this.currentName, required this.onSave});

  @override
  State<_EditPlaylistDialog> createState() => _EditPlaylistDialogState();
}

class _EditPlaylistDialogState extends State<_EditPlaylistDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _controller.text.trim();
    if (name.isNotEmpty) {
      widget.onSave(name);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Playlist'),
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
          child: const Text('Save', style: TextStyle(color: AppColors.white)),
        ),
      ],
    );
  }
}
