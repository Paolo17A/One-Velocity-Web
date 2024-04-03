import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UploadedImagesNotifier extends ChangeNotifier {
  List<Uint8List?> uploadedImages = [];

  void removeImage(Uint8List? image) {
    uploadedImages.remove(image);
    notifyListeners();
  }

  void addImages(List<Uint8List> images) {
    uploadedImages.addAll(images);
    notifyListeners();
  }

  void clearImages() {
    uploadedImages.clear();
    notifyListeners();
  }
}

final uploadedImagesProvider =
    ChangeNotifierProvider<UploadedImagesNotifier>((ref) {
  return UploadedImagesNotifier();
});
