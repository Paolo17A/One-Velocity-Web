import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:one_velocity_web/screens/add_faq_screen.dart';
import 'package:one_velocity_web/screens/add_product_screen.dart';
import 'package:one_velocity_web/screens/bookmarks_screen.dart';
import 'package:one_velocity_web/screens/cart_screen.dart';
import 'package:one_velocity_web/screens/edit_product_screen.dart';
import 'package:one_velocity_web/screens/forgot_password_screen.dart';
import 'package:one_velocity_web/screens/login_screen.dart';
import 'package:one_velocity_web/screens/purchase_history_screen.dart';
import 'package:one_velocity_web/screens/register_screen.dart';
import 'package:one_velocity_web/screens/view_faqs_screen.dart';
import 'package:one_velocity_web/screens/view_products_screen.dart';
import 'package:one_velocity_web/screens/view_purchases_screen.dart';
import 'package:one_velocity_web/screens/view_transactions_screen.dart';
import 'package:one_velocity_web/screens/view_users_screen.dart';
import 'package:one_velocity_web/utils/string_util.dart';

import '../screens/add_service_screen.dart';
import '../screens/booking_history_screen.dart';
import '../screens/edit_faq_screen.dart';
import '../screens/edit_profile_screen.dart';
import '../screens/edit_service_screen.dart';
import '../screens/help_center_screen.dart';
import '../screens/home_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/selected_product_screen.dart';
import '../screens/selected_service_screen.dart';
import '../screens/selected_user_screen.dart';
import '../screens/shop_products_screen.dart';
import '../screens/shop_services_screen.dart';
import '../screens/view_services_screen.dart';

class GoRoutes {
  static const home = '/';
  static const login = 'login';
  static const register = 'register';
  static const forgotPassword = 'forgotPassword';
  static const products = 'products';
  static const selectedProduct = 'selectedProduct';
  static const services = 'services';
  static const selectedService = 'selectedService';
  static const help = 'help';

  //  ADMIN
  static const viewProducts = 'viewProducts';
  static const addProduct = 'addProduct';
  static const editProduct = 'editProduct';
  static const viewServices = 'viewServices';
  static const addService = 'addService';
  static const editService = 'editService';
  static const viewUsers = 'viewUsers';
  static const selectedUser = 'selectedUser';
  static const viewTransactions = 'viewTransactions';
  static const viewPurchases = 'viewPurchases';
  static const viewFAQs = 'viewFAQs';
  static const addFAQ = 'addFAQ';
  static const editFAQ = 'editFAQ';

  //  CLIENT
  static const cart = 'cart';
  static const profile = 'profile';
  static const editProfile = 'editProfile';
  static const bookmarks = 'bookmarks';
  static const purchaseHistory = 'purchaseHistory';
  static const bookingsHistory = 'bookingsHistory';
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
        GoRoute(
            name: GoRoutes.products,
            path: GoRoutes.products,
            pageBuilder: (context, state) =>
                customTransition(context, state, const ShopProductsScreen())),
        GoRoute(
            name: GoRoutes.selectedProduct,
            path: '${GoRoutes.selectedProduct}/:${PathParameters.productID}',
            pageBuilder: (context, state) => customTransition(
                context,
                state,
                SelectedProductScreen(
                    productID:
                        state.pathParameters[PathParameters.productID]!))),
        GoRoute(
            name: GoRoutes.services,
            path: GoRoutes.services,
            pageBuilder: (context, state) =>
                customTransition(context, state, const ShopServicesScreen())),
        GoRoute(
            name: GoRoutes.selectedService,
            path: '${GoRoutes.selectedService}/:${PathParameters.serviceID}',
            pageBuilder: (context, state) => customTransition(
                context,
                state,
                SelectedServiceScreen(
                    serviceID:
                        state.pathParameters[PathParameters.serviceID]!))),
        GoRoute(
            name: GoRoutes.help,
            path: GoRoutes.help,
            pageBuilder: (context, state) =>
                customTransition(context, state, const HelpCenterScreen())),

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
        GoRoute(
            name: GoRoutes.viewTransactions,
            path: GoRoutes.viewTransactions,
            pageBuilder: (context, state) => customTransition(
                context, state, const ViewTransactionsScreen())),
        GoRoute(
            name: GoRoutes.viewPurchases,
            path: GoRoutes.viewPurchases,
            pageBuilder: (context, state) =>
                customTransition(context, state, const ViewPurchasesScreen())),
        //======================================================================
        //==CLIENT PAGES========================================================
        //======================================================================
        GoRoute(
            name: GoRoutes.cart,
            path: GoRoutes.cart,
            pageBuilder: (context, state) =>
                customTransition(context, state, const CartScreen())),
        GoRoute(
            name: GoRoutes.profile,
            path: GoRoutes.profile,
            pageBuilder: (context, state) =>
                customTransition(context, state, const ProfileScreen())),
        GoRoute(
            name: GoRoutes.editProfile,
            path: GoRoutes.editProfile,
            pageBuilder: (context, state) =>
                customTransition(context, state, const EditProfileScreen())),
        GoRoute(
            name: GoRoutes.bookmarks,
            path: GoRoutes.bookmarks,
            pageBuilder: (context, state) =>
                customTransition(context, state, const BookMarksScreen())),
        GoRoute(
            name: GoRoutes.purchaseHistory,
            path: GoRoutes.purchaseHistory,
            pageBuilder: (context, state) => customTransition(
                context, state, const PurchaseHistoryScreen())),
        GoRoute(
            name: GoRoutes.bookingsHistory,
            path: GoRoutes.bookingsHistory,
            pageBuilder: (context, state) =>
                customTransition(context, state, const BookingHistoryScreen())),
        GoRoute(
            name: GoRoutes.viewServices,
            path: GoRoutes.viewServices,
            pageBuilder: (context, state) =>
                customTransition(context, state, const ViewServicesScreen())),
        GoRoute(
            name: GoRoutes.addService,
            path: GoRoutes.addService,
            pageBuilder: (context, state) =>
                customTransition(context, state, const AddServiceScreen())),
        GoRoute(
            name: GoRoutes.editService,
            path: '${GoRoutes.editService}/:${PathParameters.serviceID}',
            pageBuilder: (context, state) => customTransition(
                context,
                state,
                EditServiceScreen(
                    serviceID:
                        state.pathParameters[PathParameters.serviceID]!))),
      ])
]);
