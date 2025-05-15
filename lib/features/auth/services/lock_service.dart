import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages app locking logic and persists lock state.
class LockService {
  static const _lockImmediatelyKey = 'lockImmediately';
  static const _appLockedKey = 'appLocked';
  final SharedPreferences _prefs;
  final AppLockState _lockState;
  bool? _cachedLockImmediately;
  bool? _cachedAppLocked;
  DateTime? _lastLockEvent; // Tracks last lock for cooldown

  LockService(this._prefs, this._lockState);

  /// Returns whether the app should lock immediately when backgrounded.
  Future<bool> shouldLockImmediately() async {
    if (_cachedLockImmediately != null) {
      return _cachedLockImmediately!;
    }
    final value = _prefs.getBool(_lockImmediatelyKey) ?? false;
    _cachedLockImmediately = value;
    return value;
  }

  /// Sets whether the app should lock immediately and applies lock if enabled.
  Future<void> setLockImmediately(bool value) async {
    if (_cachedLockImmediately == value) return;
    await _prefs.setBool(_lockImmediatelyKey, value);
    _cachedLockImmediately = value;
    if (value && !(await isAppLocked())) {
      await setAppLocked(true);
      _lockState.scheduleLock(const Duration(milliseconds: 500));
    }
  }

  /// Sets the app's locked state in SharedPreferences.
  Future<void> setAppLocked(bool value) async {
    if (_cachedAppLocked == value) return;
    await _prefs.setBool(_appLockedKey, value);
    _cachedAppLocked = value;
  }

  /// Returns whether the app is currently locked.
  Future<bool> isAppLocked() async {
    if (_cachedAppLocked != null) {
      return _cachedAppLocked!;
    }
    final value = _prefs.getBool(_appLockedKey) ?? false;
    _cachedAppLocked = value;
    return value;
  }

  /// Handles app lifecycle state changes to manage locking.
  Future<void> handleLifecycleState(AppLifecycleState state) async {
    switch (state) {
    case AppLifecycleState.paused:
    case AppLifecycleState.inactive:
    case AppLifecycleState.hidden:
    // Cooldown prevents redundant lock events within 300ms
    final now = DateTime.now();
    if (_lastLockEvent != null &&
    now.difference(_lastLockEvent!).inMilliseconds < 300) {
    return;
    }
    shouldLockImmediately().then((lockImmediately) async {
    if (lockImmediately && !(await isAppLocked())) {
    _lockState.scheduleLock(const Duration(milliseconds: 500));
    await setAppLocked(true);
    _lastLockEvent = now;
    }
    });
    break;
    case AppLifecycleState.resumed:
    _lastLockEvent = null;
    _lockState.cancelScheduledLock();
    if (await isAppLocked()) {
    setAppLocked(false);
    }
    _lockState.debounceRefresh();
    break;
    case AppLifecycleState.detached:
    break;
    }
  }
}

/// Manages lock state and notifies listeners for UI updates.
class AppLockState extends ChangeNotifier {
  AppLockState() {
    _init();
  }
  LockService? _lockService;
  bool _shouldLock = false;
  bool _needsRefresh = false;
  Timer? _lockTimer;
  Timer? _debounceTimer;

  bool get shouldLock => _shouldLock;
  bool get needsRefresh => _needsRefresh;

  /// Initializes lock state from LockService.
  Future<void> _init() async {
    if (_lockService != null) {
      final isLocked = await _lockService!.isAppLocked();
      _shouldLock = isLocked;
      _needsRefresh = isLocked;
      if (_needsRefresh) {
        notifyListeners();
      }
    }
  }

  /// Sets the LockService instance and initializes state.
  void setLockService(LockService lockService) {
    _lockService = lockService;
    _init();
  }

  /// Updates shouldLock and notifies listeners.
  void setShouldLock(bool value) {
    if (_shouldLock == value) return;
    _lockTimer?.cancel();
    _shouldLock = value;
    notifyListeners();
  }

  /// Schedules a lock after a delay.
  void scheduleLock(Duration delay) {
    _lockTimer?.cancel();
    _lockTimer = Timer(delay, () {
      setShouldLock(true);
    });
  }

  /// Cancels any scheduled lock.
  void cancelScheduledLock() {
    _lockTimer?.cancel();
  }

  /// Debounces refresh to prevent rapid UI updates.
  void debounceRefresh() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (_shouldLock && !_needsRefresh) {
        _needsRefresh = true;
        _shouldLock = false;
        notifyListeners();
      }
    });
  }

  /// Resets needsRefresh and notifies listeners.
  void resetRefresh() {
    if (!_needsRefresh) return;
    _needsRefresh = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _lockTimer?.cancel();
    _debounceTimer?.cancel();
    super.dispose();
  }
}