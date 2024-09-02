import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:one_velocity_web/providers/loading_provider.dart';
import 'package:one_velocity_web/providers/purchase_history_provider.dart';
import 'package:one_velocity_web/utils/firebase_util.dart';
import 'package:one_velocity_web/utils/go_router_util.dart';
import 'package:one_velocity_web/utils/string_util.dart';
import 'package:one_velocity_web/widgets/app_bar_widget.dart';
import 'package:one_velocity_web/widgets/custom_miscellaneous_widgets.dart';
import 'package:one_velocity_web/widgets/custom_padding_widgets.dart';
import 'package:one_velocity_web/widgets/left_navigator_widget.dart';
import 'package:one_velocity_web/widgets/text_widgets.dart';

import '../utils/url_util.dart';
import '../widgets/floating_chat_widget.dart';

class PurchaseHistoryScreen extends ConsumerStatefulWidget {
  const PurchaseHistoryScreen({super.key});

  @override
  ConsumerState<PurchaseHistoryScreen> createState() =>
      _PurchaseHistoryScreenState();
}

class _PurchaseHistoryScreenState extends ConsumerState<PurchaseHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      ref.read(loadingProvider.notifier).toggleLoading(true);
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      final goRouter = GoRouter.of(context);
      try {
        if (hasLoggedInUser() &&
            await getCurrentUserType() == UserTypes.admin) {
          goRouter.goNamed(GoRoutes.home);
          return;
        }

        ref
            .read(purchaseHistoryProvider)
            .setPurchaseHistories(await getClientPurchaseHistory());
        ref.read(loadingProvider.notifier).toggleLoading(false);
      } catch (error) {
        scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('Error getting purchase history: $error')));
        ref.read(loadingProvider.notifier).toggleLoading(false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(loadingProvider);
    ref.watch(purchaseHistoryProvider);
    return Scaffold(
      appBar: appBarWidget(context),
      floatingActionButton: FloatingChatWidget(
          senderUID: FirebaseAuth.instance.currentUser!.uid, otherUID: adminID),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            secondAppBar(context),
            switchedLoadingContainer(
                ref.read(loadingProvider),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    clientProfileNavigator(context,
                        path: GoRoutes.purchaseHistory),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.8,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          blackSarabunBold('PURCHASE HISTORY', fontSize: 40),
                          _purchaseHistoryEntries()
                        ],
                      ),
                    )
                  ],
                ))
          ],
        ),
      ),
    );
  }

  Widget _purchaseHistoryEntries() {
    return ref.read(purchaseHistoryProvider).purchaseHistory.isNotEmpty
        ? ListView.builder(
            shrinkWrap: true,
            itemCount: ref.read(purchaseHistoryProvider).purchaseHistory.length,
            itemBuilder: (context, index) {
              return _purchaseHistoryEntry(
                  ref.read(purchaseHistoryProvider).purchaseHistory[index]);
            })
        : Center(
            child: blackSarabunBold('YOU HAVE NOT PURCHASED ANY ITEMS YET',
                fontSize: 30),
          );
  }

  Widget _purchaseHistoryEntry(DocumentSnapshot purchaseDoc) {
    final purchaseData = purchaseDoc.data() as Map<dynamic, dynamic>;
    String status = purchaseData[PurchaseFields.purchaseStatus];
    String productID = purchaseData[PurchaseFields.productID];
    num quantity = purchaseData[PurchaseFields.quantity];

    return FutureBuilder(
      future: getThisProductDoc(productID),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting ||
            !snapshot.hasData ||
            snapshot.hasError) return snapshotHandler(snapshot);

        final productData = snapshot.data!.data() as Map<dynamic, dynamic>;
        List<dynamic> imageURLs = productData[ProductFields.imageURLs];
        String name = productData[ProductFields.name];
        num price = productData[ProductFields.price];
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
              onTap: () {
                GoRouter.of(context).goNamed(GoRoutes.selectedProduct,
                    pathParameters: {PathParameters.productID: productID});
                GoRouter.of(context).pushNamed(GoRoutes.selectedProduct,
                    pathParameters: {PathParameters.productID: productID});
              },
              child: all10Pix(
                  child: Container(
                decoration: BoxDecoration(border: Border.all()),
                padding: EdgeInsets.all(10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                                image: DecorationImage(
                                    image: NetworkImage(imageURLs[0]),
                                    fit: BoxFit.cover))),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 30),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              blackSarabunBold(name, fontSize: 25),
                              Row(
                                children: [
                                  blackSarabunRegular(
                                      'SRP: PHP ${formatPrice(price.toDouble())}',
                                      fontSize: 15),
                                  const Gap(15),
                                  blackSarabunRegular(
                                      'Quantity: ${quantity.toString()}',
                                      fontSize: 15),
                                ],
                              ),
                              const Gap(15),
                              blackSarabunRegular('Status: $status',
                                  fontSize: 15),
                              /*if (status == PurchaseStatuses.pickedUp)
                                _downloadInvoiceFutureBuilder(purchaseDoc.id)*/
                            ],
                          ),
                        ),
                      ],
                    ),
                    all20Pix(
                        child: whiteSarabunBold(
                            'PHP ${(price * quantity).toStringAsFixed(2)}'))
                  ],
                ),
              ))),
        );
      },
    );
  }

  Widget _downloadInvoiceFutureBuilder(String purchaseID) {
    return FutureBuilder(
      future: getThisPaymentDoc(purchaseID),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting ||
            !snapshot.hasData ||
            snapshot.hasError) return snapshotHandler(snapshot);
        final paymentData = snapshot.data!.data() as Map<dynamic, dynamic>;
        String invoiceURL = paymentData[PaymentFields.invoiceURL];
        return TextButton(
            onPressed: () async => launchThisURL(context, invoiceURL),
            child: whiteSarabunRegular('Download Invoice',
                fontSize: 12,
                textAlign: TextAlign.left,
                decoration: TextDecoration.underline));
      },
    );
  }
}
