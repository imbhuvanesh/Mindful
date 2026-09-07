import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show ChangeNotifier, kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:usage_stats/usage_stats.dart'
    hide AppInfo, UsageInfo, EventUsageInfo, ConfigurationInfo;
import 'package:zo_app_blocker/zo_app_blocker.dart';

import '../models/app_lock.dart';
import '../screens/block/mindful_block_screen.dart';

/// Locks apps for a fixed time window and unlocks them automatically.
///
/// The native plugin keeps blocked apps locked even if Mindful is swiped
/// away (its foreground service persists the block list on-device). Auto
/// unlock is handled here with a timer, and any lock whose hour has passed
/// is cleared the next time the app starts.
class LockService extends ChangeNotifier {
  LockService._();
  static final LockService instance = LockService._();

  static const int lockMinutes = 60;
  static const _prefsKey = 'mindful_locks';

  final ZoAppBlocker _zo = ZoAppBlocker.instance;
  SharedPreferences? _prefs;

  final Map<String, AppLock> _locks = {};
  final Map<String, Timer> _timers = {};
  final Map<String, AppInfo> _installed = {};

  bool _ready = false;
  bool _supported = false;

  bool get ready => _ready;
  bool get isSupported => _supported;

  /// All currently locked apps, soonest-to-unlock first.
  List<AppLock> get locks {
    final list = _locks.values.toList()
      ..sort((a, b) => a.lockedUntil.compareTo(b.lockedUntil));
    return list;
  }

  bool isLocked(String packageName) => _locks.containsKey(packageName);

  Future<void> init() async {
    try {
      await _init();
    } catch (_) {}
    _ready = true;
    notifyListeners();
  }

