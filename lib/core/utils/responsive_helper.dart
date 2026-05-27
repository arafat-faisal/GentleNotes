/// Responsive layout utilities.
///
/// Provides breakpoint checks used throughout the app to switch between
/// mobile and desktop/tablet layouts.
library responsive_helper;

import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

class ResponsiveHelper {
  ResponsiveHelper._(); // Prevent instantiation

  /// Returns true when the screen width is below [AppConstants.mobileBreakpoint].
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < AppConstants.mobileBreakpoint;
  }

  /// Returns true when the screen width is at or above [AppConstants.mobileBreakpoint].
  static bool isDesktop(BuildContext context) {
    return !isMobile(context);
  }

  /// Returns the screen width.
  static double screenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  /// Returns the screen height.
  static double screenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }
}
