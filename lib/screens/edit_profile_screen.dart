import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:one_velocity_web/widgets/text_widgets.dart';

import '../providers/loading_provider.dart';
import '../utils/firebase_util.dart';
import '../utils/go_router_util.dart';
import '../utils/string_util.dart';
import '../widgets/app_bar_widget.dart';
import '../widgets/custom_button_widgets.dart';
import '../widgets/custom_miscellaneous_widgets.dart';
import '../widgets/custom_padding_widgets.dart';
import '../widgets/custom_text_field_widget.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final mobileNumberController = TextEditingController();

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
          return;
        }
        final userDoc = await getCurrentUserDoc();
        final userData = userDoc.data() as Map<dynamic, dynamic>;
        if (userData[UserFields.userType] == UserTypes.admin) {
          goRouter.goNamed(GoRoutes.home);
          return;
        }
        firstNameController.text = userData[UserFields.firstName];
        lastNameController.text = userData[UserFields.lastName];
        mobileNumberController.text = userData[UserFields.mobileNumber];
        ref.read(loadingProvider.notifier).toggleLoading(false);
      } catch (error) {
        scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('Error getting user profile: $error')));
        ref.read(loadingProvider.notifier).toggleLoading(false);
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
    mobileNumberController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(loadingProvider);
    return Scaffold(
      appBar: appBarWidget(context),
      backgroundColor: Colors.white,
      body: stackedLoadingContainer(
          context,
          ref.read(loadingProvider),
          SingleChildScrollView(
            child: Column(
              children: [
                secondAppBar(context),
                horizontal5Percent(
                  context,
                  child: Column(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          vertical20Pix(
                            child: backButton(context,
                                onPress: () => GoRouter.of(context)
                                    .goNamed(GoRoutes.profile)),
                          ),
                          _editProfileHeader(),
                          _firstNameControllerWidget(),
                          _lasttNameControllerWidget(),
                          _mobileNumberControllerWidget()
                        ],
                      ),
                      submitButton(context,
                          label: 'SAVE CHANGES',
                          onPress: () => editClientProfile(context, ref,
                              firstNameController: firstNameController,
                              lastNameController: lastNameController,
                              mobileNumberController: mobileNumberController))
                    ],
                  ),
                ),
              ],
            ),
          )),
    );
  }

  Widget _editProfileHeader() {
    return montserratBlackBold('EDIT PROFILE', fontSize: 50);
  }

  Widget _firstNameControllerWidget() {
    return vertical20Pix(
        child: CustomTextField(
            text: 'First Name',
            controller: firstNameController,
            textInputType: TextInputType.name,
            displayPrefixIcon: const Icon(Icons.person)));
  }

  Widget _lasttNameControllerWidget() {
    return vertical20Pix(
        child: CustomTextField(
            text: 'Last Name',
            controller: lastNameController,
            textInputType: TextInputType.name,
            displayPrefixIcon: const Icon(Icons.person)));
  }

  Widget _mobileNumberControllerWidget() {
    return vertical20Pix(
        child: CustomTextField(
            text: 'Mobile Number',
            controller: mobileNumberController,
            textInputType: TextInputType.number,
            displayPrefixIcon: const Icon(Icons.phone)));
  }
}
