import 'package:carousel_slider/carousel_slider.dart';
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
  Map<String, double> paymentBreakdown = {
    'PENDING': 0,
    'APPROVED': 0,
    'DENIED': 0
  };
  num totalSales = 0;
  //  CLIENT
  List<DocumentSnapshot> productDocs = [];
  List<DocumentSnapshot> wheelProductDocs = [];
  List<DocumentSnapshot> batteryProductDocs = [];
  List<DocumentSnapshot> serviceDocs = [];
  List<DocumentSnapshot> paymentDocs = [];

  CarouselSliderController wheelsController = CarouselSliderController();
  CarouselSliderController batteryController = CarouselSliderController();
  CarouselSliderController allProductsController = CarouselSliderController();
  CarouselSliderController allServicesController = CarouselSliderController();

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
          }
        } else {
          productDocs = await getAllProducts();
          serviceDocs = await getAllServices();
        }

        wheelProductDocs = productDocs.where((productDoc) {
          final productData = productDoc.data() as Map<dynamic, dynamic>;
          return productData[ProductFields.category] == ProductCategories.wheel;
        }).toList();
        batteryProductDocs = productDocs.where((productDoc) {
          final productData = productDoc.data() as Map<dynamic, dynamic>;
          return productData[ProductFields.category] ==
              ProductCategories.battery;
        }).toList();

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
        hasLoggedInUser() && ref.read(userTypeProvider) == UserTypes.admin
            ? adminDashboard()
            : regularHome(),
      ),
    );
  }

  Widget regularHome() {
    return SingleChildScrollView(
      child: Column(
        children: [
          secondAppBar(context),
          landingWidget(),
          if (wheelProductDocs.isNotEmpty) _wheelProducts(),
          if (batteryProductDocs.isNotEmpty) _batteryProducts(),
          if (productDocs.isNotEmpty) _allProducts(),
          if (serviceDocs.isNotEmpty) _allServices(),
          footerWidget(context)
        ],
      ),
    );
  }

  Widget landingWidget() {
    return Container(
      width: double.infinity,
      height: 600,
      decoration: BoxDecoration(
        image: DecorationImage(
            image: AssetImage(ImagePaths.landing), fit: BoxFit.fill),
      ),
    );
  }

  Widget _wheelProducts() {
    wheelProductDocs.shuffle();
    return itemCarouselTemplate(context,
        label: 'Wheels',
        carouselSliderController: wheelsController,
        itemDocs: wheelProductDocs);
  }

  Widget _batteryProducts() {
    batteryProductDocs.shuffle();
    return itemCarouselTemplate(context,
        label: 'Batteries',
        carouselSliderController: batteryController,
        itemDocs: batteryProductDocs);
  }

  Widget _allProducts() {
    productDocs.shuffle();
    return itemCarouselTemplate(context,
        label: 'All Products',
        carouselSliderController: allProductsController,
        itemDocs: productDocs);
  }

  Widget _allServices() {
    serviceDocs.shuffle();
    return vertical20Pix(
      child: Container(
          width: MediaQuery.of(context).size.width,
          padding: const EdgeInsets.all(10),
          child: Column(children: [
            blackSarabunBold("All Services", fontSize: 32),
            Container(width: 220, height: 8, color: CustomColors.crimson),
            Gap(10),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              IconButton(
                  onPressed: () => allServicesController.previousPage(),
                  icon: blackSarabunRegular('<', fontSize: 60)),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                height: 400,
                child: CarouselSlider.builder(
                  carouselController: allServicesController,
                  itemCount: serviceDocs.length,
                  disableGesture: true,
                  options: CarouselOptions(
                      viewportFraction: 0.2,
                      enlargeCenterPage: true,
                      scrollPhysics: NeverScrollableScrollPhysics(),
                      enlargeFactor: 0.2),
                  itemBuilder: (context, index, realIndex) {
                    return itemEntry(context,
                        itemDoc: serviceDocs[index],
                        onPress: () => GoRouter.of(context).goNamed(
                                GoRoutes.selectedService,
                                pathParameters: {
                                  PathParameters.serviceID:
                                      serviceDocs[index].id
                                }));
                  },
                ),
              ),
              IconButton(
                  onPressed: () => allServicesController.nextPage(),
                  icon: blackSarabunRegular('>', fontSize: 60)),
            ])
          ])),
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
          height: MediaQuery.of(context).size.height,
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
              color: CustomColors.nimbusCloud,
              boxShadow: [
                BoxShadow(offset: Offset(4, 4), blurRadius: 4, spreadRadius: -4)
              ]),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            blackSarabunRegular(
                'OVERALL TOTAL SALES: PHP ${formatPrice(totalSales.toDouble())}',
                fontSize: 30),
            blackSarabunRegular(
                'Best Selling Product: ${bestSellerName.isNotEmpty ? bestSellerName : 'N/A'}',
                fontSize: 18),
            blackSarabunRegular(
                'Best Selling Service: ${topRatedName.isNotEmpty ? topRatedName : 'N/A'}',
                fontSize: 18)
          ])),
    );
  }

  Widget _analyticsBreakdown() {
    return vertical20Pix(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        child: Wrap(
          spacing: 50,
          runSpacing: 50,
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
            blackSarabunBold('PAYMENT STATUSES'),
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
