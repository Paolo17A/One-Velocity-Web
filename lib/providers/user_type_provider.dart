import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/string_util.dart';

class UserTypeProvider extends StateNotifier<String> {
  UserTypeProvider() : super(UserTypes.client);

  void setUserType(String userType) {
    state = userType;
  }
}

final userTypeProvider = StateNotifierProvider<UserTypeProvider, String>(
    (ref) => UserTypeProvider());
