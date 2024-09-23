import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../providers/loading_provider.dart';
import '../utils/color_util.dart';
import '../utils/firebase_util.dart';
import '../utils/go_router_util.dart';
import '../utils/string_util.dart';
import '../widgets/app_bar_widget.dart';
import '../widgets/custom_button_widgets.dart';
import '../widgets/custom_miscellaneous_widgets.dart';
import '../widgets/custom_padding_widgets.dart';
import '../widgets/custom_text_field_widget.dart';
import '../widgets/text_widgets.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<RegisterScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final mobileNumberController = TextEditingController();

  @override
  void dispose() {
    super.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
    mobileNumberController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(loadingProvider);
    return Scaffold(
      appBar: appBarWidget(context, showActions: false),
      body: stackedLoadingContainer(
        context,
        ref.read(loadingProvider),
        Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          decoration: BoxDecoration(
              image: DecorationImage(
                  image: AssetImage(ImagePaths.background), fit: BoxFit.fill)),
          child: Stack(
            children: [
              Container(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height,
                  color: Colors.white.withOpacity(0.8)),
              SingleChildScrollView(
                child: Column(
                  children: [secondAppBar(context), _registerContainer()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _registerContainer() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: roundedNimbusContainer(context,
          child: Column(
            children: [
              vertical20Pix(child: blackSarabunBold('REGISTER', fontSize: 40)),
              Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CustomTextField(
                      text: 'Email Address',
                      controller: emailController,
                      textInputType: TextInputType.emailAddress,
                      displayPrefixIcon: const Icon(Icons.email))),
              Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CustomTextField(
                      text: 'Password',
                      controller: passwordController,
                      textInputType: TextInputType.visiblePassword,
                      displayPrefixIcon: const Icon(Icons.lock))),
              Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CustomTextField(
                      text: 'Confirm Password',
                      controller: confirmPasswordController,
                      textInputType: TextInputType.visiblePassword,
                      displayPrefixIcon: const Icon(Icons.lock))),
              const Gap(30),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: CustomTextField(
                    text: 'First Name',
                    controller: firstNameController,
                    textInputType: TextInputType.name,
                    displayPrefixIcon: const Icon(Icons.person)),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: CustomTextField(
                    text: 'Last Name',
                    controller: lastNameController,
                    textInputType: TextInputType.name,
                    displayPrefixIcon: const Icon(Icons.person)),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: CustomTextField(
                    text: 'Mobile Number',
                    controller: mobileNumberController,
                    textInputType: TextInputType.number,
                    displayPrefixIcon: const Icon(Icons.phone)),
              ),
              submitButton(context,
                  label: 'REGISTER',
                  onPress: () => registerNewUser(context, ref,
                      emailController: emailController,
                      passwordController: passwordController,
                      confirmPasswordController: confirmPasswordController,
                      firstNameController: firstNameController,
                      lastNameController: lastNameController,
                      mobileNumberController: mobileNumberController)),
              const Divider(color: CustomColors.ultimateGray),
              TextButton(
                  onPressed: () =>
                      GoRouter.of(context).goNamed(GoRoutes.forgotPassword),
                  child: const Text(
                    'Forgot Password?',
                    style: TextStyle(
                        decoration: TextDecoration.underline,
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  )),
              TextButton(
                  onPressed: () => GoRouter.of(context).goNamed(GoRoutes.login),
                  child: const Text(
                    'Already have an account?',
                    style: TextStyle(
                        decoration: TextDecoration.underline,
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ))
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
