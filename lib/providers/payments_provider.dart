import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:one_velocity_web/utils/string_util.dart';

class PaymentsNotifier extends ChangeNotifier {
  List<DocumentSnapshot> paymentDocs = [];

  void setPaymentDocs(List<DocumentSnapshot> payments) {
    paymentDocs = payments;
    notifyListeners();
  }

  void sortPaymentsByDate() {
    paymentDocs.sort((a, b) {
      DateTime aTime = (a[PaymentFields.dateCreated] as Timestamp).toDate();
      DateTime bTime = (b[PaymentFields.dateCreated] as Timestamp).toDate();
      return bTime.compareTo(aTime);
    });
  }
}

final paymentsProvider =
    ChangeNotifierProvider<PaymentsNotifier>((ref) => PaymentsNotifier());
