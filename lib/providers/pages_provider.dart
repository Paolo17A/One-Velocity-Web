import 'package:flutter_riverpod/flutter_riverpod.dart';

class PagesProvider extends StateNotifier<Map<String, int>> {
  PagesProvider() : super({'currentPage': 1, 'maxPage': 1});

  void setCurrentPage(int val) {
    state = {...state, 'currentPage': val};
  }

  void setMaxPage(int val) {
    state = {...state, 'maxPage': val};
  }

  int getCurrentPage() {
    return state['currentPage']!;
  }

  int getMaxPage() {
    return state['maxPage']!;
  }
}

final pagesProvider = StateNotifierProvider<PagesProvider, Map<String, int>>(
    (ref) => PagesProvider());
