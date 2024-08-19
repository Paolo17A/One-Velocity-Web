import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:one_velocity_web/providers/faq_provider.dart';
import '../providers/loading_provider.dart';
import '../utils/delete_entry_dialog_util.dart';
import '../utils/firebase_util.dart';
import '../utils/go_router_util.dart';
import '../utils/string_util.dart';
import '../widgets/app_bar_widget.dart';
import '../widgets/custom_button_widgets.dart';
import '../widgets/custom_miscellaneous_widgets.dart';
import '../widgets/custom_padding_widgets.dart';
import '../widgets/left_navigator_widget.dart';
import '../widgets/text_widgets.dart';

class ViewFAQsScreen extends ConsumerStatefulWidget {
  const ViewFAQsScreen({super.key});

  @override
  ConsumerState<ViewFAQsScreen> createState() => _ViewFAQsScreenState();
}

class _ViewFAQsScreenState extends ConsumerState<ViewFAQsScreen> {
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
        ref.read(faqsProvider).setFAQDocs(await getAllFAQs());
        ref.read(loadingProvider.notifier).toggleLoading(false);
      } catch (error) {
        scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('Error getting FAQs: $error')));
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          leftNavigator(context, path: GoRoutes.viewFAQs),
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            child: switchedLoadingContainer(
              ref.read(loadingProvider),
              SingleChildScrollView(
                child: horizontal5Percent(context,
                    child: Column(
                      children: [_addFAQButton(), _faqContainer()],
                    )),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _addFAQButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
        ElevatedButton(
            onPressed: () => GoRouter.of(context).goNamed(GoRoutes.addFAQ),
            child: whiteSarabunBold('ADD FAQ'))
      ]),
    );
  }

  Widget _faqContainer() {
    return viewContentContainer(
      context,
      child: Column(
        children: [
          _faqLabelRow(),
          ref.read(faqsProvider).faqDocs.isNotEmpty
              ? _faqEntries()
              : viewContentUnavailable(context, text: 'NO AVAILABLE FAQs'),
        ],
      ),
    );
  }

  Widget _faqLabelRow() {
    return viewContentLabelRow(context, children: [
      viewFlexLabelTextCell('Category', 2,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(20))),
      viewFlexLabelTextCell('Question', 3),
      viewFlexLabelTextCell('Answer', 3),
      viewFlexLabelTextCell('Actions', 2,
          borderRadius: BorderRadius.only(topRight: Radius.circular(20)))
    ]);
  }

  Widget _faqEntries() {
    return SizedBox(
        height: MediaQuery.of(context).size.height * 0.65,
        child: ListView.builder(
            shrinkWrap: true,
            itemCount: ref.read(faqsProvider).faqDocs.length,
            itemBuilder: (context, index) {
              return _faqEntry(ref.read(faqsProvider).faqDocs[index], index);
            }));
  }

  Widget _faqEntry(DocumentSnapshot faqDoc, int index) {
    final faqData = faqDoc.data() as Map<dynamic, dynamic>;
    String category = faqData[FAQFields.category];
    String question = faqData[FAQFields.question];
    String answer = faqData[FAQFields.answer];
    Color entryColor = Colors.black;
    Color backgroundColor = Colors.white;
    return viewContentEntryRow(context, children: [
      viewFlexTextCell(category,
          flex: 2, backgroundColor: backgroundColor, textColor: entryColor),
      viewFlexTextCell(question,
          flex: 3, backgroundColor: backgroundColor, textColor: entryColor),
      viewFlexTextCell(answer,
          flex: 3, backgroundColor: backgroundColor, textColor: entryColor),
      viewFlexActionsCell([
        editEntryButton(context,
            onPress: () => GoRouter.of(context).goNamed(GoRoutes.editFAQ,
                pathParameters: {'faqID': faqDoc.id})),
        deleteEntryButton(context,
            onPress: () => displayDeleteEntryDialog(context,
                message: 'Are you sure you wish to remove this FAQ?',
                deleteEntry: () =>
                    deleteFAQEntry(context, ref, faqID: faqDoc.id)))
      ], flex: 2, backgroundColor: backgroundColor)
    ]);
  }
}
