import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker_web/image_picker_web.dart';

import '../providers/loading_provider.dart';
import '../providers/uploaded_images_provider.dart';
import '../utils/firebase_util.dart';
import '../utils/go_router_util.dart';
import '../utils/string_util.dart';
import '../widgets/app_bar_widget.dart';
import '../widgets/custom_button_widgets.dart';
import '../widgets/custom_miscellaneous_widgets.dart';
import '../widgets/custom_padding_widgets.dart';
import '../widgets/custom_text_field_widget.dart';
import '../widgets/dropdown_widget.dart';
import '../widgets/left_navigator_widget.dart';
import '../widgets/text_widgets.dart';

class EditServiceScreen extends ConsumerStatefulWidget {
  final String serviceID;
  const EditServiceScreen({super.key, required this.serviceID});

  @override
  ConsumerState<EditServiceScreen> createState() => _EditServiceScreenState();
}

class _EditServiceScreenState extends ConsumerState<EditServiceScreen> {
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  bool isAvailable = false;
  final priceController = TextEditingController();
  List<dynamic> imageURLs = [];
  List<Uint8List?> selectedItemImages = [];
  String selectedCategory = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final goRouter = GoRouter.of(context);
      try {
        ref.read(uploadedImagesProvider).clearImages();
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
        final service = await getThisServiceDoc(widget.serviceID);
        final serviceData = service.data() as Map<dynamic, dynamic>;
        nameController.text = serviceData[ServiceFields.name];
        descriptionController.text = serviceData[ServiceFields.description];
        selectedCategory = serviceData[ServiceFields.category];
        isAvailable = serviceData[ServiceFields.isAvailable];
        priceController.text = serviceData[ServiceFields.price].toString();
        imageURLs = serviceData[ServiceFields.imageURLs];
        setState(() {});
        ref.read(loadingProvider.notifier).toggleLoading(false);
      } catch (error) {
        ref.read(loadingProvider.notifier).toggleLoading(false);
      }
    });
  }

  Future<void> _pickLogoImage() async {
    final pickedFiles = await ImagePickerWeb.getMultiImagesAsBytes();
    if (pickedFiles != null) {
      ref.read(uploadedImagesProvider.notifier).addImages(pickedFiles);
    }
  }

  @override
  void dispose() {
    super.dispose();
    nameController.dispose();
    descriptionController.dispose();
    priceController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(loadingProvider);
    selectedItemImages = ref.watch(uploadedImagesProvider).uploadedImages;
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
                    child: Column(children: [
                      _backButton(),
                      _editServiceHeaderWidget(),
                      _serviceNameWidget(),
                      _serviceDescriptionWidget(),
                      _serviceCategoryWidget(),
                      SizedBox(
                        width: double.infinity,
                        child: Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            children: [
                              _serviceAvailabilityWidget(),
                              _servicePriceWidget()
                            ]),
                      ),
                      _serviceImagesWidget(),
                      _submitButtonWidget()
                    ])),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _backButton() {
    return vertical20Pix(
      child: Row(children: [
        ElevatedButton(
            onPressed: () =>
                GoRouter.of(context).goNamed(GoRoutes.viewServices),
            child: whiteSarabunBold('BACK'))
      ]),
    );
  }

  Widget _editServiceHeaderWidget() {
    return blackSarabunBold(
      'EDIT Service',
      textAlign: TextAlign.center,
      fontSize: 38,
    );
  }

  Widget _serviceNameWidget() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      vertical10Pix(child: blackSarabunBold('Service Name', fontSize: 24)),
      CustomTextField(
          text: 'Service Name',
          controller: nameController,
          textInputType: TextInputType.text,
          displayPrefixIcon: null),
      const Gap(20)
    ]);
  }

  Widget _serviceDescriptionWidget() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      vertical10Pix(
          child: blackSarabunBold('Service Description', fontSize: 24)),
      CustomTextField(
          text: 'Service Description',
          controller: descriptionController,
          textInputType: TextInputType.multiline,
          displayPrefixIcon: null),
    ]);
  }

  Widget _serviceCategoryWidget() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      vertical10Pix(child: blackSarabunBold('Service Category', fontSize: 24)),
      Container(
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(5)),
        child: dropdownWidget(selectedCategory, (newVal) {
          setState(() {
            selectedCategory = newVal!;
          });
        }, [
          ServiceCategories.paintJob,
          ServiceCategories.repair
        ], selectedCategory.isNotEmpty ? selectedCategory : 'Select a category',
            false),
      )
    ]);
  }

  Widget _serviceAvailabilityWidget() {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          vertical10Pix(
              child: blackSarabunBold('Is this service currently available?',
                  fontSize: 24)),
          Checkbox(
              value: isAvailable,
              onChanged: (newVal) {
                setState(() {
                  isAvailable = newVal!;
                });
              })
        ],
      ),
    );
  }

  Widget _servicePriceWidget() {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          vertical10Pix(child: blackSarabunBold('Price', fontSize: 24)),
          CustomTextField(
              text: 'Price',
              controller: priceController,
              textInputType: TextInputType.number,
              displayPrefixIcon: null),
        ],
      ),
    );
  }

  Widget _serviceImagesWidget() {
    return vertical20Pix(
      child: SizedBox(
        width: double.infinity,
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                uploadImageButton('UPLOAD IMAGES', _pickLogoImage),
                if (selectedItemImages.isNotEmpty)
                  vertical10Pix(
                    child: Wrap(
                        children: selectedItemImages.map((itemByte) {
                      return selectedMemoryImageDisplay(itemByte!, () {
                        ref.read(uploadedImagesProvider).removeImage(itemByte);
                      });
                    }).toList()),
                  )
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _submitButtonWidget() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 50),
      child: ElevatedButton(
        onPressed: () => editServiceEntry(context, ref,
            serviceID: widget.serviceID,
            nameController: nameController,
            descriptionController: descriptionController,
            isAvailable: isAvailable,
            selectedCategory: selectedCategory,
            priceController: priceController),
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: whiteSarabunBold('SUBMIT'),
        ),
      ),
    );
  }
}
