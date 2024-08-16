import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:one_velocity_web/utils/string_util.dart';
import 'package:one_velocity_web/widgets/text_widgets.dart';

import '../providers/loading_provider.dart';
import '../utils/color_util.dart';
import '../utils/firebase_util.dart';
import '../widgets/app_bar_widget.dart';
import '../widgets/custom_miscellaneous_widgets.dart';
import '../widgets/custom_padding_widgets.dart';

class HelpCenterScreen extends ConsumerStatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  ConsumerState<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends ConsumerState<HelpCenterScreen> {
  List<DocumentSnapshot> allFAQs = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      ref.read(loadingProvider.notifier).toggleLoading(true);
      allFAQs = await getAllFAQs();
      ref.read(loadingProvider.notifier).toggleLoading(false);
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(loadingProvider);
    return Scaffold(
      appBar: appBarWidget(context),
      body: switchedLoadingContainer(
        ref.read(loadingProvider),
        SingleChildScrollView(
            child: Column(
          children: [
            secondAppBar(context),
            horizontal5Percent(context,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [_faqHeader(), _faqEntries()],
                )),
          ],
        )),
      ),
    );
  }

  Widget _faqHeader() {
    return blackSarabunBold('FREQUENTLY ASKED QUESTIONS', fontSize: 40);
  }

  Widget _faqEntries() {
    return allFAQs.isNotEmpty
        ? SizedBox(
            height: MediaQuery.of(context).size.height * 0.9,
            child: ListView.builder(
                shrinkWrap: true,
                itemCount: allFAQs.length,
                itemBuilder: (context, index) {
                  return _faqEntry(allFAQs[index]);
                }),
          )
        : blackSarabunBold('NO FAQS AVAILABLE', fontSize: 30);
  }

  Widget _faqEntry(DocumentSnapshot faqDoc) {
    final faqData = faqDoc.data() as Map<dynamic, dynamic>;
    String question = faqData[FAQFields.question];
    String answer = faqData[FAQFields.answer];
    return vertical10Pix(
        child: ExpansionTile(
      collapsedBackgroundColor: CustomColors.blackBeauty,
      backgroundColor: CustomColors.blackBeauty.withOpacity(0.8),
      collapsedIconColor: Colors.white,
      iconColor: Colors.white,
      collapsedShape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: whiteSarabunBold(question, fontSize: 27),
      children: [vertical20Pix(child: whiteSarabunBold(answer))],
    ));
  }
}
