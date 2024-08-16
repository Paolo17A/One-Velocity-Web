import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:one_velocity_web/utils/color_util.dart';
import 'package:one_velocity_web/utils/string_util.dart';
import 'package:one_velocity_web/widgets/custom_padding_widgets.dart';
import 'package:one_velocity_web/widgets/text_widgets.dart';

import '../utils/firebase_util.dart';
import '../utils/go_router_util.dart';

PreferredSizeWidget appBarWidget(BuildContext context,
    {bool showActions = true}) {
  return AppBar(
      toolbarHeight: 60,
      automaticallyImplyLeading: false,
      backgroundColor: Colors.white,
      title: InkWell(
        onTap: () {
          GoRouter.of(context).goNamed(GoRoutes.home);
          GoRouter.of(context).pushReplacementNamed(GoRoutes.home);
        },
        child: Row(
          children: [
            CircleAvatar(
                backgroundColor: Colors.transparent,
                backgroundImage: AssetImage(ImagePaths.logo)),
            horizontal20Pix(
                child: Row(
              children: [
                grenadineSarabunRegular('ONE\t '),
                blackSarabunRegular('VELOCITY CAR CARE INC.')
              ],
            ))
          ],
        ),
      ),
      actions: showActions
          ? [
              if (hasLoggedInUser())
                IconButton(
                    onPressed: () =>
                        GoRouter.of(context).goNamed(GoRoutes.bookingsHistory),
                    icon: const Icon(Icons.receipt,
                        color: CustomColors.ultimateGray)),
              if (hasLoggedInUser())
                IconButton(
                    onPressed: () =>
                        GoRouter.of(context).goNamed(GoRoutes.cart),
                    icon: const Icon(Icons.shopping_cart_rounded,
                        color: CustomColors.ultimateGray)),
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
