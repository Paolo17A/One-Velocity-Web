import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/loading_provider.dart';
import '../utils/firebase_util.dart';
import '../utils/go_router_util.dart';
import '../utils/string_util.dart';
import '../widgets/app_bar_widget.dart';
import '../widgets/custom_button_widgets.dart';
import '../widgets/custom_miscellaneous_widgets.dart';
import '../widgets/custom_padding_widgets.dart';
import '../widgets/left_navigator_widget.dart';
import '../widgets/text_widgets.dart';

class ViewProductsScreen extends ConsumerStatefulWidget {
  const ViewProductsScreen({super.key});

  @override
  ConsumerState<ViewProductsScreen> createState() => _ViewProductsScreenState();
}

class _ViewProductsScreenState extends ConsumerState<ViewProductsScreen> {
  List<DocumentSnapshot> allProductDocs = [];
  List<DocumentSnapshot> currentDisplayedProducts = [];
  int currentPage = 0;
  int maxPage = 0;
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
        allProductDocs = await getAllProducts();

        currentPage = 0;
        maxPage = (allProductDocs.length / 10).floor();
        if (allProductDocs.length % 10 == 0) maxPage--;
        setDisplayedProducts();
        ref.read(loadingProvider.notifier).toggleLoading(false);
      } catch (error) {
        scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('Error getting products: $error')));
        ref.read(loadingProvider.notifier).toggleLoading(false);
      }
    });
  }

  void setDisplayedProducts() {
    if (allProductDocs.length > 10) {
      currentDisplayedProducts = allProductDocs
          .getRange(currentPage * 10,
              min((currentPage * 10) + 10, allProductDocs.length))
          .toList();
    } else
      currentDisplayedProducts = allProductDocs;
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(loadingProvider);
    return Scaffold(
      appBar: appBarWidget(context, showActions: false),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          leftNavigator(context, path: GoRoutes.viewProducts),
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            child: switchedLoadingContainer(
                ref.read(loadingProvider),
                SingleChildScrollView(
                    child: horizontal5Percent(context,
                        child: Column(
                          children: [_addProductButton(), _productsContainer()],
                        )))),
          )
        ],
      ),
    );
  }

  Widget _addProductButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        blackSarabunBold('PRODUCTS', fontSize: 40),
        ElevatedButton(
            onPressed: () => GoRouter.of(context).goNamed(GoRoutes.addProduct),
            child: whiteSarabunBold('ADD NEW PRODUCT'))
      ]),
    );
  }

  Widget _productsContainer() {
    return viewContentContainer(
      context,
      child: Column(
        children: [
          _productLabelRow(),
          allProductDocs.isNotEmpty
              ? _productEntries()
              : viewContentUnavailable(context, text: 'NO AVAILABLE PRODUCTS'),
          if (allProductDocs.length > 10)
            pageNavigatorButtons(
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
                })
        ],
      ),
    );
  }

  Widget _productLabelRow() {
    return viewContentLabelRow(context, children: [
      viewFlexLabelTextCell('Name', 4,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(20))),
      viewFlexLabelTextCell('Category', 2),
      viewFlexLabelTextCell('Remaining Quantity', 2),
      viewFlexLabelTextCell('Actions', 2,
          borderRadius: BorderRadius.only(topRight: Radius.circular(20)))
    ]);
  }

  Widget _productEntries() {
    return Container(
        height: 500,
        decoration: BoxDecoration(border: Border.all()),
        child: ListView.builder(
            shrinkWrap: true,
            itemCount: currentDisplayedProducts.length,
            itemBuilder: (context, index) {
              return _productEntry(currentDisplayedProducts[index], index);
            }));
  }

  Widget _productEntry(DocumentSnapshot productDoc, int index) {
    final productData = productDoc.data() as Map<dynamic, dynamic>;
    String name = productData[ProductFields.name];
    String category = productData[ProductFields.category];
    num quantity = productData[ProductFields.quantity];
    Color entryColor = Colors.black;
    Color backgroundColor = Colors.white;
    return viewContentEntryRow(context, children: [
      viewFlexTextCell(name,
          flex: 4, backgroundColor: backgroundColor, textColor: entryColor),
      viewFlexTextCell(category,
          flex: 2, backgroundColor: backgroundColor, textColor: entryColor),
      viewFlexTextCell(quantity.toString(),
          flex: 2, backgroundColor: backgroundColor, textColor: entryColor),
      viewFlexActionsCell([
        viewEntryButton(context,
            onPress: () => GoRouter.of(context).goNamed(
                GoRoutes.selectedProduct,
                pathParameters: {PathParameters.productID: productDoc.id})),
        editEntryButton(context,
            onPress: () => GoRouter.of(context).goNamed(GoRoutes.editProduct,
                pathParameters: {PathParameters.productID: productDoc.id})),
      ], flex: 2, backgroundColor: backgroundColor)
    ]);
  }
}
