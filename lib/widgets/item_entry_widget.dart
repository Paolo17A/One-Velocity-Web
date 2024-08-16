import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:one_velocity_web/utils/string_util.dart';

import '../utils/color_util.dart';
import 'text_widgets.dart';

Widget itemEntry(BuildContext context,
    {required DocumentSnapshot itemDoc,
    required Function onPress,
    Color fontColor = Colors.black}) {
  final itemData = itemDoc.data() as Map<dynamic, dynamic>;
  List<dynamic> itemImages = itemData['imageURLs'];
  String firstImage = itemImages[0];
  String itemName = itemData['name'];
  double price = itemData['price'];
  return MouseRegion(
    cursor: SystemMouseCursors.click,
    child: GestureDetector(
      onTap: () => onPress(),
      child: Container(
        width: 250,
        height: 360,
        decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(),
            boxShadow: [
              BoxShadow(offset: Offset(4, 4), color: CustomColors.ultimateGray)
            ]),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
                padding: const EdgeInsets.all(10),
                child: Container(
                  height: 250,
                  decoration: BoxDecoration(
                      border: Border.all(),
                      image: DecorationImage(
                          fit: BoxFit.fill, image: NetworkImage(firstImage))),
                )),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Container(
                width: 250,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      blackSarabunBold(itemName,
                          textOverflow: TextOverflow.ellipsis),
                      grenadineSarabunRegular(
                          'PHP ${formatPrice(price.toDouble())}',
                          fontSize: 17),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
