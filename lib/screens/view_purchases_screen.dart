import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:one_velocity_web/providers/pages_provider.dart';
import 'package:one_velocity_web/providers/payments_provider.dart';
import 'package:one_velocity_web/widgets/app_bar_widget.dart';
import 'package:one_velocity_web/widgets/left_navigator_widget.dart';
import 'package:one_velocity_web/widgets/product_payment_widget.dart';
import 'package:one_velocity_web/widgets/text_widgets.dart';

import '../providers/loading_provider.dart';
import '../utils/firebase_util.dart';
import '../utils/go_router_util.dart';
import '../utils/string_util.dart';
import '../widgets/custom_button_widgets.dart';
import '../widgets/custom_miscellaneous_widgets.dart';
import '../widgets/custom_padding_widgets.dart';

class ViewPurchasesScreen extends ConsumerStatefulWidget {
  const ViewPurchasesScreen({super.key});

  @override
  ConsumerState<ViewPurchasesScreen> createState() =>
      _ViewPurchasesScreenState();
}

class _ViewPurchasesScreenState extends ConsumerState<ViewPurchasesScreen> {
  int currentPage = 0;
  int maxPage = 0;
  int entriesPerPage = 8;
  List<DocumentSnapshot> currentDisplayedPurchases = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      ref.read(loadingProvider.notifier).toggleLoading(true);
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      final goRouter = GoRouter.of(context);
      try {
        if (hasLoggedInUser() &&
            await getCurrentUserType() == UserTypes.client) {
          ref.read(loadingProvider.notifier).toggleLoading(false);
          goRouter.goNamed(GoRoutes.home);
          return;
        }

        ref
            .read(paymentsProvider)
            .setPaymentDocs(await getAllProductPaymentDocs());

        ref.read(paymentsProvider).paymentDocs.sort((a, b) {
          DateTime aTime =
              (a[PurchaseFields.dateCreated] as Timestamp).toDate();
          DateTime bTime =
              (b[PurchaseFields.dateCreated] as Timestamp).toDate();
          return bTime.compareTo(aTime);
        });
        currentPage = 0;
        maxPage =
            (ref.read(paymentsProvider).paymentDocs.length / entriesPerPage)
                .floor();
        if (ref.read(paymentsProvider).paymentDocs.length % entriesPerPage == 0)
          maxPage--;
        setDisplayedPurchases();
        ref.read(loadingProvider.notifier).toggleLoading(false);
      } catch (error) {
        scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('Error getting all purchases: $error')));
        ref.read(loadingProvider.notifier).toggleLoading(false);
      }
    });
  }

  void setDisplayedPurchases() {
    Future.delayed(Duration(milliseconds: 100)).then((value) {
      if (ref.read(paymentsProvider).paymentDocs.length > entriesPerPage) {
        currentDisplayedPurchases = ref
            .read(paymentsProvider)
            .paymentDocs
            .getRange(
                currentPage * entriesPerPage,
                min((currentPage * entriesPerPage) + entriesPerPage,
                    ref.read(paymentsProvider).paymentDocs.length))
            .toList();
      } else {
        currentDisplayedPurchases = ref.read(paymentsProvider).paymentDocs;
      }
      currentDisplayedPurchases.forEach((element) {
        print(element.id);
      });
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(loadingProvider);
    ref.watch(paymentsProvider);
    ref.watch(pagesProvider);
    return Scaffold(
      appBar: appBarWidget(context, showActions: false),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          leftNavigator(context, path: GoRoutes.viewPurchases),
          SizedBox(
              width: MediaQuery.of(context).size.width * 0.8,
              child: switchedLoadingContainer(
                  ref.read(loadingProvider),
                  SingleChildScrollView(
                    child: horizontal5Percent(context,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            blackSarabunBold('PURCHASES', fontSize: 40),
                            _purchasesContainer(),
                            if (ref.read(paymentsProvider).paymentDocs.length >
                                entriesPerPage)
                              pageNavigatorButtons(
                                  currentPage: currentPage,
                                  maxPage: maxPage,
                                  onPreviousPage: () {
                                    currentPage--;
                                    setState(() {
                                      currentDisplayedPurchases.clear();
                                      setDisplayedPurchases();
                                    });
                                  },
                                  onNextPage: () {
                                    currentPage++;
                                    setState(() {
                                      currentDisplayedPurchases.clear();
                                      setDisplayedPurchases();
                                    });
                                  })
                          ],
                        )),
                  )))
        ],
      ),
    );
  }

  Widget _purchasesContainer() {
    return vertical20Pix(
      child: Center(
        child: Wrap(
            spacing: 20,
            runSpacing: 20,
            children: currentDisplayedPurchases
                .map((productPayment) => ProductPaymentWidget(
                    ref: ref, productPaymentDoc: productPayment))
                .toList()),
      ),
    );
  }
}
