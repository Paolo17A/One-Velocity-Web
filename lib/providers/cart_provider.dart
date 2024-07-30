import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker_web/image_picker_web.dart';
import 'package:one_velocity_web/utils/string_util.dart';

class CartNotifier extends ChangeNotifier {
  List<DocumentSnapshot> cartItems = [];
  List<String> selectedCartItemIDs = [];
  String selectedPaymentMethod = '';
  /*String selectedCartItem = '';
  num selectedCartItemSRP = 0;*/
  Uint8List? proofOfPaymentBytes;

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

  void selectCartItem(String item) {
    if (selectedCartItemIDs.contains(item)) return;
    selectedCartItemIDs.add(item);
    notifyListeners();
  }

  void deselectCartItem(String item) {
    if (!selectedCartItemIDs.contains(item)) return;
    selectedCartItemIDs.remove(item);
    notifyListeners();
  }

  void resetSelectedCartItems() {
    selectedCartItemIDs.clear();
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

  void setProofOfPaymentBytes() async {
    final pickedFile = await ImagePickerWeb.getImageAsBytes();
    if (pickedFile == null) {
      return;
    }
    proofOfPaymentBytes = pickedFile;
    notifyListeners();
  }

  void resetProofOfPaymentBytes() async {
    proofOfPaymentBytes = null;
    notifyListeners();
  }
}

final cartProvider =
    ChangeNotifierProvider<CartNotifier>((ref) => CartNotifier());
