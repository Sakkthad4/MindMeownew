import 'dart:async';

import 'package:flutter/material.dart';

import 'ble/robot_celebration.dart';

final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

final NavigatorObserver robotFeatureMotionObserver =
    _RobotFeatureMotionObserver();

class _RobotFeatureMotionObserver extends NavigatorObserver {
  static const _featureRoutes = <String>{
    '/calendar',
    '/stretch',
    '/gemini',
    '/geminiloop',
    '/healthcare',
  };

  void _moveForFeature(Route<dynamic>? route) {
    if (_featureRoutes.contains(route?.settings.name)) {
      // This one-set greeting deliberately sends no eye commands.
      unawaited(RobotCelebrationController.instance.greetFeature());
    }
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _moveForFeature(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _moveForFeature(newRoute);
  }
}
