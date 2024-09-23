// ignore_for_file: unnecessary_cast

import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:one_velocity_web/providers/bookmarks_provider.dart';
import 'package:one_velocity_web/providers/cart_provider.dart';
import 'package:one_velocity_web/providers/faq_provider.dart';
import 'package:one_velocity_web/providers/profile_image_url_provider.dart';
import 'package:one_velocity_web/providers/purchases_provider.dart';

import '../providers/bookings_provider.dart';
import '../providers/loading_provider.dart';
import '../providers/payments_provider.dart';
import '../providers/uploaded_images_provider.dart';
import 'go_router_util.dart';
import 'string_util.dart';

//==============================================================================
//USERS=========================================================================
//==============================================================================
bool hasLoggedInUser() {
  return FirebaseAuth.instance.currentUser != null;
}

Future registerNewUser(BuildContext context, WidgetRef ref,
    {required TextEditingController emailController,
    required TextEditingController passwordController,
    required TextEditingController confirmPasswordController,
    required TextEditingController firstNameController,
    required TextEditingController lastNameController,
    required TextEditingController mobileNumberController}) async {
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  final goRouter = GoRouter.of(context);
  try {
    if (emailController.text.isEmpty ||
        passwordController.text.isEmpty ||
        confirmPasswordController.text.isEmpty ||
        firstNameController.text.isEmpty ||
        lastNameController.text.isEmpty ||
        mobileNumberController.text.isEmpty) {
      scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Please fill up all given fields.')));
      return;
    }
    if (!emailController.text.contains('@') ||
        !emailController.text.contains('.com')) {
      scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Please input a valid email address')));
      return;
    }
    if (passwordController.text != confirmPasswordController.text) {
      scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('The passwords do not match')));
      return;
    }
    if (passwordController.text.length < 6) {
      scaffoldMessenger.showSnackBar(const SnackBar(
          content: Text('The password must be at least six characters long')));
      return;
    }
    if (mobileNumberController.text.length != 11 ||
        mobileNumberController.text[0] != '0' ||
        mobileNumberController.text[1] != '9') {
      scaffoldMessenger.showSnackBar(const SnackBar(
          content: Text(
              'The mobile number must be an 11 digit number formatted as: 09XXXXXXXXX')));
      return;
    }
    ref.read(loadingProvider.notifier).toggleLoading(true);
    await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(), password: passwordController.text);
    await FirebaseFirestore.instance
        .collection(Collections.users)
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .set({
      UserFields.email: emailController.text.trim(),
      UserFields.password: passwordController.text,
      UserFields.firstName: firstNameController.text.trim(),
      UserFields.lastName: lastNameController.text.trim(),
      UserFields.mobileNumber: mobileNumberController.text,
      UserFields.userType: UserTypes.client,
      UserFields.profileImageURL: '',
      UserFields.bookmarkedProducts: [],
      UserFields.bookmarkedServices: []
    });
    scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Successfully registered new user')));
    await FirebaseAuth.instance.signOut();
    ref.read(loadingProvider.notifier).toggleLoading(false);

    goRouter.goNamed(GoRoutes.login);
  } catch (error) {
    scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error registering new user: $error')));
    ref.read(loadingProvider.notifier).toggleLoading(false);
  }
}

Future logInUser(BuildContext context, WidgetRef ref,
    {required TextEditingController emailController,
    required TextEditingController passwordController}) async {
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  final goRouter = GoRouter.of(context);
  try {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Please fill up all given fields.')));
      return;
    }
    ref.read(loadingProvider.notifier).toggleLoading(true);
    await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text, password: passwordController.text);
    final userDoc = await getCurrentUserDoc();
    final userData = userDoc.data() as Map<dynamic, dynamic>;

    //  reset the password in firebase in case client reset it using an email link.
    if (userData[UserFields.password] != passwordController.text) {
      await FirebaseFirestore.instance
          .collection(Collections.users)
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .update({UserFields.password: passwordController.text});
    }
    ref.read(loadingProvider.notifier).toggleLoading(false);
    goRouter.goNamed(GoRoutes.home);
    goRouter.pushReplacementNamed(GoRoutes.home);
  } catch (error) {
    scaffoldMessenger
        .showSnackBar(SnackBar(content: Text('Error logging in: $error')));
    ref.read(loadingProvider.notifier).toggleLoading(false);
  }
}

Future sendResetPasswordEmail(BuildContext context, WidgetRef ref,
    {required TextEditingController emailController}) async {
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  final goRouter = GoRouter.of(context);
  if (!emailController.text.contains('@') ||
      !emailController.text.contains('.com')) {
    scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Please input a valid email address.')));
    return;
  }
  try {
    ref.read(loadingProvider.notifier).toggleLoading(true);
    final filteredUsers = await FirebaseFirestore.instance
        .collection(Collections.users)
        .where(UserFields.email, isEqualTo: emailController.text.trim())
        .get();

    if (filteredUsers.docs.isEmpty) {
      scaffoldMessenger.showSnackBar(const SnackBar(
          content: Text('There is no user with that email address.')));
      ref.read(loadingProvider.notifier).toggleLoading(false);
      return;
    }
    if (filteredUsers.docs.first.data()[UserFields.userType] !=
        UserTypes.client) {
      scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('This feature is for clients only.')));
      ref.read(loadingProvider.notifier).toggleLoading(false);
      return;
    }
    await FirebaseAuth.instance
        .sendPasswordResetEmail(email: emailController.text.trim());
    ref.read(loadingProvider.notifier).toggleLoading(false);
    scaffoldMessenger.showSnackBar(const SnackBar(
        content: Text('Successfully sent password reset email!')));
    goRouter.goNamed(GoRoutes.login);
  } catch (error) {
    scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error sending password reset email: $error')));
    ref.read(loadingProvider.notifier).toggleLoading(false);
  }
}

Future updatePassword(BuildContext context, WidgetRef ref,
    {required TextEditingController currentPasswordController,
    required TextEditingController newPasswordController,
    required TextEditingController confirmNewPasswordController}) async {
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  if (currentPasswordController.text.isEmpty ||
      newPasswordController.text.isEmpty ||
      confirmNewPasswordController.text.isEmpty) {
    scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Please fill up all the given fields.')));
    return;
  }
  if (confirmNewPasswordController.text != newPasswordController.text) {
    scaffoldMessenger
        .showSnackBar(SnackBar(content: Text('The passwords do not match.')));
    return;
  }
  if (newPasswordController.text.length < 6) {
    scaffoldMessenger.showSnackBar(SnackBar(
        content:
            Text('Your new password must be at least 6 characters long.')));
    return;
  }
  try {
    ref.read(loadingProvider.notifier).toggleLoading(true);
    final user = await getCurrentUserDoc();
    final userData = user.data() as Map<dynamic, dynamic>;
    if (currentPasswordController.text != userData[UserFields.password]) {
      ref.read(loadingProvider.notifier).toggleLoading(false);
      scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Your old password is incorrect.')));
      return;
    }

    await FirebaseAuth.instance.currentUser!.reauthenticateWithCredential(
        EmailAuthProvider.credential(
            email: userData[UserFields.email],
            password: userData[UserFields.password]));
    await FirebaseAuth.instance.currentUser!
        .updatePassword(newPasswordController.text);
    await FirebaseFirestore.instance
        .collection(Collections.users)
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .update({UserFields.password: newPasswordController.text});
    scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Successfully updated your password.')));
    currentPasswordController.clear();
    newPasswordController.clear();
    confirmNewPasswordController.clear();
    ref.read(loadingProvider.notifier).toggleLoading(false);
  } catch (error) {
    scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error updating password: $error')));
  }
}

