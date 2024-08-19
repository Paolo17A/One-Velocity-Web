import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FAQNotifier extends ChangeNotifier {
  List<DocumentSnapshot> _faqDocs = [];

  List<DocumentSnapshot> get faqDocs => _faqDocs;

  setFAQDocs(List<DocumentSnapshot> docs) {
    _faqDocs = docs;
    notifyListeners();
  }
}

final faqsProvider =
    ChangeNotifierProvider<FAQNotifier>((ref) => FAQNotifier());
