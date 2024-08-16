import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../utils/color_util.dart';
import '../utils/delete_entry_dialog_util.dart';
import '../utils/go_router_util.dart';
import 'custom_padding_widgets.dart';

Widget leftNavigator(BuildContext context, {required String path}) {
  return Container(
    width: MediaQuery.of(context).size.width * 0.2,
    height: MediaQuery.of(context).size.height - 60,
    color: CustomColors.crimson,
    child: Column(
      children: [
        Flexible(
            child: ListView(
          padding: EdgeInsets.zero,
          children: [
            listTile(context,
                label: 'Dashboard', thisPath: GoRoutes.home, currentPath: path),
            listTile(context,
                label: 'Products',
                thisPath: GoRoutes.viewProducts,
                currentPath: path),
            listTile(context,
                label: 'Services',
                thisPath: GoRoutes.viewServices,
                currentPath: path),
            listTile(context,
                label: 'Users',
                thisPath: GoRoutes.viewUsers,
                currentPath: path),
            listTile(context,
                label: 'Transactions',
                thisPath: GoRoutes.viewTransactions,
                currentPath: path),
            listTile(context,
                label: 'Purchases',
                thisPath: GoRoutes.viewPurchases,
                currentPath: path),
            listTile(context,
                label: 'Bookings',
                thisPath: GoRoutes.viewBookings,
                currentPath: path),
            listTile(context,
                label: 'FAQs', thisPath: GoRoutes.viewFAQs, currentPath: path),
          ],
        )),
        ListTile(
            leading: const Icon(
              Icons.exit_to_app,
              color: Colors.white,
            ),
            title: const Text('Log Out',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
            onTap: () {
              FirebaseAuth.instance.signOut().then((value) {
                GoRouter.of(context).goNamed(GoRoutes.home);
                GoRouter.of(context).pushReplacementNamed(GoRoutes.home);
              });
            })
      ],
    ),
  );
}

Widget clientProfileNavigator(BuildContext context, {required String path}) {
  return Container(
    width: MediaQuery.of(context).size.width * 0.2,
    height: MediaQuery.of(context).size.height - 60,
    color: CustomColors.crimson,
    child: all20Pix(
        child: ListView(
            shrinkWrap: false,
            physics: NeverScrollableScrollPhysics(),
            children: [
          Container(
            color: path == GoRoutes.profile
                ? CustomColors.grenadine
                : CustomColors.crimson,
            child: ListTile(
                title: Text('ACCOUNT SETTINGS',
                    style: TextStyle(color: Colors.white)),
                onTap: () => GoRouter.of(context).goNamed(GoRoutes.profile)),
          ),
          Container(
            color: path == GoRoutes.bookmarks
                ? CustomColors.grenadine
                : CustomColors.crimson,
            child: ListTile(
                title: Text('BOOKMARKS', style: TextStyle(color: Colors.white)),
                onTap: () => GoRouter.of(context).goNamed(GoRoutes.bookmarks)),
          ),
          Container(
            color: path == GoRoutes.purchaseHistory
                ? CustomColors.grenadine
                : CustomColors.crimson,
            child: ListTile(
                title: Text('PRODUCT PURCHASE HISTORY',
                    style: TextStyle(color: Colors.white)),
                onTap: () =>
                    GoRouter.of(context).goNamed(GoRoutes.purchaseHistory)),
          ),
          Container(
            color: path == GoRoutes.bookingsHistory
                ? CustomColors.grenadine
                : CustomColors.crimson,
            child: ListTile(
                title: Text('SERVICE BOOKING HISTORY',
                    style: TextStyle(color: Colors.white)),
                onTap: () =>
                    GoRouter.of(context).goNamed(GoRoutes.bookingsHistory)),
          ),
          /*ListTile(
              tileColor:  path == GoRoutes.  ? CustomColors.grenadine
                  : CustomColors.crimson,
              title: Text('CHANGE PASSWORD',
                  style: TextStyle(color: Colors.white)),
              onTap: () {}),*/
          ListTile(
              tileColor: CustomColors.crimson,
              title: Text('LOG-OUT', style: const TextStyle(color: Colors.red)),
              onTap: () {
                displayDeleteEntryDialog(context,
                    message: 'Are you sure you want to log-out?',
                    deleteWord: 'Log-Out',
                    deleteEntry: () =>
                        FirebaseAuth.instance.signOut().then((value) {
                          GoRouter.of(context).goNamed(GoRoutes.home);
                          GoRouter.of(context).pushNamed(GoRoutes.home);
                        }));
              })
        ])),
  );
}

Widget listTile(BuildContext context,
    {required String label,
    required String thisPath,
    required String currentPath}) {
  return Container(
      decoration: BoxDecoration(
          color: thisPath == currentPath ? CustomColors.grenadine : null),
      child: ListTile(
          title: Text(label,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
          onTap: thisPath.isNotEmpty
              ? () {
                  GoRouter.of(context).goNamed(thisPath);
                  if (thisPath == GoRoutes.home)
                    GoRouter.of(context).pushReplacementNamed(thisPath);
                }
              : null));
}
