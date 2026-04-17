

import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../game_state.dart';

// ============================================================================
// Data Models ----
// ============================================================================

class Cell {
  int? value;
  final bool isFixed;
  Set<int> notes;
  bool isError;

  Cell({
    this.value,
    this.isFixed = false,
    Set<int>? notes,
    this.isError = false,
  }) : notes = notes ?? {};

  Cell copyWith({
    int? value,
    bool? isFixed,
    Set<int>? notes,
    bool? isError,
  }) {
    return Cell(
      value: value ?? this.value,
      isFixed: isFixed ?? this.isFixed,
      notes: notes ?? Set.from(this.notes),
      isError: isError ?? this.isError,
    );
  }
}

// ============================================================================
// Sudoku Engine (Generator + Solver) ----
// ============================================================================

class SudokuEngine {
  final int size;
  final int boxRows;
  final int boxCols;

  SudokuEngine({
    required this.size,
    required this.boxRows,
    required this.boxCols,
  }) {
    assert(size == boxRows * boxCols);
  }

  List<List<int?>> generateFullGrid() {
    final grid = List<List<int?>>.generate(
      size,
      (_) => List<int?>.filled(size, null),
    );
    _fillGrid(grid);
    return grid;
  }

  bool _fillGrid(List<List<int?>> grid) {
    for (int row = 0; row < size; row++) {
      for (int col = 0; col < size; col++) {
        if (grid[row][col] == null) {
          final numbers = _shuffledNumbers();
          for (int num in numbers) {
            if (_isSafe(grid, row, col, num)) {
              grid[row][col] = num;
              if (_fillGrid(grid)) return true;
              grid[row][col] = null;
            }
          }
          return false;
        }
      }
    }
    return true;
  }

  List<int> _shuffledNumbers() {
    final list = List<int>.generate(size, (i) => i + 1);
    list.shuffle(Random());
    return list;
  }

  bool _isSafe(List<List<int?>> grid, int row, int col, int num) {
    for (int c = 0; c < size; c++) {
      if (grid[row][c] == num) return false;
    }
    for (int r = 0; r < size; r++) {
      if (grid[r][col] == num) return false;
    }
    final boxRowStart = (row ~/ boxRows) * boxRows;
    final boxColStart = (col ~/ boxCols) * boxCols;
    for (int r = 0; r < boxRows; r++) {
      for (int c = 0; c < boxCols; c++) {
        if (grid[boxRowStart + r][boxColStart + c] == num) return false;
      }
    }
    return true;
  }

  List<List<int?>> generatePuzzle(int cellsToRemove, {List<List<int?>>? fullGrid}) {
    final full = fullGrid ?? generateFullGrid();
    final puzzle = full.map((row) => List<int?>.from(row)).toList();
    final random = Random();
    final positions = <List<int>>[];
    for (int i = 0; i < size; i++) {
      for (int j = 0; j < size; j++) {
        positions.add([i, j]);
      }
    }
    positions.shuffle(random);
    int removed = 0;
    for (var pos in positions) {
      if (removed >= cellsToRemove) break;
      final row = pos[0];
      final col = pos[1];
      final backup = puzzle[row][col];
      puzzle[row][col] = null;
      final solutions = <List<List<int?>>>[];
      _solveWithLimit(puzzle, solutions, 2);
      if (solutions.length != 1) {
        puzzle[row][col] = backup;
      } else {
        removed++;
      }
    }
    return puzzle;
  }

  void _solveWithLimit(
    List<List<int?>> grid,
    List<List<List<int?>>> solutions,
    int limit,
  ) {
    if (solutions.length >= limit) return;
    final copy = grid.map((row) => List<int?>.from(row)).toList();
    if (_solve(copy)) {
      solutions.add(copy);
    }
  }

  bool _solve(List<List<int?>> grid) {
    for (int row = 0; row < size; row++) {
      for (int col = 0; col < size; col++) {
        if (grid[row][col] == null) {
          for (int num = 1; num <= size; num++) {
            if (_isSafe(grid, row, col, num)) {
              grid[row][col] = num;
              if (_solve(grid)) return true;
              grid[row][col] = null;
            }
          }
          return false;
        }
      }
    }
    return true;
  }

