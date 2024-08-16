import 'package:flutter/material.dart';
import 'package:one_velocity_web/utils/color_util.dart';

ThemeData themeData = ThemeData(
    colorSchemeSeed: CustomColors.grenadine,
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: const AppBarTheme(
        centerTitle: false,
        backgroundColor: CustomColors.blackBeauty,
        titleTextStyle: TextStyle(
            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 30),
        iconTheme: IconThemeData(color: CustomColors.ultimateGray)),
    elevatedButtonTheme: ElevatedButtonThemeData(
        style:
            ElevatedButton.styleFrom(backgroundColor: CustomColors.grenadine)));
