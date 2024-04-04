import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PurchaseHistoryNotifier extends ChangeNotifier {
  List<DocumentSnapshot> purchaseHistory = [];

  void setPurchaseHistories(List<DocumentSnapshot> history) {
    purchaseHistory = history;
    notifyListeners();
  }
}

final purchaseHistoryProvider = ChangeNotifierProvider<PurchaseHistoryNotifier>(
    (ref) => PurchaseHistoryNotifier());