  List<List<int?>>? solve(List<List<int?>> grid) {
    final work = grid.map((row) => List<int?>.from(row)).toList();
    if (_solve(work)) return work;
    return null;
  }
}

// ============================================================================
// Level Configuration ----
// ============================================================================

class LevelConfig {
  final int size;
  final int boxRows;
  final int boxCols;
  final int cellsToRemove;

  LevelConfig({required this.size, required this.boxRows, required this.boxCols, required this.cellsToRemove});

  factory LevelConfig.forLevel(int level) {
    switch (level) {
      case 1:
        return LevelConfig(size: 6, boxRows: 2, boxCols: 3, cellsToRemove: 12);
      case 2:
        return LevelConfig(size: 6, boxRows: 2, boxCols: 3, cellsToRemove: 18);
      case 3:
        return LevelConfig(size: 9, boxRows: 3, boxCols: 3, cellsToRemove: 40);
      case 4:
        return LevelConfig(size: 9, boxRows: 3, boxCols: 3, cellsToRemove: 50);
      case 5:
        return LevelConfig(size: 9, boxRows: 3, boxCols: 3, cellsToRemove: 62);
      default:
        return LevelConfig(size: 9, boxRows: 3, boxCols: 3, cellsToRemove: 40);
    }
  }
}

// ============================================================================
// Pause Page ----
// ============================================================================

class PausePage extends StatelessWidget {
  final VoidCallback onResume;
  final VoidCallback onRestart;
  final VoidCallback onExit;
  const PausePage({super.key, required this.onResume, required this.onRestart, required this.onExit});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Color(0xFFF3F0FF), Color(0xFFE3DAFF), Color(0xFFD2C6FF)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.pause_circle_filled, size: 80, color: Color(0xFF7B61FF)),
              const SizedBox(height: 20),
              const Text('Game Paused', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: onResume,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Resume'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple.shade400,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onRestart,
                icon: const Icon(Icons.refresh),
                label: const Text('Restart Level'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onExit,
                icon: const Icon(Icons.exit_to_app),
                label: const Text('Exit to Game Details'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade400,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// GlassCard و Styled Dialog ----
// ============================================================================

class GlassCard extends StatelessWidget {
  final Widget child;
  const GlassCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 500),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.15),
            Colors.white.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 0,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

Widget buildStyledDialog({
  required String title,
  required String content,
  required IconData icon,
  required Color iconColor,
  required List<Widget> actions,
}) {
  return Dialog(
    backgroundColor: Colors.transparent,
    insetPadding: const EdgeInsets.all(20),
    child: Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.purple.shade900.withOpacity(0.95),
            Colors.deepPurple.shade700.withOpacity(0.95),
            Colors.indigo.shade900.withOpacity(0.95),
          ],
        ),
        borderRadius: BorderRadius.circular(32),
      ),
      child: GlassCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: iconColor),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'PTSerif'),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Text(
              content,
              style: const TextStyle(fontSize: 16, color: Colors.white70, fontFamily: 'PTSerif'),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: actions,
            ),
          ],
        ),
      ),
    ),
  );
}

// ============================================================================
// Game Controller ----
// ============================================================================

class GameController extends ChangeNotifier {
  final int currentLevel;
  late int gridSize;
  late int boxRows;
  late int boxCols;
  late SudokuEngine engine;

  List<List<Cell>> board = [];
  List<List<int?>>? fullSolution;

  int? selectedRow;
  int? selectedCol;
  bool isNotesMode = false;
  int mistakes = 0;
  final int maxMistakes = 3;
  Duration elapsedTime = Duration.zero;
  Timer? _timer;
  bool isGameFinished = false;

  int score = 0;
  int hintEnergy = 5;
  int? highlightedNumber;

  Map<int, int> remainingCounts = {};

  final VoidCallback onWin;
  final VoidCallback onLoss;

  GameController({
    required this.currentLevel,
    required this.onWin,
    required this.onLoss,
  }) {
    _initForLevel();
  }

  void _initForLevel() {
    final levelConfig = LevelConfig.forLevel(currentLevel);
    gridSize = levelConfig.size;
    boxRows = levelConfig.boxRows;
    boxCols = levelConfig.boxCols;
    engine = SudokuEngine(size: gridSize, boxRows: boxRows, boxCols: boxCols);
    _generateNewPuzzle(levelConfig.cellsToRemove);
    _startTimer();
  }

