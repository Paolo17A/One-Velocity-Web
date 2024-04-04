import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PurchasesNotifier extends ChangeNotifier {
  List<DocumentSnapshot> purchaseDocs = [];

  void setPurchaseDocs(List<DocumentSnapshot> purchases) {
    purchaseDocs = purchases;
    notifyListeners();
  }
}

final purchasesProvider =
    ChangeNotifierProvider<PurchasesNotifier>((ref) => PurchasesNotifier());
