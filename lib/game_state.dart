import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GameState extends ChangeNotifier {
  // ---- Basic stats ----
  int _points = 0;
  int _streak = 0;
  int _level = 1;
  int _bestStreak = 0;                       // ---- longest streak ever achieved

  // ---- Skills (will increase when player plays well) ----
  int _memory = 0;
  int _focus = 0;
  int _math = 0;
  int _logic = 0;

  // ---- Daily streak tracking ----
  DateTime? _lastActivityDate;               // ---- last date when user performed an action

  // ---- Unlocked levels per game ----
  Map<String, int> _unlockedLevels = {};

  // ---- Getters ----
  int get points => _points;
  int get streak => _streak;
  int get level => _level;
  int get bestStreak => _bestStreak;
  int get memory => _memory;
  int get focus => _focus;
  int get math => _math;
  int get logic => _logic;
  Map<String, int> get unlockedLevels => Map.unmodifiable(_unlockedLevels);

  // ---- XP progress helpers ----
  int get pointsToNextLevel => 100 - (_points % 100);
  double get xpProgress => (_points % 100) / 100;

  // ---- Constructor & loading ----
  GameState() {
    _loadData();
  }

  // ---- Increase specific skill (call this from game pages) ----
  void increaseSkill(String skill, int amount) {
    switch (skill.toLowerCase()) {
      case 'memory':
        _memory += amount;
        break;
      case 'focus':
        _focus += amount;
        break;
      case 'math':
        _math += amount;
        break;
      case 'logic':
        _logic += amount;
        break;
      default:
        debugPrint(' Unknown skill: $skill');
        return;
    }
    debugPrint(' Skill $skill increased by $amount (now: ${_getSkillValue(skill)})');
    _saveData();
    notifyListeners();
  }

  int _getSkillValue(String skill) {
    switch (skill.toLowerCase()) {
      case 'memory': return _memory;
      case 'focus': return _focus;
      case 'math': return _math;
      case 'logic': return _logic;
      default: return 0;
    }
  }

  // ---- Unlock levels ----
  int getUnlockedLevel(String gameName) {
    return _unlockedLevels[gameName.toLowerCase()] ?? 1;
  }

  void unlockLevel(String gameName, int newLevel) {
    final key = gameName.toLowerCase();
    final current = _unlockedLevels[key] ?? 1;
    debugPrint('🔑 unlockLevel: key=$key, newLevel=$newLevel, current=$current');
    if (newLevel > current) {
      _unlockedLevels[key] = newLevel;
      debugPrint('✨ _unlockedLevels["$key"] updated from $current to $newLevel');
      _saveData();
      notifyListeners();
    } else {
      debugPrint('⚠️ newLevel ($newLevel) is not greater than current ($current)');
    }
  }

  // ---- Points & Level ----
  void addPoints(int value) {
    _points += value;
    _checkLevel();
    _saveData();
    notifyListeners();
  }

  void _checkLevel() {
    int newLevel = (_points ~/ 100) + 1;
    if (newLevel > _level) {
      _level = newLevel;
      debugPrint('🎉 Level up! Now level $_level');
    }
  }

  // ---- Daily Streak Logic (based on real calendar) ----
  void updateStreak() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (_lastActivityDate == null) {
      // First activity ever
      _streak = 1;
      _lastActivityDate = today;
      debugPrint('🔥 First activity, streak = 1');
    } else {
      final last = DateTime(_lastActivityDate!.year, _lastActivityDate!.month, _lastActivityDate!.day);
      final difference = today.difference(last).inDays;

      if (difference == 0) {
        // Already active today → do nothing
        debugPrint('✅ Already active today, streak remains $_streak');
        return;
      } else if (difference == 1) {
        // Consecutive day → increase streak
        _streak++;
        debugPrint('🔥 Streak increased! New streak = $_streak');
      } else {
        // Gap of more than one day → reset streak to 1
        _streak = 1;
        debugPrint('⚠️ Streak broken! Reset to 1 (last activity: $_lastActivityDate)');
      }
      _lastActivityDate = today;
    }

    // Update best streak
    if (_streak > _bestStreak) {
      _bestStreak = _streak;
      debugPrint('🏆 New longest streak: $_bestStreak');
    }

    _saveData();
    notifyListeners();
  }

  // ---- Legacy methods (kept for compatibility) ----
  void increaseStreak() {
    updateStreak();   // now uses calendar logic
  }

  void resetStreak() {
    _streak = 0;
    _saveData();
    notifyListeners();
  }

  void updateFromGame(int newPoints, int newStreak) {
    _points = newPoints;
    _streak = newStreak;
    if (_streak > _bestStreak) _bestStreak = _streak;
    _checkLevel();
    _saveData();
    notifyListeners();
  }

  // ---- Persistence (SharedPreferences) ----
  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('points', _points);
    await prefs.setInt('streak', _streak);
    await prefs.setInt('level', _level);
    await prefs.setInt('bestStreak', _bestStreak);
    await prefs.setInt('memory', _memory);
    await prefs.setInt('focus', _focus);
    await prefs.setInt('math', _math);
    await prefs.setInt('logic', _logic);
    if (_lastActivityDate != null) {
      await prefs.setString('lastActivityDate', _lastActivityDate!.toIso8601String());
    } else {
      await prefs.remove('lastActivityDate');
    }

    final levelsMap = <String, int>{};
    for (var entry in _unlockedLevels.entries) {
      levelsMap[entry.key] = entry.value;
    }
    await prefs.setString('unlockedLevels', _encodeMap(levelsMap));
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    _points = prefs.getInt('points') ?? 0;
    _streak = prefs.getInt('streak') ?? 0;
    _level = prefs.getInt('level') ?? 1;
    _bestStreak = prefs.getInt('bestStreak') ?? 0;
    _memory = prefs.getInt('memory') ?? 0;
    _focus = prefs.getInt('focus') ?? 0;
    _math = prefs.getInt('math') ?? 0;
    _logic = prefs.getInt('logic') ?? 0;

    final dateStr = prefs.getString('lastActivityDate');
    if (dateStr != null && dateStr.isNotEmpty) {
      _lastActivityDate = DateTime.tryParse(dateStr);
    } else {
      _lastActivityDate = null;
    }

    final encoded = prefs.getString('unlockedLevels');
    if (encoded != null && encoded.isNotEmpty) {
      _unlockedLevels = _decodeMap(encoded);
    } else {
      _unlockedLevels = {
        'calcule': 1,
        'sudoku': 1,
        'poem': 1,
        'algeria': 1,
      };
    }
    notifyListeners();
  }

  String _encodeMap(Map<String, int> map) {
    return map.entries.map((e) => '${e.key}:${e.value}').join(',');
  }

  Map<String, int> _decodeMap(String encoded) {
    final map = <String, int>{};
    if (encoded.isEmpty) return map;
    final parts = encoded.split(',');
    for (var part in parts) {
      final kv = part.split(':');
      if (kv.length == 2) {
        final key = kv[0].trim();
        final value = int.tryParse(kv[1].trim());
        if (key.isNotEmpty && value != null) {
          map[key] = value;
        }
      }
    }
    return map;
  }
}