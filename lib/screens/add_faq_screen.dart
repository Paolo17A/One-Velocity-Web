import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/loading_provider.dart';
import '../utils/firebase_util.dart';
import '../utils/go_router_util.dart';
import '../utils/string_util.dart';
import '../widgets/app_bar_widget.dart';
import '../widgets/custom_miscellaneous_widgets.dart';
import '../widgets/custom_padding_widgets.dart';
import '../widgets/custom_text_field_widget.dart';
import '../widgets/dropdown_widget.dart';
import '../widgets/left_navigator_widget.dart';
import '../widgets/text_widgets.dart';

class AddFAQScreen extends ConsumerStatefulWidget {
  const AddFAQScreen({super.key});

  @override
  ConsumerState<AddFAQScreen> createState() => _AddFAQScreenState();
}

class _AddFAQScreenState extends ConsumerState<AddFAQScreen> {
  String selectedCategory = '';
  final questionController = TextEditingController();
  final answerController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
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
        ref.read(loadingProvider.notifier).toggleLoading(false);
      } catch (error) {
        ref.read(loadingProvider.notifier).toggleLoading(false);
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    questionController.dispose();
    answerController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBarWidget(context, showActions: false),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          leftNavigator(context, path: GoRoutes.viewFAQs),
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            child: switchedLoadingContainer(
              ref.read(loadingProvider),
              SingleChildScrollView(
                child: horizontal5Percent(context,
                    child: Column(children: [
                      _backButton(),
                      _newFAQHeaderWidget(),
                      _faqCategoryWidget(),
                      _questionWidget(),
                      _answerWidget(),
                      _submitButtonWidget()
                    ])),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _backButton() {
    return vertical20Pix(
      child: Row(children: [
        ElevatedButton(
            onPressed: () => GoRouter.of(context).goNamed(GoRoutes.viewFAQs),
            child: whiteSarabunBold('BACK'))
      ]),
    );
  }

  Widget _newFAQHeaderWidget() {
    return blackSarabunBold(
      'NEW FAQ',
      textAlign: TextAlign.center,
      fontSize: 38,
    );
  }

  Widget _faqCategoryWidget() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      vertical10Pix(child: blackSarabunBold('Product Category', fontSize: 24)),
      Container(
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(5)),
        child: dropdownWidget(selectedCategory, (newVal) {
          setState(() {
            selectedCategory = newVal!;
          });
        }, [
          FAQCategories.location,
          FAQCategories.paymentMethod,
          FAQCategories.products,
          FAQCategories.services
        ], selectedCategory.isNotEmpty ? selectedCategory : 'Select a category',
            false),
      )
    ]);
  }

  Widget _questionWidget() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      vertical10Pix(child: blackSarabunBold('Question', fontSize: 24)),
      CustomTextField(
          text: 'Question',
          controller: questionController,
          textInputType: TextInputType.multiline,
          displayPrefixIcon: null),
      const SizedBox(height: 20)
    ]);
  }

  Widget _answerWidget() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      vertical10Pix(child: blackSarabunBold('Answer', fontSize: 24)),
      CustomTextField(
          text: 'Answer',
          controller: answerController,
          textInputType: TextInputType.multiline,
          displayPrefixIcon: null),
    ]);
  }

  Widget _submitButtonWidget() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 50),
      child: ElevatedButton(
        onPressed: () => addFAQEntry(context, ref,
            selectedCategory: selectedCategory,
            questionController: questionController,
            answerController: answerController),
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: whiteSarabunBold('SUBMIT'),
        ),
      ),
    );
  }
}
