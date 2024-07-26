import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../utils/color_util.dart';
import '../utils/firebase_util.dart';
import '../utils/string_util.dart';
import 'custom_padding_widgets.dart';
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

Widget buildProfileImage({required String profileImageURL}) {
  return profileImageURL.isNotEmpty
      ? CircleAvatar(
          radius: 70,
          backgroundColor: CustomColors.blackBeauty,
          backgroundImage: NetworkImage(profileImageURL),
        )
      : const CircleAvatar(
          radius: 70,
          backgroundColor: CustomColors.blackBeauty,
          child: Icon(
            Icons.person,
            color: Colors.white,
            size: 80,
          ));
}

Container viewContentContainer(BuildContext context, {required Widget child}) {
  return Container(
      width: MediaQuery.of(context).size.width * 0.7,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black),
      ),
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
  return SizedBox(
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

Widget viewFlexLabelTextCell(String text, int flex) {
  return viewFlexTextCell(text,
      flex: flex,
      backgroundColor: CustomColors.blackBeauty,
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
    child: Center(child: montserratBlackBold(text, fontSize: 44)),
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
        width: MediaQuery.of(context).size.width * 0.13,
        height: MediaQuery.of(context).size.height * 0.2,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          color: Colors.white,
        ),
        child: Row(children: [
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.08,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                montserratBlackBold(count, fontSize: 40),
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.07,
                  height: 45,
                  child: ElevatedButton(
                    onPressed: onPress != null ? () => onPress() : null,
                    style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    )),
                    child: Center(
                      child: montserratWhiteRegular(demographic, fontSize: 15),
                    ),
                  ),
                )
              ],
            ),
          ),
          SizedBox(
              width: MediaQuery.of(context).size.width * 0.05,
              child: Transform.scale(scale: 2, child: displayIcon))
        ])),
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

Widget selectedNetworkImageDisplay(String imageSource, Function deleteImage) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 40),
    child: Container(
      decoration: BoxDecoration(border: Border.all(color: Colors.black)),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            SizedBox(
                width: 150, height: 150, child: Image.network(imageSource)),
            const SizedBox(height: 5),
            SizedBox(
              width: 90,
              child: ElevatedButton(
                  onPressed: () => deleteImage(),
                  child: const Icon(Icons.delete, color: Colors.white)),
            )
          ],
        ),
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
              children: [
                buildProfileImage(profileImageURL: profileImageURL),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      montserratWhiteBold(name, fontSize: 25),
                      montserratWhiteRegular('Status: $serviceStatus',
                          fontSize: 15),
                    ],
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                montserratWhiteRegular(
                    'Date Booked: ${DateFormat('MMM dd, yyyy').format(dateCreated)}',
                    fontSize: 17),
                montserratWhiteRegular(
                    'Date Requested: ${DateFormat('MMM dd, yyyy').format(dateRequsted)}',
                    fontSize: 17),
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
                      child: montserratBlackBold('X'))
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
  String serviceID = bookingData[BookingFields.serviceID];
  DateTime dateCreated =
      (bookingData[BookingFields.dateCreated] as Timestamp).toDate();
  DateTime dateRequsted =
      (bookingData[BookingFields.dateRequested] as Timestamp).toDate();

  return FutureBuilder(
    future: getThisServiceDoc(serviceID),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting ||
          !snapshot.hasData ||
          snapshot.hasError) return snapshotHandler(snapshot);

      final serviceData = snapshot.data!.data() as Map<dynamic, dynamic>;
      List<dynamic> imageURLs = serviceData[ServiceFields.imageURLs];
      String name = serviceData[ServiceFields.name];
      num price = serviceData[ServiceFields.price];
      return all10Pix(
          child: Container(
        decoration: BoxDecoration(border: Border.all(color: Colors.white)),
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.network(
                  imageURLs[0],
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      montserratWhiteBold(name, fontSize: 25),
                      if (serviceStatus != ServiceStatuses.pendingPayment)
                        const Gap(30),
                      montserratWhiteRegular('Status: $serviceStatus',
                          fontSize: 15),
                      if (userType == UserTypes.client &&
                          serviceStatus == ServiceStatuses.pendingPayment)
                        ElevatedButton(
                            onPressed: () {
                              /*GoRouter.of(context).goNamed(
                                  GoRoutes.settleBooking,
                                  pathParameters: {
                                    PathParameters.bookingID: bookingDoc.id
                                  });*/
                            },
                            child: montserratWhiteRegular('SETTLE PAYMENT'))
                    ],
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                montserratWhiteRegular(
                    'Date Booked: ${DateFormat('MMM dd, yyyy').format(dateCreated)}',
                    fontSize: 17),
                montserratWhiteRegular(
                    'Date Requested: ${DateFormat('MMM dd, yyyy').format(dateRequsted)}',
                    fontSize: 17),
                Gap(15),
                montserratWhiteBold('SRP: PHP ${formatPrice(price.toDouble())}',
                    fontSize: 15),
              ],
            )
          ],
        ),
      ));
    },
  );
}
