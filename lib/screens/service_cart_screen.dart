import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:one_velocity_web/providers/loading_provider.dart';
import 'package:one_velocity_web/widgets/custom_miscellaneous_widgets.dart';

import '../providers/cart_provider.dart';
import '../utils/color_util.dart';
import '../utils/delete_entry_dialog_util.dart';
import '../utils/firebase_util.dart';
import '../utils/go_router_util.dart';
import '../utils/string_util.dart';
import '../widgets/app_bar_widget.dart';
import '../widgets/custom_padding_widgets.dart';
import '../widgets/floating_chat_widget.dart';
import '../widgets/text_widgets.dart';

class ServiceCartScreen extends ConsumerStatefulWidget {
  const ServiceCartScreen({super.key});

  @override
  ConsumerState<ServiceCartScreen> createState() => _ServiceCartScreenState();
}

class _ServiceCartScreenState extends ConsumerState<ServiceCartScreen> {
  List<DocumentSnapshot> associatedServiceDocs = [];
  num totalAmount = 0;
  DateTime? proposedDateTime;

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
          goRouter.goNamed(GoRoutes.home);
          return;
        }
        if (await getCurrentUserType() == UserTypes.admin) {
          ref.read(loadingProvider.notifier).toggleLoading(false);
          goRouter.goNamed(GoRoutes.home);
          return;
        }
        ref
            .read(cartProvider)
            .setCartItems(await getServiceCartEntries(context));
        associatedServiceDocs = await getSelectedServiceDocs(
            await ref.read(cartProvider).cartItems.map((cartDoc) {
          final cartData = cartDoc.data() as Map<dynamic, dynamic>;
          return cartData[CartFields.itemID].toString();
        }).toList());
        setState(() {});

        print('items: ${ref.read(cartProvider).cartItems.length}');

        ref.read(loadingProvider.notifier).toggleLoading(false);
      } catch (error) {
        ref.read(loadingProvider.notifier).toggleLoading(false);
        scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('Error getting service cart: $error')));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(loadingProvider);
    ref.watch(cartProvider);
    return Scaffold(
      appBar: appBarWidget(context),
      floatingActionButton: FloatingChatWidget(
          senderUID: FirebaseAuth.instance.currentUser!.uid, otherUID: adminID),
      body: switchedLoadingContainer(
        ref.read(loadingProvider),
        SingleChildScrollView(
          child: Column(children: [
            secondAppBar(context),
            Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [_cartEntries(), _checkoutContainer()])
          ]),
        ),
      ),
    );
  }

  Widget _cartEntries() {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.75,
      child: all10Pix(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            blackSarabunBold('REQUESTED SERVICES', fontSize: 40),
            ref.read(cartProvider).cartItems.isNotEmpty
                ? ListView.builder(
                    shrinkWrap: true,
                    itemCount: ref.read(cartProvider).cartItems.length,
                    itemBuilder: (context, index) {
                      return _cartEntry(
                          ref.read(cartProvider).cartItems[index]);
                    })
                : blackSarabunBold('YOU DO NOT HAVE ANY SERVICES IN YOUR CART')
          ],
        ),
      ),
    );
  }

  Widget _cartEntry(DocumentSnapshot cartDoc) {
    final cartData = cartDoc.data() as Map<dynamic, dynamic>;
    DocumentSnapshot? associatedServiceDoc =
        associatedServiceDocs.where((serviceDoc) {
      return serviceDoc.id == cartData[CartFields.itemID].toString();
    }).firstOrNull;
    if (associatedServiceDoc == null)
      return Container();
    else {
      String name = associatedServiceDoc[ServiceFields.name];
      List<dynamic> imageURLs = associatedServiceDoc[ServiceFields.imageURLs];
      num price = associatedServiceDoc[ServiceFields.price];
      return all10Pix(
          child: Container(
              height: 100,
              decoration: BoxDecoration(color: CustomColors.ultimateGray),
              padding: EdgeInsets.all(10),
              child: Row(
                children: [
                  Flexible(
                      child: Checkbox(
                          value: ref
                              .read(cartProvider)
                              .selectedCartItemIDs
                              .contains(cartDoc.id),
                          onChanged: (newVal) {
                            if (newVal == null) return;
                            setState(() {
                              if (newVal) {
                                ref
                                    .read(cartProvider)
                                    .selectCartItem(cartDoc.id);
                              } else {
                                ref
                                    .read(cartProvider)
                                    .deselectCartItem(cartDoc.id);
                              }
                            });
                          })),
                  Flexible(
                    flex: 8,
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () => GoRouter.of(context)
                            .goNamed(GoRoutes.selectedProduct, pathParameters: {
                          PathParameters.productID: cartData[CartFields.itemID]
                        }),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                                backgroundImage: NetworkImage(imageURLs[0]),
                                backgroundColor: Colors.transparent,
                                radius: 50),
                            Gap(20),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                whiteSarabunBold(name),
                                whiteSarabunBold(
                                    'PHP ${formatPrice(price.toDouble())}',
                                    fontSize: 16),
                              ],
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                  Flexible(
                    child: ElevatedButton(
                        onPressed: () => displayDeleteEntryDialog(context,
                                message:
                                    'Are you sure you wish to remove ${name} from your cart?',
                                deleteEntry: () {
                              if (ref
                                  .read(cartProvider)
                                  .selectedCartItemIDs
                                  .contains(cartDoc.id)) {
                                ref
                                    .read(cartProvider)
                                    .deselectCartItem(cartDoc.id);
                              }
                              removeCartItem(context, ref, cartDoc: cartDoc);
                            }),
                        child: Icon(Icons.delete, color: Colors.white)),
                  )
                ],
              )));
    }
  }

  Widget _checkoutContainer() {
    return Container(
      width: MediaQuery.of(context).size.width * 0.25,
      height: MediaQuery.of(context).size.height - 100,
      color: CustomColors.ultimateGray,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 25),
            child: whiteSarabunBold('CHECKOUT', fontSize: 30),
          ),
          if (ref.read(cartProvider).selectedCartItemIDs.isNotEmpty)
            _totalAmountFutureBuilder()
          else
            whiteSarabunBold('TOTAL AMOUNT: PHP 0.00'),
          _timeSelector(),
          _requestButton()
        ],
      ),
    );
  }

  Widget _totalAmountFutureBuilder() {
    //  1. Get every associated cart DocumentSnapshot
    List<DocumentSnapshot> selectedCartDocs = [];
    for (var cartID in ref.read(cartProvider).selectedCartItemIDs) {
      selectedCartDocs.add(ref
          .read(cartProvider)
          .cartItems
          .where((element) => element.id == cartID)
          .first);
    }
    //  2. get list of associated products
    num totalAmount = 0;
    //  Go through every selected cart item
    for (var cartDoc in selectedCartDocs) {
      final cartData = cartDoc.data() as Map<dynamic, dynamic>;
      String itemID = cartData[CartFields.itemID];
      DocumentSnapshot? serviceDoc =
          associatedServiceDocs.where((item) => item.id == itemID).firstOrNull;
      if (serviceDoc == null) {
        continue;
      }
      final serviceData = serviceDoc.data() as Map<dynamic, dynamic>;
      num price = serviceData[ProductFields.price];
      totalAmount += price;
    }
    totalAmount = totalAmount;
    return whiteSarabunBold(
        'TOTAL AMOUNT: PHP ${formatPrice(totalAmount.toDouble())}');
  }

  Widget _timeSelector() {
    return all20Pix(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          whiteSarabunBold('Drop-Off Date', fontSize: 24),
          ElevatedButton(
              onPressed: () async {
                DateTime? pickedDate = await showDatePicker(
                    context: context,
                    firstDate: DateTime.now().add(Duration(days: 1)),
                    lastDate: DateTime.now().add(Duration(days: 14)));
                if (pickedDate == null) return null;
                setState(() {
                  proposedDateTime = pickedDate;
                });
              },
              child: whiteSarabunBold(proposedDateTime != null
                  ? DateFormat('MMM dd, yyyy').format(proposedDateTime!)
                  : 'Select your drop-off date')),
        ],
      ),
    );
  }

  Widget _requestButton() {
    return SizedBox(
      height: 60,
      child: ElevatedButton(
          onPressed: proposedDateTime == null ||
                  ref.read(cartProvider).selectedCartItemIDs.isEmpty
              ? null
              : () => createNewBookingRequest(context, ref,
                  datePicked: proposedDateTime!),
          style: ElevatedButton.styleFrom(
              disabledBackgroundColor: CustomColors.nimbusCloud),
          child: whiteSarabunBold('REQUEST SERVICES')),
    );
  }
}
