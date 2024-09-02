import 'package:flutter_riverpod/flutter_riverpod.dart';

class DisplayChatProvider extends StateNotifier<bool> {
  DisplayChatProvider() : super(false);

  toggleDisplayChat() {
    state = !state;
  }
}

final displayChatProvider = StateNotifierProvider<DisplayChatProvider, bool>(
    (ref) => DisplayChatProvider());