Future<DocumentSnapshot> getCurrentUserDoc() async {
  return await getThisUserDoc(FirebaseAuth.instance.currentUser!.uid);
}

Future<String> getCurrentUserType() async {
  final userDoc = await getCurrentUserDoc();
  final userData = userDoc.data() as Map<dynamic, dynamic>;
  return userData[UserFields.userType];
}

Future<DocumentSnapshot> getThisUserDoc(String userID) async {
  return await FirebaseFirestore.instance
      .collection(Collections.users)
      .doc(userID)
      .get();
}

Future<List<DocumentSnapshot>> getAllClientDocs() async {
  final users = await FirebaseFirestore.instance
      .collection(Collections.users)
      .where(UserFields.userType, isEqualTo: UserTypes.client)
      .get();
  return users.docs;
}

Future editClientProfile(BuildContext context, WidgetRef ref,
    {required TextEditingController firstNameController,
    required TextEditingController lastNameController,
    required TextEditingController mobileNumberController}) async {
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  final goRouter = GoRouter.of(context);
  if (firstNameController.text.isEmpty ||
      lastNameController.text.isEmpty ||
      mobileNumberController.text.isEmpty) {
    scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Please fill up all given fields.')));
    return;
  }
  if (mobileNumberController.text.length != 11 ||
      mobileNumberController.text[0] != '0' ||
      mobileNumberController.text[1] != '9') {
    scaffoldMessenger.showSnackBar(const SnackBar(
        content: Text(
            'The mobile number must be an 11 digit number formatted as: 09XXXXXXXXX')));
    return;
  }
  try {
    ref.read(loadingProvider.notifier).toggleLoading(true);
    await FirebaseFirestore.instance
        .collection(Collections.users)
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .update({
      UserFields.firstName: firstNameController.text.trim(),
      UserFields.lastName: lastNameController.text.trim(),
      UserFields.mobileNumber: mobileNumberController.text
    });
    ref.read(loadingProvider.notifier).toggleLoading(false);
    goRouter.goNamed(GoRoutes.profile);
  } catch (error) {
    scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error editing client profile : $error')));
    ref.read(loadingProvider.notifier).toggleLoading(false);
  }
}

Future addProfilePic(BuildContext context, WidgetRef ref,
    {required Uint8List selectedImage}) async {
  final scaffoldMessenger = ScaffoldMessenger.of(context);

  try {
    ref.read(loadingProvider.notifier).toggleLoading(true);

    final storageRef = FirebaseStorage.instance
        .ref()
        .child(StorageFields.profilePics)
        .child(FirebaseAuth.instance.currentUser!.uid);

    final uploadTask = storageRef.putData(selectedImage);
    final taskSnapshot = await uploadTask.whenComplete(() {});
    final downloadURL = await taskSnapshot.ref.getDownloadURL();

    // Update the user's data in Firestore with the image URL
    await FirebaseFirestore.instance
        .collection(Collections.users)
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .update({
      UserFields.profileImageURL: downloadURL,
    });
    scaffoldMessenger.showSnackBar(const SnackBar(
        content: Text('Successfully added new profile picture')));
    ref.read(profileImageURLProvider.notifier).setImageURL(downloadURL);
    ref.read(loadingProvider.notifier).toggleLoading(false);
  } catch (error) {
    scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error uploading new profile picture: $error')));
    ref.read(loadingProvider.notifier).toggleLoading(false);
  }
}

Future<void> removeProfilePic(BuildContext context, WidgetRef ref) async {
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  try {
    ref.read(loadingProvider.notifier).toggleLoading(true);
    await FirebaseFirestore.instance
        .collection(Collections.users)
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .update({UserFields.profileImageURL: ''});

    final storageRef = FirebaseStorage.instance
        .ref()
        .child(StorageFields.profilePics)
        .child(FirebaseAuth.instance.currentUser!.uid);

    await storageRef.delete();
    scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Successfully removed profile picture.')));
    ref.read(profileImageURLProvider.notifier).removeImageURL();
    ref.read(loadingProvider.notifier).toggleLoading(false);
  } catch (error) {
    scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error removing current profile pic: $error')));
    ref.read(loadingProvider.notifier).toggleLoading(false);
  }
}

Future addBookmarkedProduct(BuildContext context, WidgetRef ref,
    {required String productID}) async {
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  if (!hasLoggedInUser()) {
    scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Please log-in to your account first.')));
    return;
  }
  try {
    await FirebaseFirestore.instance
        .collection(Collections.users)
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .update({
      UserFields.bookmarkedProducts: FieldValue.arrayUnion([productID])
    });
    ref.read(bookmarksProvider).addProductToBookmarks(productID);
    scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Sucessfully added product to bookmarks.')));
  } catch (error) {
    scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error adding product to bookmarks: $error')));
    ref.read(loadingProvider.notifier).toggleLoading(false);
  }
}

Future removeBookmarkedProduct(BuildContext context, WidgetRef ref,
    {required String productID}) async {
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  if (!hasLoggedInUser()) {
    scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Please log-in to your account first.')));
    return;
  }
  try {
    await FirebaseFirestore.instance
        .collection(Collections.users)
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .update({
      UserFields.bookmarkedProducts: FieldValue.arrayRemove([productID])
    });
    ref.read(bookmarksProvider).removeProductFromBookmarks(productID);
    scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Sucessfully removed product from bookmarks.')));
  } catch (error) {
    scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error removing product to bookmarks: $error')));
    ref.read(loadingProvider.notifier).toggleLoading(false);
  }
}

Future addBookmarkedService(BuildContext context, WidgetRef ref,
    {required String service}) async {
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  if (!hasLoggedInUser()) {
    scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Please log-in to your account first.')));
    return;
  }
  try {
    await FirebaseFirestore.instance
        .collection(Collections.users)
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .update({
      UserFields.bookmarkedServices: FieldValue.arrayUnion([service])
    });
    ref.read(bookmarksProvider).addServiceToBookmarks(service);
    scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Sucessfully added service to bookmarks.')));
  } catch (error) {
    scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error adding service to bookmarks: $error')));
    ref.read(loadingProvider.notifier).toggleLoading(false);
  }
}

Future removeBookmarkedService(BuildContext context, WidgetRef ref,
    {required String service}) async {
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  if (!hasLoggedInUser()) {
    scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Please log-in to your account first.')));
    return;
  }
  try {
    await FirebaseFirestore.instance
        .collection(Collections.users)
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .update({
      UserFields.bookmarkedServices: FieldValue.arrayRemove([service])
    });
    ref.read(bookmarksProvider).removeServiceFromBookmarks(service);
    scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Sucessfully removed service from bookmarks.')));
  } catch (error) {
    scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error removing service to bookmarks: $error')));
    ref.read(loadingProvider.notifier).toggleLoading(false);
  }
}

//==============================================================================
//PRODUCTS======================================================================
//==============================================================================
Future<List<DocumentSnapshot>> getAllProducts() async {
  final products =
      await FirebaseFirestore.instance.collection(Collections.products).get();
  return products.docs;
}

Future<List<DocumentSnapshot>> getAllWheelProducts() async {
  final products = await FirebaseFirestore.instance
      .collection(Collections.products)
      .where(ProductFields.category, isEqualTo: ProductCategories.wheel)
      .get();
  return products.docs;
}

