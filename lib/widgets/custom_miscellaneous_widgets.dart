import 'dart:typed_data';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../providers/cart_provider.dart';
import '../utils/color_util.dart';
import '../utils/firebase_util.dart';
import '../utils/go_router_util.dart';
import '../utils/string_util.dart';
import '../utils/url_util.dart';
import 'custom_padding_widgets.dart';
import 'dropdown_widget.dart';
import 'item_entry_widget.dart';
import 'text_widgets.dart';

Widget stackedLoadingContainer(
    BuildContext context, bool isLoading, Widget child) {
  return Stack(children: [
    child,
    if (isLoading)
      Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          color: Colors.black.withOpacity(0.5),
          child: const Center(child: CircularProgressIndicator()))
  ]);
}

Widget switchedLoadingContainer(bool isLoading, Widget child) {
  return isLoading ? const Center(child: CircularProgressIndicator()) : child;
}

Widget roundedNimbusContainer(BuildContext context, {required Widget child}) {
  return Container(
      width: MediaQuery.of(context).size.width * 0.5,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: CustomColors.nimbusCloud),
      padding: const EdgeInsets.all(20),
      child: child);
}

Widget buildProfileImage(
    {required String profileImageURL, double radius = 70}) {
  return profileImageURL.isNotEmpty
      ? CircleAvatar(
          radius: radius,
          backgroundColor: CustomColors.blackBeauty,
          backgroundImage: NetworkImage(profileImageURL),
        )
      : CircleAvatar(
          radius: radius,
          backgroundColor: CustomColors.blackBeauty,
          child: Icon(
            Icons.person,
            color: Colors.white,
            size: radius + 10,
          ));
}

Container viewContentContainer(BuildContext context, {required Widget child}) {
  return Container(
      width: MediaQuery.of(context).size.width * 0.7,
      decoration: BoxDecoration(
          color: Colors.white,
          //border: Border.all(color: Colors.black),
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20), topRight: Radius.circular(20))),
      child: child);
}

Widget viewContentLabelRow(BuildContext context,
    {required List<Widget> children}) {
  return SizedBox(
      width: MediaQuery.of(context).size.width * 0.7,
      child: Row(children: children));
}

Widget viewContentEntryRow(BuildContext context,
    {required List<Widget> children}) {
  return Container(
      width: MediaQuery.of(context).size.width * 0.7,
      height: 50,
      child: Row(children: children));
}

Widget viewFlexTextCell(String text,
    {required int flex,
    required Color backgroundColor,
    required Color textColor,
    Border? customBorder,
    BorderRadius? customBorderRadius}) {
  return Flexible(
    flex: flex,
    child: Container(
        height: 50,
        decoration: BoxDecoration(
            color: backgroundColor,
            border: customBorder,
            borderRadius: customBorderRadius),
        child: ClipRRect(
          child: Center(
              child: Text(text,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 18))),
        )),
  );
}

Widget viewFlexLabelTextCell(String text, int flex,
    {BorderRadius? borderRadius}) {
  return viewFlexTextCell(text,
      flex: flex,
      backgroundColor: CustomColors.crimson,
      customBorderRadius: borderRadius,
      textColor: Colors.white);
}

Widget viewFlexActionsCell(List<Widget> children,
    {required int flex,
    required Color backgroundColor,
    Border? customBorder,
    BorderRadius? customBorderRadius}) {
  return Flexible(
      flex: flex,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
            border: customBorder,
            borderRadius: customBorderRadius,
            color: backgroundColor),
        child: Center(
            child: Wrap(
                alignment: WrapAlignment.start,
                runAlignment: WrapAlignment.spaceEvenly,
                spacing: 10,
                runSpacing: 10,
                children: children)),
      ));
}

Widget viewContentUnavailable(BuildContext context, {required String text}) {
  return SizedBox(
    height: MediaQuery.of(context).size.height * 0.65,
    child: Center(child: blackSarabunBold(text, fontSize: 44)),
  );
}

Widget analyticReportWidget(BuildContext context,
    {required String count,
    required String demographic,
    required Widget displayIcon,
    required Function? onPress}) {
  return Padding(
    padding: const EdgeInsets.all(8),
    child: Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(color: CustomColors.nimbusCloud, boxShadow: [
          BoxShadow(offset: Offset(8, 8), blurRadius: 4, spreadRadius: -8)
        ]),
        padding: EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            crimsonSarabunBold(count, fontSize: 40),
            blackSarabunRegular(demographic)
          ],
        )),
  );
}

Container breakdownContainer(BuildContext context, {required Widget child}) {
  return Container(
      width: MediaQuery.of(context).size.width * 0.25,
      height: MediaQuery.of(context).size.height * 0.4,
      decoration: BoxDecoration(boxShadow: [
        BoxShadow(
            offset: const Offset(0, 3), color: Colors.grey.withOpacity(0.5))
      ], borderRadius: BorderRadius.circular(20), color: Colors.white),
      child: Padding(padding: const EdgeInsets.all(11), child: child));
}

