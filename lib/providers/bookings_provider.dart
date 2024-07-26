import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BookingsNotifier extends ChangeNotifier {
  List<DocumentSnapshot> bookingDocs = [];

  void setBookingDocs(List<DocumentSnapshot> bookings) {
    bookingDocs = bookings;
    notifyListeners();
  }
}

final bookingsProvider =
    ChangeNotifierProvider<BookingsNotifier>((ref) => BookingsNotifier());
