import 'package:flutter/material.dart';

import '../utils/color_util.dart';
import '../utils/firebase_util.dart';

class NewMessage extends StatefulWidget {
  final String otherName;
  final String senderUID;
  final String otherUID;
  final bool isClient;
  const NewMessage(
      {super.key,
      required this.otherName,
      required this.senderUID,
      required this.otherUID,
      required this.isClient});

  @override
  State<NewMessage> createState() => _NewMessageState();
}

class _NewMessageState extends State<NewMessage> {
  final _messageController = TextEditingController();

  @override
  void dispose() {
    super.dispose();
    _messageController.dispose();
  }

  void _submitMessage() async {
    final enteredMessage = _messageController.text;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    if (enteredMessage.trim().isEmpty) {
      return;
    }
    FocusScope.of(context).unfocus();
    _messageController.clear();

    try {
      await submitMessage(
          message: enteredMessage,
          isClient: widget.isClient,
          senderUID: widget.senderUID,
          otherUID: widget.otherUID);
    } catch (error) {
      scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Error Sending Message: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 15, bottom: 1, right: 14),
      child: Row(children: [
        Expanded(
            child: TextField(
          controller: _messageController,
          textCapitalization: TextCapitalization.sentences,
          autocorrect: true,
          enableSuggestions: true,
          decoration: const InputDecoration(labelText: 'Send a message...'),
          onSubmitted: (value) => _submitMessage(),
        )),
        IconButton(
            color: Theme.of(context).colorScheme.primary,
            onPressed: _submitMessage,
            icon: const Icon(Icons.send, color: CustomColors.grenadine))
      ]),
    );
  }
}