Widget selectedMemoryImageDisplay(
    Uint8List? imageStream, Function deleteImage) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 40),
    child: Container(
      decoration: BoxDecoration(border: Border.all(color: Colors.black)),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            SizedBox(
                width: 150, height: 150, child: Image.memory(imageStream!)),
            const SizedBox(height: 5),
            SizedBox(
              width: 90,
              child: ElevatedButton(
                  onPressed: () => deleteImage(),
                  child: const Icon(
                    Icons.delete,
                    color: Colors.white,
                  )),
            )
          ],
        ),
      ),
    ),
  );
}

Widget selectedNetworkImageDisplay(String imageSource) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 40),
    child: Container(
      decoration: BoxDecoration(border: Border.all(color: Colors.black)),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: SizedBox(
            width: 150, height: 150, child: Image.network(imageSource)),
      ),
    ),
  );
}

Widget snapshotHandler(AsyncSnapshot snapshot) {
  if (snapshot.connectionState == ConnectionState.waiting) {
    return Center(child: const CircularProgressIndicator());
  } else if (!snapshot.hasData) {
    return Text('No data found');
  } else if (snapshot.hasError) {
    return Text('Error gettin data: ${snapshot.error.toString()}');
  }
  return Container();
}

Widget serviceBookingHistoryEntry(DocumentSnapshot bookingDoc) {
  final bookingData = bookingDoc.data() as Map<dynamic, dynamic>;
  String serviceStatus = bookingData[BookingFields.serviceStatus];
  String clientID = bookingData[BookingFields.clientID];
  DateTime dateCreated =
      (bookingData[BookingFields.dateCreated] as Timestamp).toDate();
  DateTime dateRequsted =
      (bookingData[BookingFields.dateRequested] as Timestamp).toDate();

  return FutureBuilder(
    future: getThisUserDoc(clientID),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting ||
          !snapshot.hasData ||
          snapshot.hasError) return snapshotHandler(snapshot);

      final userData = snapshot.data!.data() as Map<dynamic, dynamic>;
      String profileImageURL = userData[UserFields.profileImageURL];
      String name =
          '${userData[UserFields.firstName]} ${userData[UserFields.lastName]}';
      return all10Pix(
          child: Container(
        decoration: BoxDecoration(border: Border.all(color: Colors.white)),
        padding: const EdgeInsets.all(10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildProfileImage(profileImageURL: profileImageURL, radius: 50),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      blackSarabunBold(name, fontSize: 20),
                      blackSarabunRegular('Status: $serviceStatus',
                          fontSize: 16),
                    ],
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                blackSarabunRegular(
                    'Date Booked: ${DateFormat('MMM dd, yyyy').format(dateCreated)}',
                    fontSize: 16),
                blackSarabunRegular(
                    'Date Requested: ${DateFormat('MMM dd, yyyy').format(dateRequsted)}',
                    fontSize: 16),
              ],
            )
          ],
        ),
      ));
    },
  );
}

void showOtherPics(BuildContext context, {required String imageURL}) {
  showDialog(
      context: context,
      builder: (context) => AlertDialog(
              content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.7,
            height: MediaQuery.of(context).size.height * 0.7,
            child: Column(children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                      onPressed: () => GoRouter.of(context).pop(),
                      child: blackSarabunBold('X'))
                ],
              ),
              Container(
                width: MediaQuery.of(context).size.height * 0.65,
                height: MediaQuery.of(context).size.height * 0.65,
                decoration: BoxDecoration(
                    image: DecorationImage(
                        image: NetworkImage(imageURL), fit: BoxFit.fill)),
              ),
            ]),
          )));
}

