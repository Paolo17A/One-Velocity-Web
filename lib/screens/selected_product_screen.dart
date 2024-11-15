import 'package:carousel_slider/carousel_controller.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:one_velocity_web/providers/bookmarks_provider.dart';
import 'package:one_velocity_web/providers/cart_provider.dart';
import 'package:one_velocity_web/providers/user_type_provider.dart';
import 'package:one_velocity_web/utils/color_util.dart';
import 'package:one_velocity_web/utils/go_router_util.dart';
import 'package:one_velocity_web/widgets/custom_button_widgets.dart';
import 'package:one_velocity_web/widgets/left_navigator_widget.dart';
import 'package:one_velocity_web/widgets/text_widgets.dart';

import '../providers/loading_provider.dart';
import '../providers/pages_provider.dart';
import '../utils/firebase_util.dart';
import '../utils/string_util.dart';
import '../widgets/app_bar_widget.dart';
import '../widgets/custom_miscellaneous_widgets.dart';
import '../widgets/custom_padding_widgets.dart';
import '../widgets/floating_chat_widget.dart';

class SelectedProductScreen extends ConsumerStatefulWidget {
  final String productID;
  const SelectedProductScreen({super.key, required this.productID});

  @override
  ConsumerState<SelectedProductScreen> createState() =>
      _SelectedProductScreenState();
}