  Future<void> _init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
    } catch (_) {}

    _supported = _platformSupported();

    if (_supported) {
      try {
        await _zo.initialize(blockScreenCallback: onBlockScreenRequested);
        await _zo.setNotificationConfig(
          notificationBannerTitle: 'Mindful has locked a few apps',
          notificationBannerDescription:
              'They unlock automatically in about an hour.',
        );
      } catch (_) {}
    }

    try {
      await _loadAndReconcile();
      await _syncToPlugin();
    } catch (_) {}
  }

  // ---------------------------------------------------------------------
  // Locking
  // ---------------------------------------------------------------------

  /// Blocks the given apps until [Duration(hours: hour)] from now.
  ///
  /// Records how much each app was used today before locking.
  Future<void> lockApps(List<AppInfo> apps, {int minutes = lockMinutes}) async {
    if (apps.isEmpty) return;
    final now = DateTime.now();
    final until = now.add(Duration(minutes: minutes));

    // Capture each app's used minutes today before we block it.
    final used = await _usageMinutesToday(
      [for (final a in apps) a.packageName],
      now: now,
    );

    for (final app in apps) {
      final existing = _locks[app.packageName];
      _timers.remove(app.packageName)?.cancel();
      _locks[app.packageName] = AppLock(
        packageName: app.packageName,
        appName: app.appName,
        iconBytes: app.icon ?? existing?.iconBytes,
        lockedUntil: until,
        lockedAt: now,
        usedMinutes: used[app.packageName] ?? 0,
      );
      _scheduleUnlock(app.packageName, until);
    }

    await _persist();
    await _syncToPlugin();
    notifyListeners();
  }

  /// Unlocks the given apps now (no-op for anything not locked).
  Future<void> unlockMany(List<String> packageNames) async {
    var changed = false;
    for (final pkg in packageNames) {
      _timers.remove(pkg)?.cancel();
      if (_locks.remove(pkg) != null) changed = true;
    }
    if (!changed) return;
    await _persist();
    await _syncToPlugin();
    notifyListeners();
  }

  /// Unlocks [packageName] now.
  Future<void> unlock(String packageName) async {
    await unlockMany([packageName]);
  }

  /// Unlocks every locked app now.
  Future<void> unlockAll() async {
    if (_locks.isEmpty) return;
    for (final t in _timers.values) { t.cancel(); }
    _timers.clear();
    _locks.clear();
    await _persist();
    if (_supported) {
      try {
        await _zo.unblockAll();
      } catch (_) {}
    }
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // Installed apps
  // ---------------------------------------------------------------------

  /// Apps available to lock (installed, not currently locked).
  Future<List<AppInfo>> getInstalledApps() async {
    if (!_supported) return [];
    try {
      final raw = await _zo.getApps();
      final list = <AppInfo>[];
      for (final map in raw) {
        final pkg = map['packageName'] as String?;
        final name = map['appName'] as String?;
        if (pkg == null || name == null) continue;
        if (_locks.containsKey(pkg)) continue;
        list.add(_installed.putIfAbsent(
          pkg,
          () => AppInfo(
            appName: name,
            packageName: pkg,
            icon: map['icon'] as Uint8List?,
          ),
        ));
      }
      return list;
    } catch (_) {
      return [];
    }
  }

  Future<Uint8List?> getAppIcon(String packageName) async {
    if (!_supported) return null;
    try {
      return await _zo.getAppIcon(packageName);
    } catch (_) {
      return null;
    }
  }

  // ---------------------------------------------------------------------
  // Permissions
  // ---------------------------------------------------------------------

  Future<bool> get hasUsageAccess async => _check('usage');
  Future<bool> get hasOverlayAccess async => _check('overlay');
  Future<bool> get hasNotificationAccess async => _check('notifications');

  Future<bool> get allAllowed async =>
      await hasUsageAccess && await hasOverlayAccess && await hasNotificationAccess;

  Future<void> requestUsageAccess() => _request('usage');
  Future<void> requestOverlayAccess() => _request('overlay');
  Future<void> requestNotificationAccess() => _request('notifications');

  Future<bool> _check(String kind) async {
    if (!_supported) return true;
    try {
      final status = switch (kind) {
        'usage' => await _zo.checkUsageStatsPermission(),
        'overlay' => await _zo.checkOverlayPermission(),
        _ => await _zo.checkNotificationPermission(),
      };
      return status == 'granted';
    } catch (_) {
      return false;
    }
  }

  Future<void> _request(String kind) async {
    if (!_supported) return;
    try {
      if (kind == 'usage') {
        await _zo.requestUsageStatsPermission();
      } else if (kind == 'overlay') {
        await _zo.requestOverlayPermission();
      } else {
        await _zo.requestNotificationPermission();
      }
    } catch (_) {}
  }

  // ---------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------

  void _scheduleUnlock(String packageName, DateTime until) {
    final delay = until.difference(DateTime.now());
    if (delay <= Duration.zero) return;
    _timers[packageName] = Timer(delay, () => unlock(packageName));
  }

  /// Pushes the current lock state into the native plugin and clears any
  /// stale daily-time-limit rows that would make the block list be ignored.
  ///
  /// The plugin's foreground service takes a per-app "time limit" branch
  /// whenever a time-limit row exists for the foreground app. If such a row
  /// is left over, the app is tracked against a countdown and the persistent
  /// block list is never consulted — so an app could stay blocked (or slip
  /// past the block list) unexpectedly. We therefore remove time-limit rows
  /// for every locked package AND for any stale package we unblock, then
  /// re-assert the block list so every locked package takes the hard-block
  /// path.
  Future<void> _syncToPlugin() async {
    if (!_supported) return;

    for (final pkg in _locks.keys) {
      try {
        await _zo.removeAppTimeLimit(pkg);
      } catch (_) {}
    }

    final locked = _locks.keys.toSet();

    // Unblock anything the plugin still has that we no longer want locked,
    // and wipe their leftover time-limit rows too.
    try {
      final current = await _zo.getBlockedApps();
      final stale = <String>[];
      for (final map in current) {
        final pkg = map['packageName'] as String?;
        if (pkg != null && !locked.contains(pkg)) stale.add(pkg);
      }
      if (stale.isNotEmpty) {
        for (final pkg in stale) {
          try {
            await _zo.removeAppTimeLimit(pkg);
          } catch (_) {}
        }
        await _zo.unblockApps(stale);
      }
    } catch (_) {}

    try {
      if (locked.isEmpty) {
        await _zo.unblockAll();
      } else {
        await _zo.blockApps(locked.toList());
      }
    } catch (_) {}
  }

  Future<void> _persist() async {
    final data = {
      for (final e in _locks.entries) e.key: e.value.toJson(),
    };
    await _prefs?.setString(_prefsKey, jsonEncode(data));
  }

  Future<void> _loadAndReconcile() async {
    final raw = _prefs?.getString(_prefsKey);
    if (raw == null || raw.isEmpty) return;

    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final expired = <String>[];

    decoded.forEach((pkg, value) {
      final lock = AppLock.fromJson(pkg, (value as Map).cast<String, dynamic>());
      if (!lock.isExpired) {
        _locks[pkg] = lock;
        _scheduleUnlock(pkg, lock.lockedUntil);
      } else {
        expired.add(pkg);
      }
    });

    // Anything whose hour already passed gets unblocked now.
    if (expired.isNotEmpty) {
      await unlockMany(expired);
    }
    if (_locks.isNotEmpty) await _refreshIcons();
  }

  Future<void> _refreshIcons() async {
    for (final pkg in List<String>.from(_locks.keys)) {
      final lock = _locks[pkg];
      if (lock == null || lock.iconBytes != null) continue;
      final bytes = await getAppIcon(pkg);
      if (bytes != null) {
        _locks[pkg] = lock.copyWith(iconBytes: () => bytes);
      }
    }
    notifyListeners();
  }

  /// Reads real foreground minutes used today for [packages] from Android.
  Future<Map<String, double>> _usageMinutesToday(
    List<String> packages, {
    DateTime? now,
  }) async {
    final result = <String, double>{};
    if (packages.isEmpty || !_supported) return result;
    final nowLocal = now ?? DateTime.now();
    final start =
        DateTime(nowLocal.year, nowLocal.month, nowLocal.day);
    try {
      final stats = await UsageStats.queryAndAggregateUsageStats(
        start,
        nowLocal,
      );
      for (final pkg in packages) {
        final info = stats[pkg];
        if (info == null) continue;
        final ms = info.totalTimeInForegroundMs;
        if (ms != null) result[pkg] = ms / 60000.0;
      }
    } catch (_) {}
    return result;
  }

  bool _platformSupported() {
    if (kIsWeb) return false;
    try {
      return Platform.isAndroid;
    } catch (_) {
      return false;
    }
  }
}