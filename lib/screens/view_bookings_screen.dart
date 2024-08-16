import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:one_velocity_web/widgets/text_widgets.dart';

import '../providers/bookings_provider.dart';
import '../providers/loading_provider.dart';
import '../utils/delete_entry_dialog_util.dart';
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

  Widget _bookingsContainer() {
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
  }

  Widget _bookingLabelRow() {
    return viewContentLabelRow(context, children: [
      viewFlexLabelTextCell('Buyer', 3,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(20))),
      viewFlexLabelTextCell('Service', 3),
      viewFlexLabelTextCell('Date Created', 2),
      viewFlexLabelTextCell('Date Requested', 2),
      viewFlexLabelTextCell('Status', 2,
          borderRadius: BorderRadius.only(topRight: Radius.circular(20)))
    ]);
  }

  Widget _bookingEntries() {
    return SizedBox(
      height: 500,
      child: ListView.builder(
          shrinkWrap: true,
          itemCount: ref.read(bookingsProvider).bookingDocs.length,
          itemBuilder: (context, index) => _bookingEntry(
              ref.read(bookingsProvider).bookingDocs[index], index)),
    );
  }

  Widget _bookingEntry(DocumentSnapshot bookingDoc, int index) {
    final bookingData = bookingDoc.data() as Map<dynamic, dynamic>;
    String clientID = bookingData[BookingFields.clientID];
    String serviceID = bookingData[BookingFields.serviceID];
    DateTime dateCreated =
        (bookingData[BookingFields.dateCreated] as Timestamp).toDate();
    DateTime dateRequsted =
        (bookingData[BookingFields.dateRequested] as Timestamp).toDate();
    String serviceStatus = bookingData[BookingFields.serviceStatus];

    return FutureBuilder(
        future: getThisUserDoc(clientID),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting ||
              !snapshot.hasData ||
              snapshot.hasError) return snapshotHandler(snapshot);

          final clientData = snapshot.data!.data() as Map<dynamic, dynamic>;
          String formattedName =
              '${clientData[UserFields.firstName]} ${clientData[UserFields.lastName]}';
          String mobileNumber = clientData[UserFields.mobileNumber];
          return FutureBuilder(
              future: getThisServiceDoc(serviceID),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting ||
                    !snapshot.hasData ||
                    snapshot.hasError) return snapshotHandler(snapshot);

                final serviceData =
                    snapshot.data!.data() as Map<dynamic, dynamic>;
                String name = serviceData[ServiceFields.name];

                Color entryColor = Colors.black;
                Color backgroundColor = Colors.white;

                return viewContentEntryRow(context, children: [
                  viewFlexTextCell(formattedName,
                      flex: 3,
                      backgroundColor: backgroundColor,
                      textColor: entryColor),
                  viewFlexTextCell(name,
                      flex: 3,
                      backgroundColor: backgroundColor,
                      textColor: entryColor),
                  viewFlexTextCell(
                      DateFormat('MMM dd, yyyy').format(dateCreated),
                      flex: 2,
                      backgroundColor: backgroundColor,
                      textColor: entryColor),
                  viewFlexTextCell(
                      DateFormat('MMM dd, yyyy').format(dateRequsted),
                      flex: 2,
                      backgroundColor: backgroundColor,
                      textColor: entryColor),
                  viewFlexActionsCell(
                    [
                      if (serviceStatus == ServiceStatuses.pendingApproval) ...[
                        ElevatedButton(
                            onPressed: () => approveThisBookingRequest(
                                context, ref,
                                bookingID: bookingDoc.id, serviceName: name),
                            child:
                                const Icon(Icons.check, color: Colors.white)),
                        ElevatedButton(
                            onPressed: () => displayDeleteEntryDialog(context,
                                message:
                                    'Are you sure you want to deny this request?',
                                deleteWord: 'Deny',
                                deleteEntry: () => denyThisBookingRequest(
                                    context, ref,
                                    bookingID: bookingDoc.id,
                                    serviceName: name)),
                            child: const Icon(Icons.block, color: Colors.white))
                      ] else if (serviceStatus == ServiceStatuses.denied ||
                          serviceStatus == ServiceStatuses.cancelled ||
                          serviceStatus == ServiceStatuses.pendingPayment ||
                          serviceStatus == ServiceStatuses.processingPayment ||
                          serviceStatus == ServiceStatuses.serviceCompleted)
                        blackSarabunBold(serviceStatus, fontSize: 12)
                      else if (serviceStatus == ServiceStatuses.pendingDropOff)
                        ElevatedButton(
                            onPressed: () => markBookingRequestAsServiceOngoing(
                                context, ref, bookingID: bookingDoc.id),
                            child: whiteSarabunBold('MARK AS DROPPED OFF',
                                fontSize: 12))
                      else if (serviceStatus == ServiceStatuses.serviceOngoing)
                        ElevatedButton(
                            onPressed: () => markBookingRequestAsForPickUp(
                                context, ref,
                                bookingID: bookingDoc.id,
                                serviceName: name,
                                mobileNumber: mobileNumber),
                            child: whiteSarabunBold('MARK AS FOR PICK UP',
                                fontSize: 12))
                      else if (serviceStatus == ServiceStatuses.pendingPickUp)
                        ElevatedButton(
                            onPressed: () => markBookingRequestAsCompleted(
                                context, ref, bookingID: bookingDoc.id),
                            child: whiteSarabunBold('MARK AS PICKED UP',
                                fontSize: 12))
                    ],
                    flex: 2,
                    backgroundColor: backgroundColor,
                  ),
                ]);
              });
          //  Item Variables
        });
    //  Client Variables
  }
}