class _SelectedProductScreenState extends ConsumerState<SelectedProductScreen> {
  //  PRODUCT VARIABLES
  String name = '';
  String description = '';
  String category = '';
  num price = 0;
  num quantity = 0;
  List<dynamic> imageURLs = [];
  int currentImageIndex = 0;
  List<DocumentSnapshot> purchaseDocs = [];
  List<DocumentSnapshot> relatedProductDocs = [];
  CarouselSliderController relatedProductsController =
      CarouselSliderController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      ref.read(loadingProvider.notifier).toggleLoading(true);
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      try {
        //  GET PRODUCT DATA
        final product = await getThisProductDoc(widget.productID);
        final productData = product.data() as Map<dynamic, dynamic>;
        name = productData[ProductFields.name];
        description = productData[ProductFields.description];
        category = productData[ProductFields.category];
        quantity = productData[ProductFields.quantity];
        price = productData[ProductFields.price];
        imageURLs = productData[ProductFields.imageURLs];
        ref.read(pagesProvider.notifier).setCurrentPage(0);
        ref.read(pagesProvider.notifier).setMaxPage(imageURLs.length);

        //  GET USER DATA
        if (hasLoggedInUser()) {
          final user = await getCurrentUserDoc();
          final userData = user.data() as Map<dynamic, dynamic>;
          ref
              .read(userTypeProvider.notifier)
              .setUserType(userData[UserFields.userType]);
          if (ref.read(userTypeProvider) == UserTypes.client) {
            ref
                .read(bookmarksProvider)
                .setBookmarkedProducts(userData[UserFields.bookmarkedProducts]);

            ref
                .read(cartProvider)
                .setCartItems(await getProductCartEntries(context));
          } else if (ref.read(userTypeProvider) == UserTypes.admin) {
            purchaseDocs = await getProductPurchaseHistory(widget.productID);

            // FIXERS FOR OUTDATED ENTRIES
            for (var purchaseDoc in purchaseDocs) {
              final purchaseData = purchaseDoc.data() as Map<dynamic, dynamic>;
              if (!purchaseData.containsKey(PurchaseFields.dateCreated) &&
                  purchaseData.containsKey(PurchaseFields.paymentID)) {
                final payment = await getThisPaymentDoc(
                    purchaseData[PurchaseFields.paymentID]);
                final paymentData = payment.data() as Map<dynamic, dynamic>;
                final dateCreated = paymentData[PurchaseFields.dateCreated];
                await FirebaseFirestore.instance
                    .collection(Collections.purchases)
                    .doc(purchaseDoc.id)
                    .update({PurchaseFields.dateCreated: dateCreated});
              }
            }

            purchaseDocs.sort((a, b) {
              DateTime aTime =
                  (a[PurchaseFields.dateCreated] as Timestamp).toDate();
              DateTime bTime =
                  (b[PurchaseFields.dateCreated] as Timestamp).toDate();
              return bTime.compareTo(aTime);
            });
          }
        }
        relatedProductDocs = await getAllProducts();
        setState(() {
          relatedProductDocs = relatedProductDocs.where((product) {
            final productData = product.data() as Map<dynamic, dynamic>;
            String thisCategory = productData[ProductFields.category];
            return category == thisCategory;
          }).toList();
        });

        ref.read(loadingProvider.notifier).toggleLoading(false);
      } catch (error) {
        scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('Error getting selected product: $error')));
        ref.read(loadingProvider.notifier).toggleLoading(false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(loadingProvider);
    ref.watch(bookmarksProvider);
    ref.watch(cartProvider);
    currentImageIndex = ref.watch(pagesProvider.notifier).getCurrentPage();
    return Scaffold(
      appBar: appBarWidget(context),
      floatingActionButton:
          hasLoggedInUser() && ref.read(userTypeProvider) == UserTypes.client
              ? FloatingChatWidget(
                  senderUID: FirebaseAuth.instance.currentUser!.uid,
                  otherUID: adminID)
              : null,
      body: SingleChildScrollView(
        child: Column(
          children: [
            if (!hasLoggedInUser() ||
                ref.read(userTypeProvider) == UserTypes.client)
              _regularUserWidgets()
            else
              _adminWidgets()
          ],
        ),
      ),
    );
  }

  //============================================================================
  //ADMIN WIDGETS=============================================================
  //============================================================================

  Widget _adminWidgets() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        leftNavigator(context, path: GoRoutes.viewProducts),
        SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          child: switchedLoadingContainer(
              ref.read(loadingProvider),
              SingleChildScrollView(
                  child: Column(
                children: [
                  _backButton(),
                  horizontal5Percent(context,
                      child: Column(
                        children: [
                          _adminProductContainer(),
                          _adminProductPurchaseHistory()
                        ],
                      )),
                ],
              ))),
        )
      ],
    );
  }

  Widget _backButton() {
    return all20Pix(
      child: Row(
        children: [
          backButton(context,
              onPress: () =>
                  GoRouter.of(context).goNamed(GoRoutes.viewProducts))
        ],
      ),
    );
  }

  Widget _adminProductContainer() {
    return Container(
      decoration: BoxDecoration(border: Border.all()),
      padding: EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imageURLs.isNotEmpty)
            Container(
              width: MediaQuery.of(context).size.width * 0.1,
              height: MediaQuery.of(context).size.width * 0.1,
              decoration: BoxDecoration(
                  border: Border.all(),
                  image: DecorationImage(
                      fit: BoxFit.fill,
                      image: NetworkImage(imageURLs[currentImageIndex]))),
            ),
          Gap(12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              blackSarabunBold(name, fontSize: 40),
              blackSarabunRegular('PHP ${price.toStringAsFixed(2)}',
                  fontSize: 28),
              blackSarabunRegular('Category: $category', fontSize: 28),
            ],
          ),
        ],
      ),
    );
  }

  Widget _adminProductPurchaseHistory() {
    return vertical10Pix(
        child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        blackSarabunBold('PURCHASE HISTORY', fontSize: 28),
        Container(
          width: double.infinity,
          height: purchaseDocs.isEmpty ? 500 : null,
          child: purchaseDocs.isNotEmpty
              ? ListView.builder(
                  shrinkWrap: true,
                  itemCount: purchaseDocs.length,
                  itemBuilder: (context, index) =>
                      _purchaseHistoryEntry(purchaseDocs[index]))
              : Center(
                  child: blackSarabunBold(
                      'This product has not yet been purchased')),
        ),
      ],
    ));
  }

  Widget _purchaseHistoryEntry(DocumentSnapshot purchaseDoc) {
    final purchaseData = purchaseDoc.data() as Map<dynamic, dynamic>;
    num quantity = purchaseData[PurchaseFields.quantity];
    DateTime dateCreated =
        (purchaseData[PurchaseFields.dateCreated] as Timestamp).toDate();
    String purchaseStatus = purchaseData[PurchaseFields.purchaseStatus];
    String clientID = purchaseData[PurchaseFields.clientID];
    return FutureBuilder(
      future: getThisUserDoc(clientID),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting ||
            !snapshot.hasData ||
            snapshot.hasError) return snapshotHandler(snapshot);
        final userData = snapshot.data!.data() as Map<dynamic, dynamic>;
        String profileImageURL = userData[UserFields.profileImageURL];
        String formattedName =
            '${userData[UserFields.firstName]} ${userData[UserFields.lastName]}';
        return Container(
            decoration: BoxDecoration(border: Border.all()),
            padding: EdgeInsets.all(8),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              buildProfileImage(profileImageURL: profileImageURL, radius: 50),
              Gap(12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                blackSarabunBold(formattedName, fontSize: 20),
                blackSarabunRegular('Quantity: $quantity', fontSize: 12),
                blackSarabunRegular(
                    'Date Purchased: ${DateFormat('MMM dd, yyyy').format(dateCreated)}',
                    fontSize: 12),
                blackSarabunRegular('Status: $purchaseStatus', fontSize: 12),
              ])
            ]));
      },
    );
  }

  //============================================================================
  //REGULAR WIDGETS=============================================================
  //============================================================================

  Widget _regularUserWidgets() {
    return Column(
      children: [
        secondAppBar(context),
        switchedLoadingContainer(
            ref.read(loadingProvider),
            SingleChildScrollView(
              child: Column(
                children: [
                  horizontal5Percent(context, child: _productContainer()),
                  Divider(),
                  if (relatedProductDocs.isNotEmpty)
                    itemRowTemplate(context,
                        label: 'Related Products',
                        itemDocs: relatedProductDocs.take(5).toList(),
                        itemType: 'PRODUCT')
                ],
              ),
            ))
      ],
    );
  }

  Widget _productContainer() {
    return vertical20Pix(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (imageURLs.isNotEmpty) _itemImagesDisplay(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        blackSarabunBold(name, fontSize: 52),
                        crimsonSarabunBold(
                            'PHP ${formatPrice(price.toDouble())}',
                            fontSize: 40),
                        blackSarabunRegular('Category: $category',
                            fontSize: 30),
                        Gap(20),
                        Row(
                          children: [
                            IconButton(
                                onPressed: () => ref
                                        .read(bookmarksProvider)
                                        .bookmarkedProducts
                                        .contains(widget.productID)
                                    ? removeBookmarkedProduct(context, ref,
                                        productID: widget.productID)
                                    : addBookmarkedProduct(context, ref,
                                        productID: widget.productID),
                                icon: Icon(ref
                                        .read(bookmarksProvider)
                                        .bookmarkedProducts
                                        .contains(widget.productID)
                                    ? Icons.bookmark
                                    : Icons.bookmark_outline)),
                            blackSarabunRegular(ref
                                    .read(bookmarksProvider)
                                    .bookmarkedProducts
                                    .contains(widget.productID)
                                ? 'Remove from Bookmarks'
                                : 'Add to Bookmarks')
                          ],
                        ),
                        SizedBox(
                          height: 40,
                          child: ElevatedButton(
                              onPressed: quantity > 0
                                  ? () => addProductToCart(context, ref,
                                      productID: widget.productID)
                                  : null,
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: CustomColors.crimson,
                                  disabledBackgroundColor: Colors.blueGrey),
                              child: whiteSarabunRegular('ADD TO CART',
                                  textAlign: TextAlign.center)),
                        ),
                        vertical10Pix(
                          child: blackSarabunBold(
                              'Remaining Quantity: $quantity',
                              fontSize: 16),
                        ),
                      ],
                    ),
                    vertical10Pix(
                        child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        blackSarabunBold('Description:'),
                        SizedBox(
                            width: MediaQuery.of(context).size.width * 0.6,
                            child: blackSarabunRegular(description,
                                textAlign: TextAlign.justify)),
                      ],
                    )),
                  ],
                ),
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _itemImagesDisplay() {
    List<dynamic> otherImages = [];
    if (imageURLs.length > 1) otherImages = imageURLs.sublist(1);
    return Column(
      children: [
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => showOtherPics(context, imageURL: imageURLs.first),
            child: Column(
              children: [
                Container(
                  width: MediaQuery.of(context).size.width * 0.25,
                  height: MediaQuery.of(context).size.width * 0.25,
                  decoration: BoxDecoration(
                      border: Border.all(),
                      image: DecorationImage(
                          fit: BoxFit.fill,
                          image: NetworkImage(imageURLs.first))),
                ),
              ],
            ),
          ),
        ),
        SizedBox(
          width: MediaQuery.of(context).size.width * 0.25,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
                mainAxisSize: MainAxisSize.min,
                children: otherImages
                    .map((otherImage) => all10Pix(
                            child: GestureDetector(
                          onTap: () =>
                              showOtherPics(context, imageURL: otherImage),
                          child: Container(
                              decoration: BoxDecoration(border: Border.all()),
                              child: square80NetworkImage(otherImage)),
                        )))
                    .toList()),
          ),
        )
        /*all10Pix(
          child: Row(
              children: List.generate(
                  5, (index) => Icon(Icons.star, color: CustomColors.crimson))),
        )*/
      ],
    );
  }
}
