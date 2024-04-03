import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:one_velocity_web/screens/add_faq_screen.dart';
import 'package:one_velocity_web/screens/add_product_screen.dart';
import 'package:one_velocity_web/screens/edit_product_screen.dart';
import 'package:one_velocity_web/screens/forgot_password_screen.dart';
import 'package:one_velocity_web/screens/login_screen.dart';
import 'package:one_velocity_web/screens/register_screen.dart';
import 'package:one_velocity_web/screens/view_faqs_screen.dart';
import 'package:one_velocity_web/screens/view_products_screen.dart';
import 'package:one_velocity_web/screens/view_users_screen.dart';
import 'package:one_velocity_web/utils/string_util.dart';

import '../screens/edit_faq_screen.dart';
import '../screens/home_screen.dart';
import '../screens/selected_user_screen.dart';

class GoRoutes {
  static const home = '/';
  static const login = 'login';
  static const register = 'register';
  static const profile = 'profile';
  static const forgotPassword = 'forgotPassword';

  //  ADMIN
  static const viewProducts = 'viewProducts';
  static const addProduct = 'addProduct';
  static const editProduct = 'editProduct';
  static const viewServices = 'viewServices';
  //static const addService = 'addService';
  //static const editService = 'editService';
  static const viewUsers = 'viewUsers';
  static const selectedUser = 'selectedUser';
  static const viewTransactions = 'viewTransactions';
  static const viewFAQs = 'viewFAQs';
  static const addFAQ = 'addFAQ';
  static const editFAQ = 'editFAQ';
}

CustomTransitionPage customTransition(
    BuildContext context, GoRouterState state, Widget widget) {
  return CustomTransitionPage(
      fullscreenDialog: true,
      key: state.pageKey,
      child: widget,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return easeInOutCircTransition(animation, child);
      });
}

FadeTransition easeInOutCircTransition(
    Animation<double> animation, Widget child) {
  return FadeTransition(
      opacity: CurveTween(curve: Curves.easeInOutCirc).animate(animation),
      child: child);
}

final GoRouter goRoutes = GoRouter(initialLocation: GoRoutes.home, routes: [
  GoRoute(
      name: GoRoutes.home,
      path: GoRoutes.home,
      pageBuilder: (context, state) =>
          customTransition(context, state, const HomeScreen()),
      routes: [
        GoRoute(
            name: GoRoutes.login,
            path: GoRoutes.login,
            pageBuilder: (context, state) =>
                customTransition(context, state, const LoginScreen())),
        GoRoute(
            name: GoRoutes.register,
            path: GoRoutes.register,
            pageBuilder: (context, state) =>
                customTransition(context, state, const RegisterScreen())),
        GoRoute(
            name: GoRoutes.forgotPassword,
            path: GoRoutes.forgotPassword,
            pageBuilder: (context, state) =>
                customTransition(context, state, const ForgotPasswordScreen())),
        //======================================================================
        //==ADMIN PAGES=========================================================
        //======================================================================
        //  PRODUCTS
        GoRoute(
            name: GoRoutes.viewProducts,
            path: GoRoutes.viewProducts,
            pageBuilder: (context, state) =>
                customTransition(context, state, const ViewProductsScreen())),
        GoRoute(
            name: GoRoutes.addProduct,
            path: GoRoutes.addProduct,
            pageBuilder: (context, state) =>
                customTransition(context, state, const AddProductScreen())),
        GoRoute(
            name: GoRoutes.editProduct,
            path: '${GoRoutes.editProduct}/:${PathParameters.productID}',
            pageBuilder: (context, state) => customTransition(
                context,
                state,
                EditProductScreen(
                    productID:
                        state.pathParameters[PathParameters.productID]!))),
        //  USERS
        GoRoute(
            name: GoRoutes.viewUsers,
            path: GoRoutes.viewUsers,
            pageBuilder: (context, state) =>
                customTransition(context, state, const ViewUsersScreen())),
        GoRoute(
            name: GoRoutes.selectedUser,
            path: '${GoRoutes.selectedUser}/:${PathParameters.userID}',
            pageBuilder: (context, state) => customTransition(
                context,
                state,
                SelectedUserScreen(
                    userID: state.pathParameters[PathParameters.userID]!))),
        //  FAQs
        GoRoute(
            name: GoRoutes.viewFAQs,
            path: GoRoutes.viewFAQs,
            pageBuilder: (context, state) =>
                customTransition(context, state, const ViewFAQsScreen())),
        GoRoute(
            name: GoRoutes.addFAQ,
            path: GoRoutes.addFAQ,
            pageBuilder: (context, state) =>
                customTransition(context, state, const AddFAQScreen())),
        GoRoute(
            name: GoRoutes.editFAQ,
            path: '${GoRoutes.editFAQ}/:${PathParameters.faqID}',
            pageBuilder: (context, state) => customTransition(
                context,
                state,
                EditFAQScreen(
                    faqID: state.pathParameters[PathParameters.faqID]!))),
      ])
]);
