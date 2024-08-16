import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:one_velocity_web/utils/color_util.dart';

Text crimsonSarabunBold(String label,
    {double fontSize = 20,
    TextAlign textAlign = TextAlign.center,
    TextOverflow? textOverflow}) {
  return Text(
    label,
    textAlign: textAlign,
    overflow: textOverflow,
    style: GoogleFonts.sarabun(
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        color: CustomColors.crimson),
  );
}

Text grenadineSarabunRegular(String label,
    {double fontSize = 20,
    TextAlign textAlign = TextAlign.center,
    TextOverflow? textOverflow}) {
  return Text(
    label,
    textAlign: textAlign,
    overflow: textOverflow,
    style:
        GoogleFonts.sarabun(fontSize: fontSize, color: CustomColors.grenadine),
  );
}

Text blackSarabunBold(String label,
    {double fontSize = 20,
    TextAlign textAlign = TextAlign.center,
    TextDecoration? decoration,
    TextOverflow? textOverflow}) {
  return Text(
    label,
    textAlign: textAlign,
    overflow: textOverflow,
    style: GoogleFonts.sarabun(
        fontWeight: FontWeight.bold,
        decoration: decoration,
        fontSize: fontSize,
        color: CustomColors.blackBeauty),
  );
}

Text blackSarabunRegular(String label,
    {double fontSize = 20,
    TextAlign textAlign = TextAlign.center,
    TextDecoration? decoration,
    TextOverflow? textOverflow}) {
  return Text(
    label,
    textAlign: textAlign,
    overflow: textOverflow,
    style: GoogleFonts.sarabun(
        decoration: decoration,
        fontSize: fontSize,
        color: CustomColors.blackBeauty),
  );
}

Text nimbusCloudSarabunRegular(String label,
    {double fontSize = 20,
    TextAlign textAlign = TextAlign.center,
    TextOverflow? textOverflow}) {
  return Text(
    label,
    textAlign: textAlign,
    overflow: textOverflow,
    style: GoogleFonts.sarabun(
        fontSize: fontSize, color: CustomColors.nimbusCloud),
  );
}

Text whiteSarabunBold(String label,
    {double fontSize = 20,
    TextAlign textAlign = TextAlign.center,
    TextOverflow? textOverflow}) {
  return Text(
    label,
    textAlign: textAlign,
    overflow: textOverflow,
    style: GoogleFonts.sarabun(
        fontSize: fontSize, fontWeight: FontWeight.bold, color: Colors.white),
  );
}

Text whiteSarabunRegular(String label,
    {double fontSize = 20,
    TextAlign textAlign = TextAlign.center,
    TextDecoration? decoration,
    TextOverflow? textOverflow}) {
  return Text(
    label,
    textAlign: textAlign,
    overflow: textOverflow,
    style: GoogleFonts.sarabun(
        decoration: decoration, fontSize: fontSize, color: Colors.white),
  );
}

/*Text montserratCrimsonBold(String label,
    {double fontSize = 20,
    TextAlign textAlign = TextAlign.center,
    TextOverflow? textOverflow}) {
  return Text(
    label,
    textAlign: textAlign,
    overflow: textOverflow,
    style: GoogleFonts.montserrat(
        fontSize: fontSize,
        color: CustomColors.crimson,
        fontWeight: FontWeight.bold),
  );
}

Text whiteSarabunBold(String label,
    {double fontSize = 20,
    TextAlign textAlign = TextAlign.center,
    TextOverflow? textOverflow}) {
  return Text(
    label,
    textAlign: textAlign,
    overflow: textOverflow,
    style: GoogleFonts.montserrat(
        fontSize: fontSize, color: Colors.white, fontWeight: FontWeight.bold),
  );
}

Text montserratBlackRegular(String label,
    {double fontSize = 20,
    TextAlign textAlign = TextAlign.center,
    TextOverflow? textOverflow}) {
  return Text(
    label,
    textAlign: textAlign,
    overflow: textOverflow,
    style: GoogleFonts.montserrat(fontSize: fontSize, color: Colors.black),
  );
}

Text montserratWhiteRegular(String label,
    {double fontSize = 20,
    TextAlign textAlign = TextAlign.center,
    TextOverflow? textOverflow,
    TextDecoration? decoration}) {
  return Text(
    label,
    textAlign: textAlign,
    overflow: textOverflow,
    style: GoogleFonts.montserrat(
        fontSize: fontSize,
        color: Colors.white,
        decoration: decoration,
        decorationColor: Colors.white),
  );
}

Text blackSarabunBold(String label,
    {double fontSize = 20,
    TextAlign textAlign = TextAlign.center,
    TextDecoration? textDecoration,
    TextOverflow? textOverflow}) {
  return Text(
    label,
    textAlign: textAlign,
    overflow: textOverflow,
    style: GoogleFonts.montserrat(
        fontSize: fontSize,
        color: Colors.black,
        fontWeight: FontWeight.bold,
        decoration: textDecoration),
  );
}*/
