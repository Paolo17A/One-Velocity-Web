import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:one_velocity_web/widgets/text_widgets.dart';

import '../providers/bookings_provider.dart';
import '../providers/loading_provider.dart';
import '../utils/color_util.dart';
import '../utils/firebase_util.dart';
import '../utils/go_router_util.dart';
import '../utils/string_util.dart';
import '../widgets/app_bar_widget.dart';
import '../widgets/custom_miscellaneous_widgets.dart';
import '../widgets/custom_padding_widgets.dart';
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
      body: switchedLoadingContainer(
          ref.read(loadingProvider),
          Column(
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
                      child: SingleChildScrollView(
                        child: _bookingHistory(),
                      ))
                ],
              )
            ],
          )),
    );
  }

  Widget _bookingHistory() {
    return horizontal5Percent(
      context,
      child: vertical20Pix(
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
              color: CustomColors.ultimateGray,
              borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              montserratWhiteBold('SERVICE BOOKING HISTORY', fontSize: 28),
              const Divider(color: Colors.white),
              ref.read(bookingsProvider).bookingDocs.isNotEmpty
                  ? ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: ref.read(bookingsProvider).bookingDocs.length,
                      itemBuilder: (context, index) {
                        return bookingHistoryEntry(
                            ref.read(bookingsProvider).bookingDocs[index]);
                      })
                  : Center(
                      child: montserratWhiteBold(
                          'NO SERVICE BOOKING HISTORY AVAILABLE'),
                    )
            ],
          ),
        ),
      ),
    );
  }
}
