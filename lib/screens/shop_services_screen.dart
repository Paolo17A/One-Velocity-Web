import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:one_velocity_web/widgets/text_widgets.dart';

import '../providers/loading_provider.dart';
import '../providers/pages_provider.dart';
import '../utils/firebase_util.dart';
import '../utils/go_router_util.dart';
import '../utils/string_util.dart';
import '../widgets/app_bar_widget.dart';
import '../widgets/custom_button_widgets.dart';
import '../widgets/custom_miscellaneous_widgets.dart';
import '../widgets/custom_padding_widgets.dart';
import '../widgets/item_entry_widget.dart';

class ShopServicesScreen extends ConsumerStatefulWidget {
  const ShopServicesScreen({super.key});

  @override
  ConsumerState<ShopServicesScreen> createState() => _ShopServicesScreenState();
}

class _ShopServicesScreenState extends ConsumerState<ShopServicesScreen> {
  List<DocumentSnapshot> allServiceDocs = [];
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
                horizontal5Percent(
                  context,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [servicesHeader(), _availableServices()],
                  ),
                ),
              ],
            ),
          )),
    );
  }

  Widget servicesHeader() {
    return Row(children: [
      montserratBlackBold('ALL AVAILABLE SERVICES', fontSize: 60)
    ]);
  }

  Widget _availableServices() {
    int currentPage = ref.read(pagesProvider.notifier).getCurrentPage();
    int maxPage = ref.read(pagesProvider.notifier).getMaxPage();
    List<DocumentSnapshot> servicesSublist = allServiceDocs.sublist(
        (currentPage - 1) * 20,
        min(allServiceDocs.length, ((currentPage - 1) * 20) + 20));
    return Column(
      children: [
        all20Pix(
            child: allServiceDocs.isNotEmpty
                ? Wrap(
                    alignment: currentPage == maxPage
                        ? WrapAlignment.start
                        : WrapAlignment.spaceEvenly,
                    spacing: 10,
                    runSpacing: 10,
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
                : montserratBlackBold('NO SERVICES AVAILABLE', fontSize: 44)),
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
