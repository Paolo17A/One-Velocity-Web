import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:one_velocity_web/providers/bookmarks_provider.dart';
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
import '../widgets/floating_chat_widget.dart';

class BookMarksScreen extends ConsumerStatefulWidget {
  const BookMarksScreen({super.key});

  @override
  ConsumerState<BookMarksScreen> createState() => _BookMarksScreenState();
}

class _BookMarksScreenState extends ConsumerState<BookMarksScreen>
    with TickerProviderStateMixin {
  late TabController tabController;
  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 2, vsync: this);
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
        ref
            .read(bookmarksProvider)
            .setBookmarkedProducts(userData[UserFields.bookmarkedProducts]);
        ref
            .read(bookmarksProvider)
            .setBookmarkedServices(userData[UserFields.bookmarkedServices]);
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
    return DefaultTabController(
      initialIndex: 0,
      length: 2,
      child: Scaffold(
        appBar: appBarWidget(context),
        backgroundColor: Colors.white,
        floatingActionButton: FloatingChatWidget(
            senderUID: FirebaseAuth.instance.currentUser!.uid,
            otherUID: adminID),
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
                        ref.read(loadingProvider),
                        Column(
                          children: [
                            TabBar(tabs: [
                              Tab(child: blackSarabunBold('PRODUCTS')),
                              Tab(child: blackSarabunBold('SERVICES'))
                            ]),
                            SizedBox(
                              width: MediaQuery.of(context).size.width * 0.8,
                              height: MediaQuery.of(context).size.height - 150,
                              child: TabBarView(
                                  physics: NeverScrollableScrollPhysics(),
                                  children: [
                                    bookmarkedProductsContainer(),
                                    bookmarkedServicesContainer()
                                  ]),
                            )
                          ],
                        )),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget bookmarkedProductsContainer() {
    return horizontal5Percent(context,
        child: (ref.read(bookmarksProvider).bookmarkedProducts.isNotEmpty)
            ? ListView.builder(
                shrinkWrap: true,
                itemCount:
                    ref.read(bookmarksProvider).bookmarkedProducts.length,
                itemBuilder: (context, index) {
                  return _favoriteProductEntry(
                      ref.read(bookmarksProvider).bookmarkedProducts[index]);
                })
            : Center(
                child: blackSarabunBold('YOU HAVE NO BOOKMARKED ITEMS',
                    fontSize: 24)));
  }

  Widget bookmarkedServicesContainer() {
    return horizontal5Percent(context,
        child: (ref.read(bookmarksProvider).bookmarkedServices.isNotEmpty)
            ? ListView.builder(
                shrinkWrap: true,
                itemCount:
                    ref.read(bookmarksProvider).bookmarkedServices.length,
                itemBuilder: (context, index) {
                  return _favoriteServiceEntry(
                      ref.read(bookmarksProvider).bookmarkedServices[index]);
                })
            : Center(
                child: blackSarabunBold('YOU HAVE NO BOOKMARKED SERVICES',
                    fontSize: 24)));
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
                      decoration: BoxDecoration(border: Border.all()),
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
                                  blackSarabunBold(name),
                                  blackSarabunBold(
                                      'SRP: PHP ${formatPrice(price.toDouble())}')
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

  Widget _favoriteServiceEntry(String serviceID) {
    return FutureBuilder(
        future: getThisServiceDoc(serviceID),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting ||
              !snapshot.hasData ||
              snapshot.hasError) return snapshotHandler(snapshot);
          final serviceData = snapshot.data!.data() as Map<dynamic, dynamic>;
          String name = serviceData[ServiceFields.name];
          List<dynamic> imageURLs = serviceData[ServiceFields.imageURLs];
          num price = serviceData[ServiceFields.price];

          return MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () {
                GoRouter.of(context).goNamed(GoRoutes.selectedService,
                    pathParameters: {PathParameters.serviceID: serviceID});
              },
              child: all10Pix(
                  child: Container(
                      decoration: BoxDecoration(border: Border.all()),
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
                                  blackSarabunBold(name),
                                  blackSarabunBold(
                                      'SRP: PHP ${formatPrice(price.toDouble())}')
                                ],
                              )
                            ],
                          ),
                          ElevatedButton(
                              onPressed: () => displayDeleteEntryDialog(context,
                                  message:
                                      'Are you sure you wish to remove this service from your bookmarks?',
                                  deleteEntry: () => removeBookmarkedService(
                                      context, ref,
                                      service: serviceID)),
                              child: Icon(Icons.delete, color: Colors.white))
                        ],
                      ))),
            ),
          );
        });
  }
}
