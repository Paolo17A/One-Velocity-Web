import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../providers/loading_provider.dart';
import '../utils/firebase_util.dart';
import '../utils/go_router_util.dart';
import '../utils/string_util.dart';
import '../widgets/app_bar_widget.dart';
import '../widgets/custom_button_widgets.dart';
import '../widgets/custom_miscellaneous_widgets.dart';
import '../widgets/custom_padding_widgets.dart';
import '../widgets/left_navigator_widget.dart';
import '../widgets/text_widgets.dart';

class SelectedUserScreen extends ConsumerStatefulWidget {
  final String userID;
  const SelectedUserScreen({super.key, required this.userID});

  @override
  ConsumerState<SelectedUserScreen> createState() => _SelectedUserScreenState();
}

class _SelectedUserScreenState extends ConsumerState<SelectedUserScreen>
    with TickerProviderStateMixin {
  String formattedName = '';
  String profileImageURL = '';
  String mobileNumber = '';

  late TabController tabController;
  List<DocumentSnapshot> purchaseHistoryDocs = [];
  List<DocumentSnapshot> bookingHistoryDocs = [];

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 2, vsync: this);
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
        DocumentSnapshot selectedUser = await getThisUserDoc(widget.userID);
        final selectedUserData = selectedUser.data() as Map<dynamic, dynamic>;
        formattedName =
            '${selectedUserData[UserFields.firstName]} ${selectedUserData[UserFields.lastName]}';
        profileImageURL = selectedUserData[UserFields.profileImageURL];
        mobileNumber = selectedUserData[UserFields.mobileNumber];

        purchaseHistoryDocs = await getClientPurchaseHistory(widget.userID);
        purchaseHistoryDocs.sort((a, b) {
          DateTime aTime =
              (a[PurchaseFields.dateCreated] as Timestamp).toDate();
          DateTime bTime =
              (b[PurchaseFields.dateCreated] as Timestamp).toDate();
          return bTime.compareTo(aTime);
        });
        bookingHistoryDocs.sort((a, b) {
          DateTime aTime = (a[BookingFields.dateCreated] as Timestamp).toDate();
          DateTime bTime = (b[BookingFields.dateCreated] as Timestamp).toDate();
          return bTime.compareTo(aTime);
        });
        bookingHistoryDocs = await getClientBookingDocs(widget.userID);
        ref.read(loadingProvider.notifier).toggleLoading(false);
        setState(() {});
      } catch (error) {
        scaffoldMessenger.showSnackBar(SnackBar(
            content: Text('Error getting selected user data: $error')));
        ref.read(loadingProvider.notifier).toggleLoading(false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(loadingProvider);
    return DefaultTabController(
      initialIndex: 0,
      length: 2,
      child: Scaffold(
        appBar: appBarWidget(context, showActions: false),
        body: Row(
          children: [
            leftNavigator(context, path: GoRoutes.viewUsers),
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.8,
              height: MediaQuery.of(context).size.height,
              child: switchedLoadingContainer(
                  ref.read(loadingProvider),
                  SingleChildScrollView(
                    child: Column(
                      children: [
                        Row(children: [
                          all20Pix(
                              child: backButton(context,
                                  onPress: () => GoRouter.of(context)
                                      .goNamed(GoRoutes.viewUsers)))
                        ]),
                        horizontal5Percent(
                          context,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _profileContainer(),
                              Gap(20),
                              _historiesContainer()
                            ],
                          ),
                        ),
                      ],
                    ),
                  )),
            )
          ],
        ),
      ),
    );
  }

  Widget _profileContainer() {
    return Container(
        width: double.infinity,
        decoration: BoxDecoration(color: Colors.white, border: Border.all()),
        padding: EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          buildProfileImage(profileImageURL: profileImageURL),
          blackSarabunBold(formattedName, fontSize: 40),
          blackSarabunRegular('Mobile Number: $mobileNumber')
        ]));
  }

  Widget _historiesContainer() {
    return Column(
      children: [
        TabBar(tabs: [
          Tab(child: blackSarabunBold('PURCHASES')),
          Tab(child: blackSarabunBold('BOOKINGS'))
        ]),
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.5,
          child: TabBarView(physics: NeverScrollableScrollPhysics(), children: [
            _purchaseHistory(),
            _bookingHistory(),
          ]),
        )
      ],
    );
  }

  Widget _purchaseHistory() {
    return purchaseHistoryDocs.isNotEmpty
        ? ListView.builder(
            shrinkWrap: true,
            itemCount: purchaseHistoryDocs.length,
            itemBuilder: (context, index) {
              return purchaseHistoryEntry(purchaseHistoryDocs[index],
                  userType: UserTypes.admin);
            })
        : Center(
            child: blackSarabunBold('YOU HAVE NOT COMPLETED ANY PURCHASES YET',
                fontSize: 30),
          );
  }

  Widget _bookingHistory() {
    return bookingHistoryDocs.isNotEmpty
        ? ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: bookingHistoryDocs.length,
            itemBuilder: (context, index) {
              return bookingHistoryEntry(bookingHistoryDocs[index],
                  userType: UserTypes.admin);
            })
        : Center(
            child: blackSarabunBold(
                'NO ONGOING SERVICE BOOKING HISTORY AVAILABLE'));
  }
}
