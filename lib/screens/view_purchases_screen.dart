import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:one_velocity_web/providers/purchases_provider.dart';
import 'package:one_velocity_web/widgets/app_bar_widget.dart';
import 'package:one_velocity_web/widgets/left_navigator_widget.dart';
import 'package:one_velocity_web/widgets/text_widgets.dart';

import '../providers/loading_provider.dart';
import '../utils/color_util.dart';
import '../utils/firebase_util.dart';
import '../utils/go_router_util.dart';
import '../utils/string_util.dart';
import '../widgets/custom_miscellaneous_widgets.dart';
import '../widgets/custom_padding_widgets.dart';

class ViewPurchasesScreen extends ConsumerStatefulWidget {
  const ViewPurchasesScreen({super.key});

  @override
  ConsumerState<ViewPurchasesScreen> createState() =>
      _ViewPurchasesScreenState();
}

class _ViewPurchasesScreenState extends ConsumerState<ViewPurchasesScreen> {
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
          goRouter.goNamed(GoRoutes.home);
          return;
        }

        ref.read(purchasesProvider).setPurchaseDocs(await getAllPurchaseDocs());
        ref.read(loadingProvider.notifier).toggleLoading(false);
      } catch (error) {
        scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('Error getting all purchases: $error')));
        ref.read(loadingProvider.notifier).toggleLoading(false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(loadingProvider);
    ref.watch(purchasesProvider);
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
                    child: all5Percent(context, child: _purchasesContainer()),
                  )))
        ],
      ),
    );
  }

  Widget _purchasesContainer() {
    return viewContentContainer(
      context,
      child: Column(
        children: [
          _purchasesLabelRow(),
          ref.read(purchasesProvider).purchaseDocs.isNotEmpty
              ? _purchaseEntries()
              : viewContentUnavailable(context, text: 'NO AVAILABLE PURCHASES'),
        ],
      ),
    );
  }

  Widget _purchasesLabelRow() {
    return viewContentLabelRow(context, children: [
      viewFlexLabelTextCell('Buyer', 2),
      viewFlexLabelTextCell('Item', 2),
      viewFlexLabelTextCell('SRP', 1),
      viewFlexLabelTextCell('Quantity', 1),
      viewFlexLabelTextCell('Total', 1),
      viewFlexLabelTextCell('Status', 2)
    ]);
  }

  Widget _purchaseEntries() {
    return SizedBox(
      height: 500,
      child: ListView.builder(
          shrinkWrap: true,
          itemCount: ref.read(purchasesProvider).purchaseDocs.length,
          itemBuilder: (context, index) {
            final purchaseData = ref
                .read(purchasesProvider)
                .purchaseDocs[index]
                .data() as Map<dynamic, dynamic>;
            String clientID = purchaseData[PurchaseFields.clientID];
            String productID = purchaseData[PurchaseFields.productID];
            num quantity = purchaseData[PurchaseFields.quantity];
            String status = purchaseData[PurchaseFields.purchaseStatus];

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

                  return FutureBuilder(
                      future: getThisProductDoc(productID),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                                ConnectionState.waiting ||
                            !snapshot.hasData ||
                            snapshot.hasError) return snapshotHandler(snapshot);

                        final itemData =
                            snapshot.data!.data() as Map<dynamic, dynamic>;
                        String name = itemData[ProductFields.name];
                        num price = itemData[ProductFields.price];

                        Color entryColor = Colors.black;
                        Color backgroundColor = index % 2 == 0
                            ? CustomColors.ultimateGray.withOpacity(0.5)
                            : CustomColors.nimbusCloud;

                        return viewContentEntryRow(context, children: [
                          viewFlexTextCell(formattedName,
                              flex: 2,
                              backgroundColor: backgroundColor,
                              textColor: entryColor),
                          viewFlexTextCell(name,
                              flex: 2,
                              backgroundColor: backgroundColor,
                              textColor: entryColor),
                          viewFlexTextCell(price.toStringAsFixed(2),
                              flex: 1,
                              backgroundColor: backgroundColor,
                              textColor: entryColor),
                          viewFlexTextCell(quantity.toString(),
                              flex: 1,
                              backgroundColor: backgroundColor,
                              textColor: entryColor),
                          viewFlexTextCell((quantity * price).toString(),
                              flex: 1,
                              backgroundColor: backgroundColor,
                              textColor: entryColor),
                          viewFlexActionsCell(
                            [
                              if (status == PurchaseStatuses.pending)
                                montserratBlackRegular(
                                    'PENDING PAYMENT APPROVAL')
                              else if (status == PurchaseStatuses.denied)
                                montserratBlackRegular('PAYMENT DENIED')
                              else if (status == PurchaseStatuses.processing)
                                ElevatedButton(
                                    onPressed: () =>
                                        markPurchaseAsReadyForPickUp(
                                            context, ref,
                                            purchaseID: ref
                                                .read(purchasesProvider)
                                                .purchaseDocs[index]
                                                .id),
                                    child: montserratWhiteRegular(
                                        'MARK AS READY FOR PICK UP',
                                        fontSize: 12))
                              else if (status == PurchaseStatuses.forPickUp)
                                ElevatedButton(
                                    onPressed: () => markPurchaseAsPickedUp(
                                        context, ref,
                                        purchaseID: ref
                                            .read(purchasesProvider)
                                            .purchaseDocs[index]
                                            .id),
                                    child: montserratWhiteRegular(
                                        'MARK AS PICKED UP',
                                        fontSize: 12))
                              else if (status == PurchaseStatuses.pickedUp)
                                montserratBlackBold('COMPLETED')
                            ],
                            flex: 2,
                            backgroundColor: backgroundColor,
                          ),
                        ]);
                      });
                  //  Item Variables
                });
            //  Client Variables
          }),
    );
  }
}
