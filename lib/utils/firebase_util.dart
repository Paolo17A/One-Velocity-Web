import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/loading_provider.dart';
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
      UserFields.profileImageURL: ''
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
    ref.read(loadingProvider.notifier).toggleLoading(false);
    goRouter.goNamed(GoRoutes.home);
    goRouter.pushReplacementNamed(GoRoutes.home);
  } catch (error) {
    scaffoldMessenger
        .showSnackBar(SnackBar(content: Text('Error logging in: $error')));
    ref.read(loadingProvider.notifier).toggleLoading(false);
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

Future<List<DocumentSnapshot>> getAllServices() async {
  final services =
      await FirebaseFirestore.instance.collection(Collections.services).get();
  return services.docs;
}

//==============================================================================
//PRODUCTS======================================================================
//==============================================================================

Future<List<DocumentSnapshot>> getAllProducts() async {
  final products =
      await FirebaseFirestore.instance.collection(Collections.products).get();
  return products.docs;
}

Future<DocumentSnapshot> getThisProductDoc(String productID) async {
  return await FirebaseFirestore.instance
      .collection(Collections.products)
      .doc(productID)
      .get();
}

Future addProductEntry(BuildContext context, WidgetRef ref,
    {required TextEditingController nameController,
    required TextEditingController descriptionController,
    required TextEditingController quantityController,
    required TextEditingController priceController}) async {
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  final goRouter = GoRouter.of(context);
  if (nameController.text.isEmpty ||
      descriptionController.text.isEmpty ||
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
        .set({
      ProductFields.name: nameController.text.trim(),
      ProductFields.description: descriptionController.text.trim(),
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
    required TextEditingController quantityController,
    required TextEditingController priceController}) async {
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  final goRouter = GoRouter.of(context);
  if (nameController.text.isEmpty ||
      descriptionController.text.isEmpty ||
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
      ProductFields.quantity: int.parse(quantityController.text),
      ProductFields.price: double.parse(priceController.text),
      ProductFields.imageURLs: FieldValue.arrayUnion(imageURLs)
    });
    ref.read(loadingProvider.notifier).toggleLoading(false);

    scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Successfully edited this product.')));
    goRouter.goNamed(GoRoutes.viewProducts);
  } catch (error) {
    scaffoldMessenger
        .showSnackBar(SnackBar(content: Text('Error editing product: $error')));
    ref.read(loadingProvider.notifier).toggleLoading(false);
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
    {required TextEditingController questionController,
    required TextEditingController answerController}) async {
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  final goRouter = GoRouter.of(context);
  if (questionController.text.isEmpty || answerController.text.isEmpty) {
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
    required TextEditingController questionController,
    required TextEditingController answerController}) async {
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  final goRouter = GoRouter.of(context);
  if (questionController.text.isEmpty || answerController.text.isEmpty) {
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
