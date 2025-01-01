import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ResponsiveUtils {
  static bool isPhone(BuildContext context) =>
      MediaQuery.of(context).size.width < 600;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 600 &&
      MediaQuery.of(context).size.width < 1200;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1200;

  static double getResponsivePadding(BuildContext context) {
    if (isPhone(context)) return 16.w;
    if (isTablet(context)) return 24.w;
    return 32.w;
  }

  static double getResponsiveFontSize(BuildContext context, double baseSize) {
    if (isPhone(context)) return baseSize.sp;
    if (isTablet(context)) return (baseSize * 1.1).sp;
    return (baseSize * 1.2).sp;
  }
} 