Widget bookingHistoryEntry(DocumentSnapshot bookingDoc,
    {String userType = UserTypes.client}) {
  final bookingData = bookingDoc.data() as Map<dynamic, dynamic>;
  String serviceStatus = bookingData[BookingFields.serviceStatus];
  List<dynamic> serviceIDs = bookingData[BookingFields.serviceIDs];
  String paymentID = bookingData[BookingFields.paymentID];
  DateTime dateCreated =
      (bookingData[BookingFields.dateCreated] as Timestamp).toDate();
  DateTime dateRequsted =
      (bookingData[BookingFields.dateRequested] as Timestamp).toDate();

  return FutureBuilder(
    future: getSelectedServiceDocs(serviceIDs),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting ||
          !snapshot.hasData ||
          snapshot.hasError) return snapshotHandler(snapshot);
      List<dynamic> selectedServices =
          snapshot.data!.map((e) => e.data() as Map<dynamic, dynamic>).toList();
      num totalPrice = 0;
      for (var serviceData in selectedServices) {
        totalPrice += serviceData[ServiceFields.price];
      }

      return all10Pix(
          child: Container(
        decoration: BoxDecoration(border: Border.all()),
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: selectedServices.map((serviceData) {
                            final List<dynamic> imageURLs =
                                serviceData[ServiceFields.imageURLs];
                            return vertical10Pix(
                              child: Row(
                                children: [
                                  Image.network(imageURLs.first,
                                      width: 50, height: 50, fit: BoxFit.cover),
                                  Gap(10),
                                  blackSarabunBold(
                                      serviceData[ServiceFields.name],
                                      fontSize: 20,
                                      textAlign: TextAlign.left),
                                ],
                              ),
                            );
                          }).toList()),
                      if (serviceStatus != ServiceStatuses.pendingPayment)
                        const Gap(30),
                      blackSarabunRegular('Status: $serviceStatus',
                          fontSize: 15),
                      if (userType == UserTypes.client &&
                          serviceStatus == ServiceStatuses.pendingPayment)
                        ElevatedButton(
                            onPressed: () {
                              GoRouter.of(context).goNamed(
                                  GoRoutes.settleBooking,
                                  pathParameters: {
                                    PathParameters.bookingID: bookingDoc.id
                                  });
                            },
                            child: whiteSarabunRegular('SETTLE PAYMENT'))
                    ],
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                blackSarabunRegular(
                    'Date Booked: ${DateFormat('MMM dd, yyyy').format(dateCreated)}',
                    fontSize: 17),
                blackSarabunRegular(
                    'Date Requested: ${DateFormat('MMM dd, yyyy').format(dateRequsted)}',
                    fontSize: 17),
                Gap(15),
                blackSarabunBold(
                    'Total: PHP ${formatPrice(totalPrice.toDouble())}',
                    fontSize: 15),
                if (serviceStatus == ServiceStatuses.serviceCompleted)
                  _downloadInvoiceFutureBuilder(paymentID)
              ],
            )
          ],
        ),
      ));
    },
  );
}

Widget itemCarouselTemplate(BuildContext context,
    {required String label,
    required CarouselSliderController carouselSliderController,
    required List<DocumentSnapshot> itemDocs}) {
  return vertical20Pix(
    child: Container(
        width: MediaQuery.of(context).size.width,
        padding: const EdgeInsets.all(10),
        child: Column(children: [
          blackSarabunBold(label, fontSize: 32),
          Container(width: 220, height: 8, color: CustomColors.crimson),
          Gap(10),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            IconButton(
                onPressed: () => carouselSliderController.previousPage(),
                icon: blackSarabunRegular('<', fontSize: 60)),
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.8,
              height: 400,
              child: CarouselSlider.builder(
                carouselController: carouselSliderController,
                itemCount: itemDocs.length,
                disableGesture: true,
                options: CarouselOptions(
                    viewportFraction: 0.2,
                    enlargeCenterPage: true,
                    scrollPhysics: NeverScrollableScrollPhysics(),
                    enlargeFactor: 0.2),
                itemBuilder: (context, index, realIndex) {
                  return itemEntry(context, itemDoc: itemDocs[index],
                      onPress: () {
                    GoRouter.of(context).goNamed(GoRoutes.selectedProduct,
                        pathParameters: {
                          PathParameters.productID: itemDocs[index].id
                        });
                    GoRouter.of(context).pushNamed(GoRoutes.selectedProduct,
                        pathParameters: {
                          PathParameters.productID: itemDocs[index].id
                        });
                  });
                },
              ),
            ),
            IconButton(
                onPressed: () => carouselSliderController.nextPage(),
                icon: blackSarabunRegular('>', fontSize: 60)),
          ])
        ])),
  );
}

