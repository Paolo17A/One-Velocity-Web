import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker_web/image_picker_web.dart';
import 'package:one_velocity_web/utils/delete_entry_dialog_util.dart';
import 'package:one_velocity_web/utils/go_router_util.dart';
import 'package:one_velocity_web/widgets/app_bar_widget.dart';
import 'package:one_velocity_web/widgets/text_widgets.dart';

import '../providers/cart_provider.dart';
import '../providers/loading_provider.dart';
import '../utils/color_util.dart';
import '../utils/firebase_util.dart';
import '../utils/string_util.dart';
import '../widgets/custom_miscellaneous_widgets.dart';
import '../widgets/custom_padding_widgets.dart';
import '../widgets/floating_chat_widget.dart';

class ProductCartScreen extends ConsumerStatefulWidget {
  const ProductCartScreen({super.key});

  @override
  ConsumerState<ProductCartScreen> createState() => _ProductCartScreenState();
}

class _ProductCartScreenState extends ConsumerState<ProductCartScreen> {
  List<DocumentSnapshot> associatedProductDocs = [];
  num paidAmount = 0;
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
          ref.read(loadingProvider.notifier).toggleLoading(false);
          goRouter.goNamed(GoRoutes.home);
          return;
        }

        ref
            .read(cartProvider)
            .setCartItems(await getProductCartEntries(context));
        associatedProductDocs = await getSelectedProductDocs(
            ref.read(cartProvider).cartItems.map((cartDoc) {
          final cartData = cartDoc.data() as Map<dynamic, dynamic>;
          return cartData[CartFields.itemID].toString();
        }).toList());
        setState(() {});
        ref.read(cartProvider).setSelectedPaymentMethod('');
        ref.read(cartProvider).resetProofOfPaymentBytes();
        ref.read(loadingProvider.notifier).toggleLoading(false);
      } catch (error) {
        scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('Error getting selected product: $error')));
        ref.read(loadingProvider.notifier).toggleLoading(false);
      }
    });
  }

  Future _pickProofOfPayment() async {
    final pickedFile = await ImagePickerWeb.getImageAsBytes();
    if (pickedFile == null) {
      return;
    }
    await purchaseSelectedProductCartItems(context, ref,
        proofOfPayment: pickedFile, paidAmount: paidAmount);
    ref.read(cartProvider).resetSelectedCartItems();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(loadingProvider);
    ref.watch(cartProvider);
    return Scaffold(
      appBar: appBarWidget(context),
      floatingActionButton: FloatingChatWidget(
          senderUID: FirebaseAuth.instance.currentUser!.uid, otherUID: adminID),
      body: SingleChildScrollView(
        child: Column(
          children: [
            secondAppBar(context),
            switchedLoadingContainer(
              ref.read(loadingProvider),
              Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [_cartEntries(), _checkoutContainer()]),
            )
          ],
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
            blackSarabunBold('PRODUCT CART ITEMS', fontSize: 40),
            ref.read(cartProvider).cartItems.isNotEmpty
                ? ListView.builder(
                    shrinkWrap: true,
                    itemCount: ref.read(cartProvider).cartItems.length,
                    itemBuilder: (context, index) {
                      return _cartEntry(
                          ref.read(cartProvider).cartItems[index]);
                    })
                : blackSarabunBold('YOU DO NOT HAVE ANY ITEMS IN YOUR CART')
          ],
        ),
      ),
    );
  }

  Widget _cartEntry(DocumentSnapshot cartDoc) {
    final cartData = cartDoc.data() as Map<dynamic, dynamic>;
    int quantity = cartData[CartFields.quantity];
    DocumentSnapshot? associatedProductDoc =
        associatedProductDocs.where((productDoc) {
      return productDoc.id == cartData[CartFields.itemID].toString();
    }).firstOrNull;
    if (associatedProductDoc == null)
      return Container();
    else {
      String name = associatedProductDoc[ProductFields.name];
      List<dynamic> imageURLs = associatedProductDoc[ProductFields.imageURLs];
      num price = associatedProductDoc[ProductFields.price];
      num remainingQuantity = associatedProductDoc[ProductFields.quantity];
      return all10Pix(
          child: Container(
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
                                    'SRP: ${formatPrice(price.toDouble())}',
                                    fontSize: 16),
                                whiteSarabunRegular(
                                    'Remaining Quantity: $remainingQuantity',
                                    fontSize: 16)
                              ],
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                  Flexible(
                    flex: 4,
                    child: Row(
                      children: [
                        Container(
                            decoration: BoxDecoration(
                                border: Border.all(
                                    color: CustomColors.nimbusCloud)),
                            child: TextButton(
                                onPressed: quantity == 1
                                    ? null
                                    : () => changeCartItemQuantity(context, ref,
                                        cartEntryDoc: cartDoc,
                                        isIncreasing: false),
                                child: whiteSarabunBold('-'))),
                        Container(
                            decoration: BoxDecoration(
                                border: Border.all(
                                    color: CustomColors.nimbusCloud)),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              child: whiteSarabunBold(quantity.toString(),
                                  fontSize: 15),
                            )),
                        Container(
                            decoration: BoxDecoration(
                                border: Border.all(
                                    color: CustomColors.nimbusCloud)),
                            child: TextButton(
                                onPressed: quantity == remainingQuantity
                                    ? null
                                    : () => changeCartItemQuantity(context, ref,
                                        cartEntryDoc: cartDoc,
                                        isIncreasing: true),
                                child: whiteSarabunBold('+')))
                      ],
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
          const Gap(50),
          paymentMethod(ref),
          if (ref.read(cartProvider).selectedPaymentMethod.isNotEmpty)
            uploadPayment(ref),
          _checkoutButton()
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
      String productID = cartData[CartFields.itemID];
      num quantity = cartData[CartFields.quantity];
      DocumentSnapshot? productDoc = associatedProductDocs
          .where((item) => item.id == productID)
          .firstOrNull;
      if (productDoc == null) {
        continue;
      }
      final productData = productDoc.data() as Map<dynamic, dynamic>;
      num price = productData[ProductFields.price];
      totalAmount += quantity * price;
    }
    paidAmount = totalAmount;
    return whiteSarabunBold(
        'TOTAL AMOUNT: PHP ${formatPrice(totalAmount.toDouble())}');
  }

  Widget _checkoutButton() {
    return SizedBox(
      height: 60,
      child: ElevatedButton(
          onPressed: ref.read(cartProvider).selectedPaymentMethod.isEmpty ||
                  ref.read(cartProvider).selectedCartItemIDs.isEmpty
              ? null
              : () => _pickProofOfPayment(),
          style: ElevatedButton.styleFrom(
              disabledBackgroundColor: CustomColors.nimbusCloud),
          child: whiteSarabunBold('MAKE PAYMENT')),
    );
  }
}
