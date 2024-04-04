import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:one_velocity_web/widgets/text_widgets.dart';

import '../providers/loading_provider.dart';
import '../providers/pages_provider.dart';
import '../utils/firebase_util.dart';
import '../utils/go_router_util.dart';
import '../utils/string_util.dart';
import '../widgets/app_bar_widget.dart';
import '../widgets/custom_button_widgets.dart';
import '../widgets/custom_miscellaneous_widgets.dart';
import '../widgets/custom_padding_widgets.dart';
import '../widgets/item_entry_widget.dart';

class ShopProductsScreen extends ConsumerStatefulWidget {
  const ShopProductsScreen({super.key});

  @override
  ConsumerState<ShopProductsScreen> createState() => _ShopProductsScreenState();
}

class _ShopProductsScreenState extends ConsumerState<ShopProductsScreen> {
  List<DocumentSnapshot> allProductDocs = [];

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
        allProductDocs = await getAllProducts();
        ref.read(pagesProvider.notifier).setCurrentPage(1);
        ref
            .read(pagesProvider.notifier)
            .setMaxPage((allProductDocs.length / 20).ceil());
        ref.read(loadingProvider.notifier).toggleLoading(false);
      } catch (error) {
        scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('Error getting all services: $error')));
        ref.read(loadingProvider.notifier).toggleLoading(false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(loadingProvider);
    return Scaffold(
      appBar: appBarWidget(context),
      body: switchedLoadingContainer(
          ref.read(loadingProvider),
          SingleChildScrollView(
            child: Column(
              children: [
                secondAppBar(context),
                horizontal5Percent(context,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [productsHeader(), _availableProducts()],
                    ))
              ],
            ),
          )),
    );
  }

  Widget productsHeader() {
    return Row(children: [
      montserratBlackBold('ALL AVAILABLE PRODUCTS', fontSize: 60)
    ]);
  }

  Widget _availableProducts() {
    int currentPage = ref.read(pagesProvider.notifier).getCurrentPage();
    int maxPage = ref.read(pagesProvider.notifier).getMaxPage();
    return Column(
      children: [
        all20Pix(
            child: allProductDocs.isNotEmpty
                ? Wrap(
                    alignment: currentPage == maxPage
                        ? WrapAlignment.start
                        : WrapAlignment.spaceEvenly,
                    spacing: 10,
                    runSpacing: 10,
                    children: allProductDocs.map((item) {
                      return itemEntry(context,
                          itemDoc: item,
                          onPress: () => GoRouter.of(context).goNamed(
                                  GoRoutes.selectedProduct,
                                  pathParameters: {
                                    PathParameters.productID: item.id
                                  }));
                    }).toList())
                : montserratBlackBold('NO PRODUCTS AVAILABLE', fontSize: 44)),
        if (allProductDocs.length > 20)
          navigatorButtons(context,
              pageNumber: currentPage,
              onPrevious: () => currentPage == 1
                  ? null
                  : ref
                      .read(pagesProvider.notifier)
                      .setCurrentPage(currentPage + 1),
              onNext: () => currentPage == maxPage
                  ? null
                  : ref
                      .read(pagesProvider.notifier)
                      .setCurrentPage(currentPage - 1))
      ],
    );
  }
}