  void _generateNewPuzzle(int cellsToRemove) {
    final fullGrid = engine.generateFullGrid();
    fullSolution = fullGrid.map((row) => List<int?>.from(row)).toList();
    final puzzleGrid = engine.generatePuzzle(cellsToRemove, fullGrid: fullGrid);
    final newBoard = List.generate(gridSize, (row) {
      return List.generate(gridSize, (col) {
        final val = puzzleGrid[row][col];
        return Cell(
          value: val,
          isFixed: val != null,
          notes: {},
          isError: false,
        );
      });
    });
    board = newBoard;
    isGameFinished = false;
    mistakes = 0;
    score = 0;
    hintEnergy = 5;
    selectedRow = null;
    selectedCol = null;
    highlightedNumber = null;
    _updateRemainingCounts();
    _timer?.cancel();
    _startTimer();
    notifyListeners();
  }

  void _updateRemainingCounts() {
    final totalCounts = <int, int>{};
    for (int i = 1; i <= gridSize; i++) {
      totalCounts[i] = gridSize;
    }
    final placedCorrectly = <int, int>{};
    for (int i = 1; i <= gridSize; i++) {
      placedCorrectly[i] = 0;
    }
    for (int row = 0; row < gridSize; row++) {
      for (int col = 0; col < gridSize; col++) {
        final val = board[row][col].value;
        if (val != null && fullSolution != null && fullSolution![row][col] == val) {
          placedCorrectly[val] = placedCorrectly[val]! + 1;
        }
      }
    }
    remainingCounts = {};
    for (int i = 1; i <= gridSize; i++) {
      remainingCounts[i] = totalCounts[i]! - placedCorrectly[i]!;
    }
  }

