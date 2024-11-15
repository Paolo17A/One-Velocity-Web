import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:one_velocity_web/providers/category_provider.dart';
import 'package:one_velocity_web/providers/pages_provider.dart';
import 'package:one_velocity_web/utils/color_util.dart';
import 'package:one_velocity_web/widgets/text_widgets.dart';

import '../providers/loading_provider.dart';
import '../utils/firebase_util.dart';
import '../utils/go_router_util.dart';
import '../utils/string_util.dart';
import '../widgets/app_bar_widget.dart';
import '../widgets/custom_button_widgets.dart';
import '../widgets/custom_miscellaneous_widgets.dart';
import '../widgets/custom_padding_widgets.dart';
import '../widgets/floating_chat_widget.dart';
import '../widgets/item_entry_widget.dart';

class ShopProductsScreen extends ConsumerStatefulWidget {
  const ShopProductsScreen({super.key});

  @override
  ConsumerState<ShopProductsScreen> createState() => _ShopProductsScreenState();
}

class _ShopProductsScreenState extends ConsumerState<ShopProductsScreen> {
  List<DocumentSnapshot> allProductDocs = [];
  List<DocumentSnapshot> filteredProductDocs = [];
  List<DocumentSnapshot> currentlyDisplayedFilteredProducts = [];
  int currentPage = 0;
  int maxPage = 0;
  int productsPerPage = 8;

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
          ref.read(loadingProvider.notifier).toggleLoading(false);
          goRouter.goNamed(GoRoutes.home);
          return;
        }
        allProductDocs = await getAllProducts();
        setFilteredProducts();

        ref.read(loadingProvider.notifier).toggleLoading(false);
      } catch (error) {
        scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('Error getting all services: $error')));
        ref.read(loadingProvider.notifier).toggleLoading(false);
      }
    });
  }

  void setFilteredProducts() {
    currentPage = 0;
    String currentCategory = ref.read(categoryProvider).currentCategory;
    setState(() {
      if (currentCategory == 'VIEW ALL') {
        filteredProductDocs = allProductDocs;
      } else {
        filteredProductDocs = allProductDocs.where((product) {
          final productData = product.data() as Map<dynamic, dynamic>;
          String category = productData[ProductFields.category];
          return category == currentCategory;
        }).toList();
      }
      maxPage = (filteredProductDocs.length / productsPerPage).floor();
      if (filteredProductDocs.length % productsPerPage == 0) maxPage--;
    });
    setDisplayedProducts();
  }

  void setDisplayedProducts() {
    if (filteredProductDocs.length > productsPerPage) {
      currentlyDisplayedFilteredProducts = filteredProductDocs
          .getRange(
              currentPage * productsPerPage,
              min((currentPage * productsPerPage) + productsPerPage,
                  filteredProductDocs.length))
          .toList();
    } else
      currentlyDisplayedFilteredProducts = filteredProductDocs;
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(loadingProvider);
    ref.watch(categoryProvider);
    ref.watch(pagesProvider);
    return Scaffold(
      appBar: appBarWidget(context),
      floatingActionButton: hasLoggedInUser()
          ? FloatingChatWidget(
              senderUID: FirebaseAuth.instance.currentUser!.uid,
              otherUID: adminID)
          : null,
      body: switchedLoadingContainer(
          ref.read(loadingProvider),
          Column(
            children: [
              secondAppBar(context),
              SizedBox(
                height: MediaQuery.of(context).size.height - 100,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _productCategoryWidget(),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.8,
                      height: MediaQuery.of(context).size.height * 0.9,
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                productsHeader(),
                                _availableProducts(),
                                if (filteredProductDocs.length >
                                    productsPerPage)
                                  all20Pix(
                                    child: pageNavigatorButtons(
                                        currentPage: currentPage,
                                        maxPage: maxPage,
                                        onPreviousPage: () {
                                          currentPage--;
                                          setState(() {
                                            setDisplayedProducts();
                                          });
                                        },
                                        onNextPage: () {
                                          currentPage++;
                                          setState(() {
                                            setDisplayedProducts();
                                          });
                                        }),
                                  )
                              ],
                            ),
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ],
          )),
    );
  }

  Widget productsHeader() {
    return blackSarabunBold(
        '${ref.read(categoryProvider).currentCategory == 'VIEW ALL' ? 'ALL PRODUCTS' : '${ref.read(categoryProvider).currentCategory} PRODUCTS'}',
        fontSize: 40);
  }

  Widget _productCategoryWidget() {
    return Container(
      width: MediaQuery.of(context).size.width * 0.2,
      height: MediaQuery.of(context).size.height - 60,
      color: CustomColors.crimson,
      child: all20Pix(
          child: ListView(
              shrinkWrap: false,
              physics: NeverScrollableScrollPhysics(),
              children: [
            Container(
              color: ref.read(categoryProvider).currentCategory == "VIEW ALL"
                  ? CustomColors.grenadine
                  : CustomColors.crimson,
              child: ListTile(
                  title:
                      Text('VIEW ALL', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    ref.read(categoryProvider).setCategory('VIEW ALL');
                    setFilteredProducts();
                  }),
            ),
            Container(
              color: ref.read(categoryProvider).currentCategory ==
                      ProductCategories.wheel
                  ? CustomColors.grenadine
                  : CustomColors.crimson,
              child: ListTile(
                  title: Text(ProductCategories.wheel,
                      style: TextStyle(color: Colors.white)),
                  onTap: () {
                    ref
                        .read(categoryProvider)
                        .setCategory(ProductCategories.wheel);
                    setFilteredProducts();
                  }),
            ),
            Container(
              color: ref.read(categoryProvider).currentCategory ==
                      ProductCategories.battery
                  ? CustomColors.grenadine
                  : CustomColors.crimson,
              child: ListTile(
                  title: Text(ProductCategories.battery,
                      style: TextStyle(color: Colors.white)),
                  onTap: () {
                    ref
                        .read(categoryProvider)
                        .setCategory(ProductCategories.battery);
                    setFilteredProducts();
                  }),
            ),
            Container(
              color: ref.read(categoryProvider).currentCategory ==
                      ProductCategories.accessory
                  ? CustomColors.grenadine
                  : CustomColors.crimson,
              child: ListTile(
                  title: Text(ProductCategories.accessory,
                      style: TextStyle(color: Colors.white)),
                  onTap: () {
                    ref
                        .read(categoryProvider)
                        .setCategory(ProductCategories.accessory);
                    setFilteredProducts();
                  }),
            ),
            Container(
              color: ref.read(categoryProvider).currentCategory ==
                      ProductCategories.others
                  ? CustomColors.grenadine
                  : CustomColors.crimson,
              child: ListTile(
                  title: Text(ProductCategories.others,
                      style: TextStyle(color: Colors.white)),
                  onTap: () {
                    ref
                        .read(categoryProvider)
                        .setCategory(ProductCategories.others);
                    setFilteredProducts();
                  }),
            ),
          ])),
    );
  }

  Widget _availableProducts() {
    return SizedBox(
      height: currentlyDisplayedFilteredProducts.isEmpty
          ? MediaQuery.of(context).size.height * 0.9
          : null,
      child: all20Pix(
          child: currentlyDisplayedFilteredProducts.isNotEmpty
              ? Wrap(
                  alignment: WrapAlignment.start,
                  spacing: 100,
                  runSpacing: 100,
                  children: currentlyDisplayedFilteredProducts.map((item) {
                    return itemEntry(context,
                        itemDoc: item,
                        onPress: () => GoRouter.of(context).goNamed(
                                GoRoutes.selectedProduct,
                                pathParameters: {
                                  PathParameters.productID: item.id
                                }));
                  }).toList())
              : Center(
                  child:
                      blackSarabunBold('NO PRODUCTS AVAILABLE', fontSize: 32))),
    );
  }
}
