import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BookMarksNotifier extends ChangeNotifier {
  List<dynamic> bookmarkedProducts = [];
  List<dynamic> bookmarkedServices = [];

  void setBookmarkedProducts(List<dynamic> products) {
    bookmarkedProducts = products;
    notifyListeners();
  }

  void addProductToBookmarks(dynamic product) {
    bookmarkedProducts.add(product);
    notifyListeners();
  }

  void removeProductFromBookmarks(dynamic product) {
    bookmarkedProducts.remove(product);
    notifyListeners();
  }

  void setBookmarkedServices(List<dynamic> services) {
    bookmarkedServices = services;
    notifyListeners();
  }

  void addServiceToBookmarks(dynamic service) {
    bookmarkedServices.add(service);
    notifyListeners();
  }

  void removeServiceFromBookmarks(dynamic service) {
    bookmarkedServices.remove(service);
    notifyListeners();
  }
}

final bookmarksProvider =
    ChangeNotifierProvider<BookMarksNotifier>((ref) => BookMarksNotifier());
