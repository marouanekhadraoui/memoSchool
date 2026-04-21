import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/wilaya.dart';
import '../game_state.dart';

enum GamePhase { revealing, playing, levelComplete, gameOver }

class LevelRegion {
  final String name;
  final Rect rect;
  final double zoom;
  const LevelRegion({required this.name, required this.rect, required this.zoom});
}

class GameController extends ChangeNotifier {
  final GameState globalGameState;
  final String gameName = 'algeria';
  
  int currentLevel;
  Rect viewRect;
  double zoom;
  List<Wilaya> allWilayas;
  List<Wilaya> regionWilayas = [];
  List<String> targetIds = [];
  Set<String> discoveredIds = {};
  int mistakes = 0;
  int remainingTargets = 0;
  GamePhase phase = GamePhase.revealing;
  String? currentTargetId;
  Timer? revealTimer;
  Timer? flashTimer;
  
  final int maxMistakes = 3;
  
  int revealDuration = 10;   
  
  int score = 0;
  int hintEnergy = 5;
  Duration elapsedTime = Duration.zero;
  Timer? _timer;
  bool isGameFinished = false;
  int revealSecondsLeft = 5;
  
  static final List<LevelRegion> levelRegions = [
    LevelRegion(name: 'South', rect: Rect.fromLTWH(20, 215, 508, 755), zoom: 2.0),
    LevelRegion(name: 'Center', rect: Rect.fromLTWH(120, 150, 400, 400), zoom: 2.3),
    LevelRegion(name: 'NorthWest', rect: Rect.fromLTWH(40, 170, 400, 400), zoom: 2.5),
    LevelRegion(name: 'NorthEast', rect: Rect.fromLTWH(80, 170, 400, 400), zoom: 1.5),
    LevelRegion(name: 'Full', rect: Rect.fromLTWH(-30,50, 600, 800), zoom: 2.0),
  ];

  static final Map<int, List<String>> levelWilayaIds = {
    1: ['01', '08', '11', '33', '58', '49', '52', '53', '56', '50', '54','30','37'],
    2: ['02''03', '04', '05', '06', '09', '12', '14', '16' ,'17', '18', '19', '21', '23', '24', '26', '30','32' ,'38','39', '40', '42', '43',  '47', '51', '55','57'],
    3: [
      '13', '45', '32', '22', '46', '31', '27', '29', '48', '14', '02',
      '44', '09','08', '42', '35', '15', '10', '34', '28', '17', '03', 
      '47', '50', '08', '56', '22', '38', '26', '22','20' 
    ],
    4: [
      '13', '20', '22', '02', '09', '06', '18', '23', '29', '14', '05','04','45','13','03','17','12','57','39','55','47','03','58','49','08','52' 
    ],
    5: [
      '21', '04', '19', '31', '42', '28', '14', '38', '03', '45', '32',
      '47', '30', '56', '33', '53', '01', '58', '11', '50', '16', '22',
      '46', '27', '29', '48', '02', '44', '09', '35', '15', '10', '34',
      '25', '23', '36', '41', '24', '18', '06', '05', '07', '12', '40',
      '43', '20', '37', '39', '49', '51', '52', '54', '55', '57', '17','22','22','22'
    ],
  };

  GameController({
    required this.globalGameState,
    required this.currentLevel,
    required this.allWilayas,
  }) : viewRect = levelRegions[currentLevel - 1].rect,
       zoom = levelRegions[currentLevel - 1].zoom {
    _initLevel();
  }

