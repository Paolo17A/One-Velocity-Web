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
  String currentCategory = 'VIEW ALL';
  List<DocumentSnapshot> allFAQs = [];
  List<DocumentSnapshot> filteredFAQs = [];
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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                categoriesNavigator(),
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.8,
                  child: horizontal5Percent(context,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [_faqHeader(), _faqEntries()],
                      )),
                ),
              ],
            ),
          ],
        )),
      ),
    );
  }

  Widget categoriesNavigator() {
    return Container(
        width: MediaQuery.of(context).size.width * 0.2,
        height: MediaQuery.of(context).size.height - 60,
        color: CustomColors.crimson,
        padding: const EdgeInsets.all(20),
        child: ListView(
            shrinkWrap: false,
            physics: NeverScrollableScrollPhysics(),
            children: [
              all10Pix(
                child: GestureDetector(
                  onTap: () {
                    currentCategory = 'VIEW ALL';
                    setState(() {
                      filteredFAQs = allFAQs;
                    });
                  },
                  child: Container(
                      padding: EdgeInsets.all(10),
                      color: currentCategory == 'VIEW ALL'
                          ? CustomColors.grenadine
                          : CustomColors.crimson,
                      child: whiteSarabunRegular('VIEW ALL',
                          textAlign: TextAlign.left)),
                ),
              ),
              categoryTemplate(FAQCategories.location),
              categoryTemplate(FAQCategories.paymentMethod),
              categoryTemplate(FAQCategories.products),
              categoryTemplate(FAQCategories.services)
            ]));
  }

  Widget categoryTemplate(String category) {
    return all10Pix(
      child: GestureDetector(
        onTap: () {
          currentCategory = category;
          setState(() {
            filteredFAQs = allFAQs.where((faq) {
              final faqData = faq.data() as Map<dynamic, dynamic>;
              return currentCategory == faqData[FAQFields.category];
            }).toList();
          });
        },
        child: Container(
            padding: EdgeInsets.all(10),
            color: currentCategory == category
                ? CustomColors.grenadine
                : CustomColors.crimson,
            child: whiteSarabunRegular(category, textAlign: TextAlign.left)),
      ),
    );
  }

  Widget _faqHeader() {
    return blackSarabunBold('FREQUENTLY ASKED QUESTIONS', fontSize: 40);
  }

  Widget _faqEntries() {
    return filteredFAQs.isNotEmpty
        ? SizedBox(
            height: MediaQuery.of(context).size.height * 0.9,
            child: ListView.builder(
                shrinkWrap: true,
                itemCount: filteredFAQs.length,
                itemBuilder: (context, index) {
                  return _faqEntry(filteredFAQs[index]);
                }),
          )
        : blackSarabunBold(
            'No FAQs Avaialble for ${currentCategory.toLowerCase()}',
            fontSize: 30);
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
