import 'package:flutter/material.dart';
import 'analytics_helper.dart';

class AnalyticsRouteObserver extends NavigatorObserver {
  void _sendScreenView(Route<dynamic> route) {
    final screenName = route.settings.name ?? route.runtimeType.toString();
    AnalyticsHelper.logScreenView(screenName);
  }

  @override
  void didPush(Route route, Route? previousRoute) {
    super.didPush(route, previousRoute);
    _sendScreenView(route);
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null) _sendScreenView(newRoute);
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    super.didPop(route, previousRoute);
    if (previousRoute != null) _sendScreenView(previousRoute);
  }
}