Future<List<DocumentSnapshot>> getAllBattryProducts() async {
  final products = await FirebaseFirestore.instance
      .collection(Collections.products)
      .where(ProductFields.category, isEqualTo: ProductCategories.battery)
      .get();
  return products.docs;
}

Future<DocumentSnapshot> getThisProductDoc(String productID) async {
  return await FirebaseFirestore.instance
      .collection(Collections.products)
      .doc(productID)
      .get();
}

Future<List<DocumentSnapshot>> getSelectedProductDocs(
    List<String> productIDs) async {
  if (productIDs.isEmpty) {
    return [];
  }
  final products = await FirebaseFirestore.instance
      .collection(Collections.products)
      .where(FieldPath.documentId, whereIn: productIDs)
      .get();
  return products.docs.map((doc) => doc as DocumentSnapshot).toList();
}

Future addProductEntry(BuildContext context, WidgetRef ref,
    {required TextEditingController nameController,
    required TextEditingController descriptionController,
    required String selectedCategory,
    required TextEditingController quantityController,
    required TextEditingController priceController}) async {
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  final goRouter = GoRouter.of(context);
  if (nameController.text.isEmpty ||
      descriptionController.text.isEmpty ||
      selectedCategory.isEmpty ||
      quantityController.text.isEmpty ||
      priceController.text.isEmpty) {
    scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Please fill up all fields.')));
    return;
  }
  if (int.tryParse(quantityController.text) == null ||
      int.parse(quantityController.text) <= 0) {
    scaffoldMessenger.showSnackBar(const SnackBar(
        content: Text(
            'Please input a valid whole number greater than zero for the quantity.')));
    return;
  }
  if (int.tryParse(priceController.text) == null ||
      int.parse(priceController.text) <= 0) {
    scaffoldMessenger.showSnackBar(const SnackBar(
        content: Text(
            'Please input a valid number greater than zero for the price.')));
    return;
  }
  if (ref.read(uploadedImagesProvider).uploadedImages.isEmpty) {
    scaffoldMessenger.showSnackBar(const SnackBar(
        content: Text('Please upload at least one product image.')));
    return;
  }
  try {
    ref.read(loadingProvider.notifier).toggleLoading(true);
    String productID = DateTime.now().millisecondsSinceEpoch.toString();

    //  Upload Item Images to Firebase Storage
    List<String> imageURLs = [];
    for (int i = 0;
        i < ref.read(uploadedImagesProvider).uploadedImages.length;
        i++) {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child(StorageFields.products)
          .child(productID)
          .child('${generateRandomHexString(6)}.png');
      final uploadTask = storageRef
          .putData(ref.read(uploadedImagesProvider).uploadedImages[i]!);
      final taskSnapshot = await uploadTask.whenComplete(() {});
      final downloadURL = await taskSnapshot.ref.getDownloadURL();
      imageURLs.add(downloadURL);
    }

    await FirebaseFirestore.instance
        .collection(Collections.products)
        .doc(productID)
        .set({
      ProductFields.name: nameController.text.trim(),
      ProductFields.description: descriptionController.text.trim(),
      ProductFields.category: selectedCategory,
      ProductFields.quantity: int.parse(quantityController.text),
      ProductFields.price: double.parse(priceController.text),
      ProductFields.imageURLs: imageURLs
    });
    ref.read(loadingProvider.notifier).toggleLoading(false);

    scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Successfully added new product.')));
    goRouter.goNamed(GoRoutes.viewProducts);
  } catch (error) {
    scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error adding new product: $error')));
    ref.read(loadingProvider.notifier).toggleLoading(false);
  }
}

Future editProductEntry(BuildContext context, WidgetRef ref,
    {required String productID,
    required TextEditingController nameController,
    required TextEditingController descriptionController,
    required String selectedCategory,
    required TextEditingController quantityController,
    required TextEditingController priceController}) async {
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  if (nameController.text.isEmpty ||
      descriptionController.text.isEmpty ||
      selectedCategory.isEmpty ||
      quantityController.text.isEmpty ||
      priceController.text.isEmpty) {
    scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Please fill up all fields.')));
    return;
  }
  if (int.tryParse(quantityController.text) == null ||
      int.parse(quantityController.text) <= 0) {
    scaffoldMessenger.showSnackBar(const SnackBar(
        content: Text(
            'Please input a valid whole number greater than zero for the quantity.')));
    return;
  }
  if (int.tryParse(priceController.text) == null ||
      int.parse(priceController.text) <= 0) {
    scaffoldMessenger.showSnackBar(const SnackBar(
        content: Text(
            'Please input a valid number greater than zero for the price.')));
    return;
  }
  try {
    ref.read(loadingProvider.notifier).toggleLoading(true);
    //  Upload Item Images to Firebase Storage
    List<String> imageURLs = [];
    for (int i = 0;
        i < ref.read(uploadedImagesProvider).uploadedImages.length;
        i++) {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child(Collections.products)
          .child(productID)
          .child('${generateRandomHexString(6)}.png');
      final uploadTask = storageRef
          .putData(ref.read(uploadedImagesProvider).uploadedImages[i]!);
      final taskSnapshot = await uploadTask.whenComplete(() {});
      final downloadURL = await taskSnapshot.ref.getDownloadURL();
      imageURLs.add(downloadURL);
    }

    await FirebaseFirestore.instance
        .collection(Collections.products)
        .doc(productID)
        .update({
      ProductFields.name: nameController.text.trim(),
      ProductFields.description: descriptionController.text.trim(),
      ProductFields.category: selectedCategory,
      ProductFields.quantity: int.parse(quantityController.text),
      ProductFields.price: double.parse(priceController.text),
      ProductFields.imageURLs: FieldValue.arrayUnion(imageURLs)
    });
    ref.read(loadingProvider.notifier).toggleLoading(false);

    scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Successfully edited this product.')));
    ref.read(profileImageURLProvider.notifier).removeImageURL();
  } catch (error) {
    scaffoldMessenger
        .showSnackBar(SnackBar(content: Text('Error editing product: $error')));
    ref.read(loadingProvider.notifier).toggleLoading(false);
  }
}

//==============================================================================
//==CART--======================================================================
//==============================================================================
Future<List<DocumentSnapshot>> getProductCartEntries(
    BuildContext context) async {
  final cartProducts = await FirebaseFirestore.instance
      .collection(Collections.cart)
      .where(CartFields.clientID,
          isEqualTo: FirebaseAuth.instance.currentUser!.uid)
      .where(CartFields.cartType, isEqualTo: CartTypes.product)
      .get();
  return cartProducts.docs.map((doc) => doc as DocumentSnapshot).toList();
}

Future<List<DocumentSnapshot>> getServiceCartEntries(
    BuildContext context) async {
  final cartProducts = await FirebaseFirestore.instance
      .collection(Collections.cart)
      .where(CartFields.clientID,
          isEqualTo: FirebaseAuth.instance.currentUser!.uid)
      .where(CartFields.cartType, isEqualTo: CartTypes.service)
      .get();
  return cartProducts.docs.map((doc) => doc as DocumentSnapshot).toList();
}

Future<DocumentSnapshot> getThisCartEntry(String cartID) async {
  return await FirebaseFirestore.instance
      .collection(Collections.cart)
      .doc(cartID)
      .get();
}