  void _initLevel() {
    List<Wilaya> newRegionWilayas = [];
    if (levelWilayaIds.containsKey(currentLevel)) {
      final ids = levelWilayaIds[currentLevel]!;
      for (var id in ids) {
        final matches = allWilayas.where((w) => w.id == id).toList();
        if (matches.isNotEmpty) newRegionWilayas.add(matches.first);
      }
    } else {
      newRegionWilayas = allWilayas.where((w) {
        final bounds = w.path.getBounds();
        return viewRect.overlaps(bounds);
      }).toList();
    }
    if (newRegionWilayas.isEmpty) newRegionWilayas = List.from(allWilayas);
    regionWilayas = newRegionWilayas;
    
    final random = Random();
    final List<Wilaya> weightedList = [];
    for (var w in regionWilayas) {
      weightedList.add(w);
    }
    final shuffled = List<Wilaya>.from(weightedList)..shuffle(random);
    targetIds = shuffled.take(4).map((w) => w.id).toList();
    
    remainingTargets = targetIds.length;
    discoveredIds.clear();
    mistakes = 0;
    score = 0;
    hintEnergy = 5;
    elapsedTime = Duration.zero;
    isGameFinished = false;
    revealSecondsLeft = revealDuration;
    
    for (var w in allWilayas) {
      w.isDiscovered = false;
      w.isFlashing = false;
    }
    
    phase = GamePhase.revealing;
    currentTargetId = null;
    
    _timer?.cancel();
    _startTimer();
    
    revealTimer?.cancel();
    revealTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (phase == GamePhase.revealing) {
        revealSecondsLeft--;
        notifyListeners();
        if (revealSecondsLeft <= 0) {
          timer.cancel();
          phase = GamePhase.playing;
          _selectNextTarget();
          notifyListeners();
        }
      } else {
        timer.cancel();
      }
    });
    
    notifyListeners();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!isGameFinished && phase == GamePhase.playing) {
        elapsedTime += const Duration(seconds: 1);
        notifyListeners();
      }
    });
  }

  void _selectNextTarget() {
    final remaining = targetIds.where((id) => !discoveredIds.contains(id)).toList();
    if (remaining.isNotEmpty) {
      final random = Random();
      currentTargetId = remaining[random.nextInt(remaining.length)];
    } else {
      currentTargetId = null;
    }
    notifyListeners();
  }

  void onWilayaTap(Wilaya tappedWilaya) {
    if (phase != GamePhase.playing || isGameFinished) return;
    
    if (tappedWilaya.id == currentTargetId) {
      _flashWilaya(tappedWilaya, Colors.green);
      discoveredIds.add(tappedWilaya.id);
      tappedWilaya.isDiscovered = true;
      remainingTargets--;
      
      int points = 10;
      if (elapsedTime.inSeconds < 30) points += 5;
      score += points;
      globalGameState.addPoints(points);
      globalGameState.increaseStreak();
      
      if (remainingTargets == 0) {
        _winGame();
      } else {
        _selectNextTarget();
      }
    } else {
      _flashWilaya(tappedWilaya, Colors.red);
      mistakes++;
      globalGameState.resetStreak();
      
      if (mistakes >= maxMistakes) {
        _loseGame();
      } else {
        notifyListeners();
      }
    }
  }

  void _flashWilaya(Wilaya w, Color color) {
    w.isFlashing = true;
    w.flashColor = color;
    flashTimer?.cancel();
    flashTimer = Timer(const Duration(milliseconds: 150), () {
      w.isFlashing = false;
      notifyListeners();
    });
    notifyListeners();
  }

  bool useHint() {
    if (phase != GamePhase.playing || isGameFinished) return false;
    if (hintEnergy <= 0) return false;
    if (currentTargetId == null) return false;
    
    final targetWilaya = allWilayas.firstWhere((w) => w.id == currentTargetId);
    if (targetWilaya != null) {
      _flashWilaya(targetWilaya, Colors.lightBlue);
      hintEnergy--;
      score = (score - 5).clamp(0, double.infinity).toInt();
      notifyListeners();
      return true;
    }
    return false;
  }

  void _winGame() {
    if (isGameFinished) return;
    isGameFinished = true;
    phase = GamePhase.levelComplete;
    _timer?.cancel();
    revealTimer?.cancel();
    final nextLevel = currentLevel + 1;
    if (nextLevel <= 5) {
      globalGameState.unlockLevel(gameName, nextLevel);
    }
    notifyListeners();
  }

  void _loseGame() {
    if (isGameFinished) return;
    isGameFinished = true;
    phase = GamePhase.gameOver;
    _timer?.cancel();
    revealTimer?.cancel();
    notifyListeners();
  }

  void resetLevel() {
    _timer?.cancel();
    _initLevel();
  }

  void pauseTimer() {
    _timer?.cancel();
    _timer = null;
    revealTimer?.cancel();
  }

  void resumeTimer() {
    if (!isGameFinished && phase == GamePhase.playing) {
      _startTimer();
    }
  }

  @override
  void dispose() {
    revealTimer?.cancel();
    flashTimer?.cancel();
    _timer?.cancel();
    super.dispose();
  }
}