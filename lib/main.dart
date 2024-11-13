import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:one_velocity_web/firebase_options.dart';
import 'package:one_velocity_web/utils/go_router_util.dart';
import 'package:one_velocity_web/utils/string_util.dart';
import 'package:one_velocity_web/utils/theme_util.dart';

Uint8List? logoImageBytes;
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  ByteData img = await rootBundle.load(ImagePaths.logo);
  logoImageBytes = img.buffer.asUint8List();
  runApp(ProviderScope(child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'One Velocity Car Care Inc.',
        theme: themeData,
        routerConfig: goRoutes);
  }
}
