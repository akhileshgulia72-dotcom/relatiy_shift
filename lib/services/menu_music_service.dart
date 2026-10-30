import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'navigation_ad_service.dart';

final menuMusicRouteObserver = RouteObserver<PageRoute<dynamic>>();

/// One player shared by the opening, home, and level selection routes.
class MenuMusicService with WidgetsBindingObserver {
  MenuMusicService._();
  static final instance = MenuMusicService._();
  static const preferenceKey = 'menuMusicEnabled';
  final AudioPlayer _player = AudioPlayer();
  final Set<Object> _visibleRoutes = {};
  bool _enabled = true;
  bool _loaded = false;
  bool _sourceStarted = false;
  bool _appForeground = true;
  Future<void> _pending = Future.value();

  bool get enabled => _enabled;

  Future<void> initialize() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool(preferenceKey) ?? true;
    WidgetsBinding.instance.addObserver(this);
    _loaded = true;
    await _player.setReleaseMode(ReleaseMode.loop);
    await _player.setVolume(.35);
    await _sync();
  }

  Future<void> setEnabled(bool enabled) async {
    _enabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(preferenceKey, enabled);
    await _sync();
  }

  void show(Object route) {
    _visibleRoutes.add(route);
    NavigationAdService.instance.menuVisible(route, true);
    _sync();
  }

  void hide(Object route) {
    _visibleRoutes.remove(route);
    NavigationAdService.instance.menuVisible(route, false);
    _sync();
  }

  Future<void> _sync() {
    _pending = _pending.catchError((Object _) {}).then((_) async {
      if (!_loaded) return;
      try {
        if (_enabled && _appForeground && _visibleRoutes.isNotEmpty) {
          if (_player.state != PlayerState.playing) {
            if (_sourceStarted) {
              await _player.resume();
            } else {
              await _player.play(AssetSource('audio/childhood_wonder.mp3'));
              _sourceStarted = true;
            }
          }
        } else if (_player.state == PlayerState.playing) {
          await _player.pause();
        }
      } catch (_) {
        // Music failure must not interrupt navigation or gameplay.
      }
    });
    return _pending;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appForeground = state == AppLifecycleState.resumed;
    _sync();
  }
}

/// A menu route plays music only while it is the visible page route.
mixin MenuMusicRoute<T extends StatefulWidget> on State<T>
    implements RouteAware {
  PageRoute<dynamic>? _musicRoute;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute<dynamic> && route != _musicRoute) {
      if (_musicRoute != null) menuMusicRouteObserver.unsubscribe(this);
      _musicRoute = route;
      menuMusicRouteObserver.subscribe(this, route);
      MenuMusicService.instance.show(this);
    }
  }

  @override
  void didPush() => MenuMusicService.instance.show(this);
  @override
  void didPopNext() => MenuMusicService.instance.show(this);
  @override
  void didPushNext() => MenuMusicService.instance.hide(this);
  @override
  void didPop() => MenuMusicService.instance.hide(this);

  @override
  void dispose() {
    menuMusicRouteObserver.unsubscribe(this);
    MenuMusicService.instance.hide(this);
    super.dispose();
  }
}
