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
  static const String cart = 'cart';
  static const String purchases = 'purchases';
  static const String payments = 'payments';
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
  static const String bookmarkedProducts = 'bookmarkedProducts';
  static const String bookmarkedServices = 'bookmarkedServices';
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
  static const String category = 'category';
}

class ProductCategories {
  static const String wheel = 'WHEEL';
  static const String battery = 'BATTERY';
  static const String accessory = 'ACCESSORY';
  static const String others = 'OTHERS';
}

class CartFields {
  static const String clientID = 'clientID';
  static const String productID = 'productID';
  static const String quantity = 'quantity';
}

class PaymentFields {
  static const String clientID = 'clientID';
  static const String productID = 'productID';
  static const String paidAmount = 'paidAmount';
  static const String paymentMethod = 'paymentMethod';
  static const String proofOfPayment = 'proofOfPayment';
  static const String paymentStatus = 'paymentStatus';
  static const String paymentVerified = 'paymentVerified';
  static const String dateCreated = 'dateCreated';
  static const String dateApproved = 'dateApproved';
  static const String invoiceURL = 'invoiceURL';
}

class PurchaseFields {
  static const String clientID = 'clientID';
  static const String productID = 'productID';
  static const String quantity = 'quantity';
  static const String purchaseStatus = 'purchaseStatus';
  static const String datePickedUp = 'datePickedUp';
  static const String rating = 'rating';
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

class StorageFields {
  static const String profilePics = 'profilePics';
  static const String payments = 'payments';
  static const String products = 'products';
  static const String invoices = 'invoices';
}

class PaymentStatuses {
  static const String pending = 'PENDING';
  static const String approved = 'APPROVED';
  static const String denied = 'DENIED';
}

class PurchaseStatuses {
  static const String denied = 'DENIED';
  static const String pending = 'PENDING';
  static const String processing = 'PROCESSING';
  static const String forPickUp = 'FOR PICK UP';
  static const String pickedUp = 'PICKED UP';
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
