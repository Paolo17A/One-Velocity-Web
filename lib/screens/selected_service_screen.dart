import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../providers/loading_provider.dart';
import '../providers/pages_provider.dart';
import '../providers/user_type_provider.dart';
import '../utils/color_util.dart';
import '../utils/firebase_util.dart';
import '../utils/go_router_util.dart';
import '../utils/string_util.dart';
import '../widgets/app_bar_widget.dart';
import '../widgets/custom_button_widgets.dart';
import '../widgets/custom_miscellaneous_widgets.dart';
import '../widgets/custom_padding_widgets.dart';
import '../widgets/left_navigator_widget.dart';
import '../widgets/text_widgets.dart';

class SelectedServiceScreen extends ConsumerStatefulWidget {
  final String serviceID;
  const SelectedServiceScreen({super.key, required this.serviceID});

  @override
  ConsumerState<SelectedServiceScreen> createState() =>
      _SelectedServiceScreenState();
}

class _SelectedServiceScreenState extends ConsumerState<SelectedServiceScreen> {
  //  SERVICE VARIABLES
  String name = '';
  String description = '';
  num price = 0;
  String category = '';
  bool isAvailable = false;
  List<dynamic> imageURLs = [];
  int currentImageIndex = 0;

  List<DocumentSnapshot> bookingHistoryDocs = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      ref.read(loadingProvider.notifier).toggleLoading(true);
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      try {
        final service = await getThisServiceDoc(widget.serviceID);
        final serviceData = service.data() as Map<dynamic, dynamic>;
        name = serviceData[ServiceFields.name];
        description = serviceData[ServiceFields.description];
        price = serviceData[ServiceFields.price];
        isAvailable = serviceData[ServiceFields.isAvailable];
        imageURLs = serviceData[ServiceFields.imageURLs];
        category = serviceData[ServiceFields.category];
        if (ref.read(userTypeProvider) == UserTypes.admin) {
          bookingHistoryDocs = await getServiceBookingHistory(widget.serviceID);
        }
        ref.read(pagesProvider.notifier).setCurrentPage(0);
        ref.read(pagesProvider.notifier).setMaxPage(imageURLs.length);
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
    currentImageIndex = ref.watch(pagesProvider.notifier).getCurrentPage();
    return Scaffold(
        appBar: appBarWidget(context),
        body: hasLoggedInUser() && ref.read(userTypeProvider) == UserTypes.admin
            ? _adminView()
            : _clientWidgets());
  }

  //============================================================================
  //ADMIN WIDGETS===============================================================
  //============================================================================

