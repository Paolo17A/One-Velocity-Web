import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CategoryNotifer extends ChangeNotifier {
  String currentCategory = 'VIEW ALL';

  void setCategory(String category) {
    currentCategory = category;
    notifyListeners();
  }
}

final categoryProvider =
    ChangeNotifierProvider<CategoryNotifer>((ref) => CategoryNotifer());
