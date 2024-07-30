import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:one_velocity_web/providers/payments_provider.dart';
import 'package:one_velocity_web/utils/go_router_util.dart';
import 'package:one_velocity_web/widgets/app_bar_widget.dart';
import 'package:one_velocity_web/widgets/custom_miscellaneous_widgets.dart';
import 'package:one_velocity_web/widgets/custom_padding_widgets.dart';
import 'package:one_velocity_web/widgets/left_navigator_widget.dart';
import 'package:one_velocity_web/widgets/text_widgets.dart';

import '../providers/loading_provider.dart';
import '../providers/pages_provider.dart';
import '../utils/color_util.dart';
import '../utils/delete_entry_dialog_util.dart';
import '../utils/firebase_util.dart';
import '../utils/string_util.dart';

class ViewTransactionsScreen extends ConsumerStatefulWidget {
  const ViewTransactionsScreen({super.key});

  @override
  ConsumerState<ViewTransactionsScreen> createState() =>
      _ViewTransactionsScreenState();
}

class _ViewTransactionsScreenState
    extends ConsumerState<ViewTransactionsScreen> {
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
          return;
        }
        final userDoc = await getCurrentUserDoc();
        final userData = userDoc.data() as Map<dynamic, dynamic>;
        if (userData[UserFields.userType] == UserTypes.client) {
          goRouter.goNamed(GoRoutes.home);
          return;
        }
        ref.read(paymentsProvider).setPaymentDocs(await getAllPaymentDocs());

        ref.read(pagesProvider.notifier).setCurrentPage(1);
        ref.read(pagesProvider.notifier).setMaxPage(
            (ref.read(paymentsProvider).paymentDocs.length / 10).ceil());
        ref.read(loadingProvider.notifier).toggleLoading(false);
      } catch (error) {
        scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('Error getting payments: $error')));
        ref.read(loadingProvider.notifier).toggleLoading(false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(loadingProvider);
    ref.watch(pagesProvider);
    ref.watch(paymentsProvider);
    return Scaffold(
      appBar: appBarWidget(context, showActions: false),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          leftNavigator(context, path: GoRoutes.viewTransactions),
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            child: switchedLoadingContainer(
                ref.read(loadingProvider),
                SingleChildScrollView(
                  child: all5Percent(context,
                      child: Column(
                        children: [
                          _paymentsContainer(),
                        ],
                      )),
                )),
          )
        ],
      ),
    );
  }

  Widget _paymentsContainer() {
    return viewContentContainer(
      context,
      child: Column(
        children: [
          _paymentsLabelRow(),
          ref.read(paymentsProvider).paymentDocs.isNotEmpty
              ? _paymentEntries()
              : viewContentUnavailable(context,
                  text: 'NO AVAILABLE TRANSACTIONS'),
        ],
      ),
    );
  }

  Widget _paymentsLabelRow() {
    return viewContentLabelRow(context, children: [
      viewFlexLabelTextCell('Buyer', 3),
      viewFlexLabelTextCell('Amount Paid', 2),
      viewFlexLabelTextCell('Payment', 2),
      viewFlexLabelTextCell('Actions', 2)
    ]);
  }

  Widget _paymentEntries() {
    return SizedBox(
      height: 500,
      child: ListView.builder(
          shrinkWrap: true,
          itemCount: ref.read(paymentsProvider).paymentDocs.length,
          itemBuilder: (context, index) {
            final paymentData = ref
                .read(paymentsProvider)
                .paymentDocs[index]
                .data() as Map<dynamic, dynamic>;
            String clientID = paymentData[PaymentFields.clientID];
            num totalAmount = paymentData[PaymentFields.paidAmount];
            String paymentMethod = paymentData[PaymentFields.paymentMethod];
            String proofOfPayment = paymentData[PaymentFields.proofOfPayment];
            List<dynamic> purchaseIDs = paymentData[PaymentFields.purchaseIDs];
            String paymentType = paymentData[PaymentFields.paymentType];
            return FutureBuilder(
                future: getThisUserDoc(clientID),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting ||
                      !snapshot.hasData ||
                      snapshot.hasError) return snapshotHandler(snapshot);

                  final clientData =
                      snapshot.data!.data() as Map<dynamic, dynamic>;
                  String formattedName =
                      '${clientData[UserFields.firstName]} ${clientData[UserFields.lastName]}';
                  Color entryColor = Colors.black;
                  Color backgroundColor = index % 2 == 0
                      ? CustomColors.ultimateGray.withOpacity(0.5)
                      : CustomColors.nimbusCloud;
                  return viewContentEntryRow(
                    context,
                    children: [
                      viewFlexTextCell(formattedName,
                          flex: 3,
                          backgroundColor: backgroundColor,
                          textColor: entryColor),
                      viewFlexTextCell('PHP ${totalAmount.toStringAsFixed(2)}',
                          flex: 2,
                          backgroundColor: backgroundColor,
                          textColor: entryColor),
                      viewFlexActionsCell(
                        [
                          ElevatedButton(
                              onPressed: () => showProofOfPaymentDialog(
                                  paymentMethod: paymentMethod,
                                  proofOfPayment: proofOfPayment),
                              child: montserratWhiteRegular('VIEW'))
                        ],
                        flex: 2,
                        backgroundColor: backgroundColor,
                      ),
                      viewFlexActionsCell([
                        if (paymentData[PaymentFields.paymentVerified])
                          montserratBlackBold('VERIFIED'),
                        if (!paymentData[PaymentFields.paymentVerified])
                          ElevatedButton(
                              onPressed: () => approveThisPayment(context, ref,
                                  paymentID: ref
                                      .read(paymentsProvider)
                                      .paymentDocs[index]
                                      .id,
                                  purchaseIDs: purchaseIDs,
                                  paymentType: paymentType),
                              child: Icon(
                                Icons.check,
                                color: Colors.white,
                              )),
                        if (!paymentData[PaymentFields.paymentVerified])
                          ElevatedButton(
                              onPressed: () => displayDeleteEntryDialog(context,
                                  message:
                                      'Are you sure you want to deny this payment?',
                                  deleteWord: 'Deny',
                                  deleteEntry: () => denyThisPayment(
                                      context, ref,
                                      paymentID: ref
                                          .read(paymentsProvider)
                                          .paymentDocs[index]
                                          .id,
                                      purchaseIDs: purchaseIDs,
                                      paymentType: paymentType)),
                              child: Icon(Icons.block, color: Colors.white))
                      ], flex: 2, backgroundColor: backgroundColor)
                    ],
                  );
                });
          }),
    );
  }

  void showProofOfPaymentDialog(
      {required String paymentMethod, required String proofOfPayment}) {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30)),
              content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.45,
                height: MediaQuery.of(context).size.height * 0.7,
                child: Column(
                  children: [
                    montserratBlackBold('Payment Method: $paymentMethod',
                        fontSize: 30),
                    const Gap(10),
                    Container(
                      width: MediaQuery.of(context).size.width * 0.25,
                      height: MediaQuery.of(context).size.height * 0.5,
                      decoration: BoxDecoration(
                          color: Colors.black,
                          image: DecorationImage(
                              image: NetworkImage(proofOfPayment))),
                    ),
                    const Gap(30),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.1,
                      height: 30,
                      child: ElevatedButton(
                          onPressed: () => GoRouter.of(context).pop(),
                          child: montserratWhiteBold('CLOSE')),
                    )
                  ],
                ),
              ),
            ));
  }
}
