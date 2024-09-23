import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:one_velocity_web/widgets/text_widgets.dart';

import '../providers/loading_provider.dart';
import '../utils/firebase_util.dart';
import '../utils/go_router_util.dart';
import '../utils/string_util.dart';
import '../widgets/app_bar_widget.dart';
import '../widgets/custom_miscellaneous_widgets.dart';
import '../widgets/custom_padding_widgets.dart';
import '../widgets/floating_chat_widget.dart';
import '../widgets/left_navigator_widget.dart';

class BookingHistoryScreen extends ConsumerStatefulWidget {
  const BookingHistoryScreen({super.key});

  @override
  ConsumerState<BookingHistoryScreen> createState() =>
      _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends ConsumerState<BookingHistoryScreen>
    with TickerProviderStateMixin {
  late TabController tabController;
  List<DocumentSnapshot> ongoingBookingDocs = [];
  List<DocumentSnapshot> completedBookingDocs = [];

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
          ref.read(loadingProvider.notifier).toggleLoading(false);
          goRouter.goNamed(GoRoutes.login);
          return;
        }
        final userDoc = await getCurrentUserDoc();
        final userData = userDoc.data() as Map<dynamic, dynamic>;
        if (userData[UserFields.userType] == UserTypes.admin) {
          ref.read(loadingProvider.notifier).toggleLoading(false);
          goRouter.goNamed(GoRoutes.home);
          return;
        }
        List<DocumentSnapshot> bookingDocs = await getUserBookingDocs();
        ongoingBookingDocs = bookingDocs.where((bookingDoc) {
          final bookingData = bookingDoc.data() as Map<dynamic, dynamic>;
          return bookingData[BookingFields.serviceStatus] ==
                  ServiceStatuses.pendingApproval ||
              bookingData[BookingFields.serviceStatus] ==
                  ServiceStatuses.pendingDropOff ||
              bookingData[BookingFields.serviceStatus] ==
                  ServiceStatuses.pendingPayment;
        }).toList();
        completedBookingDocs = bookingDocs.where((bookingDoc) {
          final bookingData = bookingDoc.data() as Map<dynamic, dynamic>;
          return bookingData[BookingFields.serviceStatus] ==
                  ServiceStatuses.serviceCompleted ||
              bookingData[BookingFields.serviceStatus] ==
                  ServiceStatuses.denied ||
              bookingData[BookingFields.serviceStatus] ==
                  ServiceStatuses.cancelled;
        }).toList();
        ref.read(loadingProvider.notifier).toggleLoading(false);
      } catch (error) {
        scaffoldMessenger.showSnackBar(SnackBar(
            content: Text('Error getting your booking history: $error')));
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
        body: switchedLoadingContainer(
            ref.read(loadingProvider),
            SingleChildScrollView(
              child: Column(
                children: [
                  secondAppBar(context),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      clientProfileNavigator(context,
                          path: GoRoutes.bookingsHistory),
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.8,
                        child: Column(
                          children: [
                            TabBar(tabs: [
                              Tab(child: blackSarabunBold('ONGOING')),
                              Tab(child: blackSarabunBold('COMPLETED'))
                            ]),
                            SizedBox(
                              height: MediaQuery.of(context).size.height - 150,
                              child: TabBarView(
                                  physics: NeverScrollableScrollPhysics(),
                                  children: [
                                    _ongoingBookingHistory(),
                                    _completedBookingHistory(),
                                  ]),
                            )
                          ],
                        ),
                      )
                    ],
                  )
                ],
              ),
            )),
      ),
    );
  }

  Widget _ongoingBookingHistory() {
    return horizontal5Percent(
      context,
      child: vertical20Pix(
        child: Container(
          padding: const EdgeInsets.all(10),
          child: ongoingBookingDocs.isNotEmpty
              ? ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: ongoingBookingDocs.length,
                  itemBuilder: (context, index) {
                    // return blackSarabunBold(
                    //     ref.read(bookingsProvider).bookingDocs[index].id);
                    return bookingHistoryEntry(ongoingBookingDocs[index]);
                  })
              : Center(
                  child: blackSarabunBold(
                      'NO ONGOING SERVICE BOOKING HISTORY AVAILABLE'),
                ),
        ),
      ),
    );
  }

  Widget _completedBookingHistory() {
    return horizontal5Percent(
      context,
      child: vertical20Pix(
        child: Container(
          padding: const EdgeInsets.all(10),
          child: completedBookingDocs.isNotEmpty
              ? ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: completedBookingDocs.length,
                  itemBuilder: (context, index) {
                    // return blackSarabunBold(
                    //     ref.read(bookingsProvider).bookingDocs[index].id);
                    return bookingHistoryEntry(completedBookingDocs[index]);
                  })
              : Center(
                  child: blackSarabunBold(
                      'NO COMPLETED SERVICE BOOKING HISTORY AVAILABLE'),
                ),
        ),
      ),
    );
  }
}