Future addProductToCart(BuildContext context, WidgetRef ref,
    {required String productID}) async {
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  if (!hasLoggedInUser()) {
    scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Please log-in to your account first.')));
    return;
  }
  try {
    if (ref.read(cartProvider).cartContainsThisItem(productID)) {
      scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('This item is already in your cart.')));
      return;
    }

    final cartDocReference =
        await FirebaseFirestore.instance.collection(Collections.cart).add({
      CartFields.itemID: productID,
      CartFields.clientID: FirebaseAuth.instance.currentUser!.uid,
      CartFields.quantity: 1,
      CartFields.cartType: CartTypes.product
    });
    ref.read(cartProvider.notifier).addCartItem(await cartDocReference.get());
    scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Successfully added this item to your cart.')));
  } catch (error) {
    scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error adding product to cart: $error')));
  }
}

Future addServiceToCart(BuildContext context, WidgetRef ref,
    {required String serviceID}) async {
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  if (!hasLoggedInUser()) {
    scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Please log-in to your account first.')));
    return;
  }
  try {
    if (ref.read(cartProvider).cartContainsThisItem(serviceID)) {
      scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('This service is already in your cart.')));
      return;
    }

    final cartDocReference =
        await FirebaseFirestore.instance.collection(Collections.cart).add({
      CartFields.itemID: serviceID,
      CartFields.clientID: FirebaseAuth.instance.currentUser!.uid,
      CartFields.quantity: 1,
      CartFields.cartType: CartTypes.service
    });
    ref.read(cartProvider.notifier).addCartItem(await cartDocReference.get());
    scaffoldMessenger.showSnackBar(SnackBar(
        content: Text('Successfully added this service to your cart.')));
  } catch (error) {
    scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error adding product to cart: $error')));
  }
}

void removeCartItem(BuildContext context, WidgetRef ref,
    {required DocumentSnapshot cartDoc}) async {
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  try {
    ref.read(loadingProvider.notifier).toggleLoading(true);
    await cartDoc.reference.delete();

    scaffoldMessenger.showSnackBar(const SnackBar(
        content: Text('Successfully removed this item from your cart.')));
    ref.read(cartProvider).removeCartItem(cartDoc);
    ref.read(loadingProvider.notifier).toggleLoading(false);
  } catch (error) {
    scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error removing cart item: $error')));
    ref.read(loadingProvider.notifier).toggleLoading(false);
  }
}

Future changeCartItemQuantity(BuildContext context, WidgetRef ref,
    {required DocumentSnapshot cartEntryDoc,
    required bool isIncreasing}) async {
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  try {
    final cartEntryData = cartEntryDoc.data() as Map<dynamic, dynamic>;
    int quantity = cartEntryData[CartFields.quantity];
    if (isIncreasing) {
      quantity++;
    } else {
      quantity--;
    }
    await FirebaseFirestore.instance
        .collection(Collections.cart)
        .doc(cartEntryDoc.id)
        .update({CartFields.quantity: quantity});
    ref.read(cartProvider).setCartItems(await getProductCartEntries(context));
  } catch (error) {
    scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error changing item quantity: $error')));
  }
}

//==============================================================================
//==FAQS========================================================================
//==============================================================================
Future<List<DocumentSnapshot>> getAllFAQs() async {
  final faqs =
      await FirebaseFirestore.instance.collection(Collections.faqs).get();
  return faqs.docs;
}

Future<DocumentSnapshot> getThisFAQDoc(String faqID) async {
  return await FirebaseFirestore.instance
      .collection(Collections.faqs)
      .doc(faqID)
      .get();
}

Future addFAQEntry(BuildContext context, WidgetRef ref,
    {required String selectedCategory,
    required TextEditingController questionController,
    required TextEditingController answerController}) async {
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  final goRouter = GoRouter.of(context);
  if (selectedCategory.isEmpty ||
      questionController.text.isEmpty ||
      answerController.text.isEmpty) {
    scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Please fill up all fields.')));
    return;
  }
  try {
    ref.read(loadingProvider.notifier).toggleLoading(true);
    String faqID = DateTime.now().millisecondsSinceEpoch.toString();
    await FirebaseFirestore.instance
        .collection(Collections.faqs)
        .doc(faqID)
        .set({
      FAQFields.category: selectedCategory,
      FAQFields.question: questionController.text.trim(),
      FAQFields.answer: answerController.text.trim()
    });
    ref.read(loadingProvider.notifier).toggleLoading(false);

    scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Successfully added new FAQ.')));
    goRouter.goNamed(GoRoutes.viewFAQs);
  } catch (error) {
    scaffoldMessenger
        .showSnackBar(SnackBar(content: Text('Error adding FAQ: $error')));
    ref.read(loadingProvider.notifier).toggleLoading(false);
  }
}

Future editFAQEntry(BuildContext context, WidgetRef ref,
    {required String faqID,
    required String selectedCategory,
    required TextEditingController questionController,
    required TextEditingController answerController}) async {
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  final goRouter = GoRouter.of(context);
  if (selectedCategory.isEmpty ||
      questionController.text.isEmpty ||
      answerController.text.isEmpty) {
    scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Please fill up all fields.')));
    return;
  }
  try {
    ref.read(loadingProvider.notifier).toggleLoading(true);
    await FirebaseFirestore.instance
        .collection(Collections.faqs)
        .doc(faqID)
        .update({
      FAQFields.category: selectedCategory,
      FAQFields.question: questionController.text.trim(),
      FAQFields.answer: answerController.text.trim()
    });
    ref.read(loadingProvider.notifier).toggleLoading(false);

    scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Successfully edited this FAQ.')));
    goRouter.goNamed(GoRoutes.viewFAQs);
  } catch (error) {
    scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error editing this FAQ: $error')));
    ref.read(loadingProvider.notifier).toggleLoading(false);
  }
}

Future deleteFAQEntry(BuildContext context, WidgetRef ref,
    {required String faqID}) async {
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  final goRouter = GoRouter.of(context);
  try {
    ref.read(loadingProvider.notifier).toggleLoading(true);
    await FirebaseFirestore.instance
        .collection(Collections.faqs)
        .doc(faqID)
        .delete();
    ref.read(faqsProvider).setFAQDocs(await getAllFAQs());
    ref.read(loadingProvider.notifier).toggleLoading(false);

    scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Successfully deleted this FAQ.')));
    goRouter.pushReplacementNamed(GoRoutes.viewFAQs);
  } catch (error) {
    scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error deleting this FAQ: $error')));
    ref.read(loadingProvider.notifier).toggleLoading(false);
  }
}

//==============================================================================
//==PURCHASES===================================================================
//==============================================================================
Future<List<DocumentSnapshot>> getAllPurchaseDocs() async {
  final purchases =
      await FirebaseFirestore.instance.collection(Collections.purchases).get();
  return purchases.docs.reversed.toList();
}

Future<List<DocumentSnapshot>> getThesePurchaseDocs(
    List<dynamic> purchaseIDs) async {
  final purchases = await FirebaseFirestore.instance
      .collection(Collections.purchases)
      .where(FieldPath.documentId, whereIn: purchaseIDs)
      .get();
  return purchases.docs.reversed.toList();
}

