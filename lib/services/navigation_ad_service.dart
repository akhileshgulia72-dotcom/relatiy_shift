import 'package:flutter/material.dart';
import 'ads_service.dart';

final navigationAdObserver = _NavigationAdObserver();

/// Counts page changes, then waits for a calm menu screen before showing ads.
class NavigationAdService {
  NavigationAdService._();
  static final instance = NavigationAdService._();
  final Set<Object> _visibleMenus = {};
  int _changes = 0;
  bool _pending = false;
  bool _checking = false;

  void pageChanged() {
    _changes++;
    if (_changes % 3 == 0) _pending = true;
    _schedule();
  }

  void menuVisible(Object menu, bool visible) {
    if (visible) {
      _visibleMenus.add(menu);
    } else {
      _visibleMenus.remove(menu);
    }
    _schedule();
  }

  void _schedule() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pending && _visibleMenus.isNotEmpty && !_checking) _showIfDue();
    });
  }

  Future<void> _showIfDue() async {
    _checking = true;
    // Let the new page settle before covering it with a full-screen ad.
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (_pending && _visibleMenus.isNotEmpty) {
      final shown = await AdsService.instance.showNavigationInterstitial();
      if (shown) _pending = false;
    }
    _checking = false;
  }
}

class _NavigationAdObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is PageRoute && previousRoute != null) {
      NavigationAdService.instance.pageChanged();
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is PageRoute && previousRoute is PageRoute) {
      NavigationAdService.instance.pageChanged();
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (newRoute is PageRoute && oldRoute is PageRoute) {
      NavigationAdService.instance.pageChanged();
    }
  }
}
