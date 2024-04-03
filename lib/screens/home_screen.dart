import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:one_velocity_web/utils/color_util.dart';
import 'package:one_velocity_web/widgets/app_bar_widget.dart';
import 'package:pie_chart/pie_chart.dart';

import '../providers/loading_provider.dart';
import '../providers/user_type_provider.dart';
import '../utils/firebase_util.dart';
import '../utils/go_router_util.dart';
import '../utils/string_util.dart';
import '../widgets/custom_miscellaneous_widgets.dart';
import '../widgets/custom_padding_widgets.dart';
import '../widgets/left_navigator_widget.dart';
import '../widgets/text_widgets.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  //  ADMIN
  int productsCount = 0;
  int servicesCount = 0;
  int userCount = 0;

  //  CLIENT
  List<DocumentSnapshot> productDocs = [];
  List<DocumentSnapshot> serviceDocs = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      ref.read(loadingProvider.notifier).toggleLoading(true);
      if (hasLoggedInUser()) {
        ref
            .read(userTypeProvider.notifier)
            .setUserType(await getCurrentUserType());
      }
      if (ref.read(userTypeProvider) == UserTypes.admin) {
        final products = await getAllProducts();
        productsCount = products.length;
        final services = await getAllServices();
        servicesCount = services.length;
        final users = await getAllClientDocs();
        userCount = users.length;
      } else {
        productDocs = await getAllProducts();
        serviceDocs = await getAllServices();
        setState(() {});
      }
      ref.read(loadingProvider.notifier).toggleLoading(false);
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(loadingProvider);
    return Scaffold(
      appBar: appBarWidget(context,
          showActions: !hasLoggedInUser() ||
              ref.read(userTypeProvider) == UserTypes.client),
      body: switchedLoadingContainer(
        ref.read(loadingProvider),
        SingleChildScrollView(
          child:
              hasLoggedInUser() && ref.read(userTypeProvider) == UserTypes.admin
                  ? adminDashboard()
                  : regularHome(),
        ),
      ),
    );
  }

  Widget regularHome() {
    return Column(
      children: [secondAppBar(context)],
    );
  }

  //============================================================================
  //  ADMIN WIDGETS

  Widget adminDashboard() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        leftNavigator(context, path: GoRoutes.home),
        SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          child: switchedLoadingContainer(
              ref.read(loadingProvider),
              SingleChildScrollView(
                child: horizontal5Percent(context,
                    child: Column(
                      children: [
                        _platformSummary(),
                        _analyticsBreakdown(),
                        Row(children: [_paymentStatuses()])
                      ],
                    )),
              )),
        )
      ],
    );
  }

  Widget _platformSummary() {
    String topRatedName = '';
    String bestSellerName = '';

    return vertical20Pix(
      child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: CustomColors.blackBeauty,
          ),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            montserratWhiteBold('OVERALL TOTAL SALES: PHP 0.00', fontSize: 30),
            montserratWhiteBold(
                'Best Selling Product: ${bestSellerName.isNotEmpty ? bestSellerName : 'N/A'}',
                fontSize: 18),
            montserratWhiteBold(
                'Best Selling Service: ${topRatedName.isNotEmpty ? topRatedName : 'N/A'}',
                fontSize: 18)
          ])),
    );
  }

  Widget _analyticsBreakdown() {
    return vertical20Pix(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: CustomColors.ultimateGray,
        ),
        child: Wrap(
          spacing: MediaQuery.of(context).size.width * 0.01,
          runSpacing: MediaQuery.of(context).size.height * 0.01,
          alignment: WrapAlignment.spaceEvenly,
          runAlignment: WrapAlignment.spaceEvenly,
          children: [
            analyticReportWidget(context,
                count: productsCount.toString(),
                demographic: 'Available Products',
                displayIcon: const Icon(Icons.settings),
                onPress: () =>
                    GoRouter.of(context).goNamed(GoRoutes.viewProducts)),
            analyticReportWidget(context,
                count: servicesCount.toString(),
                demographic: 'Available Services',
                displayIcon: const Icon(Icons.home_repair_service),
                onPress: () =>
                    GoRouter.of(context).goNamed(GoRoutes.viewServices)),
            analyticReportWidget(context,
                count: userCount.toString(),
                demographic: 'Registered Users',
                displayIcon: const Icon(Icons.people),
                onPress: () =>
                    GoRouter.of(context).goNamed(GoRoutes.viewUsers)),
            analyticReportWidget(context,
                count: '0',
                demographic: 'Ongoing Job Orders',
                displayIcon: const Icon(Icons.online_prediction_sharp),
                onPress: () {}),
          ],
        ),
      ),
    );
  }

  Widget _paymentStatuses() {
    return breakdownContainer(context,
        child: Column(
          children: [
            montserratBlackBold('PAYMENT STATUSES'),
            const PieChart(dataMap: {
              'PENDING': 1,
              'APPROVED': 4,
              'DENIED': 0
            }, colorList: [
              CustomColors.grenadine,
              CustomColors.ultimateGray,
              CustomColors.blackBeauty
            ], chartValuesOptions: ChartValuesOptions(decimalPlaces: 0)),
          ],
        ));
  }
}