Future purchaseSelectedProductCartItems(BuildContext context, WidgetRef ref,
    {required Uint8List? proofOfPayment, required num paidAmount}) async {
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  try {
    ref.read(loadingProvider.notifier).toggleLoading(true);
    //  1. Generate a purchase document for the selected cart item
    List<String> purchaseIDs = [];
    for (var cartItem in ref.read(cartProvider).selectedCartItemIDs) {
      final cartDoc = await getThisCartEntry(cartItem);
      final cartData = cartDoc.data() as Map<dynamic, dynamic>;

      DocumentReference purchaseReference = await FirebaseFirestore.instance
          .collection(Collections.purchases)
          .add({
        PurchaseFields.productID: cartData[CartFields.itemID],
        PurchaseFields.clientID: cartData[CartFields.clientID],
        PurchaseFields.quantity: cartData[CartFields.quantity],
        PurchaseFields.purchaseStatus: PurchaseStatuses.pending,
        PurchaseFields.dateCreated: DateTime.now(),
        PurchaseFields.datePickedUp: DateTime(1970),
        PurchaseFields.rating: '',
      });

      purchaseIDs.add(purchaseReference.id);

      //  Added step: update the item's remaining quantity
      await FirebaseFirestore.instance
          .collection(Collections.products)
          .doc(cartData[CartFields.itemID])
          .update({
        ProductFields.quantity:
            FieldValue.increment(-cartData[CartFields.quantity])
      });

      await FirebaseFirestore.instance
          .collection(Collections.cart)
          .doc(cartItem)
          .delete();
    }

    //  2. Generate a payment document in Firestore
    DocumentReference paymentReference =
        await FirebaseFirestore.instance.collection(Collections.payments).add({
      PaymentFields.clientID: FirebaseAuth.instance.currentUser!.uid,
      PaymentFields.paidAmount: paidAmount,
      //PaymentFields.proofOfPayment: downloadURL,
      PaymentFields.paymentVerified: false,
      PaymentFields.paymentStatus: PaymentStatuses.pending,
      PaymentFields.paymentMethod: ref.read(cartProvider).selectedPaymentMethod,
      PaymentFields.dateCreated: DateTime.now(),
      PaymentFields.dateApproved: DateTime(1970),
      PaymentFields.invoiceURL: '',
      PaymentFields.purchaseIDs: purchaseIDs,
      PaymentFields.paymentType: PaymentTypes.product
    });

    //  2. Upload the proof of payment image to Firebase Storage
    final storageRef = FirebaseStorage.instance
        .ref()
        .child(StorageFields.payments)
        .child('${paymentReference.id}.png');
    final uploadTask = storageRef.putData(proofOfPayment!);
    final taskSnapshot = await uploadTask;
    final downloadURL = await taskSnapshot.ref.getDownloadURL();

    await FirebaseFirestore.instance
        .collection(Collections.payments)
        .doc(paymentReference.id)
        .update({PaymentFields.proofOfPayment: downloadURL});

    for (var purchaseID in purchaseIDs) {
      await FirebaseFirestore.instance
          .collection(Collections.purchases)
          .doc(purchaseID)
          .update({PurchaseFields.paymentID: paymentReference.id});
    }
    ref.read(cartProvider).cartItems = await getProductCartEntries(context);
    scaffoldMessenger.showSnackBar(const SnackBar(
        content:
            Text('Successfully settled payment and created purchase order')));
    ref.read(loadingProvider.notifier).toggleLoading(false);
  } catch (error) {
    scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error purchasing this cart item: $error')));
    ref.read(loadingProvider.notifier).toggleLoading(false);
  }
}

Future<List<DocumentSnapshot>> getUserPurchaseHistory() async {
  final purchases = await FirebaseFirestore.instance
      .collection(Collections.purchases)
      .where(PurchaseFields.clientID,
          isEqualTo: FirebaseAuth.instance.currentUser!.uid)
      .get();
  return purchases.docs.map((doc) => doc as DocumentSnapshot).toList();
}

Future<List<DocumentSnapshot>> getClientPurchaseHistory(String clientID) async {
  final purchases = await FirebaseFirestore.instance
      .collection(Collections.purchases)
      .where(PurchaseFields.clientID, isEqualTo: clientID)
      .get();
  return purchases.docs.map((doc) => doc as DocumentSnapshot).toList();
}

Future<List<DocumentSnapshot>> getProductPurchaseHistory(
    String productID) async {
  final purchases = await FirebaseFirestore.instance
      .collection(Collections.purchases)
      .where(PurchaseFields.productID, isEqualTo: productID)
      .get();
  return purchases.docs.map((doc) => doc as DocumentSnapshot).toList();
}

Future markPurchasesAsReadyForPickUp(BuildContext context, WidgetRef ref,
    {required List<String> purchaseIDs}) async {
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  try {
    ref.read(loadingProvider.notifier).toggleLoading(true);
    for (var purchaseID in purchaseIDs) {
      await FirebaseFirestore.instance
          .collection(Collections.purchases)
          .doc(purchaseID)
          .update({PurchaseFields.purchaseStatus: PurchaseStatuses.forPickUp});
    }
    ref.read(paymentsProvider).setPaymentDocs(await getAllProductPaymentDocs());
    ref.read(loadingProvider.notifier).toggleLoading(false);
    scaffoldMessenger.showSnackBar(SnackBar(
        content: Text('Successfully marked purchases as ready for pick-up')));
  } catch (error) {
    scaffoldMessenger.showSnackBar(SnackBar(
        content: Text('Error marking purchase as ready for pick up: $error')));
    ref.read(loadingProvider.notifier).toggleLoading(false);
  }
}

Future markPurchaseAsPickedUp(BuildContext context, WidgetRef ref,
    {required List<String> purchaseIDs,
    required String paymentID,
    required Uint8List pdfBytes}) async {
  final scaffoldMessenger = ScaffoldMessenger.of(context);

  try {
    ref.read(loadingProvider.notifier).toggleLoading(true);
    final storageRef = FirebaseStorage.instance
        .ref()
        .child(StorageFields.invoices)
        .child('$paymentID.pdf');
    final uploadTask = storageRef.putData(pdfBytes);
    final taskSnapshot = await uploadTask;
    final downloadURL = await taskSnapshot.ref.getDownloadURL();
    for (var purchaseID in purchaseIDs) {
      await FirebaseFirestore.instance
          .collection(Collections.purchases)
          .doc(purchaseID)
          .update({
        PurchaseFields.purchaseStatus: PurchaseStatuses.pickedUp,
        PurchaseFields.datePickedUp: DateTime.now()
      });
    }

    await FirebaseFirestore.instance
        .collection(Collections.payments)
        .doc(paymentID)
        .update({PaymentFields.invoiceURL: downloadURL});

    ref.read(purchasesProvider).setPurchaseDocs(await getAllPurchaseDocs());
    scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Successfully marked purchase picked up')));
    ref.read(loadingProvider.notifier).toggleLoading(false);
  } catch (error) {
    scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error marking purchase picked up: $error')));
    ref.read(loadingProvider.notifier).toggleLoading(false);
  }
}

//==============================================================================
//==PAYMENTS====================================================================
//==============================================================================
Future<List<DocumentSnapshot>> getAllPaymentDocs() async {
  final payments =
      await FirebaseFirestore.instance.collection(Collections.payments).get();
  return payments.docs.reversed.toList();
}

Future<List<DocumentSnapshot>> getAllProductPaymentDocs() async {
  final payments = await FirebaseFirestore.instance
      .collection(Collections.payments)
      .where(PaymentFields.paymentType, isEqualTo: PaymentTypes.product)
      .get();
  return payments.docs;
}

Future<DocumentSnapshot> getThisPaymentDoc(String paymentID) async {
  return FirebaseFirestore.instance
      .collection(Collections.payments)
      .doc(paymentID)
      .get();
}

