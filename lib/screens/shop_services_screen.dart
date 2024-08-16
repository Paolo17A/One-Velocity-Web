import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:one_velocity_web/widgets/text_widgets.dart';

import '../providers/loading_provider.dart';
import '../providers/pages_provider.dart';
import '../utils/color_util.dart';
import '../utils/firebase_util.dart';
import '../utils/go_router_util.dart';
import '../utils/string_util.dart';
import '../widgets/app_bar_widget.dart';
import '../widgets/custom_button_widgets.dart';
import '../widgets/custom_miscellaneous_widgets.dart';
import '../widgets/custom_padding_widgets.dart';
import '../widgets/dropdown_widget.dart';
import '../widgets/item_entry_widget.dart';

class ShopServicesScreen extends ConsumerStatefulWidget {
  const ShopServicesScreen({super.key});

  @override
  ConsumerState<ShopServicesScreen> createState() => _ShopServicesScreenState();
}

class _ShopServicesScreenState extends ConsumerState<ShopServicesScreen> {
  List<DocumentSnapshot> allServiceDocs = [];
  List<DocumentSnapshot> filteredServiceDocs = [];
  String selectedCategory = 'VIEW ALL';

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
        filteredServiceDocs = allServiceDocs;
        ref.read(pagesProvider.notifier).setCurrentPage(1);
        ref
            .read(pagesProvider.notifier)
            .setMaxPage((allServiceDocs.length / 20).ceil());
        ref.read(loadingProvider.notifier).toggleLoading(false);
      } catch (error) {
        scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('Error getting all services: $error')));
        ref.read(loadingProvider.notifier).toggleLoading(false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(loadingProvider);
    return Scaffold(
      appBar: appBarWidget(context),
      body: switchedLoadingContainer(
          ref.read(loadingProvider),
          SingleChildScrollView(
            child: Column(
              children: [
                secondAppBar(context),
                servicesHeader(),
                _servicesCategoryWidget(),
                _availableServices(),
                footerWidget(context)
              ],
            ),
          )),
    );
  }

  Widget servicesHeader() {
    return blackSarabunBold(
        '${selectedCategory == 'VIEW ALL' ? 'ALL SERVICES' : '$selectedCategory SERVICES'}',
        fontSize: 40);
  }

  Widget _servicesCategoryWidget() {
    return Container(
      width: MediaQuery.of(context).size.width * 0.3,
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(5)),
      child: Column(
        children: [
          dropdownWidget(selectedCategory, (newVal) {
            setState(() {
              selectedCategory = newVal!;
              print(selectedCategory);
              if (selectedCategory == 'VIEW ALL') {
                filteredServiceDocs = allServiceDocs;
              } else {
                filteredServiceDocs = allServiceDocs.where((serviceDoc) {
                  final serviceData =
                      serviceDoc.data() as Map<dynamic, dynamic>;
                  return serviceData[ServiceFields.category] ==
                      selectedCategory;
                }).toList();
              }
            });
          },
              [
                'VIEW ALL',
                ServiceCategories.paintJob,
                ServiceCategories.repair
              ],
              selectedCategory.isNotEmpty
                  ? selectedCategory
                  : 'Select a category',
              false),
          vertical10Pix(
              child: Container(
                  width: MediaQuery.of(context).size.width * 0.4,
                  height: 8,
                  color: CustomColors.crimson))
        ],
      ),
    );
  }

  Widget _availableServices() {
    int currentPage = ref.read(pagesProvider.notifier).getCurrentPage();
    int maxPage = ref.read(pagesProvider.notifier).getMaxPage();
    List<DocumentSnapshot> servicesSublist = filteredServiceDocs.sublist(
        (currentPage - 1) * 20,
        min(filteredServiceDocs.length, ((currentPage - 1) * 20) + 20));
    return Column(
      children: [
        all20Pix(
            child: filteredServiceDocs.isNotEmpty
                ? Wrap(
                    alignment: currentPage == maxPage
                        ? WrapAlignment.start
                        : WrapAlignment.spaceEvenly,
                    spacing: 100,
                    runSpacing: 100,
                    children: servicesSublist.asMap().entries.map((item) {
                      DocumentSnapshot thisService =
                          allServiceDocs[item.key + ((currentPage - 1) * 20)];
                      return itemEntry(context,
                          itemDoc: thisService,
                          onPress: () => GoRouter.of(context).goNamed(
                                  GoRoutes.selectedService,
                                  pathParameters: {
                                    PathParameters.serviceID: thisService.id
                                  }));
                    }).toList())
                : blackSarabunBold('NO SERVICES AVAILABLE', fontSize: 44)),
        if (allServiceDocs.length > 20)
          navigatorButtons(context,
              pageNumber: currentPage,
              onPrevious: () => currentPage == 1
                  ? null
                  : ref
                      .read(pagesProvider.notifier)
                      .setCurrentPage(currentPage + 1),
              onNext: () => currentPage == maxPage
                  ? null
                  : ref
                      .read(pagesProvider.notifier)
                      .setCurrentPage(currentPage - 1))
      ],
    );
  }
}
