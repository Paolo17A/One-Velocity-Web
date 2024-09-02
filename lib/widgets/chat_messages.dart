import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:one_velocity_web/utils/string_util.dart';
import 'package:one_velocity_web/widgets/text_widgets.dart';

import '../utils/firebase_util.dart';
import 'message_bubble_widget.dart';

class ChatMessages extends StatefulWidget {
  final String senderUID;
  final String otherUID;
  const ChatMessages(
      {super.key, required this.senderUID, required this.otherUID});

  @override
  State<ChatMessages> createState() => _ChatMessagesState();
}

class _ChatMessagesState extends State<ChatMessages> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: getChatDocumentId(widget.senderUID, widget.otherUID),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: const CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.hasError) {
            return blackSarabunRegular('Error getting messages');
          }
          return StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection(Collections.messages)
                  .doc(snapshot.data!)
                  .collection(MessageFields.messageThread)
                  .orderBy(MessageFields.dateTimeSent, descending: true)
                  .snapshots(),
              builder: (ctx, chatSnapshots) {
                if (!chatSnapshots.hasData ||
                    chatSnapshots.data!.docs.isEmpty) {
                  return const Center(child: Text('No messages found'));
                }
                if (chatSnapshots.hasError) {
                  return const Center(child: Text('Something went wrong...'));
                }

                final loadedMessages = chatSnapshots.data!.docs;
                return ListView.builder(
                    padding:
                        const EdgeInsets.only(bottom: 40, left: 13, right: 13),
                    reverse: true,
                    //dragStartBehavior: DragStartBehavior.start,
                    itemCount: loadedMessages.length,
                    itemBuilder: (ctx, index) {
                      final chatMessage = loadedMessages[index].data();
                      final nextChatMessage = index + 1 < loadedMessages.length
                          ? loadedMessages[index + 1].data()
                          : null;
                      final currentMessageUserID =
                          chatMessage[MessageFields.sender];
                      final nextMessageUserID = nextChatMessage != null
                          ? nextChatMessage[MessageFields.sender]
                          : null;
                      final nextUserIsSame =
                          nextMessageUserID == currentMessageUserID;
                      if (nextUserIsSame) {
                        return MessageBubble.next(
                            message: chatMessage[MessageFields.messageContent],
                            isMe: widget.senderUID == currentMessageUserID);
                      } else {
                        return MessageBubble.first(
                            message: chatMessage[MessageFields.messageContent],
                            isMe: widget.senderUID == currentMessageUserID);
                      }
                    });
              });
        });
  }
}
