import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/string_util.dart';

class PurchasesNotifier extends ChangeNotifier {
  List<DocumentSnapshot> purchaseDocs = [];

  void setPurchaseDocs(List<DocumentSnapshot> purchases) {
    purchaseDocs = purchases;
    notifyListeners();
  }

  void sortPurchasesByDate() {
    purchaseDocs.sort((a, b) {
      DateTime aTime = (a[PurchaseFields.dateCreated] as Timestamp).toDate();
      DateTime bTime = (b[PurchaseFields.dateCreated] as Timestamp).toDate();
      return bTime.compareTo(aTime);
    });
  }
}

final purchasesProvider =
    ChangeNotifierProvider<PurchasesNotifier>((ref) => PurchasesNotifier());
