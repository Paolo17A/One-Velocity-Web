import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoadingProvider extends StateNotifier<bool> {
  LoadingProvider() : super(false);

  void toggleLoading(bool val) {
    state = val;
  }
}

final loadingProvider =
    StateNotifierProvider<LoadingProvider, bool>((ref) => LoadingProvider());
