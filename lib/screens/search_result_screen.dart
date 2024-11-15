import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:one_velocity_web/main.dart';
import 'package:one_velocity_web/providers/user_type_provider.dart';
import 'package:one_velocity_web/widgets/app_bar_widget.dart';
import 'package:one_velocity_web/widgets/item_entry_widget.dart';
import 'package:one_velocity_web/widgets/text_widgets.dart';
import '../providers/loading_provider.dart';
import '../utils/firebase_util.dart';
import '../utils/go_router_util.dart';
import '../utils/string_util.dart';
import '../widgets/custom_miscellaneous_widgets.dart';
import '../widgets/custom_padding_widgets.dart';

class SearchResultScreen extends ConsumerStatefulWidget {
  final String searchInput;
  const SearchResultScreen({super.key, required this.searchInput});

  @override
  ConsumerState<SearchResultScreen> createState() => _SearchResultScreenState();
}

class _SearchResultScreenState extends ConsumerState<SearchResultScreen> {
  List<Widget> itemWidgets = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      MyApp.searchController.text = widget.searchInput;
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      final goRouter = GoRouter.of(context);
      try {
        ref.read(loadingProvider.notifier).toggleLoading(true);

        if (hasLoggedInUser()) {
          final userDoc = await getCurrentUserDoc();
          final userData = userDoc.data() as Map<dynamic, dynamic>;
          String userType = userData[UserFields.userType];
          ref.read(userTypeProvider.notifier).setUserType(userType);
          if (ref.read(userTypeProvider) == UserTypes.admin) {
            ref.read(loadingProvider.notifier).toggleLoading(false);
            goRouter.goNamed(GoRoutes.home);
            return;
          }
        }

        List<DocumentSnapshot> itemDocs =
            await searchForTheseProducts(widget.searchInput);
        print('products found: ${itemDocs.length}');
        itemDocs.forEach((item) {
          itemWidgets.add(itemEntry(context, itemDoc: item, onPress: () {
            GoRouter.of(context).goNamed(GoRoutes.selectedProduct,
                pathParameters: {PathParameters.productID: item.id});
            GoRouter.of(context).pushNamed(GoRoutes.selectedProduct,
                pathParameters: {PathParameters.productID: item.id});
          }));
        });
        print('MADE IT HERE');
        itemDocs = await searchForTheseServices(widget.searchInput);
        itemDocs.forEach((item) {
          itemWidgets.add(itemEntry(context, itemDoc: item, onPress: () {
            GoRouter.of(context).goNamed(GoRoutes.selectedService,
                pathParameters: {PathParameters.serviceID: item.id});
            GoRouter.of(context).pushNamed(GoRoutes.selectedService,
                pathParameters: {PathParameters.serviceID: item.id});
          }));
        });
        itemWidgets.shuffle();
        ref.read(loadingProvider.notifier).toggleLoading(false);
      } catch (error) {
        ref.read(loadingProvider.notifier).toggleLoading(false);
        scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('Error getting search results: $error')));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(loadingProvider);
    return Scaffold(
      appBar: appBarWidget(context),
      body: stackedLoadingContainer(
          context,
          ref.read(loadingProvider),
          SingleChildScrollView(
            child: Column(
              children: [
                secondAppBar(context),
                Divider(color: Colors.white),
                horizontal5Percent(
                  context,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      vertical20Pix(
                          child: blackSarabunBold(
                              '${itemWidgets.length.toString()} ITEMS FOUND FOR "${widget.searchInput}"',
                              fontSize: 26,
                              textAlign: TextAlign.left)),
                      _itemEntries()
                    ],
                  ),
                ),
              ],
            ),
          )),
    );
  }

  Widget _itemEntries() {
    return vertical20Pix(
      child: Center(
          child: Wrap(
              alignment: WrapAlignment.start,
              spacing: 60,
              runSpacing: 60,
              children: itemWidgets)),
    );
  }
}
