import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:one_velocity_web/main.dart';
import 'package:one_velocity_web/utils/color_util.dart';
import 'package:one_velocity_web/utils/string_util.dart';
import 'package:one_velocity_web/widgets/custom_padding_widgets.dart';
import 'package:one_velocity_web/widgets/custom_text_field_widget.dart';
import 'package:one_velocity_web/widgets/text_widgets.dart';

import '../utils/firebase_util.dart';
import '../utils/go_router_util.dart';

PreferredSizeWidget appBarWidget(BuildContext context,
    {bool showActions = true, String currentPath = ''}) {
  return AppBar(
      toolbarHeight: 60,
      automaticallyImplyLeading: false,
      backgroundColor: Colors.white,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: InkWell(
              onTap: () {
                GoRouter.of(context).goNamed(GoRoutes.home);
                GoRouter.of(context).pushReplacementNamed(GoRoutes.home);
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                      backgroundColor: Colors.transparent,
                      backgroundImage: AssetImage(ImagePaths.logo)),
                  horizontal20Pix(
                      child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      grenadineSarabunRegular('ONE\t '),
                      blackSarabunRegular('VELOCITY CAR CARE INC.')
                    ],
                  ))
                ],
              ),
            ),
          ),
          if (MyApp.displaySearchBar)
            Flexible(
                child: CustomTextField(
                    text: 'Search...',
                    controller: MyApp.searchController,
                    textInputType: TextInputType.text,
                    hasSearchButton: true,
                    onSearchPress: () {
                      GoRouter.of(context)
                          .goNamed(GoRoutes.search, pathParameters: {
                        PathParameters.searchInput: MyApp.searchController.text
                      });
                      GoRouter.of(context)
                          .pushNamed(GoRoutes.search, pathParameters: {
                        PathParameters.searchInput: MyApp.searchController.text
                      });
                    },
                    displayPrefixIcon: null))
        ],
      ),
      actions: showActions
          ? [
              if (hasLoggedInUser())
                cartPopUpMenu(context, currentPath: currentPath),
              // if (hasLoggedInUser())
              //   IconButton(
              //       onPressed: () =>
              //           GoRouter.of(context).goNamed(GoRoutes.serviceCart),
              //       icon: const Icon(Icons.receipt,
              //           color: CustomColors.ultimateGray)),
              // if (hasLoggedInUser())
              //   IconButton(
              //       onPressed: () =>
              //           GoRouter.of(context).goNamed(GoRoutes.productCart),
              //       icon: const Icon(Icons.shopping_cart_rounded,
              //           color: CustomColors.ultimateGray)),
              const Gap(20)
            ]
          : null);
}

PreferredSizeWidget secondAppBar(BuildContext context) {
  return AppBar(
    toolbarHeight: 40,
    automaticallyImplyLeading: false,
    backgroundColor: CustomColors.crimson,
    title: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            TextButton(
                onPressed: () =>
                    GoRouter.of(context).goNamed(GoRoutes.products),
                child: whiteSarabunRegular('PRODUCTS')),
            TextButton(
                onPressed: () =>
                    GoRouter.of(context).goNamed(GoRoutes.services),
                child: whiteSarabunRegular('SERVICES'))
          ],
        ),
        Row(
          children: [
            if (hasLoggedInUser())
              TextButton(
                  onPressed: () =>
                      GoRouter.of(context).goNamed(GoRoutes.profile),
                  child: whiteSarabunRegular('PROFILE')),
            TextButton(
                onPressed: () => GoRouter.of(context).goNamed(GoRoutes.help),
                child: whiteSarabunRegular('HELP')),
            if (!hasLoggedInUser())
              TextButton(
                  onPressed: () =>
                      GoRouter.of(context).goNamed(GoRoutes.register),
                  child: whiteSarabunRegular('SIGN-UP')),
            if (!hasLoggedInUser())
              TextButton(
                  onPressed: () => GoRouter.of(context).goNamed(GoRoutes.login),
                  child: whiteSarabunRegular('LOG-IN')),
          ],
        ),
      ],
    ),
  );
}

Widget cartPopUpMenu(BuildContext context, {required String currentPath}) {
  return PopupMenuButton(
      color: CustomColors.blackBeauty,
      onSelected: (value) {
        if (currentPath == value) return;
        GoRouter.of(context).goNamed(value.toString());
      },
      child: Icon(Icons.shopping_cart_rounded, color: Colors.black),
      itemBuilder: (context) => [
            PopupMenuItem(
                value: GoRoutes.productCart,
                child: whiteSarabunBold('Products Cart')),
            PopupMenuItem(
                value: GoRoutes.serviceCart,
                child: whiteSarabunBold('Services Cart')),
          ]);
}
