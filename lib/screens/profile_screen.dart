import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker_web/image_picker_web.dart';
import 'package:one_velocity_web/providers/profile_image_url_provider.dart';
import 'package:one_velocity_web/widgets/left_navigator_widget.dart';

import '../providers/loading_provider.dart';
import '../utils/color_util.dart';
import '../utils/firebase_util.dart';
import '../utils/go_router_util.dart';
import '../utils/string_util.dart';
import '../widgets/app_bar_widget.dart';
import '../widgets/custom_miscellaneous_widgets.dart';
import '../widgets/custom_padding_widgets.dart';
import '../widgets/floating_chat_widget.dart';
import '../widgets/text_widgets.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  String formattedName = '';
  String profileImageURL = '';
  String mobileNumber = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      final goRouter = GoRouter.of(context);
      try {
        ref.read(loadingProvider.notifier).toggleLoading(true);
        if (!hasLoggedInUser()) {
          goRouter.goNamed(GoRoutes.login);
          ref.read(loadingProvider.notifier).toggleLoading(false);

          return;
        }
        final userDoc = await getCurrentUserDoc();
        final userData = userDoc.data() as Map<dynamic, dynamic>;
        if (userData[UserFields.userType] == UserTypes.admin) {
          goRouter.goNamed(GoRoutes.home);
          ref.read(loadingProvider.notifier).toggleLoading(false);
          return;
        }
        formattedName =
            '${userData[UserFields.firstName]} ${userData[UserFields.lastName]}';
        ref
            .read(profileImageURLProvider.notifier)
            .setImageURL(userData[UserFields.profileImageURL]);
        mobileNumber = userData[UserFields.mobileNumber];
        ref.read(loadingProvider.notifier).toggleLoading(false);
      } catch (error) {
        scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('Error getting user profile: $error')));
        ref.read(loadingProvider.notifier).toggleLoading(false);
      }
    });
  }

  Future _pickImage() async {
    final pickedFile = await ImagePickerWeb.getImageAsBytes();
    if (pickedFile == null) {
      return;
    }
    addProfilePic(context, ref, selectedImage: pickedFile);
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(loadingProvider);
    profileImageURL = ref.watch(profileImageURLProvider).profileImageURL;
    return Scaffold(
      appBar: appBarWidget(context),
      floatingActionButton: FloatingChatWidget(
          senderUID: FirebaseAuth.instance.currentUser!.uid, otherUID: adminID),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            secondAppBar(context),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                clientProfileNavigator(context, path: GoRoutes.profile),
                Container(
                  width: MediaQuery.of(context).size.width * 0.8,
                  child: switchedLoadingContainer(
                    ref.read(loadingProvider),
                    profileDetailsContainer(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget profileDetailsContainer() {
    return horizontal5Percent(
      context,
      child: Column(
        children: [
          Gap(40),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      buildProfileImage(profileImageURL: profileImageURL),
                      Column(
                        children: [
                          if (profileImageURL.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.all(10),
                              child: ElevatedButton(
                                  onPressed: () =>
                                      removeProfilePic(context, ref),
                                  child: whiteSarabunRegular('REMOVE PICTURE')),
                            )
                          else
                            Padding(
                              padding: const EdgeInsets.all(10),
                              child: ElevatedButton(
                                  onPressed: () => _pickImage(),
                                  child: whiteSarabunRegular('UPLOAD PICTURE')),
                            ),
                        ],
                      ),
                    ],
                  ),
                  blackSarabunBold(formattedName, fontSize: 40),
                  blackSarabunRegular('Mobile Number: $mobileNumber')
                ],
              ),
              ElevatedButton(
                  onPressed: () =>
                      GoRouter.of(context).goNamed(GoRoutes.editProfile),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: CustomColors.nimbusCloud),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      children: [
                        Icon(Icons.edit, color: Colors.black),
                        Gap(4),
                        blackSarabunRegular('Edit Profile', fontSize: 24),
                      ],
                    ),
                  ))
            ],
          ),
          const Divider(color: CustomColors.blackBeauty)
        ],
      ),
    );
  }
}
