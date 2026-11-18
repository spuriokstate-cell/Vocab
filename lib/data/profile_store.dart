import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/profile.dart';

/// Saves child profiles and all their progress on this device only.
/// Works the same on Android, iOS and Windows.
class ProfileStore {
  ProfileStore(this._prefs);

  static const _idsKey = 'vi_profile_ids';
  static const _activeKey = 'vi_active_profile';
  static String _profileKey(String id) => 'vi_profile_$id';

  final SharedPreferences _prefs;
  final Map<String, Timer> _pending = {};

  static Future<ProfileStore> open() async =>
      ProfileStore(await SharedPreferences.getInstance());

  List<ChildProfile> loadAll() {
    final ids = _prefs.getStringList(_idsKey) ?? const [];
    final out = <ChildProfile>[];
    for (final id in ids) {
      final raw = _prefs.getString(_profileKey(id));
      if (raw == null) continue;
      try {
        out.add(ChildProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>));
      } catch (_) {
        // A damaged record is skipped rather than crashing the app.
      }
    }
    return out;
  }

  String? get activeId => _prefs.getString(_activeKey);
  Future<void> setActive(String id) => _prefs.setString(_activeKey, id);

  /// Saves right away.
  Future<void> save(ChildProfile p) async {
    _pending.remove(p.id)?.cancel();
    final ids = _prefs.getStringList(_idsKey) ?? <String>[];
    if (!ids.contains(p.id)) {
      await _prefs.setStringList(_idsKey, [...ids, p.id]);
    }
    await _prefs.setString(_profileKey(p.id), jsonEncode(p.toJson()));
  }

  /// Saves shortly after the last change, so answering many questions
  /// quickly doesn't write the file every time.
  void saveSoon(ChildProfile p) {
    _pending.remove(p.id)?.cancel();
    _pending[p.id] = Timer(const Duration(milliseconds: 600), () => save(p));
  }

  /// Writes any delayed saves now.
  Future<void> flush(Iterable<ChildProfile> profiles) async {
    for (final p in profiles) {
      if (_pending.containsKey(p.id)) await save(p);
    }
  }

  Future<void> delete(String id) async {
    _pending.remove(id)?.cancel();
    final ids = _prefs.getStringList(_idsKey) ?? <String>[];
    await _prefs.setStringList(_idsKey, ids.where((x) => x != id).toList());
    await _prefs.remove(_profileKey(id));
  }
}
