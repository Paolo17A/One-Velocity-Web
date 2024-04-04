import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:one_velocity_web/utils/string_util.dart';

class CartNotifier extends ChangeNotifier {
  List<DocumentSnapshot> cartItems = [];
  String selectedPaymentMethod = '';
  String selectedCartItem = '';
  num selectedCartItemSRP = 0;

  void setCartItems(List<DocumentSnapshot> items) {
    cartItems = items;
    notifyListeners();
  }

  void addCartItem(dynamic item) {
    cartItems.add(item);
    notifyListeners();
  }

  void removeCartItem(DocumentSnapshot item) {
    cartItems.remove(item);
    notifyListeners();
  }

  bool cartContainsThisItem(String itemID) {
    return cartItems.any((cartItem) {
      final cartData = cartItem.data() as Map<dynamic, dynamic>;
      return cartData[CartFields.productID] == itemID;
    });
  }

  void setSelectedPaymentMethod(String paymentMethod) {
    selectedPaymentMethod = paymentMethod;
    notifyListeners();
  }

  void setSelectedCartItem(String cartID, num srp, num quantity) {
    selectedCartItem = cartID;
    selectedCartItemSRP = srp;
    notifyListeners();
  }

  DocumentSnapshot? getSelectedCartDoc() {
    return cartItems
        .where((element) => element.id == selectedCartItem)
        .firstOrNull;
  }
}

final cartProvider =
    ChangeNotifierProvider<CartNotifier>((ref) => CartNotifier());
