import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/loading_provider.dart';
import '../providers/pages_provider.dart';
import '../utils/color_util.dart';
import '../utils/delete_entry_dialog_util.dart';
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
        montserratBlackBold('SERVICES', fontSize: 40),
        ElevatedButton(
            onPressed: () => GoRouter.of(context).goNamed(GoRoutes.addService),
            child: montserratWhiteBold('ADD NEW SERVICE'))
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
      viewFlexLabelTextCell('Name', 4),
      viewFlexLabelTextCell('Available', 2),
      viewFlexLabelTextCell('Actions', 2)
    ]);
  }

  Widget _serviceEntries() {
    return SizedBox(
        height: MediaQuery.of(context).size.height * 0.65,
        child: ListView.builder(
            shrinkWrap: true,
            itemCount: ref.read(pagesProvider.notifier).getCurrentPage() ==
                        ref.read(pagesProvider.notifier).getMaxPage() &&
                    allServiceDocs.length % 10 != 0
                ? allServiceDocs.length % 10
                : 10,
            itemBuilder: (context, index) {
              return _serviceEntry(
                  allServiceDocs[index +
                      ((ref.read(pagesProvider.notifier).getCurrentPage() - 1) *
                          10)],
                  index);
            }));
  }

  Widget _serviceEntry(DocumentSnapshot serviceDoc, int index) {
    final serviceData = serviceDoc.data() as Map<dynamic, dynamic>;
    String name = serviceData[ServiceFields.name];
    bool isAvailable = serviceData[ServiceFields.isAvailable];
    Color entryColor = Colors.black;
    Color backgroundColor = index % 2 == 0
        ? CustomColors.ultimateGray.withOpacity(0.5)
        : CustomColors.nimbusCloud;
    return viewContentEntryRow(context, children: [
      viewFlexTextCell(name,
          flex: 4, backgroundColor: backgroundColor, textColor: entryColor),
      viewFlexTextCell(isAvailable ? 'YES' : 'NO',
          flex: 2, backgroundColor: backgroundColor, textColor: entryColor),
      viewFlexActionsCell([
        editEntryButton(context,
            onPress: () => GoRouter.of(context).goNamed(GoRoutes.editService,
                pathParameters: {PathParameters.serviceID: serviceDoc.id})),
        deleteEntryButton(context,
            onPress: () => displayDeleteEntryDialog(context,
                message: 'Are you sure you wish to remove this service?',
                deleteEntry: () {}))
      ], flex: 2, backgroundColor: backgroundColor)
    ]);
  }
}
