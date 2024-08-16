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

class SelectedUserScreen extends ConsumerStatefulWidget {
  final String userID;
  const SelectedUserScreen({super.key, required this.userID});

  @override
  ConsumerState<SelectedUserScreen> createState() => _SelectedUserScreenState();
}

class _SelectedUserScreenState extends ConsumerState<SelectedUserScreen> {
  String formattedName = '';
  String profileImageURL = '';
  String mobileNumber = '';

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
        DocumentSnapshot selectedUser = await getThisUserDoc(widget.userID);
        final selectedUserData = selectedUser.data() as Map<dynamic, dynamic>;
        formattedName =
            '${selectedUserData[UserFields.firstName]} ${selectedUserData[UserFields.lastName]}';
        profileImageURL = selectedUserData[UserFields.profileImageURL];
        mobileNumber = selectedUserData[UserFields.mobileNumber];
        ref.read(loadingProvider.notifier).toggleLoading(false);
        setState(() {});
      } catch (error) {
        scaffoldMessenger.showSnackBar(SnackBar(
            content: Text('Error getting selected user data: $error')));
        ref.read(loadingProvider.notifier).toggleLoading(false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(loadingProvider);
    return Scaffold(
      appBar: appBarWidget(context, showActions: false),
      body: Row(
        children: [
          leftNavigator(context, path: GoRoutes.viewUsers),
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            child: switchedLoadingContainer(
                ref.read(loadingProvider),
                horizontal5Percent(
                  context,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      vertical20Pix(
                        child: backButton(context,
                            onPress: () => GoRouter.of(context)
                                .goNamed(GoRoutes.viewUsers)),
                      ),
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20)),
                        padding: EdgeInsets.all(20),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              buildProfileImage(
                                  profileImageURL: profileImageURL),
                              blackSarabunBold(formattedName, fontSize: 40),
                              Text('Mobile Number: $mobileNumber',
                                  style: const TextStyle(
                                      color: Colors.black, fontSize: 20))
                            ]),
                      )
                    ],
                  ),
                )),
          )
        ],
      ),
    );
  }
}
