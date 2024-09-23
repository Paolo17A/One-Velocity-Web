import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/loading_provider.dart';
import '../providers/pages_provider.dart';
import '../utils/firebase_util.dart';
import '../utils/go_router_util.dart';
import '../utils/string_util.dart';
import '../widgets/app_bar_widget.dart';
import '../widgets/custom_button_widgets.dart';
import '../widgets/custom_miscellaneous_widgets.dart';
import '../widgets/custom_padding_widgets.dart';
import '../widgets/left_navigator_widget.dart';
import '../widgets/text_widgets.dart';

class ViewServicesScreen extends ConsumerStatefulWidget {
  const ViewServicesScreen({super.key});

  @override
  ConsumerState<ViewServicesScreen> createState() => _ViewServicesScreenState();
}

class _ViewServicesScreenState extends ConsumerState<ViewServicesScreen> {
  List<DocumentSnapshot> allServiceDocs = [];
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      final goRouter = GoRouter.of(context);
      try {
        ref.read(loadingProvider.notifier).toggleLoading(true);
        if (!hasLoggedInUser()) {
          ref.read(loadingProvider.notifier).toggleLoading(false);
          goRouter.goNamed(GoRoutes.login);
          return;
        }
        final userDoc = await getCurrentUserDoc();
        final userData = userDoc.data() as Map<dynamic, dynamic>;
        if (userData[UserFields.userType] == UserTypes.client) {
          goRouter.goNamed(GoRoutes.home);
          return;
        }
        allServiceDocs = await getAllServices();
        for (var serviceDoc in allServiceDocs) {
          final serviceData = serviceDoc.data() as Map<dynamic, dynamic>;
          if (!serviceData.containsKey(ServiceFields.category)) {
            await FirebaseFirestore.instance
                .collection(Collections.services)
                .doc(serviceDoc.id)
                .update({ServiceFields.category: ServiceCategories.repair});
          }
        }

        ref.read(pagesProvider.notifier).setCurrentPage(1);
        ref
            .read(pagesProvider.notifier)
            .setMaxPage((allServiceDocs.length / 10).ceil());
        ref.read(loadingProvider.notifier).toggleLoading(false);
      } catch (error) {
        scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('Error getting services: $error')));
        ref.read(loadingProvider.notifier).toggleLoading(false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(loadingProvider);
    ref.watch(pagesProvider);
    return Scaffold(
      appBar: appBarWidget(context, showActions: false),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          leftNavigator(context, path: GoRoutes.viewServices),
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            child: switchedLoadingContainer(
                ref.read(loadingProvider),
                SingleChildScrollView(
                    child: horizontal5Percent(context,
                        child: Column(
                          children: [_addServiceButton(), _serviceContainer()],
                        )))),
          )
        ],
      ),
    );
  }

  Widget _addServiceButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        blackSarabunBold('SERVICES', fontSize: 40),
        ElevatedButton(
            onPressed: () => GoRouter.of(context).goNamed(GoRoutes.addService),
            child: whiteSarabunBold('ADD NEW SERVICE'))
      ]),
    );
  }

  Widget _serviceContainer() {
    return viewContentContainer(
      context,
      child: Column(
        children: [
          _serviceLabelRow(),
          allServiceDocs.isNotEmpty
              ? _serviceEntries()
              : viewContentUnavailable(context, text: 'NO AVAILABLE SERVICES'),
        ],
      ),
    );
  }

  Widget _serviceLabelRow() {
    return viewContentLabelRow(context, children: [
      viewFlexLabelTextCell('Name', 4,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(20))),
      viewFlexLabelTextCell('Available', 2),
      viewFlexLabelTextCell('Category', 1),
      viewFlexLabelTextCell('Actions', 2,
          borderRadius: BorderRadius.only(topRight: Radius.circular(20)))
    ]);
  }

  Widget _serviceEntries() {
    return Container(
        height: allServiceDocs.length > 10 ? null : 500,
        decoration: BoxDecoration(border: Border.all()),
        child: ListView.builder(
            shrinkWrap: true,
            itemCount: allServiceDocs.length,
            itemBuilder: (context, index) {
              return _serviceEntry(allServiceDocs[index], index);
            }));
  }

  Widget _serviceEntry(DocumentSnapshot serviceDoc, int index) {
    final serviceData = serviceDoc.data() as Map<dynamic, dynamic>;
    String name = serviceData[ServiceFields.name];
    String category = serviceData[ServiceFields.category];
    bool isAvailable = serviceData[ServiceFields.isAvailable];
    Color entryColor = Colors.black;
    Color backgroundColor = Colors.white;
    return viewContentEntryRow(context, children: [
      viewFlexTextCell(name,
          flex: 4, backgroundColor: backgroundColor, textColor: entryColor),
      viewFlexTextCell(isAvailable ? 'YES' : 'NO',
          flex: 2, backgroundColor: backgroundColor, textColor: entryColor),
      viewFlexTextCell(category,
          flex: 1, backgroundColor: backgroundColor, textColor: entryColor),
      viewFlexActionsCell([
        viewEntryButton(context,
            onPress: () => GoRouter.of(context).goNamed(
                GoRoutes.selectedService,
                pathParameters: {PathParameters.serviceID: serviceDoc.id})),
        editEntryButton(context,
            onPress: () => GoRouter.of(context).goNamed(GoRoutes.editService,
                pathParameters: {PathParameters.serviceID: serviceDoc.id})),
      ], flex: 2, backgroundColor: backgroundColor)
    ]);
  }
}
