import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:one_velocity_web/providers/payments_provider.dart';
import 'package:one_velocity_web/widgets/app_bar_widget.dart';
import 'package:one_velocity_web/widgets/left_navigator_widget.dart';
import 'package:one_velocity_web/widgets/product_payment_widget.dart';
import 'package:one_velocity_web/widgets/text_widgets.dart';

import '../providers/loading_provider.dart';
import '../utils/firebase_util.dart';
import '../utils/go_router_util.dart';
import '../utils/string_util.dart';
import '../widgets/custom_miscellaneous_widgets.dart';
import '../widgets/custom_padding_widgets.dart';

class ViewPurchasesScreen extends ConsumerStatefulWidget {
  const ViewPurchasesScreen({super.key});

  @override
  ConsumerState<ViewPurchasesScreen> createState() =>
      _ViewPurchasesScreenState();
}

class _ViewPurchasesScreenState extends ConsumerState<ViewPurchasesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      ref.read(loadingProvider.notifier).toggleLoading(true);
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      final goRouter = GoRouter.of(context);
      try {
        if (hasLoggedInUser() &&
            await getCurrentUserType() == UserTypes.client) {
          ref.read(loadingProvider.notifier).toggleLoading(false);
          goRouter.goNamed(GoRoutes.home);
          return;
        }

        ref
            .read(paymentsProvider)
            .setPaymentDocs(await getAllProductPaymentDocs());

        ref.read(loadingProvider.notifier).toggleLoading(false);
      } catch (error) {
        scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('Error getting all purchases: $error')));
        ref.read(loadingProvider.notifier).toggleLoading(false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(loadingProvider);
    ref.watch(paymentsProvider);
    return Scaffold(
      appBar: appBarWidget(context, showActions: false),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          leftNavigator(context, path: GoRoutes.viewPurchases),
          SizedBox(
              width: MediaQuery.of(context).size.width * 0.8,
              child: switchedLoadingContainer(
                  ref.read(loadingProvider),
                  SingleChildScrollView(
                    child: horizontal5Percent(context,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            blackSarabunBold('PURCHASES', fontSize: 40),
                            _paymentsContainer(),
                          ],
                        )),
                  )))
        ],
      ),
    );
  }

  Widget _paymentsContainer() {
    return Wrap(
        spacing: 20,
        runSpacing: 20,
        children: ref
            .read(paymentsProvider)
            .paymentDocs
            .map((productPayment) => ProductPaymentWidget(
                ref: ref, productPaymentDoc: productPayment))
            .toList());
  }
}
