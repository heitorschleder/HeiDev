import 'package:flutter/material.dart';

abstract class AppContext {
  static final navigatorKey = GlobalKey<NavigatorState>();
  static final snackBarKey = GlobalKey<ScaffoldMessengerState>();
  static final localizationKey = GlobalKey();

  static BuildContext get navigatorContext => navigatorKey.currentState!.context;
}
