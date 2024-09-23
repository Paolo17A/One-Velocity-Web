import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:one_velocity_web/widgets/service_payment_widget.dart';
import 'package:one_velocity_web/widgets/text_widgets.dart';

import '../providers/bookings_provider.dart';
import '../providers/loading_provider.dart';
import '../utils/firebase_util.dart';
import '../utils/go_router_util.dart';
import '../utils/string_util.dart';
import '../widgets/app_bar_widget.dart';
import '../widgets/custom_miscellaneous_widgets.dart';
import '../widgets/custom_padding_widgets.dart';
import '../widgets/left_navigator_widget.dart';

class ViewBookingsScreen extends ConsumerStatefulWidget {
  const ViewBookingsScreen({super.key});

  @override
  ConsumerState<ViewBookingsScreen> createState() => _ViewBookingsScreenState();
}

class _ViewBookingsScreenState extends ConsumerState<ViewBookingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      ref.read(loadingProvider.notifier).toggleLoading(true);
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      final goRouter = GoRouter.of(context);
      try {
        if (hasLoggedInUser() &&
            await getCurrentUserType() == UserTypes.client) {
          ref.read(loadingProvider.notifier).toggleLoading(false);
          goRouter.goNamed(GoRoutes.home);
          return;
        }

        ref.read(bookingsProvider).setBookingDocs(await getAllBookingDocs());
        ref.read(loadingProvider.notifier).toggleLoading(false);
      } catch (error) {
        scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('Error getting all bookings: $error')));
        ref.read(loadingProvider.notifier).toggleLoading(false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(loadingProvider);
    ref.watch(bookingsProvider);
    return Scaffold(
      appBar: appBarWidget(context, showActions: false),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          leftNavigator(context, path: GoRoutes.viewBookings),
          SizedBox(
              width: MediaQuery.of(context).size.width * 0.8,
              child: switchedLoadingContainer(
                  ref.read(loadingProvider),
                  SingleChildScrollView(
                    child: horizontal5Percent(context,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            vertical20Pix(
                                child:
                                    blackSarabunBold('BOOKINGS', fontSize: 40)),
                            _bookingsContainer(),
                          ],
                        )),
                  )))
        ],
      ),
    );
  }

  /*Widget _bookingsContainer() {
    return viewContentContainer(
      context,
      child: Column(
        children: [
          _bookingLabelRow(),
          ref.read(bookingsProvider).bookingDocs.isNotEmpty
              ? _bookingEntries()
              : viewContentUnavailable(context, text: 'NO AVAILABLE BOOKINGS'),
        ],
      ),
    );
  }*/

  Widget _bookingsContainer() {
    return ref.read(bookingsProvider).bookingDocs.isNotEmpty
        ? Wrap(
            spacing: 20,
            runSpacing: 20,
            children: ref
                .read(bookingsProvider)
                .bookingDocs
                .map((bookingDoc) =>
                    ServicePaymentWidget(ref: ref, bookingDoc: bookingDoc))
                .toList())
        : Center(
            child: blackSarabunBold('NO BOOKINGS AVAILABLE', fontSize: 28));
  }
}
