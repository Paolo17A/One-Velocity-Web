import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:one_velocity_web/utils/firebase_util.dart';

import '../providers/loading_provider.dart';
import '../utils/color_util.dart';
import '../utils/go_router_util.dart';
import '../widgets/app_bar_widget.dart';
import '../widgets/custom_button_widgets.dart';
import '../widgets/custom_miscellaneous_widgets.dart';
import '../widgets/custom_padding_widgets.dart';
import '../widgets/custom_text_field_widget.dart';
import '../widgets/text_widgets.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void dispose() {
    super.dispose();
    emailController.dispose();
    passwordController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(loadingProvider);
    return Scaffold(
      appBar: appBarWidget(context, showActions: false),
      body: stackedLoadingContainer(
          context,
          ref.read(loadingProvider),
          Column(
            children: [secondAppBar(context), _logInContainer()],
          )),
    );
  }

  Widget _logInContainer() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: roundedNimbusContainer(context,
          child: Column(
            children: [
              vertical20Pix(child: blackSarabunBold('LOG-IN', fontSize: 40)),
              CustomTextField(
                  text: 'Email Address',
                  controller: emailController,
                  textInputType: TextInputType.emailAddress,
                  displayPrefixIcon: const Icon(Icons.email)),
              const Gap(16),
              CustomTextField(
                text: 'Password',
                controller: passwordController,
                textInputType: TextInputType.visiblePassword,
                displayPrefixIcon: const Icon(Icons.lock),
                onSearchPress: () => logInUser(context, ref,
                    emailController: emailController,
                    passwordController: passwordController),
              ),
              submitButton(context,
                  label: 'LOG-IN',
                  onPress: () => logInUser(context, ref,
                      emailController: emailController,
                      passwordController: passwordController)),
              const Divider(color: CustomColors.ultimateGray),
              TextButton(
                  onPressed: () =>
                      GoRouter.of(context).goNamed(GoRoutes.forgotPassword),
                  child: blackSarabunBold('Forgot Password?',
                      fontSize: 16, decoration: TextDecoration.underline)),
              TextButton(
                  onPressed: () =>
                      GoRouter.of(context).goNamed(GoRoutes.register),
                  child: blackSarabunBold('Don\'t have an account?',
                      fontSize: 16, decoration: TextDecoration.underline))
            ],
          )),
    );
  }

  Widget roundedNimbusContainer(BuildContext context, {required Widget child}) {
    return Container(
        width: MediaQuery.of(context).size.width * 0.5,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: CustomColors.nimbusCloud),
        padding: const EdgeInsets.all(20),
        child: child);
  }
}
