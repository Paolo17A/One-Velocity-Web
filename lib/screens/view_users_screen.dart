import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/loading_provider.dart';
import '../utils/firebase_util.dart';
import '../utils/go_router_util.dart';
import '../utils/string_util.dart';
import '../widgets/app_bar_widget.dart';
import '../widgets/custom_button_widgets.dart';
import '../widgets/custom_miscellaneous_widgets.dart';
import '../widgets/custom_padding_widgets.dart';
import '../widgets/left_navigator_widget.dart';
import '../widgets/text_widgets.dart';

class ViewUsersScreen extends ConsumerStatefulWidget {
  const ViewUsersScreen({super.key});

  @override
  ConsumerState<ViewUsersScreen> createState() => _ViewUsersScreenState();
}

class _ViewUsersScreenState extends ConsumerState<ViewUsersScreen> {
  List<DocumentSnapshot> allUserDocs = [];
  List<DocumentSnapshot> currentDisplayedUsers = [];
  int currentPage = 0;
  int maxPage = 0;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      final goRouter = GoRouter.of(context);
      try {
        ref.read(loadingProvider.notifier).toggleLoading(true);
        if (!hasLoggedInUser()) {
          goRouter.goNamed(GoRoutes.login);
          return;
        }
        final userDoc = await getCurrentUserDoc();
        final userData = userDoc.data() as Map<dynamic, dynamic>;
        if (userData[UserFields.userType] == UserTypes.client) {
          goRouter.goNamed(GoRoutes.home);
          return;
        }
        allUserDocs = await getAllClientDocs();

        currentPage = 0;
        maxPage = (allUserDocs.length / 10).floor();
        if (allUserDocs.length % 10 == 0) maxPage--;
        setDisplayedUsers();
        ref.read(loadingProvider.notifier).toggleLoading(false);
      } catch (error) {
        scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('Error getting registered users: $error')));
        ref.read(loadingProvider.notifier).toggleLoading(false);
      }
    });
  }

  void setDisplayedUsers() {
    if (allUserDocs.length > 10) {
      currentDisplayedUsers = allUserDocs
          .getRange(currentPage * 10,
              min((currentPage * 10) + 10, allUserDocs.length))
          .toList();
    } else
      currentDisplayedUsers = allUserDocs;
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(loadingProvider);
    return Scaffold(
      appBar: appBarWidget(context, showActions: false),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          leftNavigator(context, path: GoRoutes.viewUsers),
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            child: switchedLoadingContainer(
                ref.read(loadingProvider),
                SingleChildScrollView(
                  child: horizontal5Percent(context,
                      child: viewContentContainer(context,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              blackSarabunBold('USERS', fontSize: 40),
                              _usersLabelRow(),
                              allUserDocs.isNotEmpty
                                  ? _userEntries()
                                  : viewContentUnavailable(context,
                                      text: 'NO AVAILABLE USERS'),
                              if (allUserDocs.length > 10)
                                pageNavigatorButtons(
                                    currentPage: currentPage,
                                    maxPage: maxPage,
                                    onPreviousPage: () {
                                      currentPage--;
                                      setState(() {
                                        setDisplayedUsers();
                                      });
                                    },
                                    onNextPage: () {
                                      currentPage++;
                                      setState(() {
                                        setDisplayedUsers();
                                      });
                                    })
                            ],
                          ))),
                )),
          )
        ],
      ),
    );
  }

  Widget _usersLabelRow() {
    return viewContentLabelRow(context, children: [
      viewFlexLabelTextCell('Name', 3,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(20))),
      viewFlexLabelTextCell('Actions', 2,
          borderRadius: BorderRadius.only(topRight: Radius.circular(20)))
    ]);
  }

  Widget _userEntries() {
    return Container(
        height: 500,
        decoration: BoxDecoration(border: Border.all()),
        child: ListView.builder(
            shrinkWrap: true,
            itemCount: currentDisplayedUsers.length,
            physics: NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              return _userEntry(currentDisplayedUsers[index], index);
            }));
  }

  Widget _userEntry(DocumentSnapshot userDoc, int index) {
    final userData = userDoc.data() as Map<dynamic, dynamic>;
    String formattedName =
        '${userData[UserFields.firstName]} ${userData[UserFields.lastName]}';
    Color entryColor = Colors.black;
    Color backgroundColor = Colors.white;
    return viewContentEntryRow(context, children: [
      viewFlexTextCell(formattedName,
          flex: 3, backgroundColor: backgroundColor, textColor: entryColor),
      viewFlexActionsCell([
        viewEntryButton(context,
            onPress: () => GoRouter.of(context).goNamed(GoRoutes.selectedUser,
                pathParameters: {'userID': userDoc.id}))
      ], flex: 2, backgroundColor: backgroundColor)
    ]);
  }
}