  void _startTimer() {
    elapsedTime = Duration.zero;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!isGameFinished) {
        elapsedTime += const Duration(seconds: 1);
        notifyListeners();
      }
    });
  }

  void selectCell(int row, int col) {
    if (isGameFinished) return;
    selectedRow = row;
    selectedCol = col;
    final cell = board[row][col];
    highlightedNumber = cell.value;
    notifyListeners();
  }

  bool attemptPlaceNumber(int number) {
    if (isGameFinished) return false;
    if (selectedRow == null || selectedCol == null) return false;
    final row = selectedRow!;
    final col = selectedCol!;
    final cell = board[row][col];
    if (cell.isFixed) return false;

    if (isNotesMode) {
      if (cell.notes.contains(number)) {
        cell.notes.remove(number);
      } else {
        if (cell.value == null) {
          cell.notes.add(number);
        }
      }
      cell.value = null;
      cell.isError = false;
      notifyListeners();
      return true;
    }

    final isCorrect = (fullSolution != null && fullSolution![row][col] == number);

    if (isCorrect) {
      cell.value = number;
      cell.notes.clear();
      cell.isError = false;
      int points = 10;
      if (elapsedTime.inSeconds < 30) points += 5;
      score += points;
      _updateRemainingCounts();
      notifyListeners();
      if (isBoardComplete()) {
        _winGame();
      }
      return true;
    } else {
      cell.isError = true;
      mistakes++;
      notifyListeners();
      Future.delayed(const Duration(seconds: 1), () {
        if (board[row][col].isError) {
          board[row][col].isError = false;
          notifyListeners();
        }
      });
      if (mistakes >= maxMistakes) {
        _loseGame();
      }
      return false;
    }
  }

  void erase() {
    if (isGameFinished) return;
    if (selectedRow == null || selectedCol == null) return;
    final cell = board[selectedRow!][selectedCol!];
    if (cell.isFixed) return;
    final oldValue = cell.value;
    cell.value = null;
    cell.notes.clear();
    cell.isError = false;
    if (oldValue != null && fullSolution != null && fullSolution![selectedRow!][selectedCol!] == oldValue) {
      _updateRemainingCounts();
    }
    notifyListeners();
  }

  List<List<int?>> _toNullableGrid() {
    return List.generate(gridSize, (i) {
      return List.generate(gridSize, (j) => board[i][j].value);
    });
  }

  bool isBoardComplete() {
    for (int i = 0; i < gridSize; i++) {
      for (int j = 0; j < gridSize; j++) {
        if (board[i][j].value == null) return false;
        if (board[i][j].isError) return false;
        if (fullSolution != null && board[i][j].value != fullSolution![i][j]) return false;
      }
    }
    return true;
  }

  void _winGame() {
    if (isGameFinished) return;
    isGameFinished = true;
    _timer?.cancel();
    onWin();
    notifyListeners();
  }

  void _loseGame() {
    if (isGameFinished) return;
    isGameFinished = true;
    _timer?.cancel();
    onLoss();
    notifyListeners();
  }

  void resetGame() {
    _timer?.cancel();
    _initForLevel();
  }

  void toggleNotesMode() {
    isNotesMode = !isNotesMode;
    notifyListeners();
  }

  bool useHint() {
    if (isGameFinished) return false;
    if (hintEnergy <= 0) return false;
    if (fullSolution == null) return false;

    for (int i = 0; i < gridSize; i++) {
      for (int j = 0; j < gridSize; j++) {
        if (board[i][j].value == null || board[i][j].isError) {
          final correct = fullSolution![i][j];
          if (correct != null && board[i][j].value != correct) {
            selectedRow = i;
            selectedCol = j;
            final cell = board[i][j];
            if (cell.isFixed) continue;
            cell.value = correct;
            cell.notes.clear();
            cell.isError = false;
            hintEnergy--;
            score = max(0, score - 5);
            _updateRemainingCounts();
            notifyListeners();
            return true;
          }
        }
      }
    }
    return false;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

// ============================================================================
// SudokuPage ----
// ============================================================================

class SudokuPage extends StatefulWidget {
  final int level;
  const SudokuPage({super.key, required this.level});

  @override
  State<SudokuPage> createState() => _SudokuPageState();
}

class _SudokuPageState extends State<SudokuPage> with SingleTickerProviderStateMixin {
  late GameController controller;
  late AnimationController _shakeController;
  int? _errorRow, _errorCol;
  int? _flashRow, _flashCol;
  Timer? _flashTimer;

  final AudioPlayer _audioCorrect = AudioPlayer();
  final AudioPlayer _audioWrong = AudioPlayer();

  // إعدادات الصوت والاهتزاز ----
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _loadSettings();
    _preloadSounds();
    controller = GameController(
      currentLevel: widget.level,
      onWin: _onGameWin,
      onLoss: _onGameLoss,
    );
    controller.addListener(_onControllerUpdate);
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _soundEnabled = prefs.getBool('sudoku_sound_enabled') ?? true;
      _vibrationEnabled = prefs.getBool('sudoku_vibration_enabled') ?? true;
    });
  }

  Future<void> _saveSoundSetting(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sudoku_sound_enabled', value);
  }

  Future<void> _saveVibrationSetting(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sudoku_vibration_enabled', value);
  }

  void _toggleSound() {
    setState(() {
      _soundEnabled = !_soundEnabled;
      _saveSoundSetting(_soundEnabled);
    });
  }

  void _toggleVibration() {
    setState(() {
      _vibrationEnabled = !_vibrationEnabled;
      _saveVibrationSetting(_vibrationEnabled);
    });
  }

  void _onControllerUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _preloadSounds() async {
    try {
      await _audioCorrect.setSourceAsset('sounds/correct.wav');
      await _audioWrong.setSourceAsset('sounds/wrong.wav');
      print('✅ Audio loaded successfully');
    } catch (e) {
      print('❌ Error loading sounds: $e');
    }
  }

  void _playCorrectSound() async {
    if (!_soundEnabled) return;
    try {
      await _audioCorrect.play(AssetSource('sounds/correct.wav'));
      print('🔊 Playing correct sound');
    } catch (e) {
      print('❌ Error playing correct sound: $e');
    }
  }

  void _playWrongSound() async {
    if (!_soundEnabled) return;
    try {
      await _audioWrong.play(AssetSource('sounds/wrong.wav'));
      print('🔊 Playing wrong sound');
    } catch (e) {
      print('❌ Error playing wrong sound: $e');
    }
  }

  void _vibrate() async {
    if (!_vibrationEnabled) return;
    try {
      if (await Vibration.hasVibrator() ?? false) {
        Vibration.vibrate(duration: 100);
        print('📳 Vibrated');
      }
    } catch (e) {
      print('❌ Vibration error: $e');
    }
  }

  void _onGameWin() {
    final gameState = Provider.of<GameState>(context, listen: false);
    gameState.addPoints(controller.score);
    final nextLevel = widget.level + 1;
    if (nextLevel <= 5) {
      gameState.unlockLevel('sudoku', nextLevel);
    }
    _showWinDialog();
  }

  void _onGameLoss() {
    _showLossDialog();
  }

  void _onNumberPressed(int number) {
    if (controller.isGameFinished) return;
    final success = controller.attemptPlaceNumber(number);
    if (success) {
      _playCorrectSound();
      if (controller.selectedRow != null && controller.selectedCol != null) {
        _showFlash(controller.selectedRow!, controller.selectedCol!);
      }
    } else {
      if (!controller.isNotesMode) {
        _playWrongSound();
        _vibrate();
        if (controller.selectedRow != null && controller.selectedCol != null) {
          _triggerShake(controller.selectedRow!, controller.selectedCol!);
        }
      }
    }
    controller.highlightedNumber = number;
  }

  void _triggerShake(int row, int col) {
    setState(() {
      _errorRow = row;
      _errorCol = col;
    });
    _shakeController.forward().then((_) {
      _shakeController.reverse();
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) setState(() {
          _errorRow = null;
          _errorCol = null;
        });
      });
    });
  }

  void _showFlash(int row, int col) {
    setState(() {
      _flashRow = row;
      _flashCol = col;
    });
    _flashTimer?.cancel();
    _flashTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() {
        _flashRow = null;
        _flashCol = null;
      });
    });
  }

  void _showWinDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => buildStyledDialog(
        title: '🎉 Victory! 🎉',
        content: 'Congratulations!\nYou completed level ${widget.level} in ${_formatDuration(controller.elapsedTime)}\nScore: ${controller.score}\nMistakes: ${controller.mistakes}',
        icon: Icons.emoji_events,
        iconColor: Colors.amber,
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.deepPurple),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  void _showLossDialog() {
    if (controller.isGameFinished) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => buildStyledDialog(
        title: 'Game Over',
        content: 'You made ${controller.maxMistakes} mistakes.\nBetter luck next time!',
        icon: Icons.sentiment_dissatisfied,
        iconColor: Colors.redAccent,
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              controller.resetGame();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.deepPurple),
            child: const Text('Try Again'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.grey, foregroundColor: Colors.white),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }

  void _pauseGame() {
    if (controller.isGameFinished) return;
    controller._timer?.cancel();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => PausePage(
          onResume: () {
            Navigator.pop(ctx);
            controller._startTimer();
            setState(() {});
          },
          onRestart: () {
            Navigator.pop(ctx);
            controller.resetGame();
          },
          onExit: () {
            Navigator.pop(ctx);
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Sudoku - Level ${widget.level}'),
          centerTitle: true,
          backgroundColor: Colors.white,
          foregroundColor: Colors.deepPurple,
          elevation: 0,
          actions: [
            IconButton(
              icon: Icon(_soundEnabled ? Icons.volume_up : Icons.volume_off, color: const Color(0xFF7B61FF)),
              onPressed: _toggleSound,
              tooltip: _soundEnabled ? 'Disable Sound' : 'Enable Sound',
            ),
            IconButton(
              icon: Icon(_vibrationEnabled ? Icons.vibration : Icons.notifications_off, color: const Color(0xFF7B61FF)),
              onPressed: _toggleVibration,
              tooltip: _vibrationEnabled ? 'Disable Vibration' : 'Enable Vibration',
            ),
            IconButton(
              icon: const Icon(Icons.pause_circle_filled, color: Color(0xFF7B61FF)),
              onPressed: _pauseGame,
              tooltip: 'Pause',
            ),
          ],
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.white, Color(0xFFF3F0FF), Color(0xFFE3DAFF), Color(0xFFD2C6FF)],
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _infoChip(Icons.score, '${controller.score}'),
                    _infoChip(Icons.error_outline, '${controller.mistakes}/${controller.maxMistakes}'),
                    _infoChip(Icons.timer, _formatDuration(controller.elapsedTime)),
                    _infoChip(Icons.bolt, '${controller.hintEnergy}'),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(color: Color(0xFF372C60), blurRadius: 0, offset: const Offset(6, 4)),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _buildGrid(),
                      ),
                    ),
                  ),
                ),
              ),
              _buildNumberPad(),
              const SizedBox(height: 8),
              _buildActionButtons(),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Color(0xFF372C60), blurRadius: 0, offset: const Offset(1, 2)),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF7B61FF)),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontFamily: 'PTSerif', color: Colors.black87)),
        ],
      ),
    );
  }

  // ========================
  // COLORING LOGIC ----
  // ========================
  Color _getCellBackgroundColor({
    required int row,
    required int col,
    required Cell cell,
    required bool isSelected,
    required bool isSameNumber,
    required bool isRowHighlight,
    required bool isColHighlight,
    required bool isBoxHighlight,
  }) {
    if (cell.isError) return const Color(0xFFE57373);
    if (isSelected) return const Color(0xFF7B61FF).withOpacity(0.3);
    if (isSameNumber) return const Color(0xFFA569BD).withOpacity(0.3);
    if (isBoxHighlight) return const Color(0xFFD2C6FF).withOpacity(0.5);
    if (isRowHighlight || isColHighlight) return const Color(0xFFF3F0FF);
    return Colors.white;
  }

  bool _isInSameBox(int row, int col, int boxRows, int boxCols, int? selectedRow, int? selectedCol) {
    if (selectedRow == null || selectedCol == null) return false;
    final boxRowStart = (selectedRow ~/ boxRows) * boxRows;
    final boxColStart = (selectedCol ~/ boxCols) * boxCols;
    return row >= boxRowStart &&
        row < boxRowStart + boxRows &&
        col >= boxColStart &&
        col < boxColStart + boxCols;
  }

  BoxBorder _buildBorder(int row, int col, int size, int boxRows, int boxCols) {
    final isRightThick = (col + 1) % boxCols == 0 && col != size - 1;
    final isBottomThick = (row + 1) % boxRows == 0 && row != size - 1;
    return Border(
      right: isRightThick
          ? const BorderSide(color: Color(0xFF7B61FF), width: 2)
          : const BorderSide(color: Color(0xFFDDDDDD), width: 0.5),
      bottom: isBottomThick
          ? const BorderSide(color: Color(0xFF7B61FF), width: 2)
          : const BorderSide(color: Color(0xFFDDDDDD), width: 0.5),
      left: col == 0 ? const BorderSide(color: Color(0xFFDDDDDD), width: 0.5) : BorderSide.none,
      top: row == 0 ? const BorderSide(color: Color(0xFFDDDDDD), width: 0.5) : BorderSide.none,
    );
  }

  Widget _buildGrid() {
    final size = controller.gridSize;
    final boxRows = controller.boxRows;
    final boxCols = controller.boxCols;
    final selectedRow = controller.selectedRow;
    final selectedCol = controller.selectedCol;
    final highlightedNumber = controller.highlightedNumber;

    return GestureDetector(
      onTapDown: (_) => FocusScope.of(context).unfocus(),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: size,
          childAspectRatio: 1,
        ),
        itemCount: size * size,
        itemBuilder: (ctx, index) {
          final row = index ~/ size;
          final col = index % size;
          final cell = controller.board[row][col];
          final isSelected = (selectedRow == row && selectedCol == col);
          final isSameNumber = (cell.value != null && highlightedNumber != null && cell.value == highlightedNumber);
          final isRowHighlight = (selectedRow == row);
          final isColHighlight = (selectedCol == col);
          final isBoxHighlight = _isInSameBox(row, col, boxRows, boxCols, selectedRow, selectedCol);
          final isErrorCell = (row == _errorRow && col == _errorCol);

          Color bgColor = _getCellBackgroundColor(
            row: row,
            col: col,
            cell: cell,
            isSelected: isSelected,
            isSameNumber: isSameNumber,
            isRowHighlight: isRowHighlight,
            isColHighlight: isColHighlight,
            isBoxHighlight: isBoxHighlight,
          );

          Widget cellChild = Center(
            child: cell.value != null
                ? Text(
                    cell.value.toString(),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'PTSerif',
                      color: cell.isFixed ? Colors.black87 : (cell.isError ? const Color(0xFFE57373) : const Color(0xFF7B61FF)),
                    ),
                  )
                : _buildNotesWidget(cell.notes, size),
          );

          if (isErrorCell) {
            cellChild = Transform.translate(
              offset: Offset(_shakeController.value * 5, 0),
              child: cellChild,
            );
          }

          return Container(
            decoration: BoxDecoration(
              color: bgColor,
              border: _buildBorder(row, col, size, boxRows, boxCols),
            ),
            child: InkWell(
              onTap: () => controller.selectCell(row, col),
              child: cellChild,
            ),
          );
        },
      ),
    );
  }

  Widget _buildNotesWidget(Set<int> notes, int gridSize) {
    if (notes.isEmpty) return const SizedBox();
    final crossAxisCount = gridSize == 6 ? 3 : 3;
    return Padding(
      padding: const EdgeInsets.all(4),
      child: GridView.count(
        crossAxisCount: crossAxisCount,
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        children: List.generate(gridSize, (num) {
          final number = num + 1;
          final show = notes.contains(number);
          return Center(
            child: Text(
              show ? number.toString() : '',
              style: TextStyle(
                fontSize: gridSize == 6 ? 12 : 10,
                fontFamily: 'PTSerif',
                color: Colors.black54,
              ),
            ),
          );
        }),
      ),
    );
  }

  // ========================
  // NUMBER PAD WITH SHADOW & PRESS SCALE ----
  // ========================
  Widget _buildNumberPad() {
    final maxNum = controller.gridSize;
    final remaining = controller.remainingCounts;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: List.generate(maxNum, (i) {
          final num = i + 1;
          final remainingCount = remaining[num] ?? maxNum;
          return _NumberButton(
            number: num,
            remainingCount: remainingCount,
            onPressed: () => _onNumberPressed(num),
          );
        }),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _actionButton(
          icon: Icons.edit_note,
          label: controller.isNotesMode ? 'Notes ON' : 'Notes',
          isActive: controller.isNotesMode,
          onPressed: controller.toggleNotesMode,
        ),
        _actionButton(
          icon: Icons.delete_outline,
          label: 'Erase',
          onPressed: () => controller.erase(),
        ),
        _actionButton(
          icon: Icons.lightbulb_outline,
          label: 'Hint (1)',
          onPressed: () {
            if (!controller.useHint()) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Not enough hint energy!')),
              );
            }
          },
        ),
      ],
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool isActive = false,
  }) {
    return Column(
      children: [
        IconButton(
          onPressed: onPressed,
          icon: Icon(icon, color: isActive ? const Color(0xFF7B61FF) : Colors.black54),
          style: IconButton.styleFrom(
            backgroundColor: Colors.white,
            padding: const EdgeInsets.all(12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 11, fontFamily: 'PTSerif', color: isActive ? const Color(0xFF7B61FF) : Colors.black54),
        ),
      ],
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    controller.removeListener(_onControllerUpdate);
    _shakeController.dispose();
    _flashTimer?.cancel();
    _audioCorrect.dispose();
    _audioWrong.dispose();
    controller.dispose();
    super.dispose();
  }
}

// ============================================================================
// Custom Number Button with Shadow and Press Animation ----
// ============================================================================
class _NumberButton extends StatefulWidget {
  final int number;
  final int remainingCount;
  final VoidCallback onPressed;

  const _NumberButton({
    required this.number,
    required this.remainingCount,
    required this.onPressed,
  });

  @override
  State<_NumberButton> createState() => _NumberButtonState();
}

class _NumberButtonState extends State<_NumberButton> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _scale,
      duration: const Duration(milliseconds: 100),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _scale = 0.95),
        onTapUp: (_) => setState(() => _scale = 1.0),
        onTapCancel: () => setState(() => _scale = 1.0),
        onTap: widget.onPressed,
        child: Container(
          width: 65,
          height: 65,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF7B61FF).withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF372C60),
                blurRadius: 0,
                offset: const Offset(1, 2),
              ),
            ],
          ),
          child: Stack(
            children: [
              Center(
                child: Text(
                  widget.number.toString(),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'PTSerif',
                    color: Color(0xFF7B61FF),
                  ),
                ),
              ),
              Positioned(
                left: 6,
                bottom: 6,
                child: Text(
                  '${widget.remainingCount}',
                  style: const TextStyle(fontSize: 11, fontFamily: 'PTSerif', color: Colors.black54),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}