Future approveThisPayment(BuildContext context, WidgetRef ref,
    {required String paymentID,
    required List<dynamic> purchaseIDs,
    required String paymentType}) async {
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  try {
    ref.read(loadingProvider.notifier).toggleLoading(true);

    await FirebaseFirestore.instance
        .collection(Collections.payments)
        .doc(paymentID)
        .update({
      PaymentFields.dateApproved: DateTime.now(),
      PaymentFields.paymentVerified: true,
      PaymentFields.paymentStatus: PaymentStatuses.approved,
    });
    if (paymentType == PaymentTypes.product) {
      for (var purchaseID in purchaseIDs) {
        await FirebaseFirestore.instance
            .collection(Collections.purchases)
            .doc(purchaseID)
            .update(
                {PurchaseFields.purchaseStatus: PurchaseStatuses.processing});
      }
    } else if (paymentType == PaymentTypes.service) {
      for (var purchaseID in purchaseIDs) {
        await FirebaseFirestore.instance
            .collection(Collections.bookings)
            .doc(purchaseID)
            .update(
                {BookingFields.serviceStatus: ServiceStatuses.pendingDropOff});
      }
    }

    ref.read(paymentsProvider).setPaymentDocs(await getAllPaymentDocs());
    scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Successfully approved this payment')));
    ref.read(loadingProvider.notifier).toggleLoading(false);
  } catch (error) {
    scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error approving this payment: $error')));
    ref.read(loadingProvider.notifier).toggleLoading(false);
  }
}

Future denyThisPayment(BuildContext context, WidgetRef ref,
    {required String paymentID,
    required List<dynamic> purchaseIDs,
    required String paymentType}) async {
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  try {
    ref.read(loadingProvider.notifier).toggleLoading(true);

    await FirebaseFirestore.instance
        .collection(Collections.payments)
        .doc(paymentID)
        .update({
      PaymentFields.dateApproved: DateTime.now(),
      PaymentFields.paymentVerified: true,
      PaymentFields.paymentStatus: PaymentStatuses.denied
    });
    if (paymentType == PaymentTypes.product) {
      for (var purchaseID in purchaseIDs) {
        await FirebaseFirestore.instance
            .collection(Collections.purchases)
            .doc(purchaseID)
            .update({PurchaseFields.purchaseStatus: PurchaseStatuses.denied});
      }
    } else if (paymentType == PaymentTypes.service) {
      for (var purchaseID in purchaseIDs) {
        await FirebaseFirestore.instance
            .collection(Collections.bookings)
            .doc(purchaseID)
            .update({BookingFields.serviceStatus: ServiceStatuses.denied});
      }
    }
    ref.read(paymentsProvider).setPaymentDocs(await getAllPaymentDocs());
    scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Successfully denied this payment')));
    ref.read(loadingProvider.notifier).toggleLoading(false);
  } catch (error) {
    scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error denying this payment: $error')));
    ref.read(loadingProvider.notifier).toggleLoading(false);
  }
}

Future settleBookingRequestPayment(BuildContext context, WidgetRef ref,
    {required String bookingID,
    required List<dynamic> purchaseIDs,
    required num servicePrice}) async {
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  final goRouter = GoRouter.of(context);
  try {
    ref.read(loadingProvider.notifier).toggleLoading(true);
    //  1. Generate a payment document in Firestore
    await FirebaseFirestore.instance
        .collection(Collections.payments)
        .doc(bookingID)
        .set({
      PaymentFields.clientID: FirebaseAuth.instance.currentUser!.uid,
      PaymentFields.paidAmount: servicePrice,
      PaymentFields.paymentVerified: false,
      PaymentFields.paymentStatus: PaymentStatuses.pending,
      PaymentFields.paymentMethod: ref.read(cartProvider).selectedPaymentMethod,
      PaymentFields.dateCreated: DateTime.now(),
      PaymentFields.dateApproved: DateTime(1970),
      PaymentFields.invoiceURL: '',
      PaymentFields.paymentType: PaymentTypes.service,
      PaymentFields.purchaseIDs: purchaseIDs
    });

    //  3. Upload the proof of payment image to Firebase Storage
    final storageRef = FirebaseStorage.instance
        .ref()
        .child(StorageFields.payments)
        .child('${bookingID}.png');
    final uploadTask =
        storageRef.putData(ref.read(cartProvider).proofOfPaymentBytes!);
    final taskSnapshot = await uploadTask;
    final downloadURL = await taskSnapshot.ref.getDownloadURL();
    await FirebaseFirestore.instance
        .collection(Collections.payments)
        .doc(bookingID)
        .update({PaymentFields.proofOfPayment: downloadURL});

    //  2. Change bookings status
    await FirebaseFirestore.instance
        .collection(Collections.bookings)
        .doc(bookingID)
        .update(
            {BookingFields.serviceStatus: ServiceStatuses.processingPayment});
    scaffoldMessenger.showSnackBar(SnackBar(
        content: Text('Successfully settled booking request payment!')));
    goRouter.goNamed(GoRoutes.bookingsHistory);
    ref.read(loadingProvider.notifier).toggleLoading(false);
  } catch (error) {
    scaffoldMessenger.showSnackBar(SnackBar(
        content: Text('Error seetling booking request payment: $error')));
    ref.read(loadingProvider.notifier).toggleLoading(false);
  }
}

//==============================================================================
//==SERVICES====================================================================
//==============================================================================
Future<List<DocumentSnapshot>> getAllServices() async {
  final services =
      await FirebaseFirestore.instance.collection(Collections.services).get();
  return services.docs;
}

Future<DocumentSnapshot> getThisServiceDoc(String serviceID) async {
  return await FirebaseFirestore.instance
      .collection(Collections.services)
      .doc(serviceID)
      .get();
}

Future<List<DocumentSnapshot>> getSelectedServiceDocs(
    List<dynamic> serviceIDs) async {
  if (serviceIDs.isEmpty) {
    return [];
  }
  final services = await FirebaseFirestore.instance
      .collection(Collections.services)
      .where(FieldPath.documentId, whereIn: serviceIDs)
      .get();
  return services.docs.map((doc) => doc as DocumentSnapshot).toList();
}

Future addServiceEntry(BuildContext context, WidgetRef ref,
    {required TextEditingController nameController,
    required TextEditingController descriptionController,
    required bool isAvailable,
    required String selectedCategory,
    required TextEditingController priceController}) async {
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  final goRouter = GoRouter.of(context);
  if (nameController.text.isEmpty ||
      descriptionController.text.isEmpty ||
      priceController.text.isEmpty) {
    scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Please fill up all fields.')));
    return;
  }
  if (int.tryParse(priceController.text) == null ||
      int.parse(priceController.text) <= 0) {
    scaffoldMessenger.showSnackBar(const SnackBar(
        content: Text(
            'Please input a valid number greater than zero for the price.')));
    return;
  }
  if (ref.read(uploadedImagesProvider).uploadedImages.isEmpty) {
    scaffoldMessenger.showSnackBar(const SnackBar(
        content: Text('Please upload at least one service image.')));
    return;
  }
  if (selectedCategory.isEmpty) {
    scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Please select a service category.')));
    return;
  }
  try {
    ref.read(loadingProvider.notifier).toggleLoading(true);
    String serviceID = DateTime.now().millisecondsSinceEpoch.toString();

    //  Upload Item Images to Firebase Storage
    List<String> imageURLs = [];
    for (int i = 0;
        i < ref.read(uploadedImagesProvider).uploadedImages.length;
        i++) {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child(Collections.services)
          .child(serviceID)
          .child('${generateRandomHexString(6)}.png');
      final uploadTask = storageRef
          .putData(ref.read(uploadedImagesProvider).uploadedImages[i]!);
      final taskSnapshot = await uploadTask.whenComplete(() {});
      final downloadURL = await taskSnapshot.ref.getDownloadURL();
      imageURLs.add(downloadURL);
    }

    await FirebaseFirestore.instance
        .collection(Collections.services)
        .doc(serviceID)
        .set({
      ServiceFields.name: nameController.text.trim(),
      ServiceFields.description: descriptionController.text.trim(),
      ServiceFields.isAvailable: isAvailable,
      ServiceFields.price: double.parse(priceController.text),
      ServiceFields.imageURLs: imageURLs,
      ServiceFields.category: selectedCategory
    });
    ref.read(loadingProvider.notifier).toggleLoading(false);

    scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Successfully added new service.')));
    goRouter.goNamed(GoRoutes.viewServices);
  } catch (error) {
    scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error adding new service: $error')));
    ref.read(loadingProvider.notifier).toggleLoading(false);
  }
}

