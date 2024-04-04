import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PaymentsNotifier extends ChangeNotifier {
  List<DocumentSnapshot> paymentDocs = [];

  void setPaymentDocs(List<DocumentSnapshot> payments) {
    paymentDocs = payments;
    notifyListeners();
  }
}

final paymentsProvider =
    ChangeNotifierProvider<PaymentsNotifier>((ref) => PaymentsNotifier());
