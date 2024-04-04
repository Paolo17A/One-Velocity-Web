import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:one_velocity_web/providers/bookmarks_provider.dart';
import 'package:one_velocity_web/utils/color_util.dart';
import 'package:one_velocity_web/utils/delete_entry_dialog_util.dart';
import 'package:one_velocity_web/widgets/app_bar_widget.dart';
import 'package:one_velocity_web/widgets/custom_miscellaneous_widgets.dart';
import 'package:one_velocity_web/widgets/custom_padding_widgets.dart';
import 'package:one_velocity_web/widgets/left_navigator_widget.dart';
import 'package:one_velocity_web/widgets/text_widgets.dart';

import '../providers/loading_provider.dart';
import '../utils/firebase_util.dart';
import '../utils/go_router_util.dart';
import '../utils/string_util.dart';

class BookMarksScreen extends ConsumerStatefulWidget {
  const BookMarksScreen({super.key});

  @override
  ConsumerState<BookMarksScreen> createState() => _BookMarksScreenState();
}

class _BookMarksScreenState extends ConsumerState<BookMarksScreen> {
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
          ref.read(loadingProvider.notifier).toggleLoading(false);
          return;
        }
        final userDoc = await getCurrentUserDoc();
        final userData = userDoc.data() as Map<dynamic, dynamic>;
        if (userData[UserFields.userType] == UserTypes.admin) {
          goRouter.goNamed(GoRoutes.home);
          ref.read(loadingProvider.notifier).toggleLoading(false);
          return;
        }
        ref.read(bookmarksProvider).bookmarkedProducts =
            userData[UserFields.bookmarkedProducts];
        ref.read(loadingProvider.notifier).toggleLoading(false);
      } catch (error) {
        scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('Error getting user profile: $error')));
        ref.read(loadingProvider.notifier).toggleLoading(false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(loadingProvider);
    ref.watch(bookmarksProvider);
    return Scaffold(
      appBar: appBarWidget(context),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            secondAppBar(context),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                clientProfileNavigator(context, path: GoRoutes.bookmarks),
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.8,
                  child: switchedLoadingContainer(
                      ref.read(loadingProvider), bookmarksContainer()),
                )
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget bookmarksContainer() {
    return horizontal5Percent(context,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Gap(40),
            montserratBlackBold('BOOKMARKED PRODUCTS', fontSize: 40),
            if (ref.read(bookmarksProvider).bookmarkedProducts.isNotEmpty)
              ListView.builder(
                  shrinkWrap: true,
                  itemCount:
                      ref.read(bookmarksProvider).bookmarkedProducts.length,
                  itemBuilder: (context, index) {
                    return _favoriteProductEntry(
                        ref.read(bookmarksProvider).bookmarkedProducts[index]);
                  })
            else
              Center(
                  child: montserratBlackBold('YOU HAVE NO BOOKMARKED ITEMS',
                      fontSize: 24))
          ],
        ));
  }

  Widget _favoriteProductEntry(String productID) {
    return FutureBuilder(
        future: getThisProductDoc(productID),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting ||
              !snapshot.hasData ||
              snapshot.hasError) return snapshotHandler(snapshot);
          final productData = snapshot.data!.data() as Map<dynamic, dynamic>;
          String name = productData[ProductFields.name];
          List<dynamic> imageURLs = productData[ProductFields.imageURLs];
          num price = productData[ProductFields.price];

          return MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () {
                GoRouter.of(context).goNamed(GoRoutes.selectedProduct,
                    pathParameters: {PathParameters.productID: productID});
              },
              child: all10Pix(
                  child: Container(
                      decoration:
                          BoxDecoration(color: CustomColors.ultimateGray),
                      padding: EdgeInsets.all(10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
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
                                  montserratWhiteBold(name),
                                  montserratWhiteBold(
                                      'SRP: ${price.toStringAsFixed(2)}')
                                ],
                              )
                            ],
                          ),
                          ElevatedButton(
                              onPressed: () => displayDeleteEntryDialog(context,
                                  message:
                                      'Are you sure you wish to remove this product from your bookmarks?',
                                  deleteEntry: () => removeBookmarkedProduct(
                                      context, ref,
                                      productID: productID)),
                              child: Icon(Icons.delete, color: Colors.white))
                        ],
                      ))),
            ),
          );
        });
  }
}