Future editServiceEntry(BuildContext context, WidgetRef ref,
    {required String serviceID,
    required TextEditingController nameController,
    required TextEditingController descriptionController,
    required bool isAvailable,
    required String selectedCategory,
    required TextEditingController priceController}) async {
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  final goRouter = GoRouter.of(context);
  if (nameController.text.isEmpty ||
      descriptionController.text.isEmpty ||
      priceController.text.isEmpty) {
    scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Please fill up all fields.')));
    return;
  }
  if (int.tryParse(priceController.text) == null ||
      int.parse(priceController.text) <= 0) {
    scaffoldMessenger.showSnackBar(const SnackBar(
        content: Text(
            'Please input a valid number greater than zero for the price.')));
    return;
  }
  if (selectedCategory.isEmpty) {
    scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Please select a service category.')));
    return;
  }
  try {
    ref.read(loadingProvider.notifier).toggleLoading(true);

    //  Upload Item Images to Firebase Storage
    List<String> imageURLs = [];
    for (int i = 0;
        i < ref.read(uploadedImagesProvider).uploadedImages.length;
        i++) {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child(Collections.services)
          .child(serviceID)
          .child('${generateRandomHexString(6)}.png');
      final uploadTask = storageRef
          .putData(ref.read(uploadedImagesProvider).uploadedImages[i]!);
      final taskSnapshot = await uploadTask;
      final downloadURL = await taskSnapshot.ref.getDownloadURL();
      imageURLs.add(downloadURL);
    }

    await FirebaseFirestore.instance
        .collection(Collections.services)
        .doc(serviceID)
        .update({
      ServiceFields.name: nameController.text.trim(),
      ServiceFields.description: descriptionController.text.trim(),
      ServiceFields.isAvailable: isAvailable,
      ServiceFields.price: double.parse(priceController.text),
      ServiceFields.imageURLs: FieldValue.arrayUnion(imageURLs),
      ServiceFields.category: selectedCategory
    });
    ref.read(loadingProvider.notifier).toggleLoading(false);

    scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Successfully edited this service.')));
    goRouter.goNamed(GoRoutes.viewServices);
  } catch (error) {
    scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error editing this service: $error')));
    ref.read(loadingProvider.notifier).toggleLoading(false);
  }
}

Future deleteServiceEntry(BuildContext context, WidgetRef ref,
    {required String serviceID}) async {
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  final goRouter = GoRouter.of(context);
  try {
    ref.read(loadingProvider.notifier).toggleLoading(true);
    await FirebaseFirestore.instance
        .collection(Collections.services)
        .doc(serviceID)
        .delete();

    final storageRef = await FirebaseStorage.instance
        .ref()
        .child(Collections.services)
        .child(serviceID)
        .listAll();
    for (var product in storageRef.items) {
      await product.delete();
    }
    ref.read(loadingProvider.notifier).toggleLoading(false);

    scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Successfully deleted this service.')));
    goRouter.pushReplacementNamed(GoRoutes.viewServices);
  } catch (error) {
    scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error deleting this service: $error')));
    ref.read(loadingProvider.notifier).toggleLoading(false);
  }
}

//==============================================================================
//==BOOKING=====================================================================
//==============================================================================
Future<List<DocumentSnapshot>> getAllBookingDocs() async {
  final bookings =
      await FirebaseFirestore.instance.collection(Collections.bookings).get();
  return bookings.docs.map((e) => e as DocumentSnapshot).toList();
}

Future<DocumentSnapshot> getThisBookingDoc(String bookingID) async {
  return await FirebaseFirestore.instance
      .collection(Collections.bookings)
      .doc(bookingID)
      .get();
}

Future<List<DocumentSnapshot>> getUserBookingDocs() async {
  final bookings = await FirebaseFirestore.instance
      .collection(Collections.bookings)
      .where(BookingFields.clientID,
          isEqualTo: FirebaseAuth.instance.currentUser!.uid)
      .get();
  return bookings.docs.reversed.map((e) => e as DocumentSnapshot).toList();
}

Future<List<DocumentSnapshot>> getClientBookingDocs(String clientID) async {
  final bookings = await FirebaseFirestore.instance
      .collection(Collections.bookings)
      .where(BookingFields.clientID, isEqualTo: clientID)
      .get();
  return bookings.docs.reversed.map((e) => e as DocumentSnapshot).toList();
}

Future createNewBookingRequest(BuildContext context, WidgetRef ref,
    {required DateTime datePicked}) async {
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  try {
    ref.read(loadingProvider.notifier).toggleLoading(true);
    List<dynamic> serviceIDs = [];
    for (var cartID in ref.read(cartProvider).selectedCartItemIDs) {
      final cartDoc = await getThisCartEntry(cartID);
      final cartData = cartDoc.data() as Map<dynamic, dynamic>;
      serviceIDs.add(cartData[CartFields.itemID]);
    }
    await FirebaseFirestore.instance.collection(Collections.bookings).add({
      BookingFields.serviceIDs: serviceIDs,
      BookingFields.clientID: FirebaseAuth.instance.currentUser!.uid,
      BookingFields.dateCreated: DateTime.now(),
      BookingFields.dateRequested: datePicked,
      BookingFields.serviceStatus: ServiceStatuses.pendingApproval
    });

    for (var cartID in ref.read(cartProvider).selectedCartItemIDs) {
      await FirebaseFirestore.instance
          .collection(Collections.cart)
          .doc(cartID)
          .delete();
    }
    ref.read(cartProvider).resetSelectedCartItems();
    ref.read(cartProvider).setCartItems(await getServiceCartEntries(context));

    scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Successfully requested for this service.')));
    ref.read(loadingProvider.notifier).toggleLoading(false);
  } catch (error) {
    scaffoldMessenger.showSnackBar(SnackBar(
        content: Text('Error creating new service booking request: $error')));
    ref.read(loadingProvider.notifier).toggleLoading(false);
  }
}

Future approveThisBookingRequest(BuildContext context, WidgetRef ref,
    {required String bookingID}) async {
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  try {
    ref.read(loadingProvider.notifier).toggleLoading(true);

    await FirebaseFirestore.instance
        .collection(Collections.bookings)
        .doc(bookingID)
        .update({BookingFields.serviceStatus: ServiceStatuses.pendingPayment});
    ref.read(bookingsProvider).setBookingDocs(await getAllBookingDocs());
    scaffoldMessenger.showSnackBar(const SnackBar(
        content: Text('Successfully approved this booking request')));
    ref.read(loadingProvider.notifier).toggleLoading(false);
  } catch (error) {
    scaffoldMessenger.showSnackBar(SnackBar(
        content: Text('Error approving this booking request: $error')));
    ref.read(loadingProvider.notifier).toggleLoading(false);
  }
}

