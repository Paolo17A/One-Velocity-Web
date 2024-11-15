import 'dart:math';

String adminID = 'Gaz292NpJah1K0IAjqIlAUFPg1Q2';

class ImagePaths {
  static const String logo = 'assets/images/one_velocity.jpg';
  static const String landing = 'assets/images/landing.png';
  static const String background = 'assets/images/background.jpg';
  static const String wheel = 'assets/images/wheel.jpeg';
  static const String battery = 'assets/images/battery.jpeg';
  static const String paintJob = 'assets/images/paint job.jpg';
  static const String repair = 'assets/images/repair.png';
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
  static const String bookings = 'bookings';
  static const String messages = 'messages';
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
  static const String lastActive = 'lastActive';
}

class FAQFields {
  static const String question = 'question';
  static const String answer = 'answer';
  static const String category = 'category';
}

class FAQCategories {
  static const String location = 'LOCATION';
  static const String paymentMethod = 'PAYMENT METHODS';
  static const String services = 'SERVICES';
  static const String products = 'PRODUCTS';
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
  static const String itemID = 'itemID';
  static const String quantity = 'quantity';
  static const String cartType = 'cartType';
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
  static const String purchaseIDs = 'purchaseIDs';
  static const String paymentType = 'paymentType';
}

class PurchaseFields {
  static const String clientID = 'clientID';
  static const String productID = 'productID';
  static const String paymentID = 'paymentID';
  static const String quantity = 'quantity';
  static const String purchaseStatus = 'purchaseStatus';
  static const String datePickedUp = 'datePickedUp';
  static const String dateCreated = 'dateCreated';
  static const String rating = 'rating';
}

class ServiceFields {
  static const String name = 'name';
  static const String description = 'description';
  static const String isAvailable = 'isAvailable';
  static const String price = 'price';
  static const String imageURLs = 'imageURLs';
  static const String category = 'category';
}

class PathParameters {
  static const String userID = 'userID';
  static const String faqID = 'faqID';
  static const String productID = 'productID';
  static const String serviceID = 'serviceID';
  static const String bookingID = 'bookingID';
  static const String searchInput = 'searchInput';
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

class BookingFields {
  static const String serviceIDs = 'serviceIDs';
  static const String clientID = 'clientID';
  static const String paymentID = 'paymentID';
  static const String serviceStatus = 'serviceStatus';
  static const String dateCreated = 'dateCreated';
  static const String dateRequested = 'dateRequsted';
}

class ServiceStatuses {
  static const String pendingApproval = 'PENDING APPROVAL';
  static const String pendingPayment = 'PENDING PAYMENT';
  static const String processingPayment = 'PROCESSING PAYMENT';
  static const String pendingDropOff = 'PENDING DROP OFF';
  static const String serviceOngoing = 'SERVICE ONGOING';
  static const String pendingPickUp = 'PENDING PICK UP';
  static const String serviceCompleted = 'SERVICE COMPLETED';
  static const String denied = 'DENIED';
  static const String cancelled = 'CANCELLED';
}

class CartTypes {
  static const String product = 'PRODUCT';
  static const String service = 'SERVICE';
}

class PaymentTypes {
  static const String product = 'PRODUCT';
  static const String service = 'SERVICE';
}

class ServiceCategories {
  static const String paintJob = 'PAINT JOB';
  static const String repair = 'REPAIR';
}

class MessageFields {
  static const String messageThread = 'messageThread';
  static const String messageContent = 'messageContent';
  static const String dateTimeSent = 'dateTimeSent';
  static const String dateTimeCreated = 'dateTimeCreated';
  static const String lastMessageSent = 'lastMessageSent';
  static const String sender = 'sender';
  static const String adminID = 'adminID';
  static const String clientID = 'clientID';
  static const String adminUnread = 'adminUnread';
  static const String clientUnread = 'clientUnread';
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

String formatPrice(double amount) {
  // Round the amount to two decimal places
  amount = double.parse((amount).toStringAsFixed(2));

  // Convert the double to a string and split it into whole and decimal parts
  List<String> parts = amount.toString().split('.');

  // Format the whole part with commas
  String formattedWhole = '';
  for (int i = 0; i < parts[0].length; i++) {
    if (i != 0 && (parts[0].length - i) % 3 == 0) {
      formattedWhole += ',';
    }
    formattedWhole += parts[0][i];
  }

  // If there's a decimal part, add it back
  String formattedAmount = formattedWhole;
  if (parts.length > 1) {
    formattedAmount += '.${parts[1].length == 1 ? '${parts[1]}0' : parts[1]}';
  } else {
    // If there's no decimal part, append '.00'
    formattedAmount += '.00';
  }

  return formattedAmount;
}
