import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:one_velocity_web/providers/loading_provider.dart';
import 'package:one_velocity_web/utils/firebase_util.dart';
import 'package:one_velocity_web/widgets/app_bar_widget.dart';
import 'package:one_velocity_web/widgets/custom_miscellaneous_widgets.dart';
import 'package:one_velocity_web/widgets/custom_padding_widgets.dart';
import 'package:one_velocity_web/widgets/text_widgets.dart';

import '../widgets/custom_button_widgets.dart';
import '../widgets/custom_text_field_widget.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final emailController = TextEditingController();

  @override
  void dispose() {
    super.dispose();
    emailController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBarWidget(context),
      body: stackedLoadingContainer(
          context,
          ref.read(loadingProvider),
          SingleChildScrollView(
            child: Column(
                children: [secondAppBar(context), forgotPasswordContainer()]),
          )),
    );
  }

  Widget forgotPasswordContainer() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 40),
      child: roundedWhiteContainer(context,
          child: Column(
            children: [
              vertical20Pix(
                  child: montserratBlackBold('RESET PASSWORD', fontSize: 40)),
              Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CustomTextField(
                      text: 'Email Address',
                      controller: emailController,
                      textInputType: TextInputType.emailAddress,
                      displayPrefixIcon: const Icon(Icons.email))),
              submitButton(context,
                  label: 'SEND RESET\nPASSWORD EMAIL',
                  onPress: () => sendResetPasswordEmail(context, ref,
                      emailController: emailController)),
            ],
          )),
    );
  }

  Widget roundedWhiteContainer(BuildContext context, {required Widget child}) {
    return Container(
        width: MediaQuery.of(context).size.width * 0.5,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20), color: Colors.white),
        padding: const EdgeInsets.all(20),
        child: child);
  }
}
