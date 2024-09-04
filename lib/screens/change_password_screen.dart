import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:one_velocity_web/providers/loading_provider.dart';
import 'package:one_velocity_web/widgets/custom_miscellaneous_widgets.dart';
import 'package:one_velocity_web/widgets/custom_padding_widgets.dart';
import 'package:one_velocity_web/widgets/custom_text_field_widget.dart';
import 'package:one_velocity_web/widgets/text_widgets.dart';

import '../utils/firebase_util.dart';
import '../utils/go_router_util.dart';
import '../utils/string_util.dart';
import '../widgets/app_bar_widget.dart';
import '../widgets/left_navigator_widget.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final currentPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmNewPasswordController = TextEditingController();
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
        ref.read(loadingProvider.notifier).toggleLoading(false);
      } catch (error) {
        ref.read(loadingProvider.notifier).toggleLoading(false);
        scaffoldMessenger.showSnackBar(SnackBar(
            content:
                Text('Error initializing change password screen: $error')));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(loadingProvider);
    return Scaffold(
      appBar: appBarWidget(context),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            secondAppBar(context),
            stackedLoadingContainer(
              context,
              ref.read(loadingProvider),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  clientProfileNavigator(context,
                      path: GoRoutes.changePassword),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.8,
                    child: horizontal5Percent(context,
                        child: Column(
                          children: [
                            vertical10Pix(
                                child: blackSarabunBold('CHANGE PASSWORD',
                                    fontSize: 52)),
                            _passwordTextFields(),
                            vertical20Pix(
                                child: ElevatedButton(
                                    onPressed: () => updatePassword(
                                        context, ref,
                                        currentPasswordController:
                                            currentPasswordController,
                                        newPasswordController:
                                            newPasswordController,
                                        confirmNewPasswordController:
                                            confirmNewPasswordController),
                                    child: whiteSarabunBold('UPDATE PASSWORD')))
                          ],
                        )),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _passwordTextFields() {
    return roundedNimbusContainer(context,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          CustomTextField(
              text: 'Current Password',
              controller: currentPasswordController,
              textInputType: TextInputType.visiblePassword,
              displayPrefixIcon: Icon(Icons.lock)),
          vertical10Pix(
              child: CustomTextField(
                  text: 'New Password',
                  controller: newPasswordController,
                  textInputType: TextInputType.visiblePassword,
                  displayPrefixIcon: Icon(Icons.lock))),
          CustomTextField(
              text: 'Confirm New Password',
              controller: confirmNewPasswordController,
              textInputType: TextInputType.visiblePassword,
              displayPrefixIcon: Icon(Icons.lock)),
        ]));
  }
}