  Widget _adminView() {
    return switchedLoadingContainer(
      ref.read(loadingProvider),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          leftNavigator(context, path: GoRoutes.viewServices),
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            child: SingleChildScrollView(
              child: horizontal5Percent(context,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _backButton(),
                      _productBasicDetails(),
                      _purchaseHistory()
                    ],
                  )),
            ),
          )
        ],
      ),
    );
  }

  Widget _backButton() {
    return vertical20Pix(
      child: backButton(context,
          onPress: () => GoRouter.of(context).goNamed(GoRoutes.viewServices)),
    );
  }

  Widget _productBasicDetails() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
          color: CustomColors.ultimateGray.withOpacity(0.25),
          borderRadius: BorderRadius.circular(10)),
      padding: const EdgeInsets.all(10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          children: [
            if (imageURLs.isNotEmpty)
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                    onTap: () => showOtherPics(context,
                        imageURL: imageURLs[currentImageIndex]),
                    child: Image.network(imageURLs[0],
                        width: 150, height: 150, fit: BoxFit.cover)),
              ),
            Gap(20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                montserratBlackBold(name, fontSize: 40),
                montserratBlackRegular('PHP ${price.toStringAsFixed(2)}',
                    fontSize: 32),
                vertical10Pix(
                  child: montserratBlackBold(
                      'Is Available: ${isAvailable ? 'YES' : 'NO'}',
                      fontSize: 16),
                ),
                montserratBlackRegular(description, fontSize: 20)
              ],
            )
          ],
        )
      ]),
    );
  }

  Widget _purchaseHistory() {
    return vertical20Pix(
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
            color: CustomColors.ultimateGray,
            borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            montserratWhiteBold('SERVICE BOOKING HISTORY', fontSize: 28),
            const Divider(color: Colors.white),
            bookingHistoryDocs.isNotEmpty
                ? ListView.builder(
                    shrinkWrap: true,
                    itemCount: bookingHistoryDocs.length,
                    itemBuilder: (context, index) {
                      return serviceBookingHistoryEntry(
                          bookingHistoryDocs[index]);
                    })
                : Center(
                    child: montserratWhiteBold('NO BOOKING HISTORY AVAILABLE'),
                  )
          ],
        ),
      ),
    );
  }

  //============================================================================
  //CLIENT WIDGETS==============================================================
  //============================================================================

  Widget _clientWidgets() {
    return Column(
      children: [
        secondAppBar(context),
        switchedLoadingContainer(
            ref.read(loadingProvider),
            SingleChildScrollView(
              child: horizontal5Percent(context, child: _serviceContainer()),
            ))
      ],
    );
  }

  Widget _serviceContainer() {
    return vertical20Pix(
        child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageURLs.isNotEmpty) _itemImagesDisplay(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        montserratBlackBold(name, fontSize: 60),
                        montserratBlackBold('PHP ${price.toStringAsFixed(2)}',
                            fontSize: 40),
                        montserratBlackRegular('Category: $category',
                            fontSize: 30),
                      ],
                    ),
                    const Gap(30),
                    SizedBox(
                        height: 40,
                        child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.zero),
                                disabledBackgroundColor: Colors.blueGrey),
                            onPressed: isAvailable
                                ? () async {
                                    if (!hasLoggedInUser()) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(SnackBar(
                                              content: Text(
                                                  'Please log-in to your account first.')));
                                      return;
                                    }
                                    DateTime? datePicked = await showDatePicker(
                                        context: context,
                                        firstDate: DateTime.now()
                                            .add(Duration(days: 1)),
                                        lastDate: DateTime.now()
                                            .add(Duration(days: 7)));
                                    if (datePicked == null) {
                                      return;
                                    }
                                    createNewBookingRequest(context, ref,
                                        serviceID: widget.serviceID,
                                        datePicked: datePicked);
                                  }
                                : null,
                            child: montserratWhiteRegular(
                                'REQUEST THIS SERVICE',
                                textAlign: TextAlign.center))),
                    all10Pix(
                        child: montserratBlackBold(
                            'Is Available: ${isAvailable ? 'YES' : ' NO'}',
                            fontSize: 16)),
                    Container(
                        width: MediaQuery.of(context).size.width * 0.6,
                        decoration: BoxDecoration(border: Border.all()),
                        padding: EdgeInsets.all(10),
                        child: montserratBlackRegular(description,
                            textAlign: TextAlign.left)),
                  ]),
            ),
          ],
        ),
      ],
    ));
  }

  Widget _itemImagesDisplay() {
    return Column(
      children: [
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () =>
                showOtherPics(context, imageURL: imageURLs[currentImageIndex]),
            child: Column(
              children: [
                Container(
                  width: MediaQuery.of(context).size.width * 0.25,
                  height: MediaQuery.of(context).size.width * 0.25,
                  decoration: BoxDecoration(
                      border: Border.all(),
                      image: DecorationImage(
                          fit: BoxFit.fill,
                          image: NetworkImage(imageURLs[currentImageIndex]))),
                ),
              ],
            ),
          ),
        ),
        if (imageURLs.length > 1)
          vertical10Pix(
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.2,
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                        onPressed: () => currentImageIndex == 0
                            ? null
                            : ref
                                .read(pagesProvider.notifier)
                                .setCurrentPage(currentImageIndex - 1),
                        child: const Icon(Icons.arrow_left)),
                    TextButton(
                        onPressed: () =>
                            currentImageIndex == imageURLs.length - 1
                                ? null
                                : ref
                                    .read(pagesProvider.notifier)
                                    .setCurrentPage(currentImageIndex + 1),
                        child: const Icon(Icons.arrow_right))
                  ]),
            ),
          )
      ],
    );
  }
}
