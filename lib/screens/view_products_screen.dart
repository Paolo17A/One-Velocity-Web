import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/loading_provider.dart';
import '../providers/pages_provider.dart';
import '../utils/color_util.dart';
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

        ref.read(pagesProvider.notifier).setCurrentPage(1);
        ref
            .read(pagesProvider.notifier)
            .setMaxPage((allProductDocs.length / 10).ceil());
        ref.read(loadingProvider.notifier).toggleLoading(false);
      } catch (error) {
        scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('Error getting products: $error')));
        ref.read(loadingProvider.notifier).toggleLoading(false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(loadingProvider);
    ref.watch(pagesProvider);
    return Scaffold(
      appBar: appBarWidget(context, showActions: false),
      body: Row(
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
      child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
        ElevatedButton(
            onPressed: () => GoRouter.of(context).goNamed(GoRoutes.addProduct),
            child: montserratWhiteBold('ADD NEW PRODUCT'))
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
        ],
      ),
    );
  }

  Widget _productLabelRow() {
    return viewContentLabelRow(context, children: [
      viewFlexLabelTextCell('Name', 4),
      viewFlexLabelTextCell('Remaining Quantity', 2),
      viewFlexLabelTextCell('Actions', 2)
    ]);
  }

  Widget _productEntries() {
    return SizedBox(
        height: MediaQuery.of(context).size.height * 0.65,
        child: ListView.builder(
            shrinkWrap: true,
            itemCount: ref.read(pagesProvider.notifier).getCurrentPage() ==
                        ref.read(pagesProvider.notifier).getMaxPage() &&
                    allProductDocs.length % 10 != 0
                ? allProductDocs.length % 10
                : 10,
            itemBuilder: (context, index) {
              return _productEntry(
                  allProductDocs[index +
                      ((ref.read(pagesProvider.notifier).getCurrentPage() - 1) *
                          10)],
                  index);
            }));
  }

  Widget _productEntry(DocumentSnapshot productDoc, int index) {
    final productData = productDoc.data() as Map<dynamic, dynamic>;
    String name = productData[ProductFields.name];
    num quantity = productData[ProductFields.quantity];
    Color entryColor = Colors.black;
    Color backgroundColor = index % 2 == 0
        ? CustomColors.ultimateGray.withOpacity(0.5)
        : CustomColors.nimbusCloud;
    return viewContentEntryRow(context, children: [
      viewFlexTextCell(name,
          flex: 4, backgroundColor: backgroundColor, textColor: entryColor),
      viewFlexTextCell(quantity.toString(),
          flex: 2, backgroundColor: backgroundColor, textColor: entryColor),
      viewFlexActionsCell([
        editEntryButton(context,
            onPress: () => GoRouter.of(context).goNamed(GoRoutes.editProduct,
                pathParameters: {PathParameters.productID: productDoc.id})),
        /*deleteEntryButton(context,
            onPress: () => displayDeleteEntryDialog(context,
                message: 'Are you sure you wish to remove this product?',
                deleteEntry: () {}))*/
      ], flex: 2, backgroundColor: backgroundColor)
    ]);
  }
}
