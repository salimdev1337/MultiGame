import 'package:flutter/material.dart';

/// Dialog to prompt user for nickname
class NicknameDialog extends StatefulWidget {
  final String? currentNickname;

  const NicknameDialog({super.key, this.currentNickname});

  @override
  State<NicknameDialog> createState() => _NicknameDialogState();
}

class _NicknameDialogState extends State<NicknameDialog> {
  late TextEditingController _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentNickname);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final nickname = _controller.text.trim();

    if (nickname.isEmpty) {
      setState(() => _error = 'Please enter a nickname');
      return;
    }

    if (nickname.length < 2) {
      setState(() => _error = 'Nickname must be at least 2 characters');
      return;
    }

    if (nickname.length > 20) {
      setState(() => _error = 'Nickname must be less than 20 characters');
      return;
    }

    Navigator.of(context).pop(nickname);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF21242b),
      title: Row(
        children: [
          Icon(Icons.person, color: Theme.of(context).primaryColor),
          const SizedBox(width: 12),
          const Text('Choose Your Nickname'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'This nickname will appear on the leaderboard with your scores.',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _controller,
            autofocus: true,
            maxLength: 20,
            decoration: InputDecoration(
              labelText: 'Nickname',
              hintText: 'Enter your nickname',
              errorText: _error,
              prefixIcon: const Icon(Icons.badge),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: Theme.of(context).primaryColor,
                  width: 2,
                ),
              ),
            ),
            onSubmitted: (_) => _submit(),
            onChanged: (value) {
              if (_error != null) {
                setState(() => _error = null);
              }
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.black,
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

/// Show nickname dialog
Future<String?> showNicknameDialog(
  BuildContext context, {
  String? currentNickname,
}) {
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (context) => NicknameDialog(currentNickname: currentNickname),
  );
}
