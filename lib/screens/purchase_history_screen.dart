import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:one_velocity_web/providers/loading_provider.dart';
import 'package:one_velocity_web/utils/firebase_util.dart';
import 'package:one_velocity_web/utils/go_router_util.dart';
import 'package:one_velocity_web/utils/string_util.dart';
import 'package:one_velocity_web/widgets/app_bar_widget.dart';
import 'package:one_velocity_web/widgets/custom_miscellaneous_widgets.dart';
import 'package:one_velocity_web/widgets/left_navigator_widget.dart';
import 'package:one_velocity_web/widgets/text_widgets.dart';

import '../widgets/floating_chat_widget.dart';

class PurchaseHistoryScreen extends ConsumerStatefulWidget {
  const PurchaseHistoryScreen({super.key});

  @override
  ConsumerState<PurchaseHistoryScreen> createState() =>
      _PurchaseHistoryScreenState();
}

class _PurchaseHistoryScreenState extends ConsumerState<PurchaseHistoryScreen>
    with TickerProviderStateMixin {
  late TabController tabController;

  List<DocumentSnapshot> ongoingPurchaseDocs = [];
  List<DocumentSnapshot> completedPurchaseDocs = [];

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      ref.read(loadingProvider.notifier).toggleLoading(true);
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      final goRouter = GoRouter.of(context);
      try {
        if (hasLoggedInUser() &&
            await getCurrentUserType() == UserTypes.admin) {
          goRouter.goNamed(GoRoutes.home);
          return;
        }
        List<DocumentSnapshot> purchaseHistoryDocs =
            await getUserPurchaseHistory();

        purchaseHistoryDocs.sort((a, b) {
          DateTime aTime =
              (a[PurchaseFields.dateCreated] as Timestamp).toDate();
          DateTime bTime =
              (b[PurchaseFields.dateCreated] as Timestamp).toDate();
          return bTime.compareTo(aTime);
        });
        ongoingPurchaseDocs = purchaseHistoryDocs.where((purchaseDoc) {
          final purchaseData = purchaseDoc.data() as Map<dynamic, dynamic>;
          return purchaseData[PurchaseFields.purchaseStatus] !=
              PurchaseStatuses.pickedUp;
        }).toList();
        completedPurchaseDocs = purchaseHistoryDocs.where((purchaseDoc) {
          final purchaseData = purchaseDoc.data() as Map<dynamic, dynamic>;
          return purchaseData[PurchaseFields.purchaseStatus] ==
              PurchaseStatuses.pickedUp;
        }).toList();
        ref.read(loadingProvider.notifier).toggleLoading(false);
      } catch (error) {
        scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('Error getting purchase history: $error')));
        ref.read(loadingProvider.notifier).toggleLoading(false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(loadingProvider);
    return DefaultTabController(
      initialIndex: 0,
      length: 2,
      child: Scaffold(
        appBar: appBarWidget(context),
        floatingActionButton: FloatingChatWidget(
            senderUID: FirebaseAuth.instance.currentUser!.uid,
            otherUID: adminID),
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          child: Column(
            children: [
              secondAppBar(context),
              switchedLoadingContainer(
                  ref.read(loadingProvider),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      clientProfileNavigator(context,
                          path: GoRoutes.purchaseHistory),
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.8,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            blackSarabunBold('PURCHASE HISTORY', fontSize: 40),
                            TabBar(tabs: [
                              Tab(child: blackSarabunBold('ONGOING')),
                              Tab(child: blackSarabunBold('COMPLETED'))
                            ]),
                            SizedBox(
                              width: MediaQuery.of(context).size.width * 0.8,
                              height: MediaQuery.of(context).size.height - 150,
                              child: TabBarView(
                                  physics: NeverScrollableScrollPhysics(),
                                  children: [
                                    _ongoingPurchaseHistoryEntries(),
                                    _completedPurchaseHistoryEntries()
                                  ]),
                            )
                          ],
                        ),
                      )
                    ],
                  ))
            ],
          ),
        ),
      ),
    );
  }

  Widget _ongoingPurchaseHistoryEntries() {
    return ongoingPurchaseDocs.isNotEmpty
        ? ListView.builder(
            shrinkWrap: true,
            itemCount: ongoingPurchaseDocs.length,
            itemBuilder: (context, index) {
              return purchaseHistoryEntry(ongoingPurchaseDocs[index]);
            })
        : Center(
            child:
                blackSarabunBold('YOU HAVE NO ONGOING PURCHASES', fontSize: 30),
          );
  }

  Widget _completedPurchaseHistoryEntries() {
    return completedPurchaseDocs.isNotEmpty
        ? ListView.builder(
            shrinkWrap: true,
            itemCount: completedPurchaseDocs.length,
            itemBuilder: (context, index) {
              return purchaseHistoryEntry(completedPurchaseDocs[index]);
            })
        : Center(
            child: blackSarabunBold('YOU HAVE NOT COMPLETED ANY PURCHASES YET',
                fontSize: 30),
          );
  }
}
