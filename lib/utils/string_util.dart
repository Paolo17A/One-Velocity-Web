import 'dart:math';

class ImagePaths {
  static const String logo = 'assets/images/one_velocity.jpg';
}

class UserTypes {
  static const String client = 'CLIENT';
  static const String admin = 'ADMIN';
}

class Collections {
  static const String users = 'users';
  static const String faqs = 'faqs';
  static const String products = 'products';
  static const String services = 'services';
}

class UserFields {
  static const String email = 'email';
  static const String password = 'password';
  static const String firstName = 'firstName';
  static const String lastName = 'lastName';
  static const String mobileNumber = 'mobileNumber';
  static const String userType = 'userType';
  static const String profileImageURL = 'profileImageURL';
}

class FAQFields {
  static const String question = 'question';
  static const String answer = 'answer';
}

class ProductFields {
  static const String name = 'name';
  static const String description = 'description';
  static const String quantity = 'quantity';
  static const String price = 'price';
  static const String imageURLs = 'imageURLs';
}

class ServiceFields {
  static const String name = 'name';
  static const String description = 'description';
  static const String isAvailable = 'isAvailable';
  static const String price = 'price';
  static const String imageURLs = 'imageURLs';
}

class PathParameters {
  static const String userID = 'userID';
  static const String faqID = 'faqID';
  static const String productID = 'productID';
  static const String serviceID = 'serviceID';
}

String generateRandomHexString(int length) {
  final random = Random();
  final codeUnits = List.generate(length ~/ 2, (index) {
    return random.nextInt(255);
  });

  final hexString =
      codeUnits.map((value) => value.toRadixString(16).padLeft(2, '0')).join();
  return hexString;
}
