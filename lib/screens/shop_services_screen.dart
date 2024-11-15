import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:one_velocity_web/providers/pages_provider.dart';
import 'package:one_velocity_web/widgets/text_widgets.dart';

import '../providers/category_provider.dart';
import '../providers/loading_provider.dart';
import '../utils/color_util.dart';
import '../utils/firebase_util.dart';
import '../utils/go_router_util.dart';
import '../utils/string_util.dart';
import '../widgets/app_bar_widget.dart';
import '../widgets/custom_button_widgets.dart';
import '../widgets/custom_miscellaneous_widgets.dart';
import '../widgets/custom_padding_widgets.dart';
import '../widgets/floating_chat_widget.dart';
import '../widgets/item_entry_widget.dart';

class ShopServicesScreen extends ConsumerStatefulWidget {
  const ShopServicesScreen({super.key});

  @override
  ConsumerState<ShopServicesScreen> createState() => _ShopServicesScreenState();
}

class _ShopServicesScreenState extends ConsumerState<ShopServicesScreen> {
  List<DocumentSnapshot> allServiceDocs = [];
  List<DocumentSnapshot> filteredServiceDocs = [];
  List<DocumentSnapshot> currentlyDisplayedFilteredService = [];
  int currentPage = 0;
  int maxPage = 0;
  int servicesPerPage = 8;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      ref.read(loadingProvider.notifier).toggleLoading(true);
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      final goRouter = GoRouter.of(context);
      try {
        if (hasLoggedInUser() &&
            await getCurrentUserType() == UserTypes.admin) {
          goRouter.goNamed(GoRoutes.home);
          return;
        }
        allServiceDocs = await getAllServices();
        setFilteredServices();
        ref.read(loadingProvider.notifier).toggleLoading(false);
      } catch (error) {
        scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('Error getting all services: $error')));
        ref.read(loadingProvider.notifier).toggleLoading(false);
      }
    });
  }

  void setFilteredServices() {
    currentPage = 0;
    String currentCategory = ref.read(categoryProvider).currentCategory;
    setState(() {
      if (currentCategory == 'VIEW ALL') {
        filteredServiceDocs = allServiceDocs;
      } else {
        filteredServiceDocs = allServiceDocs.where((service) {
          final serviceData = service.data() as Map<dynamic, dynamic>;
          String category = serviceData[ServiceFields.category];
          return category == currentCategory;
        }).toList();
      }
      maxPage = (filteredServiceDocs.length / servicesPerPage).floor();
      if (filteredServiceDocs.length % servicesPerPage == 0) maxPage--;
    });
    setDisplayedServices();
  }

  void setDisplayedServices() {
    if (filteredServiceDocs.length > servicesPerPage) {
      currentlyDisplayedFilteredService = filteredServiceDocs
          .getRange(
              currentPage * servicesPerPage,
              min((currentPage * servicesPerPage) + servicesPerPage,
                  filteredServiceDocs.length))
          .toList();
    } else
      currentlyDisplayedFilteredService = filteredServiceDocs;
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(loadingProvider);
    ref.watch(categoryProvider);
    ref.watch(pagesProvider);
    return Scaffold(
      appBar: appBarWidget(context),
      floatingActionButton: hasLoggedInUser()
          ? FloatingChatWidget(
              senderUID: FirebaseAuth.instance.currentUser!.uid,
              otherUID: adminID)
          : null,
      body: switchedLoadingContainer(
          ref.read(loadingProvider),
          Column(
            children: [
              secondAppBar(context),
              SizedBox(
                height: MediaQuery.of(context).size.height - 100,
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _serviceCategoryWidget(),
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.8,
                        height: MediaQuery.of(context).size.height * 0.9,
                        child: SingleChildScrollView(
                          child: Column(children: [
                            servicesHeader(),
                            _availableServices(),
                            if (filteredServiceDocs.length > servicesPerPage)
                              all20Pix(
                                child: pageNavigatorButtons(
                                    currentPage: currentPage,
                                    maxPage: maxPage,
                                    onPreviousPage: () {
                                      currentPage--;
                                      setState(() {
                                        setDisplayedServices();
                                      });
                                    },
                                    onNextPage: () {
                                      currentPage++;
                                      setState(() {
                                        setDisplayedServices();
                                      });
                                    }),
                              )
                          ]),
                        ),
                      )
                    ]),
              )
            ],
          )),
    );
  }

  Widget servicesHeader() {
    return blackSarabunBold(
        '${ref.read(categoryProvider).currentCategory == 'VIEW ALL' ? 'ALL SERVICES' : '${ref.read(categoryProvider).currentCategory} SERVICES'}',
        fontSize: 40);
  }

  Widget _serviceCategoryWidget() {
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
              color: ref.read(categoryProvider).currentCategory == "VIEW ALL"
                  ? CustomColors.grenadine
                  : CustomColors.crimson,
              child: ListTile(
                  title:
                      Text('VIEW ALL', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    ref.read(categoryProvider).setCategory('VIEW ALL');
                    setFilteredServices();
                  }),
            ),
            Container(
              color: ref.read(categoryProvider).currentCategory ==
                      ServiceCategories.paintJob
                  ? CustomColors.grenadine
                  : CustomColors.crimson,
              child: ListTile(
                  title: Text(ServiceCategories.paintJob,
                      style: TextStyle(color: Colors.white)),
                  onTap: () {
                    ref
                        .read(categoryProvider)
                        .setCategory(ServiceCategories.paintJob);
                    setFilteredServices();
                  }),
            ),
            Container(
              color: ref.read(categoryProvider).currentCategory ==
                      ServiceCategories.repair
                  ? CustomColors.grenadine
                  : CustomColors.crimson,
              child: ListTile(
                  title: Text(ServiceCategories.repair,
                      style: TextStyle(color: Colors.white)),
                  onTap: () {
                    ref
                        .read(categoryProvider)
                        .setCategory(ServiceCategories.repair);
                    setFilteredServices();
                  }),
            )
          ])),
    );
  }

  Widget _availableServices() {
    return Column(
      children: [
        all20Pix(
            child: currentlyDisplayedFilteredService.isNotEmpty
                ? Wrap(
                    alignment: WrapAlignment.start,
                    spacing: 100,
                    runSpacing: 100,
                    children: currentlyDisplayedFilteredService
                        .asMap()
                        .entries
                        .map((item) {
                      DocumentSnapshot thisService =
                          currentlyDisplayedFilteredService[item.key];
                      return itemEntry(context,
                          itemDoc: thisService,
                          onPress: () => GoRouter.of(context).goNamed(
                                  GoRoutes.selectedService,
                                  pathParameters: {
                                    PathParameters.serviceID: thisService.id
                                  }));
                    }).toList())
                : blackSarabunBold('NO SERVICES AVAILABLE', fontSize: 44)),
      ],
    );
  }
}
