import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../providers/bookmarks_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/loading_provider.dart';
import '../providers/pages_provider.dart';
import '../providers/user_type_provider.dart';
import '../utils/firebase_util.dart';
import '../utils/go_router_util.dart';
import '../utils/string_util.dart';
import '../widgets/app_bar_widget.dart';
import '../widgets/custom_button_widgets.dart';
import '../widgets/custom_miscellaneous_widgets.dart';
import '../widgets/custom_padding_widgets.dart';
import '../widgets/floating_chat_widget.dart';
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

  List<DocumentSnapshot> bookingHistoryDocs = [];
  List<DocumentSnapshot> relatedServicesDocs = [];
  CarouselSliderController relatedServicesController =
      CarouselSliderController();
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

        ref.read(pagesProvider.notifier).setCurrentPage(0);
        ref.read(pagesProvider.notifier).setMaxPage(imageURLs.length);
        if (hasLoggedInUser()) {
          final user = await getCurrentUserDoc();
          final userData = user.data() as Map<dynamic, dynamic>;
          ref
              .read(userTypeProvider.notifier)
              .setUserType(userData[UserFields.userType]);
          if (ref.read(userTypeProvider) == UserTypes.client) {
            ref
                .read(bookmarksProvider)
                .setBookmarkedServices(userData[UserFields.bookmarkedProducts]);
            ref
                .read(cartProvider)
                .setCartItems(await getServiceCartEntries(context));
            relatedServicesDocs = await getAllServices();

            setState(() {
              relatedServicesDocs = relatedServicesDocs.where((service) {
                final serviceData = service.data() as Map<dynamic, dynamic>;
                String thisCategory = serviceData[ServiceFields.category];
                return category == thisCategory;
              }).toList();
            });
          } else if (ref.read(userTypeProvider) == UserTypes.admin) {
            bookingHistoryDocs =
                await getServiceBookingHistory(widget.serviceID);
          }
        } else {
          relatedServicesDocs = await getAllServices();

          setState(() {
            relatedServicesDocs = relatedServicesDocs.where((service) {
              final serviceData = service.data() as Map<dynamic, dynamic>;
              String thisCategory = serviceData[ServiceFields.category];
              return category == thisCategory;
            }).toList();
          });
        }
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
    ref.watch(bookmarksProvider);
    return Scaffold(
        appBar: appBarWidget(context),
        floatingActionButton:
            hasLoggedInUser() && ref.read(userTypeProvider) == UserTypes.client
                ? FloatingChatWidget(
                    senderUID: FirebaseAuth.instance.currentUser!.uid,
                    otherUID: adminID)
                : null,
        body: SingleChildScrollView(
          child:
              hasLoggedInUser() && ref.read(userTypeProvider) == UserTypes.admin
                  ? _adminView()
                  : _clientWidgets(),
        ));
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
              child: Column(
                children: [
                  _backButton(),
                  horizontal5Percent(context,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [_productBasicDetails(), _purchaseHistory()],
                      )),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _backButton() {
    return all20Pix(
        child: Row(children: [
      backButton(context,
          onPress: () => GoRouter.of(context).goNamed(GoRoutes.viewServices))
    ]));
  }

  Widget _productBasicDetails() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(border: Border.all()),
      padding: const EdgeInsets.all(10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          children: [
            if (imageURLs.isNotEmpty)
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                    onTap: () =>
                        showOtherPics(context, imageURL: imageURLs.first),
                    child: Image.network(imageURLs[0],
                        width: 150, height: 150, fit: BoxFit.cover)),
              ),
            Gap(20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                blackSarabunBold(name, fontSize: 40),
                blackSarabunRegular('PHP ${price.toStringAsFixed(2)}',
                    fontSize: 32),
                vertical10Pix(
                  child: blackSarabunBold(
                      'Is Available: ${isAvailable ? 'YES' : 'NO'}',
                      fontSize: 16),
                ),
                blackSarabunRegular(description, fontSize: 20)
              ],
            )
          ],
        )
      ]),
    );
  }

  Widget _purchaseHistory() {
    return vertical20Pix(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          blackSarabunBold('BOOKING HISTORY', fontSize: 28),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(border: Border.all()),
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                bookingHistoryDocs.isNotEmpty
                    ? ListView.builder(
                        shrinkWrap: true,
                        itemCount: bookingHistoryDocs.length,
                        itemBuilder: (context, index) {
                          return serviceBookingHistoryEntry(
                              bookingHistoryDocs[index]);
                        })
                    : Center(
                        child: blackSarabunBold(
                            'This service has not yet been booked.'),
                      )
              ],
            ),
          ),
        ],
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
              child: horizontal5Percent(context,
                  child: Column(
                    children: [
                      _serviceContainer(),
                      Divider(),
                      if (relatedServicesDocs.isNotEmpty)
                        itemRowTemplate(context,
                            label: 'Related Services',
                            itemDocs: relatedServicesDocs.take(5).toList(),
                            itemType: 'SERVICE')
                    ],
                  )),
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
                        blackSarabunBold(name, fontSize: 60),
                        blackSarabunBold('PHP ${formatPrice(price.toDouble())}',
                            fontSize: 40),
                        blackSarabunRegular('Category: $category',
                            fontSize: 30),
                      ],
                    ),
                    const Gap(30),
                    Row(
                      children: [
                        IconButton(
                            onPressed: () => ref
                                    .read(bookmarksProvider)
                                    .bookmarkedServices
                                    .contains(widget.serviceID)
                                ? removeBookmarkedService(context, ref,
                                    service: widget.serviceID)
                                : addBookmarkedService(context, ref,
                                    service: widget.serviceID),
                            icon: Icon(ref
                                    .read(bookmarksProvider)
                                    .bookmarkedServices
                                    .contains(widget.serviceID)
                                ? Icons.bookmark
                                : Icons.bookmark_outline)),
                        blackSarabunRegular(ref
                                .read(bookmarksProvider)
                                .bookmarkedServices
                                .contains(widget.serviceID)
                            ? 'Remove from Bookmarks'
                            : 'Add to Bookmarks')
                      ],
                    ),
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
                                    addServiceToCart(context, ref,
                                        serviceID: widget.serviceID);
                                  }
                                : null,
                            child: whiteSarabunRegular('REQUEST THIS SERVICE',
                                textAlign: TextAlign.center))),
                    all10Pix(
                        child: blackSarabunBold(
                            'Is Available: ${isAvailable ? 'YES' : ' NO'}',
                            fontSize: 16)),
                    Container(
                        width: MediaQuery.of(context).size.width * 0.6,
                        decoration: BoxDecoration(border: Border.all()),
                        padding: EdgeInsets.all(10),
                        child: blackSarabunRegular(description,
                            textAlign: TextAlign.left)),
                  ]),
            ),
          ],
        ),
      ],
    ));
  }

  Widget _itemImagesDisplay() {
    List<dynamic> otherImages = [];
    if (imageURLs.length > 1) otherImages = imageURLs.sublist(1);
    return Column(
      children: [
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => showOtherPics(context, imageURL: imageURLs.first),
            child: Column(
              children: [
                Container(
                  width: MediaQuery.of(context).size.width * 0.25,
                  height: MediaQuery.of(context).size.width * 0.25,
                  decoration: BoxDecoration(
                      border: Border.all(),
                      image: DecorationImage(
                          fit: BoxFit.fill,
                          image: NetworkImage(imageURLs.first))),
                ),
              ],
            ),
          ),
        ),
        SizedBox(
          width: MediaQuery.of(context).size.width * 0.25,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
                mainAxisSize: MainAxisSize.min,
                children: otherImages
                    .map((otherImage) => all10Pix(
                            child: GestureDetector(
                          onTap: () =>
                              showOtherPics(context, imageURL: otherImage),
                          child: Container(
                              decoration: BoxDecoration(border: Border.all()),
                              child: square80NetworkImage(otherImage)),
                        )))
                    .toList()),
          ),
        )
      ],
    );
  }
}
