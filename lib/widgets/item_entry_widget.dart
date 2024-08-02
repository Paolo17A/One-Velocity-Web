import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

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
        decoration: BoxDecoration(color: CustomColors.ultimateGray),
        child: Column(
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
                decoration: BoxDecoration(
                    color: CustomColors.ultimateGray.withOpacity(0.05)),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Column(
                    children: [
                      montserratWhiteBold(itemName,
                          textOverflow: TextOverflow.ellipsis),
                      Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              montserratWhiteBold(
                                  'PHP ${price.toStringAsFixed(2)}',
                                  fontSize: 17),
                            ],
                          ),
                        ],
                      ),
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
