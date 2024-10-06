import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:one_velocity_web/providers/loading_provider.dart';
import 'package:one_velocity_web/widgets/custom_padding_widgets.dart';
import 'package:one_velocity_web/widgets/left_navigator_widget.dart';
import 'package:one_velocity_web/widgets/text_widgets.dart';

import '../utils/color_util.dart';
import '../utils/firebase_util.dart';
import '../utils/go_router_util.dart';
import '../utils/string_util.dart';
import '../widgets/app_bar_widget.dart';
import '../widgets/chat_messages.dart';
import '../widgets/new_message_widget.dart';

class ViewMessagesScreen extends ConsumerStatefulWidget {
  const ViewMessagesScreen({super.key});

  @override
  ConsumerState<ViewMessagesScreen> createState() => _ViewMessagesScreenState();
}

class _ViewMessagesScreenState extends ConsumerState<ViewMessagesScreen> {
  String selectedMessageThreadID = '';
  String selectedClientID = '';
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      final goRouter = GoRouter.of(context);
      try {
        ref.read(loadingProvider.notifier).toggleLoading(true);
        if (!hasLoggedInUser()) {
          ref.read(loadingProvider.notifier).toggleLoading(false);
          goRouter.goNamed(GoRoutes.login);
          return;
        }
        final userDoc = await getCurrentUserDoc();
        final userData = userDoc.data() as Map<dynamic, dynamic>;
        if (userData[UserFields.userType] == UserTypes.client) {
          ref.read(loadingProvider.notifier).toggleLoading(false);
          goRouter.goNamed(GoRoutes.home);
          return;
        }
        ref.read(loadingProvider.notifier).toggleLoading(false);
      } catch (error) {
        ref.read(loadingProvider.notifier).toggleLoading(false);
        scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('Error initializing messages screen')));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: appBarWidget(context, showActions: false),
        body: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          leftNavigator(context, path: GoRoutes.messages),
          SizedBox(
              width: MediaQuery.of(context).size.width * 0.8,
              child: all5Percent(context,
                  child: Container(
                    decoration: BoxDecoration(border: Border.all()),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        messageThreadsContainerStreamWidget(),
                        if (selectedClientID.isNotEmpty)
                          selectedMessageThreadContainer()
                      ],
                    ),
                  )))
        ]));
  }

  Widget messageThreadsContainerStreamWidget() {
    return Container(
      width: MediaQuery.of(context).size.width * 0.15,
      decoration: BoxDecoration(border: Border.all()),

      //height: MediaQuery.of(context).size.height * 0.75,
      child: StreamBuilder(
          stream: FirebaseFirestore.instance
              .collection(Collections.messages)
              .snapshots(includeMetadataChanges: true),
          builder: (context, snapshots) {
            if (snapshots.connectionState == ConnectionState.waiting) {
              return Center(child: const CircularProgressIndicator());
            }
            if (!snapshots.hasData || snapshots.data!.docs.isEmpty) {
              return const Center(child: Text('No message threads found'));
            }
            if (snapshots.hasError) {
              return const Center(child: Text('Something went wrong...'));
            }
            final messageThreadDocs = snapshots.data!.docs.where((messageDoc) {
              final messageData = messageDoc.data();
              return messageData.containsKey(MessageFields.lastMessageSent);
            }).toList();
            messageThreadDocs.sort((a, b) {
              DateTime aTime =
                  (a[MessageFields.lastMessageSent] as Timestamp).toDate();
              DateTime bTime =
                  (b[MessageFields.lastMessageSent] as Timestamp).toDate();
              return bTime.compareTo(aTime);
            });
            return Column(
                children: messageThreadDocs
                    .map((messageDoc) => messageThreadEntry(messageDoc))
                    .toList());
          }),
    );
  }

  Widget messageThreadEntry(DocumentSnapshot messageDoc) {
    final messageData = messageDoc.data() as Map<dynamic, dynamic>;
    String clientUID = messageData[MessageFields.clientID];
    String adminUID = messageData[MessageFields.adminID];
    if (clientUID == adminUID) {
      FirebaseFirestore.instance
          .collection(Collections.messages)
          .doc(messageDoc.id)
          .delete();
      return Container();
    }
    return StreamBuilder(
        stream: messageDoc.reference
            .collection(MessageFields.messageThread)
            .orderBy(MessageFields.dateTimeSent, descending: true)
            .snapshots(),
        builder: (context, snapshots) {
          if (!snapshots.hasData ||
              snapshots.data!.docs.isEmpty ||
              snapshots.hasError) {
            return Container();
          }

          final latestMessageData = snapshots.data!.docs.first.data();
          DateTime dateTimeSent =
              (latestMessageData[MessageFields.dateTimeSent] as Timestamp)
                  .toDate();
          String messageContent = latestMessageData['messageContent'];
          return InkWell(
            onTap: () {
              if (selectedMessageThreadID == messageDoc.id) return;
              setAdminMessagesAsRead(messageThreadID: messageDoc.id);
              setState(() {
                selectedMessageThreadID = messageDoc.id;
                selectedClientID = clientUID;
              });
            },
            child: Container(
                width: MediaQuery.of(context).size.width * 0.15,
                decoration: BoxDecoration(
                    color: messageDoc.id == selectedMessageThreadID
                        ? CustomColors.nimbusCloud.withOpacity(0.2)
                        : Colors.transparent,
                    border: Border.all(color: CustomColors.nimbusCloud)),
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    //montserratText(messageDoc.id),
                    blackSarabunRegular(
                        DateFormat('MMM dd, yyyy hh:mm a').format(dateTimeSent),
                        fontSize: 14),
                    FutureBuilder(
                        future: getThisUserDoc(clientUID),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData ||
                              snapshot.connectionState ==
                                  ConnectionState.waiting ||
                              snapshot.hasError) {
                            return blackSarabunRegular('-');
                          }
                          final userData = snapshot.data!;
                          String formattedName =
                              '${userData[UserFields.firstName]} ${userData[UserFields.lastName]}';
                          return blackSarabunRegular(formattedName,
                              fontSize: 14);
                        }),
                    blackSarabunRegular(messageContent,
                        textOverflow: TextOverflow.ellipsis, fontSize: 12)
                  ],
                )),
          );
        });
  }

  Widget selectedMessageThreadContainer() {
    return SizedBox(
      width: (MediaQuery.of(context).size.width * 0.55) - 2,
      //height: MediaQuery.of(context).size.height * 0.75,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(
              height: MediaQuery.of(context).size.height * 0.65,
              child:
                  ChatMessages(senderUID: adminID, otherUID: selectedClientID)),
          Container(
            decoration: BoxDecoration(border: Border.all()),
            child: NewMessage(
                otherName: '',
                senderUID: adminID,
                otherUID: selectedClientID,
                isClient: false),
          )
        ],
      ),
    );
  }
}
