import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
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
import '../widgets/item_entry_widget.dart';
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
  List<DocumentSnapshot> paymentDocs = [];
  Map<String, double> paymentBreakdown = {
    'PENDING': 0,
    'APPROVED': 0,
    'DENIED': 0
  };
  num totalSales = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      try {
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
          paymentDocs = await getAllPaymentDocs();
          for (var payment in paymentDocs) {
            final paymentData = payment.data() as Map<dynamic, dynamic>;
            final status = paymentData[PaymentFields.paymentStatus];
            if (status == PaymentStatuses.pending) {
              paymentBreakdown[PaymentStatuses.pending] =
                  paymentBreakdown[PaymentStatuses.pending]! + 1;
            } else if (status == PaymentStatuses.approved) {
              paymentBreakdown[PaymentStatuses.approved] =
                  paymentBreakdown[PaymentStatuses.approved]! + 1;
              totalSales += paymentData[PaymentFields.paidAmount];
            } else if (status == PaymentStatuses.denied) {
              paymentBreakdown[PaymentStatuses.denied] =
                  paymentBreakdown[PaymentStatuses.denied]! + 1;
            }
          }
        } else {
          productDocs = await getAllProducts();
          serviceDocs = await getAllServices();
          setState(() {});
        }
        ref.read(loadingProvider.notifier).toggleLoading(false);
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error initializing home: $error')));
        ref.read(loadingProvider.notifier).toggleLoading(false);
      }
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
      children: [secondAppBar(context), _topProducts()],
    );
  }

  Widget _topProducts() {
    productDocs.shuffle();
    return Container(
      decoration:
          BoxDecoration(border: Border.all(color: CustomColors.ultimateGray)),
      child: LayoutBuilder(
        builder: (context, constraints) {
          int maxItemsToDisplay = (constraints.maxWidth / 275).floor();
          return Column(
            children: [
              Row(children: [
                all20Pix(
                    child: montserratBlackBold('TOP PRODUCTS', fontSize: 25))
              ]),
              Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: productDocs.isNotEmpty
                      ? MainAxisAlignment.start
                      : MainAxisAlignment.center,
                  children: productDocs.isNotEmpty
                      ? productDocs
                          .take(maxItemsToDisplay)
                          .toList()
                          .map((item) => Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 10),
                                child: itemEntry(context,
                                    itemDoc: item,
                                    onPress: () => GoRouter.of(context).goNamed(
                                            GoRoutes.selectedProduct,
                                            pathParameters: {
                                              PathParameters.productID: item.id
                                            }),
                                    fontColor: Colors.white),
                              ))
                          .toList()
                      : [
                          Center(
                              child: montserratBlackBold(
                                  'NO AVAILABLE PRODUCTS TO DISPLAY'))
                        ]),
              const Gap(10),
            ],
          );
        },
      ),
    );
  }

  //============================================================================
  //==ADMIN WIDGETS=============================================================
  //============================================================================

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
            montserratWhiteBold(
                'OVERALL TOTAL SALES: PHP ${totalSales.toStringAsFixed(2)}',
                fontSize: 30),
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
            PieChart(
                dataMap: paymentBreakdown,
                colorList: [
                  CustomColors.grenadine,
                  CustomColors.ultimateGray,
                  CustomColors.blackBeauty
                ],
                chartValuesOptions: ChartValuesOptions(decimalPlaces: 0)),
          ],
        ));
  }
}
