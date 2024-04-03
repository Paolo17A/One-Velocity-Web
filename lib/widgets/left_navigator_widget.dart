import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../utils/color_util.dart';
import '../utils/go_router_util.dart';

Widget leftNavigator(BuildContext context, {required String path}) {
  return Container(
    width: MediaQuery.of(context).size.width * 0.2,
    height: MediaQuery.of(context).size.height - 60,
    color: CustomColors.ultimateGray,
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

Widget listTile(BuildContext context,
    {required String label,
    required String thisPath,
    required String currentPath}) {
  return Container(
      decoration: BoxDecoration(
          color: thisPath == currentPath ? CustomColors.blackBeauty : null),
      child: ListTile(
          title: Text(label,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
          onTap: () => GoRouter.of(context).goNamed(thisPath)));
}
