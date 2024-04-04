import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
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
      title: InkWell(
        onTap: () => GoRouter.of(context).goNamed(GoRoutes.home),
        child: Row(
          children: [
            CircleAvatar(
                backgroundColor: Colors.transparent,
                backgroundImage: AssetImage(ImagePaths.logo)),
            horizontal20Pix(
                child: montserratWhiteBold('ONE VELOCITY CAR CARE INC.',
                    fontSize: 24))
          ],
        ),
      ),
      actions: showActions
          ? [
              if (hasLoggedInUser())
                IconButton(
                    onPressed: () =>
                        GoRouter.of(context).goNamed(GoRoutes.cart),
                    icon: const Icon(Icons.shopping_cart_rounded,
                        color: Colors.white)),
              if (hasLoggedInUser())
                TextButton(
                    onPressed: () =>
                        GoRouter.of(context).goNamed(GoRoutes.profile),
                    child: montserratWhiteBold('PROFILE')),
              if (!hasLoggedInUser())
                TextButton(
                    onPressed: () =>
                        GoRouter.of(context).goNamed(GoRoutes.register),
                    child: montserratWhiteBold('SIGN-UP')),
              if (!hasLoggedInUser())
                TextButton(
                    onPressed: () =>
                        GoRouter.of(context).goNamed(GoRoutes.login),
                    child: montserratWhiteBold('LOG-IN')),
              const Gap(20)
            ]
          : null);
}

PreferredSizeWidget secondAppBar(BuildContext context) {
  return AppBar(
    toolbarHeight: 40,
    automaticallyImplyLeading: false,
    title: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            TextButton(
                onPressed: () =>
                    GoRouter.of(context).goNamed(GoRoutes.products),
                child: montserratWhiteBold('PRODUCTS')),
            TextButton(onPressed: () {}, child: montserratWhiteBold('SERVICES'))
          ],
        ),
        TextButton(
            onPressed: () => GoRouter.of(context).goNamed(GoRoutes.help),
            child: montserratWhiteBold('HELP')),
      ],
    ),
  );
}
