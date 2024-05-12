import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:one_velocity_web/providers/bookmarks_provider.dart';
import 'package:one_velocity_web/providers/cart_provider.dart';
import 'package:one_velocity_web/widgets/text_widgets.dart';

import '../providers/loading_provider.dart';
import '../providers/pages_provider.dart';
import '../utils/firebase_util.dart';
import '../utils/go_router_util.dart';
import '../utils/string_util.dart';
import '../widgets/app_bar_widget.dart';
import '../widgets/custom_miscellaneous_widgets.dart';
import '../widgets/custom_padding_widgets.dart';

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      ref.read(loadingProvider.notifier).toggleLoading(true);
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      final goRouter = GoRouter.of(context);
      try {
        if (hasLoggedInUser() &&
            await getCurrentUserType() == UserTypes.admin) {
          goRouter.goNamed(GoRoutes.home);
          return;
        }
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
              .read(bookmarksProvider)
              .setBookmarkedProducts(userData[UserFields.bookmarkedProducts]);

          ref.read(cartProvider).setCartItems(await getCartEntries(context));
        }

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
      body: Column(
        children: [
          secondAppBar(context),
          switchedLoadingContainer(
              ref.read(loadingProvider),
              SingleChildScrollView(
                child: horizontal5Percent(context, child: _productContainer()),
              ))
        ],
      ),
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
                        montserratBlackBold(name, fontSize: 60),
                        montserratBlackBold('PHP ${price.toStringAsFixed(2)}',
                            fontSize: 40),
                        montserratBlackRegular('Category: $category',
                            fontSize: 30),
                        Gap(30),
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
                            montserratBlackRegular(ref
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
                                  shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.zero),
                                  disabledBackgroundColor: Colors.blueGrey),
                              child: montserratWhiteRegular('ADD TO CART',
                                  textAlign: TextAlign.center)),
                        ),
                        vertical10Pix(
                          child: montserratBlackBold(
                              'Remaining Quantity: $quantity',
                              fontSize: 16),
                        ),
                      ],
                    ),
                    all20Pix(child: montserratBlackRegular(description)),
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
    return Column(
      children: [
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () {
              showOtherPics();
            },
            child: Column(
              children: [
                Container(
                  width: MediaQuery.of(context).size.width * 0.25,
                  height: MediaQuery.of(context).size.width * 0.25,
                  decoration: BoxDecoration(
                      border: Border.all(),
                      image: DecorationImage(
                          fit: BoxFit.fill,
                          image: NetworkImage(imageURLs[currentImageIndex]))),
                ),
              ],
            ),
          ),
        ),
        if (imageURLs.length > 1)
          vertical10Pix(
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.2,
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                        onPressed: () => currentImageIndex == 0
                            ? null
                            : ref
                                .read(pagesProvider.notifier)
                                .setCurrentPage(currentImageIndex - 1),
                        child: const Icon(Icons.arrow_left)),
                    TextButton(
                        onPressed: () =>
                            currentImageIndex == imageURLs.length - 1
                                ? null
                                : ref
                                    .read(pagesProvider.notifier)
                                    .setCurrentPage(currentImageIndex + 1),
                        child: const Icon(Icons.arrow_right))
                  ]),
            ),
          )
      ],
    );
  }

  void showOtherPics() {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
                content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.7,
              height: MediaQuery.of(context).size.height * 0.7,
              child: Column(children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                        onPressed: () => GoRouter.of(context).pop(),
                        child: montserratBlackBold('X'))
                  ],
                ),
                Container(
                  width: MediaQuery.of(context).size.height * 0.65,
                  height: MediaQuery.of(context).size.height * 0.65,
                  decoration: BoxDecoration(
                      image: DecorationImage(
                          image: NetworkImage(imageURLs[currentImageIndex]),
                          fit: BoxFit.fill)),
                ),
              ]),
            )));
  }
}
