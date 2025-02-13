import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:one_velocity_web/widgets/text_widgets.dart';

import '../utils/color_util.dart';
import '../utils/go_router_util.dart';
import 'custom_padding_widgets.dart';

Widget submitButton(BuildContext context,
    {required String label, required Function onPress}) {
  return Padding(
      padding: const EdgeInsets.all(20),
      child: ElevatedButton(
        onPressed: () => onPress(),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ));
}

Widget backButton(BuildContext context, {required Function onPress}) {
  return ElevatedButton(
      onPressed: () => onPress(),
      style: ElevatedButton.styleFrom(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
      child: whiteSarabunBold('BACK'));
}

Widget viewEntryButton(BuildContext context, {required Function onPress}) {
  return ElevatedButton(
      onPressed: () {
        onPress();
      },
      style: ElevatedButton.styleFrom(backgroundColor: CustomColors.grenadine),
      child: const Icon(Icons.visibility, color: Colors.black));
}

Widget editEntryButton(BuildContext context, {required Function onPress}) {
  return ElevatedButton(
      onPressed: () {
        onPress();
      },
      style: ElevatedButton.styleFrom(backgroundColor: CustomColors.grenadine),
      child: const Icon(Icons.edit, color: Colors.black));
}

Widget restoreEntryButton(BuildContext context, {required Function onPress}) {
  return ElevatedButton(
      onPressed: () {
        onPress();
      },
      style: ElevatedButton.styleFrom(backgroundColor: CustomColors.grenadine),
      child: const Icon(Icons.restore, color: Colors.black));
}

Widget deleteEntryButton(BuildContext context, {required Function onPress}) {
  return ElevatedButton(
      onPressed: () {
        onPress();
      },
      style: ElevatedButton.styleFrom(backgroundColor: CustomColors.grenadine),
      child: const Icon(Icons.delete, color: Colors.black));
}

Widget uploadImageButton(String label, Function selectImage) {
  return ElevatedButton(
      onPressed: () => selectImage(),
      style: ElevatedButton.styleFrom(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
      child: Padding(
          padding: const EdgeInsets.all(7), child: whiteSarabunBold(label)));
}

Widget navigatorButtons(BuildContext context,
    {required int pageNumber,
    required Function? onPrevious,
    required Function? onNext,
    Color fontColor = Colors.black}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 20),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        pageButton(context,
            label: 'PREV', onPress: onPrevious, fontColor: fontColor),
        Padding(
          padding: const EdgeInsets.all(5.5),
          child:
              Text(pageNumber.toString(), style: TextStyle(color: fontColor)),
        ),
        pageButton(context,
            label: 'NEXT', onPress: onNext, fontColor: fontColor)
      ],
    ),
  );
}

Widget pageButton(BuildContext context,
    {required Function? onPress,
    required String label,
    Color fontColor = Colors.black}) {
  return Container(
    decoration:
        BoxDecoration(border: Border.all(color: CustomColors.ultimateGray)),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: TextButton(
          onPressed: onPress != null ? () => onPress() : null,
          style: TextButton.styleFrom(
              foregroundColor: fontColor, disabledForegroundColor: Colors.grey),
          child: Text(label)),
    ),
  );
}

Widget pageNavigatorButtons(
    {required int currentPage,
    required int maxPage,
    required Function onPreviousPage,
    required Function onNextPage}) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.end,
    children: [
      TextButton(
          onPressed: currentPage == 0
              ? null
              : () {
                  onPreviousPage();
                },
          child: Icon(Icons.arrow_back)),
      crimsonSarabunBold((currentPage + 1).toString()),
      TextButton(
          onPressed: currentPage == maxPage
              ? null
              : () {
                  onNextPage();
                },
          child: Icon(Icons.arrow_forward))
    ],
  );
}

Widget logOutButton(BuildContext context) {
  return all20Pix(
      child: ElevatedButton(
          onPressed: () {
            FirebaseAuth.instance.signOut().then((value) {
              GoRouter.of(context).goNamed(GoRoutes.home);
              GoRouter.of(context).pushReplacementNamed(GoRoutes.home);
            });
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
          child: whiteSarabunBold('LOG-OUT')));
}
