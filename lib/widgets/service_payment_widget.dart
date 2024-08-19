import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:one_velocity_web/utils/string_util.dart';

import '../utils/color_util.dart';
import '../utils/firebase_util.dart';
import 'custom_miscellaneous_widgets.dart';
import 'text_widgets.dart';

class ServicePaymentWidget extends StatefulWidget {
  final WidgetRef ref;
  final DocumentSnapshot bookingDoc;
  const ServicePaymentWidget(
      {super.key, required this.ref, required this.bookingDoc});

  @override
  State<ServicePaymentWidget> createState() => _ServicePaymentWidgetState();
}

class _ServicePaymentWidgetState extends State<ServicePaymentWidget> {
  bool _isLoading = true;
  String clientName = '';
  DateTime? dateCreated;
  DateTime? datePaid;
  num paidAmount = 0;
  String paymentStatus = '';
  String serviceStatus = '';
  List<DocumentSnapshot> serviceDocs = [];
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final bookingData = widget.bookingDoc.data() as Map<dynamic, dynamic>;
      dateCreated =
          (bookingData[BookingFields.dateCreated] as Timestamp).toDate();
      serviceStatus = bookingData[BookingFields.serviceStatus];
      //  Get client data
      String clientID = bookingData[BookingFields.clientID];
      final clientDoc = await getThisUserDoc(clientID);
      final clientData = clientDoc.data() as Map<dynamic, dynamic>;
      clientName =
          '${clientData[UserFields.firstName]} ${clientData[UserFields.lastName]}';

      //  Get products data
      final List<dynamic> serviceIDs = bookingData[BookingFields.serviceIDs];
      if (serviceIDs.isNotEmpty) {
        serviceDocs = await getSelectedServiceDocs(serviceIDs);
        for (var serviceDoc in serviceDocs) {
          final serviceData = serviceDoc.data() as Map<dynamic, dynamic>;
          paidAmount += serviceData[ServiceFields.price];
        }
      }

      setState(() {
        _isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.3,
      height: 275,
      decoration: BoxDecoration(
          color: CustomColors.ultimateGray,
          borderRadius: BorderRadius.circular(10)),
      padding: EdgeInsets.all(8),
      child: switchedLoadingContainer(
        _isLoading,
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _clientDataContainer(),
            VerticalDivider(color: Colors.white),
            _servicesContainer(),
          ],
        ),
      ),
    );
  }

  Widget _clientDataContainer() {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.15,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        whiteSarabunBold('Buyer: $clientName',
            fontSize: 22,
            textOverflow: TextOverflow.ellipsis,
            textAlign: TextAlign.left),
        if (dateCreated != null)
          whiteSarabunBold(
              'Date Created: ${DateFormat('MMM dd, yyyy').format(dateCreated!)}',
              fontSize: 16,
              textAlign: TextAlign.left),
        whiteSarabunRegular(
            'Total Payment:\n\t\tPHP ${formatPrice(paidAmount.toDouble())}',
            fontSize: 16,
            textAlign: TextAlign.left),
        Gap(20),
        dynamicButton()
      ]),
    );
  }

  Widget dynamicButton() {
    if (serviceStatus == ServiceStatuses.pendingApproval)
      return Row(children: [
        ElevatedButton(
            onPressed: () => approveThisBookingRequest(context, widget.ref,
                bookingID: widget.bookingDoc.id),
            child: whiteSarabunRegular('APPROVE')),
        Gap(4),
        ElevatedButton(
            onPressed: () => denyThisBookingRequest(context, widget.ref,
                bookingID: widget.bookingDoc.id),
            child: whiteSarabunRegular('DENY'))
      ]);
    else if (serviceStatus == ServiceStatuses.denied ||
        serviceStatus == ServiceStatuses.pendingPayment ||
        serviceStatus == ServiceStatuses.processingPayment ||
        serviceStatus == ServiceStatuses.cancelled ||
        serviceStatus == ServiceStatuses.serviceCompleted)
      return whiteSarabunBold(serviceStatus);
    else if (serviceStatus == ServiceStatuses.pendingDropOff)
      return ElevatedButton(
          onPressed: () => markBookingRequestAsServiceOngoing(
              context, widget.ref,
              bookingID: widget.bookingDoc.id),
          child: whiteSarabunBold('MARK AS DROPPED OFF', fontSize: 12));
    else if (serviceStatus == ServiceStatuses.serviceOngoing)
      return ElevatedButton(
          onPressed: () => markBookingRequestAsForPickUp(context, widget.ref,
              bookingID: widget.bookingDoc.id),
          child: whiteSarabunBold('MARK AS FOR PICK UP', fontSize: 12));
    else if (serviceStatus == ServiceStatuses.pendingPickUp)
      return ElevatedButton(
          onPressed: () => markBookingRequestAsCompleted(context, widget.ref,
              bookingID: widget.bookingDoc.id),
          child: whiteSarabunBold('MARK AS PICKED UP', fontSize: 12));
    else
      return Container();
  }

  Widget _servicesContainer() {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          whiteSarabunBold('SERVICES', fontSize: 22, textAlign: TextAlign.left),
          Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: serviceDocs
                  .take(2)
                  .map((serviceDoc) => _serviceWidget(serviceDoc))
                  .toList()),
          if (serviceDocs.length > 2)
            TextButton(
                onPressed: () {},
                child: whiteSarabunRegular(
                  'VIEW ALL',
                  fontSize: 16,
                  decoration: TextDecoration.underline,
                ))
        ],
      ),
    );
  }

  Widget _serviceWidget(DocumentSnapshot serviceDoc) {
    final serviceData = serviceDoc.data() as Map<dynamic, dynamic>;
    List<dynamic> imageURLs = serviceData[ServiceFields.imageURLs];
    String name = serviceData[ServiceFields.name];
    num price = serviceData[ServiceFields.price];
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 1),
              borderRadius: BorderRadius.circular(4)),
          padding: EdgeInsets.all(4),
          child: Row(
            //crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.network(imageURLs.first,
                  width: 50, height: 50, fit: BoxFit.cover),
              Gap(4),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.07,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      whiteSarabunBold(name,
                          fontSize: 14, textOverflow: TextOverflow.ellipsis),
                      whiteSarabunRegular(
                          'PHP ${formatPrice(price.toDouble())}',
                          fontSize: 12,
                          textAlign: TextAlign.left),
                    ]),
              ),
            ],
          )),
    );
  }
}
