import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static const String fontFamily = 'Nunito Sans';

  static const TextStyle heading1 = TextStyle(
    color: AppColors.black,
    fontSize: 30,
    fontFamily: fontFamily,
    fontWeight: FontWeight.w800,
    height: 1.33,
  );

  static const TextStyle body = TextStyle(
    color: AppColors.black,
    fontSize: 14,
    fontFamily: fontFamily,
    fontWeight: FontWeight.w400,
    height: 1.50,
  );

  static const TextStyle bodyMedium = TextStyle(
    color: AppColors.white,
    fontSize: 14,
    fontFamily: fontFamily,
    fontWeight: FontWeight.w500,
    height: 1.50,
  );

  static const TextStyle bodyBold = TextStyle(
    color: AppColors.secondary,
    fontSize: 14,
    fontFamily: fontFamily,
    fontWeight: FontWeight.w800,
    height: 1.50,
  );

  static const TextStyle link = TextStyle(
    color: AppColors.secondary,
    fontSize: 14,
    fontFamily: fontFamily,
    fontWeight: FontWeight.w400,
    height: 1.50,
  );
}