Future denyThisBookingRequest(BuildContext context, WidgetRef ref,
    {required String bookingID}) async {
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  try {
    ref.read(loadingProvider.notifier).toggleLoading(true);

    await FirebaseFirestore.instance
        .collection(Collections.bookings)
        .doc(bookingID)
        .update({BookingFields.serviceStatus: ServiceStatuses.denied});
    ref.read(bookingsProvider).setBookingDocs(await getAllBookingDocs());
    scaffoldMessenger.showSnackBar(const SnackBar(
        content: Text('Successfully denied this booking request')));
    ref.read(loadingProvider.notifier).toggleLoading(false);
  } catch (error) {
    scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error denying this booking request: $error')));
    ref.read(loadingProvider.notifier).toggleLoading(false);
  }
}

Future markBookingRequestAsServiceOngoing(BuildContext context, WidgetRef ref,
    {required String bookingID}) async {
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  try {
    ref.read(loadingProvider.notifier).toggleLoading(true);

    await FirebaseFirestore.instance
        .collection(Collections.bookings)
        .doc(bookingID)
        .update({BookingFields.serviceStatus: ServiceStatuses.serviceOngoing});
    ref.read(bookingsProvider).setBookingDocs(await getAllBookingDocs());
    scaffoldMessenger.showSnackBar(const SnackBar(
        content:
            Text('Successfully marked booking request as service ongoing.')));
    ref.read(loadingProvider.notifier).toggleLoading(false);
  } catch (error) {
    scaffoldMessenger.showSnackBar(SnackBar(
        content:
            Text('Error marking booking request as service ongoing: $error')));
    ref.read(loadingProvider.notifier).toggleLoading(false);
  }
}

Future markBookingRequestAsForPickUp(BuildContext context, WidgetRef ref,
    {required String bookingID}) async {
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  try {
    ref.read(loadingProvider.notifier).toggleLoading(true);

    await FirebaseFirestore.instance
        .collection(Collections.bookings)
        .doc(bookingID)
        .update({BookingFields.serviceStatus: ServiceStatuses.pendingPickUp});
    ref.read(bookingsProvider).setBookingDocs(await getAllBookingDocs());
    scaffoldMessenger.showSnackBar(const SnackBar(
        content:
            Text('Successfully marked booking request as pending pick up.')));
    ref.read(loadingProvider.notifier).toggleLoading(false);
  } catch (error) {
    scaffoldMessenger.showSnackBar(SnackBar(
        content:
            Text('Error marking booking request as pending pick up: $error')));
    ref.read(loadingProvider.notifier).toggleLoading(false);
  }
}

Future markBookingRequestAsCompleted(BuildContext context, WidgetRef ref,
    {required String bookingID,
    required String paymentID,
    required Uint8List pdfBytes}) async {
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  try {
    ref.read(loadingProvider.notifier).toggleLoading(true);

    await FirebaseFirestore.instance
        .collection(Collections.bookings)
        .doc(bookingID)
        .update(
            {BookingFields.serviceStatus: ServiceStatuses.serviceCompleted});

    final storageRef = FirebaseStorage.instance
        .ref()
        .child(StorageFields.invoices)
        .child('$bookingID.pdf');
    final uploadTask = storageRef.putData(pdfBytes);
    final taskSnapshot = await uploadTask;
    final downloadURL = await taskSnapshot.ref.getDownloadURL();
    await FirebaseFirestore.instance
        .collection(Collections.payments)
        .doc(paymentID)
        .update({PaymentFields.invoiceURL: downloadURL});
    ref.read(bookingsProvider).setBookingDocs(await getAllBookingDocs());
    scaffoldMessenger.showSnackBar(const SnackBar(
        content: Text('Successfully marked service request as completed')));
    ref.read(loadingProvider.notifier).toggleLoading(false);
  } catch (error) {
    scaffoldMessenger.showSnackBar(SnackBar(
        content: Text('Error marking service request as completed: $error')));
    ref.read(loadingProvider.notifier).toggleLoading(false);
  }
}

Future<List<DocumentSnapshot>> getServiceBookingHistory(
    String serviceID) async {
  final purchases = await FirebaseFirestore.instance
      .collection(Collections.bookings)
      .where(BookingFields.serviceIDs, arrayContains: serviceID)
      .get();
  return purchases.docs.map((doc) => doc as DocumentSnapshot).toList();
}

//==============================================================================
//==MESSAGES====================================================================
//==============================================================================

Future<String> getChatDocumentId(
    String currentUserUID, String otherUserUID) async {
  final userDoc = await getCurrentUserDoc();
  final currentUserData = userDoc.data() as Map<dynamic, dynamic>;
  bool isClient = currentUserData[UserFields.userType] == UserTypes.client;
  final querySnapshot = await FirebaseFirestore.instance
      .collection(Collections.messages)
      .where(MessageFields.adminID,
          isEqualTo: isClient ? otherUserUID : currentUserUID)
      .where(MessageFields.clientID,
          isEqualTo: isClient ? currentUserUID : otherUserUID)
      .get();

  if (querySnapshot.docs.isNotEmpty) {
    return querySnapshot.docs.first.id;
  } else {
    // Chat document doesn't exist yet, create a new one
    final newChatDocRef =
        FirebaseFirestore.instance.collection(Collections.messages).doc();
    await newChatDocRef.set({
      MessageFields.adminID: isClient ? otherUserUID : currentUserUID,
      MessageFields.clientID: isClient ? currentUserUID : otherUserUID,
      MessageFields.dateTimeCreated: DateTime.now(),
      MessageFields.dateTimeSent: DateTime.now(),
      MessageFields.adminUnread: 0,
      MessageFields.clientUnread: 0
    });
    return newChatDocRef.id;
  }
}

Future submitMessage(
    {required String message,
    required bool isClient,
    required String senderUID,
    required String otherUID}) async {
  //final user = FirebaseAuth.instance.currentUser!;

  final checkMessages = await FirebaseFirestore.instance
      .collection(Collections.messages)
      .where(MessageFields.adminID, isEqualTo: isClient ? otherUID : senderUID)
      .where(MessageFields.clientID, isEqualTo: isClient ? senderUID : otherUID)
      .get();
  final chatDocument = checkMessages.docs.first;
  final messageThreadCollection =
      chatDocument.reference.collection(MessageFields.messageThread);
  DateTime timeNow = DateTime.now();
  await messageThreadCollection.add({
    MessageFields.sender: senderUID,
    MessageFields.dateTimeSent: timeNow,
    MessageFields.messageContent: message
  });
  await chatDocument.reference.update({
    MessageFields.lastMessageSent: timeNow,
    isClient ? MessageFields.adminUnread : MessageFields.clientUnread:
        FieldValue.increment(1)
  });
}

Future setClientMessagesAsRead({required String messageThreadID}) async {
  await FirebaseFirestore.instance
      .collection(Collections.messages)
      .doc(messageThreadID)
      .update({MessageFields.clientUnread: 0});
}

Future setAdminMessagesAsRead({required String messageThreadID}) async {
  await FirebaseFirestore.instance
      .collection(Collections.messages)
      .doc(messageThreadID)
      .update({MessageFields.adminUnread: 0});
}
