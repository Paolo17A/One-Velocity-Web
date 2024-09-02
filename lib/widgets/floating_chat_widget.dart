import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:one_velocity_web/widgets/text_widgets.dart';

import '../providers/display_chat_provider.dart';
import '../utils/color_util.dart';
import '../utils/firebase_util.dart';
import 'chat_messages.dart';
import 'new_message_widget.dart';

class FloatingChatWidget extends ConsumerWidget {
  final String senderUID;
  final String otherUID;
  const FloatingChatWidget(
      {super.key, required this.senderUID, required this.otherUID});

  @override
  Widget build(BuildContext context, ref) {
    ref.watch(displayChatProvider);
    return hasLoggedInUser()
        ? ref.read(displayChatProvider)
            ? Container(
                width: MediaQuery.of(context).size.width * 0.25,
                height: 400,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.white,
                    border: Border.all(color: Colors.black)),
                padding: const EdgeInsets.all(10),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SizedBox(
                            width: MediaQuery.of(context).size.width * 0.2,
                            child: blackSarabunRegular('CHAT WITH ADMIN',
                                textOverflow: TextOverflow.ellipsis)),
                        TextButton(
                            onPressed: () => ref
                                .read(displayChatProvider.notifier)
                                .toggleDisplayChat(),
                            child: blackSarabunRegular('X'))
                      ],
                    ),
                    Column(
                      children: [
                        SizedBox(
                            height: 275,
                            child: ChatMessages(
                                senderUID:
                                    FirebaseAuth.instance.currentUser!.uid,
                                otherUID: otherUID)),
                        NewMessage(
                            otherName: 'ADMIN',
                            senderUID: senderUID,
                            otherUID: otherUID,
                            isClient: true)
                      ],
                    ),
                  ],
                ),
              )
            : ElevatedButton(
                onPressed: () =>
                    ref.read(displayChatProvider.notifier).toggleDisplayChat(),
                style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromRadius(30),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                      bottomLeft: Radius.circular(20),
                    )),
                    backgroundColor: CustomColors.grenadine),
                child: const Icon(
                  Icons.message_outlined,
                  color: Colors.black,
                  size: 25,
                ))
        : Container();
  }
}