Widget footerWidget(BuildContext context) {
  return Container(
    width: MediaQuery.of(context).size.width,
    color: CustomColors.blackBeauty,
    padding: EdgeInsets.all(20),
    child: Column(
      children: [
        Row(
          children: [
            all10Pix(
              child: CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 16,
                  backgroundImage: AssetImage(ImagePaths.logo)),
            ),
            grenadineSarabunRegular('ONE\t'),
            whiteSarabunRegular('VELOCITY CAR CARE INC.')
          ],
        ),
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          Flexible(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  whiteSarabunRegular('Company Mission Here',
                      textAlign: TextAlign.left),
                  whiteSarabunRegular('Company Vision Here',
                      textAlign: TextAlign.left)
                ],
              )),
          Flexible(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  whiteSarabunRegular('http://www.facebook.com/onevelocityph/',
                      textAlign: TextAlign.left),
                  whiteSarabunRegular('http://www.yotube.com/onevelocityph/',
                      textAlign: TextAlign.left),
                  whiteSarabunRegular('http://www.linkedin.com/onevelocityph/',
                      textAlign: TextAlign.left)
                ],
              )),
          Flexible(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(Icons.email, color: CustomColors.ultimateGray),
                    Gap(20),
                    whiteSarabunRegular('onevelocityph@gmail.com',
                        textAlign: TextAlign.left)
                  ]),
                  Row(children: [
                    Icon(Icons.location_city, color: CustomColors.ultimateGray),
                    Gap(20),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.3,
                      child: whiteSarabunRegular(
                          'Brgy. Pagsawitan 5 National Highway, Santa Cruz, Philippines',
                          textAlign: TextAlign.left),
                    )
                  ]),
                  Row(children: [
                    Icon(Icons.phone, color: CustomColors.ultimateGray),
                    Gap(20),
                    whiteSarabunRegular('(049) 536-2526')
                  ])
                ],
              )),
        ]),
        Gap(32),
        Column(
          children: [
            whiteSarabunRegular('Privacy Policy | Terms and Conditions',
                fontSize: 12),
            whiteSarabunRegular('Copyright 2024 One Velocity Car Care Inc.',
                fontSize: 12),
            whiteSarabunRegular(
                'Brgy. Pagsawitan 5 National Highway, Santa Cruz, Philippines',
                fontSize: 12),
            whiteSarabunRegular('(0949) 536-2526', fontSize: 12)
          ],
        )
      ],
    ),
  );
}

Widget paymentMethod(WidgetRef ref) {
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

Widget uploadPayment(WidgetRef ref) {
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

Widget purchaseHistoryEntry(DocumentSnapshot purchaseDoc,
    {String userType = UserTypes.client}) {
  final purchaseData = purchaseDoc.data() as Map<dynamic, dynamic>;
  String status = purchaseData[PurchaseFields.purchaseStatus];
  String productID = purchaseData[PurchaseFields.productID];
  num quantity = purchaseData[PurchaseFields.quantity];
  DateTime dateCreated =
      (purchaseData[PurchaseFields.dateCreated] as Timestamp).toDate();
  String paymentID = purchaseData[PurchaseFields.paymentID];
  return FutureBuilder(
    future: getThisProductDoc(productID),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting ||
          !snapshot.hasData ||
          snapshot.hasError) return snapshotHandler(snapshot);

      final productData = snapshot.data!.data() as Map<dynamic, dynamic>;
      List<dynamic> imageURLs = productData[ProductFields.imageURLs];
      String name = productData[ProductFields.name];
      num price = productData[ProductFields.price];
      return MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
            onTap: userType == UserTypes.client
                ? () {
                    GoRouter.of(context).goNamed(GoRoutes.selectedProduct,
                        pathParameters: {PathParameters.productID: productID});
                    GoRouter.of(context).pushNamed(GoRoutes.selectedProduct,
                        pathParameters: {PathParameters.productID: productID});
                  }
                : null,
            child: all10Pix(
                child: Container(
              decoration: BoxDecoration(border: Border.all()),
              padding: EdgeInsets.all(10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                              image: DecorationImage(
                                  image: NetworkImage(imageURLs[0]),
                                  fit: BoxFit.cover))),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 30),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            blackSarabunBold(name, fontSize: 25),
                            Row(
                              children: [
                                blackSarabunRegular(
                                    'SRP: PHP ${formatPrice(price.toDouble())}',
                                    fontSize: 15),
                                const Gap(15),
                                blackSarabunRegular(
                                    'Quantity: ${quantity.toString()}',
                                    fontSize: 15),
                              ],
                            ),
                            blackSarabunRegular(
                                'Date Purchased: ${(DateFormat('MMM dd, yyyy').format(dateCreated))}',
                                fontSize: 12),
                            const Gap(15),
                            blackSarabunRegular('Status: $status',
                                fontSize: 15),
                            if (status == PurchaseStatuses.pickedUp)
                              _downloadInvoiceFutureBuilder(paymentID)
                          ],
                        ),
                      ),
                    ],
                  ),
                  all20Pix(
                      child: whiteSarabunBold(
                          'PHP ${(price * quantity).toStringAsFixed(2)}'))
                ],
              ),
            ))),
      );
    },
  );
}

Widget _downloadInvoiceFutureBuilder(String paymentID) {
  return FutureBuilder(
    future: getThisPaymentDoc(paymentID),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting ||
          !snapshot.hasData ||
          snapshot.hasError) return snapshotHandler(snapshot);
      final paymentData = snapshot.data!.data() as Map<dynamic, dynamic>;
      String invoiceURL = paymentData[PaymentFields.invoiceURL];
      return TextButton(
          onPressed: () async => launchThisURL(context, invoiceURL),
          child: blackSarabunRegular('Download Invoice',
              fontSize: 12,
              textAlign: TextAlign.left,
              decoration: TextDecoration.underline));
    },
  );
}
