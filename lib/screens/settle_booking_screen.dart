// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../providers/cart_provider.dart';
import '../providers/loading_provider.dart';
import '../utils/color_util.dart';
import '../utils/firebase_util.dart';
import '../utils/go_router_util.dart';
import '../utils/string_util.dart';
import '../widgets/app_bar_widget.dart';
import '../widgets/custom_miscellaneous_widgets.dart';
import '../widgets/custom_padding_widgets.dart';
import '../widgets/dropdown_widget.dart';
import '../widgets/text_widgets.dart';

class SettleBookingScreen extends ConsumerStatefulWidget {
  final String bookingID;
  const SettleBookingScreen({super.key, required this.bookingID});

  @override
  ConsumerState<SettleBookingScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<SettleBookingScreen> {
  String serviceName = '';
  List<dynamic> imageURLs = [];
  String description = '';
  DateTime? dateCreated;
  DateTime? dateRequsted;
  num servicePrice = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      ref.read(loadingProvider.notifier).toggleLoading(true);
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      final goRouter = GoRouter.of(context);
      try {
        if (hasLoggedInUser() &&
            await getCurrentUserType() == UserTypes.admin) {
          ref.read(loadingProvider.notifier).toggleLoading(false);
          goRouter.goNamed(GoRoutes.home);
          return;
        }
        final bookingDoc = await getThisBookingDoc(widget.bookingID);
        final bookingData = bookingDoc.data() as Map<dynamic, dynamic>;
        dateCreated =
            (bookingData[BookingFields.dateCreated] as Timestamp).toDate();
        dateRequsted =
            (bookingData[BookingFields.dateRequested] as Timestamp).toDate();
        if (bookingData[BookingFields.serviceStatus] !=
            ServiceStatuses.pendingPayment) {
          scaffoldMessenger.showSnackBar(
              SnackBar(content: Text('This booking has no pending payment')));
          ref.read(loadingProvider.notifier).toggleLoading(false);
          goRouter.goNamed(GoRoutes.home);
          return;
        }

        final serviceID = bookingData[BookingFields.serviceID];
        final serviceDoc = await getThisServiceDoc(serviceID);
        final serviceData = serviceDoc.data() as Map<dynamic, dynamic>;
        serviceName = serviceData[ServiceFields.name];
        imageURLs = serviceData[ServiceFields.imageURLs];
        servicePrice =
            double.parse(serviceData[ServiceFields.price].toString());
        description = serviceData[ServiceFields.description];

        ref.read(cartProvider).setSelectedPaymentMethod('');
        //ref.read(cartProvider).resetProofOfPaymentBytes();
        ref.read(loadingProvider.notifier).toggleLoading(false);
      } catch (error) {
        scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('Error getting selected product: $error')));
        ref.read(loadingProvider.notifier).toggleLoading(false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(loadingProvider);
    ref.watch(cartProvider);
    return Scaffold(
      appBar: appBarWidget(context),
      body: SingleChildScrollView(
        child: Column(
          children: [
            secondAppBar(context),
            switchedLoadingContainer(
              ref.read(loadingProvider),
              Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [_serviceDataWidgets(), _checkoutContainer()]),
            )
          ],
        ),
      ),
    );
  }

  Widget _serviceDataWidgets() {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.75,
      child: all10Pix(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            blackSarabunBold('SELECTED SERVICE: $serviceName', fontSize: 40),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (imageURLs.isNotEmpty)
                  Container(
                      decoration: BoxDecoration(border: Border.all()),
                      child: Image.network(imageURLs[0],
                          width: MediaQuery.of(context).size.width * 0.15,
                          height: MediaQuery.of(context).size.width * 0.15,
                          fit: BoxFit.cover)),
                Gap(20),
                vertical20Pix(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (dateCreated != null)
                        blackSarabunRegular(
                            'Date Booked: ${DateFormat('MMM dd, yyyy').format(dateCreated!)}',
                            fontSize: 24),
                      if (dateRequsted != null)
                        blackSarabunRegular(
                            'Date Requested: ${DateFormat('MMM dd, yyyy').format(dateRequsted!)}',
                            fontSize: 24),
                      Gap(20),
                      blackSarabunRegular(description,
                          textAlign: TextAlign.left),
                    ],
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _checkoutContainer() {
    return Container(
      width: MediaQuery.of(context).size.width * 0.25,
      height: MediaQuery.of(context).size.height - 60,
      decoration: BoxDecoration(
          color: CustomColors.ultimateGray,
          border: Border.all(color: CustomColors.blackBeauty)),
      child: Column(
        children: [
          vertical20Pix(
            child: whiteSarabunBold(
                'PHP ${formatPrice(servicePrice.toDouble())}',
                fontSize: 40),
          ),
          const Gap(30),
          _paymentMethod(),
          if (ref.read(cartProvider).selectedPaymentMethod.isNotEmpty)
            _uploadPayment(),
          _makePaymentButton(),
          if (ref.read(cartProvider).proofOfPaymentBytes != null)
            _checkoutButton()
        ],
      ),
    );
  }

  Widget _paymentMethod() {
    return all10Pix(
        child: Column(
      children: [
        Row(
          children: [whiteSarabunBold('PAYMENT METHOD')],
        ),
        Container(
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(5)),
          child: dropdownWidget(ref.read(cartProvider).selectedPaymentMethod,
              (newVal) {
            ref.read(cartProvider).setSelectedPaymentMethod(newVal!);
          }, ['GCASH', 'PAYMAYA'], 'Select your payment method', false),
        )
      ],
    ));
  }

  Widget _uploadPayment() {
    return all10Pix(
        child: Column(
      children: [
        Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                whiteSarabunBold('SEND YOUR PAYMENT HERE'),
                if (ref.read(cartProvider).selectedPaymentMethod == 'GCASH')
                  whiteSarabunBold('GCASH: +639221234567', fontSize: 14)
                else if (ref.read(cartProvider).selectedPaymentMethod ==
                    'PAYMAYA')
                  whiteSarabunBold('PAYMAYA: +639221234567', fontSize: 14)
              ],
            )
          ],
        ),
      ],
    ));
  }

  Widget _makePaymentButton() {
    return SizedBox(
      height: 60,
      child: ElevatedButton(
          onPressed: ref.read(cartProvider).selectedPaymentMethod.isEmpty
              ? null
              : () => ref.read(cartProvider).setProofOfPaymentBytes(),
          style: ElevatedButton.styleFrom(disabledBackgroundColor: Colors.grey),
          child: whiteSarabunBold('SELECT PROOF OF PAYMENT')),
    );
  }

  Widget _checkoutButton() {
    return vertical20Pix(
        child: Column(
      children: [
        all10Pix(
            child: Image.memory(ref.read(cartProvider).proofOfPaymentBytes!,
                width: MediaQuery.of(context).size.width * 0.1,
                height: MediaQuery.of(context).size.width * 0.1,
                fit: BoxFit.cover)),
        ElevatedButton(
            onPressed: () => ref.read(cartProvider).resetProofOfPaymentBytes(),
            child: const Icon(Icons.delete, color: Colors.white)),
        vertical20Pix(
          child: SizedBox(
            height: 40,
            child: ElevatedButton(
                onPressed: () => settleBookingRequestPayment(context, ref,
                    bookingID: widget.bookingID,
                    purchaseIDs: [widget.bookingID],
                    servicePrice: servicePrice),
                child: whiteSarabunBold('SETTLE PAYMENT')),
          ),
        )
      ],
    ));
  }
}
