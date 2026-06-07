import 'package:flutter/material.dart';

class ScreenUtils {
  static const double _designWidth = 430;
  static const double _designHeight = 932;

  static double scaleWidth(BuildContext context) =>
      MediaQuery.of(context).size.width / _designWidth;

  static double scaleHeight(BuildContext context) =>
      MediaQuery.of(context).size.height / _designHeight;

  static double scaleFont(BuildContext context) =>
      scaleWidth(context).clamp(0.75, 1.25);

  static double w(double size, BuildContext context) =>
      size * scaleWidth(context);

  static double h(double size, BuildContext context) =>
      size * scaleHeight(context);

  static double f(double size, BuildContext context) =>
      size * scaleFont(context);

  static double wp(double percentage, BuildContext context) =>
      MediaQuery.of(context).size.width * (percentage / 100);

  static double hp(double percentage, BuildContext context) =>
      MediaQuery.of(context).size.height * (percentage / 100);
}

extension ResponsiveContext on BuildContext {
  double get sw => ScreenUtils.scaleWidth(this);
  double get sh => ScreenUtils.scaleHeight(this);
  double get sf => ScreenUtils.scaleFont(this);
  double w(double size) => ScreenUtils.w(size, this);
  double h(double size) => ScreenUtils.h(size, this);
  double f(double size) => ScreenUtils.f(size, this);
  double wp(double percentage) => ScreenUtils.wp(percentage, this);
  double hp(double percentage) => ScreenUtils.hp(percentage, this);
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;
}
