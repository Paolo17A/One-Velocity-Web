import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:one_velocity_web/main.dart';
import 'package:one_velocity_web/providers/category_provider.dart';
import 'package:one_velocity_web/utils/color_util.dart';
import 'package:one_velocity_web/widgets/active_clients_widget.dart';
import 'package:one_velocity_web/widgets/app_bar_widget.dart';
import 'package:one_velocity_web/widgets/floating_chat_widget.dart';
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
  Map<String, double> paymentBreakdown = {
    'PENDING': 0,
    'APPROVED': 0,
    'DENIED': 0
  };
  Map<String, double> productNameAndOrderMap = {};
  Map<String, double> serviceNameAndOrderMap = {};

  num totalSales = 0;
  String bestSellingProduct = '';
  num ongoingBookings = 0;
  num totalTransactions = 0;
  String bestSellingService = '';
  num completedPurchases = 0;
  num completedBookings = 0;
  //  CLIENT
  List<DocumentSnapshot> productDocs = [];
  List<DocumentSnapshot> wheelProductDocs = [];
  List<DocumentSnapshot> batteryProductDocs = [];
  List<DocumentSnapshot> paintJobDocs = [];
  List<DocumentSnapshot> repairDocs = [];

  List<DocumentSnapshot> serviceDocs = [];
  List<DocumentSnapshot> paymentDocs = [];
  List<DocumentSnapshot> purchaseDocs = [];
  List<DocumentSnapshot> bookingDocs = [];

  CarouselSliderController wheelsController = CarouselSliderController();
  CarouselSliderController batteryController = CarouselSliderController();
  CarouselSliderController allProductsController = CarouselSliderController();
  CarouselSliderController allServicesController = CarouselSliderController();
  int maxItemsPerRow = 5;
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
            MyApp.displaySearchBar = false;

            final products = await getAllProducts();
            productsCount = products.length;
            final services = await getAllServices();
            servicesCount = services.length;
            final users = await getAllClientDocs();
            userCount = users.length;
            paymentDocs = await getAllPaymentDocs();
            totalTransactions = paymentDocs.length;
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
            purchaseDocs = await getAllPurchaseDocs();
            completedPurchases = purchaseDocs
                .where((element) {
                  final purchaseData = element.data() as Map<dynamic, dynamic>;
                  return purchaseData[PurchaseFields.purchaseStatus] ==
                      PurchaseStatuses.pickedUp;
                })
                .toList()
                .length;
            await _establishBestSellingProduct();
            for (var purchase in purchaseDocs) {
              final purchaseData = purchase.data() as Map<dynamic, dynamic>;

              String productID = purchaseData[PurchaseFields.productID];
              DocumentSnapshot? itemDoc =
                  products.where((item) => item.id == productID).firstOrNull;
              if (itemDoc == null) continue;
              final itemData = itemDoc.data() as Map<dynamic, dynamic>;
              String name = itemData[ProductFields.name];
              if (productNameAndOrderMap.containsKey(name)) {
                productNameAndOrderMap[name] =
                    productNameAndOrderMap[name]! + 1;
              } else {
                productNameAndOrderMap[name] = 1;
              }
            }
            bookingDocs = await getAllBookingDocs();
            for (var booking in bookingDocs) {
              final bookingData = booking.data() as Map<dynamic, dynamic>;

              List<dynamic> serviceIDs = bookingData[BookingFields.serviceIDs];
              DocumentSnapshot? itemDoc = services
                  .where((item) => serviceIDs.contains(item.id))
                  .firstOrNull;
              if (itemDoc == null) continue;
              final itemData = itemDoc.data() as Map<dynamic, dynamic>;
              String name = itemData[ServiceFields.name];
              if (serviceNameAndOrderMap.containsKey(name)) {
                serviceNameAndOrderMap[name] =
                    serviceNameAndOrderMap[name]! + 1;
              } else {
                serviceNameAndOrderMap[name] = 1;
              }
            }
            ongoingBookings = bookingDocs
                .where((bookingDoc) {
                  final bookingData =
                      bookingDoc.data() as Map<dynamic, dynamic>;
                  return bookingData[BookingFields.serviceStatus] ==
                          ServiceStatuses.serviceOngoing ||
                      bookingData[BookingFields.serviceStatus] ==
                          ServiceStatuses.pendingDropOff;
                })
                .toList()
                .length;
            completedBookings = bookingDocs
                .where((bookingDoc) {
                  final bookingData =
                      bookingDoc.data() as Map<dynamic, dynamic>;
                  return bookingData[BookingFields.serviceStatus] ==
                      ServiceStatuses.serviceCompleted;
                })
                .toList()
                .length;
            await _establishBestSellingService();
          } else {
            MyApp.displaySearchBar = true;
            productDocs = await getAllProducts();
            serviceDocs = await getAllServices();
          }
        } else {
          MyApp.displaySearchBar = true;
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
        paintJobDocs = serviceDocs.where((serviceDoc) {
          final serviceData = serviceDoc.data() as Map<dynamic, dynamic>;
          return serviceData[ServiceFields.category] ==
              ServiceCategories.paintJob;
        }).toList();
        repairDocs = serviceDocs.where((serviceDoc) {
          final serviceData = serviceDoc.data() as Map<dynamic, dynamic>;
          return serviceData[ServiceFields.category] ==
              ServiceCategories.repair;
        }).toList();
        ref.read(loadingProvider.notifier).toggleLoading(false);
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error initializing home: $error')));
        ref.read(loadingProvider.notifier).toggleLoading(false);
      }
    });
  }

  Future _establishBestSellingProduct() async {
    Map<String, int> productsCountMap = {};
    int highestCount = 0;
    String highestCountProductID = '';
    List<DocumentSnapshot> filteredPurchaseDocs =
        purchaseDocs.where((purchaseDoc) {
      final purchaseData = purchaseDoc.data() as Map<dynamic, dynamic>;
      return purchaseData[PurchaseFields.purchaseStatus] ==
              PurchaseStatuses.pickedUp ||
          purchaseData[PurchaseFields.purchaseStatus] ==
              PurchaseStatuses.processing ||
          purchaseData[PurchaseFields.purchaseStatus] ==
              PurchaseStatuses.forPickUp;
    }).toList();
    for (var purchase in filteredPurchaseDocs) {
      final purchaseData = purchase.data() as Map<dynamic, dynamic>;
      String productID = purchaseData[PurchaseFields.productID];
      if (productsCountMap.containsKey(productID)) {
        productsCountMap[productID] = productsCountMap[productID]! + 1;
      } else {
        productsCountMap[productID] = 1;
      }
    }
    if (productsCountMap.isEmpty) return;
    productsCountMap.forEach((productID, count) {
      if (count > highestCount) {
        highestCountProductID = productID;
        highestCount = count;
      }
    });
    if (purchaseDocs.isNotEmpty && highestCountProductID.isNotEmpty) {
      DocumentSnapshot bestProduct =
          await getThisProductDoc(highestCountProductID);
      final productData = bestProduct.data() as Map<dynamic, dynamic>;
      bestSellingProduct = productData[ProductFields.name];
    }
  }

  Future _establishBestSellingService() async {
    Map<String, int> servicesCountMap = {};
    int highestCount = 0;
    String highestCountServicesID = '';
    List<DocumentSnapshot> filteredBookingDocs =
        bookingDocs.where((bookingDoc) {
      final bookingData = bookingDoc.data() as Map<dynamic, dynamic>;
      return bookingData[BookingFields.serviceStatus] !=
              ServiceStatuses.cancelled &&
          bookingData[BookingFields.serviceStatus] != ServiceStatuses.denied &&
          bookingData[BookingFields.serviceStatus] !=
              ServiceStatuses.pendingApproval;
    }).toList();
    for (var booking in filteredBookingDocs) {
      final bookingData = booking.data() as Map<dynamic, dynamic>;
      List<dynamic> serviceIDs = bookingData[BookingFields.serviceIDs];
      for (var serviceID in serviceIDs) {
        if (servicesCountMap.containsKey(serviceID)) {
          servicesCountMap[serviceID] = servicesCountMap[serviceID]! + 1;
        } else {
          servicesCountMap[serviceID] = 1;
        }
      }
    }
    if (servicesCountMap.isEmpty) return;
    servicesCountMap.forEach((productID, count) {
      if (count > highestCount) {
        highestCountServicesID = productID;
        highestCount = count;
      }
    });
    if (bookingDocs.isNotEmpty && highestCountServicesID.isNotEmpty) {
      DocumentSnapshot bestService =
          await getThisServiceDoc(highestCountServicesID);
      final serviceData = bestService.data() as Map<dynamic, dynamic>;
      bestSellingService = serviceData[ServiceFields.name];
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(loadingProvider);
    ref.watch(userTypeProvider);
    return Scaffold(
      appBar: appBarWidget(context,
          showActions: !hasLoggedInUser() ||
              ref.read(userTypeProvider) == UserTypes.client),
      floatingActionButton:
          hasLoggedInUser() && ref.read(userTypeProvider) == UserTypes.client
              ? FloatingChatWidget(
                  senderUID: FirebaseAuth.instance.currentUser!.uid,
                  otherUID: adminID)
              : null,
      body: switchedLoadingContainer(
        ref.read(loadingProvider),
        hasLoggedInUser() && ref.read(userTypeProvider) == UserTypes.admin
            ? adminDashboard()
            : regularHome(),
      ),
    );
  }

  Widget regularHome() {
    maxItemsPerRow = (MediaQuery.of(context).size.width / 350).floor();
    return Container(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      decoration: BoxDecoration(
          image: DecorationImage(
              image: AssetImage(ImagePaths.background), fit: BoxFit.cover)),
      child: Stack(
        children: [
          Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              color: Colors.white.withOpacity(0.95)),
          SingleChildScrollView(
            child: Column(
              children: [
                secondAppBar(context),
                landingWidget(),
                _categoriesSelector(),
                _categoriesCarousel(),
                if (productDocs.isNotEmpty) _allProducts(),
                if (serviceDocs.isNotEmpty) _allServices(),
                Gap(40),
                footerWidget(context)
              ],
            ),
          ),
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
        ));
  }

  Widget _categoriesSelector() {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Expanded(
            child: InkWell(
                onTap: () {
                  ref
                      .read(categoryProvider)
                      .setCategory(ProductCategories.wheel);
                  GoRouter.of(context).goNamed(GoRoutes.products);
                },
                child: Container(
                    height: 160,
                    decoration: BoxDecoration(
                      border: Border.all(),
                      image: DecorationImage(
                          fit: BoxFit.cover,
                          image: AssetImage(ImagePaths.wheel)),
                    ),
                    child: Stack(
                      children: [
                        Container(
                            color: CustomColors.blackBeauty.withOpacity(0.5)),
                        Center(child: whiteSarabunBold('WHEELS', fontSize: 28)),
                      ],
                    )))),
        Expanded(
            child: InkWell(
                onTap: () {
                  ref
                      .read(categoryProvider)
                      .setCategory(ProductCategories.battery);
                  GoRouter.of(context).goNamed(GoRoutes.products);
                },
                child: Container(
                    height: 160,
                    decoration: BoxDecoration(
                        border: Border.all(),
                        image: DecorationImage(
                            fit: BoxFit.cover,
                            image: AssetImage(ImagePaths.battery)),
                        color: CustomColors.blackBeauty.withOpacity(0.5)),
                    child: Stack(
                      children: [
                        Container(
                            color: CustomColors.blackBeauty.withOpacity(0.5)),
                        Center(
                            child: whiteSarabunBold('BATTERIES', fontSize: 28)),
                      ],
                    )))),
        Expanded(
            child: InkWell(
                onTap: () {
                  ref
                      .read(categoryProvider)
                      .setCategory(ServiceCategories.paintJob);
                  GoRouter.of(context).goNamed(GoRoutes.services);
                },
                child: Container(
                    height: 160,
                    decoration: BoxDecoration(
                        border: Border.all(),
                        image: DecorationImage(
                            fit: BoxFit.cover,
                            image: AssetImage(ImagePaths.paintJob)),
                        color: CustomColors.blackBeauty.withOpacity(0.5)),
                    child: Stack(
                      children: [
                        Container(
                            color: CustomColors.blackBeauty.withOpacity(0.5)),
                        Center(
                            child:
                                whiteSarabunBold('PAINT JOBS', fontSize: 28)),
                      ],
                    )))),
        Expanded(
            child: InkWell(
                onTap: () {
                  ref
                      .read(categoryProvider)
                      .setCategory(ServiceCategories.repair);
                  GoRouter.of(context).goNamed(GoRoutes.services);
                },
                child: Container(
                    height: 160,
                    decoration: BoxDecoration(
                        border: Border.all(),
                        image: DecorationImage(
                            fit: BoxFit.cover,
                            image: AssetImage(ImagePaths.repair)),
                        color: CustomColors.blackBeauty.withOpacity(0.5)),
                    child: Stack(
                      children: [
                        Container(
                            color: CustomColors.blackBeauty.withOpacity(0.5)),
                        Center(
                            child: whiteSarabunBold('REPAIRS', fontSize: 28)),
                      ],
                    )))),
      ]),
    );
  }

  Widget _categoriesCarousel() {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      height: 550,
      child: CarouselSlider(
        items: [
          _wheelProducts(),
          _batteryProducts(),
          _paintJobs(),
          _repairs(),
        ],
        options: CarouselOptions(
            //height: hasLoggedInUser() ? 540 : 485,
            viewportFraction: 1,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 7)),
      ),
    );
  }

  Widget _wheelProducts() {
    wheelProductDocs.shuffle();
    return itemRowTemplate(context,
        label: 'WHEELS',
        itemDocs: wheelProductDocs.take(maxItemsPerRow).toList(),
        itemType: 'PRODUCT');
  }

  Widget _batteryProducts() {
    batteryProductDocs.shuffle();
    return itemRowTemplate(context,
        label: 'BATTERIES',
        itemDocs: batteryProductDocs.take(maxItemsPerRow).toList(),
        itemType: 'PRODUCT');
  }

  Widget _paintJobs() {
    paintJobDocs.shuffle();
    return itemRowTemplate(context,
        label: 'PAINT JOBS',
        itemDocs: paintJobDocs.take(maxItemsPerRow).toList(),
        itemType: 'SERVICE');
  }

  Widget _repairs() {
    repairDocs.shuffle();
    return itemRowTemplate(context,
        label: 'REPAIRS',
        itemDocs: repairDocs.take(maxItemsPerRow).toList(),
        itemType: 'SERVICE');
  }

  Widget _allProducts() {
    productDocs.shuffle();
    return Column(
      children: [
        itemRowTemplate(context,
            label: 'All Products',
            itemDocs: productDocs.take(maxItemsPerRow * 2).toList(),
            itemType: 'PRODUCT'),
        if (productDocs.length > maxItemsPerRow * 2)
          SizedBox(
              width: MediaQuery.of(context).size.width * 0.8,
              child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                TextButton(
                    onPressed: () =>
                        GoRouter.of(context).goNamed(GoRoutes.products),
                    child: blackSarabunBold('VIEW ALL',
                        decoration: TextDecoration.underline))
              ]))
      ],
    );
  }

  Widget _allServices() {
    serviceDocs.shuffle();
    return Column(
      children: [
        itemRowTemplate(context,
            label: 'All Services',
            itemDocs: serviceDocs.take(maxItemsPerRow * 2).toList(),
            itemType: 'SERVICE'),
        if (serviceDocs.length > maxItemsPerRow * 2)
          SizedBox(
              width: MediaQuery.of(context).size.width * 0.8,
              child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                TextButton(
                    onPressed: () =>
                        GoRouter.of(context).goNamed(GoRoutes.services),
                    child: blackSarabunBold('VIEW ALL',
                        decoration: TextDecoration.underline))
              ]))
      ],
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
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 0.8,
                          child: Wrap(
                              alignment: WrapAlignment.spaceEvenly,
                              runSpacing: 50,
                              children: [
                                _orderBreakdownPieChart(),
                                _bookingBreakdownPieChart(),
                                //_paymentStatuses(),
                              ]),
                        ),
                        ActiveClientsWidget(),
                        Gap(40)
                      ],
                    )),
              )),
        )
      ],
    );
  }

  Widget _platformSummary() {
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
                'Best Selling Product: ${bestSellingProduct.isNotEmpty ? bestSellingProduct : 'N/A'}',
                fontSize: 18),
            blackSarabunRegular(
                'Best Selling Service: ${bestSellingService.isNotEmpty ? bestSellingService : 'N/A'}',
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
          alignment: WrapAlignment.center,
          runAlignment: WrapAlignment.spaceEvenly,
          children: [
            analyticReportWidget(context,
                count: productsCount.toString(),
                demographic: 'Available Products',
                onPress: () =>
                    GoRouter.of(context).goNamed(GoRoutes.viewProducts)),
            analyticReportWidget(context,
                count: servicesCount.toString(),
                demographic: 'Available Services',
                onPress: () =>
                    GoRouter.of(context).goNamed(GoRoutes.viewServices)),
            analyticReportWidget(context,
                count: userCount.toString(),
                demographic: 'Registered Users',
                onPress: () =>
                    GoRouter.of(context).goNamed(GoRoutes.viewUsers)),
            analyticReportWidget(context,
                count: totalTransactions.toString(),
                demographic: 'Total Transactions',
                onPress: () =>
                    GoRouter.of(context).goNamed(GoRoutes.viewTransactions)),
            analyticReportWidget(context,
                count: paymentBreakdown["PENDING"].toString(),
                demographic: 'Pending Transactions',
                onPress: () =>
                    GoRouter.of(context).goNamed(GoRoutes.viewTransactions)),
            analyticReportWidget(context,
                count: completedPurchases.toString(),
                demographic: 'Completed Purchases',
                onPress: () =>
                    GoRouter.of(context).goNamed(GoRoutes.viewPurchases)),
            analyticReportWidget(context,
                count: completedBookings.toString(),
                demographic: 'Completed Bookings',
                onPress: () =>
                    GoRouter.of(context).goNamed(GoRoutes.viewBookings)),
            analyticReportWidget(context,
                count: ongoingBookings.toString(),
                demographic: 'Ongoing Service Bookings',
                onPress: () =>
                    GoRouter.of(context).goNamed(GoRoutes.viewBookings)),
          ],
        ),
      ),
    );
  }

  Widget _paymentStatuses() {
    return breakdownContainer(context,
        child: Column(
          children: [
            blackSarabunBold('TRANSACTION STATUSES'),
            PieChart(
                dataMap: paymentBreakdown,
                colorList: [
                  CustomColors.grenadine,
                  CustomColors.ultimateGray,
                  CustomColors.blackBeauty
                ],
                legendOptions: LegendOptions(
                    legendPosition: LegendPosition.right,
                    legendTextStyle: GoogleFonts.sarabun(color: Colors.black)),
                chartValuesOptions: ChartValuesOptions(decimalPlaces: 0)),
          ],
        ));
  }

  Widget _orderBreakdownPieChart() {
    return breakdownContainer(
      context,
      child: Column(
        children: [
          blackSarabunBold('PRODUCT PURCHASES', fontSize: 20),
          if (productNameAndOrderMap.isNotEmpty)
            PieChart(
                dataMap: productNameAndOrderMap,
                //chartRadius: 300,
                animationDuration: Duration.zero,
                legendOptions: LegendOptions(
                    legendPosition: LegendPosition.right,
                    legendTextStyle: GoogleFonts.sarabun(color: Colors.black)),
                chartValuesOptions: const ChartValuesOptions(decimalPlaces: 0))
          else
            blackSarabunBold('NO ORDERS HAVE BEEN MADE YET')
        ],
      ),
    );
  }

  Widget _bookingBreakdownPieChart() {
    return breakdownContainer(
      context,
      child: Column(
        children: [
          blackSarabunBold('SERVICE BOOKINGS', fontSize: 20),
          if (serviceNameAndOrderMap.isNotEmpty)
            PieChart(
                dataMap: serviceNameAndOrderMap,
                //chartRadius: 300,
                animationDuration: Duration.zero,
                legendOptions: LegendOptions(
                    legendPosition: LegendPosition.right,
                    legendTextStyle: GoogleFonts.sarabun(color: Colors.black)),
                chartValuesOptions: const ChartValuesOptions(decimalPlaces: 0))
          else
            blackSarabunBold('NO BOOKINGS HAVE BEEN MADE YET')
        ],
      ),
    );
  }
}
