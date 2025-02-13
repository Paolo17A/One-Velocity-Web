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

class EditProductScreen extends ConsumerStatefulWidget {
  final String productID;
  const EditProductScreen({super.key, required this.productID});

  @override
  ConsumerState<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends ConsumerState<EditProductScreen> {
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  String selectedCategory = '';
  final quantityController = TextEditingController();
  final priceController = TextEditingController();
  List<dynamic> imageURLs = [];
  List<Uint8List?> selectedItemImages = [];

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
        final product = await getThisProductDoc(widget.productID);
        final productData = product.data() as Map<dynamic, dynamic>;
        nameController.text = productData[ProductFields.name];
        descriptionController.text = productData[ProductFields.description];
        selectedCategory = productData[ProductFields.category];
        quantityController.text =
            productData[ProductFields.quantity].toString();
        priceController.text = productData[ProductFields.price].toString();
        imageURLs = productData[ProductFields.imageURLs];
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
    quantityController.dispose();
    priceController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(loadingProvider);
    ref.watch(uploadedImagesProvider);
    selectedItemImages = ref.watch(uploadedImagesProvider).uploadedImages;
    return Scaffold(
      appBar: appBarWidget(context, showActions: false),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          leftNavigator(context, path: GoRoutes.viewProducts),
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            child: switchedLoadingContainer(
              ref.read(loadingProvider),
              SingleChildScrollView(
                child: horizontal5Percent(context,
                    child: Column(children: [
                      _backButton(),
                      _newProductHeaderWidget(),
                      _productNameWidget(),
                      _productDescriptionWidget(),
                      _productCategoryWidget(),
                      SizedBox(
                        width: double.infinity,
                        child: Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            children: [
                              _productQuantityWidget(),
                              _productPriceWidget()
                            ]),
                      ),
                      _productImagesWidget(),
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
                GoRouter.of(context).goNamed(GoRoutes.viewProducts),
            child: whiteSarabunBold('BACK'))
      ]),
    );
  }

  Widget _newProductHeaderWidget() {
    return blackSarabunBold(
      'EDIT PRODUCT',
      textAlign: TextAlign.center,
      fontSize: 38,
    );
  }

  Widget _productNameWidget() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      vertical10Pix(child: blackSarabunBold('Product Name', fontSize: 24)),
      CustomTextField(
          text: 'Product Name',
          controller: nameController,
          textInputType: TextInputType.text,
          displayPrefixIcon: null),
      const Gap(20)
    ]);
  }

  Widget _productDescriptionWidget() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      vertical10Pix(
          child: blackSarabunBold('Product Description', fontSize: 24)),
      CustomTextField(
          text: 'Product Description',
          controller: descriptionController,
          textInputType: TextInputType.multiline,
          displayPrefixIcon: null),
    ]);
  }

  Widget _productCategoryWidget() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      vertical10Pix(child: blackSarabunBold('Product Category', fontSize: 24)),
      Container(
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(5)),
        child: dropdownWidget(selectedCategory, (newVal) {
          setState(() {
            selectedCategory = newVal!;
          });
        }, [
          ProductCategories.wheel,
          ProductCategories.battery,
          ProductCategories.accessory,
          ProductCategories.others
        ], selectedCategory.isNotEmpty ? selectedCategory : 'Select a category',
            false),
      )
    ]);
  }

  Widget _productQuantityWidget() {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          vertical10Pix(
              child: blackSarabunBold('Starting Quantity', fontSize: 24)),
          CustomTextField(
              text: 'Starting Quantity',
              controller: quantityController,
              textInputType: TextInputType.number,
              displayPrefixIcon: null),
        ],
      ),
    );
  }

  Widget _productPriceWidget() {
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

  Widget _productImagesWidget() {
    return vertical20Pix(
      child: SizedBox(
        width: double.infinity,
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                uploadImageButton('UPLOAD IMAGES', _pickLogoImage),
                vertical10Pix(
                    child: Wrap(children: [
                  if (!ref.read(loadingProvider) && imageURLs.isNotEmpty)
                    ...imageURLs
                        .map((imageURL) => all10Pix(
                                child: selectedNetworkImageDisplay(imageURL,
                                    deleteImage: () {
                              if (imageURLs.length +
                                      selectedItemImages.length ==
                                  1) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                    content: Text(
                                        'You must have at least one image available for this item.')));
                                return;
                              }
                              setState(() {
                                imageURLs.remove(imageURL);
                              });
                            })))
                        .toList(),
                  if (selectedItemImages.isNotEmpty)
                    ...selectedItemImages
                        .map((imageByte) => all10Pix(
                                child:
                                    selectedMemoryImageDisplay(imageByte, () {
                              if (imageURLs.length +
                                      selectedItemImages.length ==
                                  1) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                    content: Text(
                                        'You must have at least one image available for this item.')));
                                return;
                              }
                              setState(() {
                                selectedItemImages.remove(imageByte!);
                              });
                            })))
                        .toList()
                ]))
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
        onPressed: () => editProductEntry(context, ref,
            productID: widget.productID,
            nameController: nameController,
            descriptionController: descriptionController,
            selectedCategory: selectedCategory,
            quantityController: quantityController,
            priceController: priceController),
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: whiteSarabunBold('SUBMIT'),
        ),
      ),
    );
  }
}
