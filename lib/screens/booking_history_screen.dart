import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:one_velocity_web/widgets/text_widgets.dart';

import '../providers/bookings_provider.dart';
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

class _BookingHistoryScreenState extends ConsumerState<BookingHistoryScreen> {
  @override
  void initState() {
    super.initState();
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
        ref.read(bookingsProvider).setBookingDocs(await getUserBookingDocs());
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
    ref.watch(bookingsProvider);
    return Scaffold(
      appBar: appBarWidget(context),
      floatingActionButton: FloatingChatWidget(
          senderUID: FirebaseAuth.instance.currentUser!.uid, otherUID: adminID),
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
                        height: MediaQuery.of(context).size.height - 100,
                        child: _bookingHistory())
                  ],
                )
              ],
            ),
          )),
    );
  }

  Widget _bookingHistory() {
    return horizontal5Percent(
      context,
      child: vertical20Pix(
        child: Container(
          padding: const EdgeInsets.all(10),
          child: ref.read(bookingsProvider).bookingDocs.isNotEmpty
              ? ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: ref.read(bookingsProvider).bookingDocs.length,
                  itemBuilder: (context, index) {
                    // return blackSarabunBold(
                    //     ref.read(bookingsProvider).bookingDocs[index].id);
                    return bookingHistoryEntry(
                        ref.read(bookingsProvider).bookingDocs[index]);
                  })
              : Center(
                  child:
                      whiteSarabunBold('NO SERVICE BOOKING HISTORY AVAILABLE'),
                ),
        ),
      ),
    );
  }
}
