import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:provider/provider.dart';
import 'package:vibration/vibration.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../game_state.dart';

// ------------------------------------------------------------
// GlassCard - نمط البطاقة الزجاجية المستخدمة في الحوارات
// ------------------------------------------------------------
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
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ------------------------------------------------------------
// نموذج السؤال الداخلي ----
// ------------------------------------------------------------
class _Question {
  final String text;
  final int correctAnswer;
  final List<int> options;
  final int level;
  final String operationType;

  _Question({
    required this.text,
    required this.correctAnswer,
    required this.options,
    required this.level,
    required this.operationType,
  });
}

// ------------------------------------------------------------
// صفحة التوقف المؤقت (Pause Page) ----
// ------------------------------------------------------------
class PausePage extends StatelessWidget {
  final VoidCallback onResume;
  final VoidCallback onRestart;
  final VoidCallback onExit;

  const PausePage({
    super.key,
    required this.onResume,
    required this.onRestart,
    required this.onExit,
  });

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
              const Icon(Icons.pause_circle_filled, size: 80, color: Color(0xFF636070)),
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

// ------------------------------------------------------------
// صفحة اللعبة الرئيسية (CalcPage) ----
// ------------------------------------------------------------
class CalcPage extends StatefulWidget {
  final String gameName;
  final int level;

  const CalcPage({
    super.key,
    required this.gameName,
    this.level = 1,
  });

  @override
  State<CalcPage> createState() => _CalcPageState();
}

class _CalcPageState extends State<CalcPage> with TickerProviderStateMixin {
  late int _currentLevel;
  int _completedInLevel = 0;
  int _errorCount = 0;
  int _totalScore = 0;
  int _brainPower = 5;
  int _difficultyModifier = 0;

  static const int _timeLimit = 40;
  late Timer _stageTimer;
  int _timeRemaining = _timeLimit;
  bool _stageFailed = false;
  bool _levelCompleted = false;

  late _Question _currentQuestion;
  bool _isAnswered = false;
  int? _selectedIndex;
  String _feedbackMsg = '';
  Color _feedbackColor = Colors.transparent;
  bool _showFeedback = false;

  bool _hintUsed = false;
  int? _hintAnswer;

  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  final Random _random = Random();

  // الصوت والاهتزاز ----
  final AudioPlayer _audioPlayerCorrect = AudioPlayer();
  final AudioPlayer _audioPlayerWrong = AudioPlayer();

  // إعدادات الصوت والاهتزاز ----
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  late SharedPreferences _prefs;

  @override
  void initState() {
    super.initState();
    _currentLevel = widget.level.clamp(1, 5);
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(_scaleController);
    _loadSettings();
    _preloadSounds();
    _startStageTimer();
    _loadNewQuestion();
  }

  Future<void> _loadSettings() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      _soundEnabled = _prefs.getBool('sound_enabled') ?? true;
      _vibrationEnabled = _prefs.getBool('vibration_enabled') ?? true;
    });
  }

  Future<void> _saveSettings() async {
    await _prefs.setBool('sound_enabled', _soundEnabled);
    await _prefs.setBool('vibration_enabled', _vibrationEnabled);
  }

  void _toggleSound() {
    setState(() {
      _soundEnabled = !_soundEnabled;
      _saveSettings();
    });
  }

  void _toggleVibration() {
    setState(() {
      _vibrationEnabled = !_vibrationEnabled;
      _saveSettings();
    });
  }

  Future<void> _preloadSounds() async {
    try {
      await _audioPlayerCorrect.setSourceAsset('sounds/correct.wav');
      await _audioPlayerWrong.setSourceAsset('sounds/wrong.wav');
    } catch (e) {
      debugPrint('Error loading sound: $e');
    }
  }

  void _playCorrectSound() async {
    if (_soundEnabled) {
      try {
        await _audioPlayerCorrect.play(AssetSource('sounds/correct.wav'));
      } catch (e) {
        debugPrint('Correct sound error: $e');
      }
    }
  }

  void _playWrongSound() async {
    if (_soundEnabled) {
      try {
        await _audioPlayerWrong.play(AssetSource('sounds/wrong.wav'));
      } catch (e) {
        debugPrint('Wrong sound error: $e');
      }
    }
  }

  void _vibrate() async {
    if (_vibrationEnabled) {
      try {
        if (await Vibration.hasVibrator() ?? false) {
          Vibration.vibrate(duration: 100);
        }
      } catch (e) {
        debugPrint('Vibration error: $e');
      }
    }
  }

  void _startStageTimer() {
    _stageTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_stageFailed || _levelCompleted || _completedInLevel >= 8) return;
      if (_timeRemaining <= 0) {
        _stageFailed = true;
        timer.cancel();
        _failStage('Time is up!');
      } else {
        setState(() {
          _timeRemaining--;
        });
      }
    });
  }

  @override
  void dispose() {
    _stageTimer.cancel();
    _scaleController.dispose();
    _audioPlayerCorrect.dispose();
    _audioPlayerWrong.dispose();
    super.dispose();
  }

  void _loadNewQuestion() {
    if (_stageFailed || _levelCompleted) return;
    if (_completedInLevel >= 8) {
      _completeLevel();
      return;
    }

    setState(() {
      _isAnswered = false;
      _selectedIndex = null;
      _feedbackMsg = '';
      _feedbackColor = Colors.transparent;
      _showFeedback = false;
      _hintUsed = false;
      _hintAnswer = null;
    });

    _currentQuestion = _generateQuestion();
  }

  // ------------------------------------------------------------
  // توليد الأسئلة (نفس الكود الأصلي) ----
  // ------------------------------------------------------------
  _Question _generateQuestion() {
    int maxNumber;
    switch (_currentLevel) {
      case 1:
        maxNumber = 30 + _difficultyModifier * 4;
        break;
      case 2:
        maxNumber = 60 + _difficultyModifier * 5;
        break;
      case 3:
        maxNumber = 90 + _difficultyModifier * 6;
        break;
      case 4:
        maxNumber = 120 + _difficultyModifier * 7;
        break;
      default:
        maxNumber = 150 + _difficultyModifier * 8;
    }
    maxNumber = maxNumber.clamp(15, 200);

    if (_currentLevel >= 3 && _random.nextDouble() < 0.3) {
      return _generateMissingNumberQuestion(maxNumber);
    } else if (_currentLevel >= 4 && _random.nextDouble() < 0.3) {
      return _generateFindOperationQuestion(maxNumber);
    } else {
      return _generateBasicOperation(maxNumber);
    }
  }

  _Question _generateBasicOperation(int maxNumber) {
    List<String> ops = ['+', '-'];
    if (_currentLevel >= 1) ops.add('*');
    if (_currentLevel >= 2) ops.add('/');

    String op = ops[_random.nextInt(ops.length)];
    int a, b, correctAnswer;

    if (op == '+') {
      a = _random.nextInt(maxNumber - 1) + 1;
      b = _random.nextInt(maxNumber - a) + 1;
      correctAnswer = a + b;
    } else if (op == '-') {
      a = _random.nextInt(maxNumber - 1) + 1;
      b = _random.nextInt(a) + 1;
      correctAnswer = a - b;
    } else if (op == '*') {
      a = _random.nextInt((maxNumber ~/ 3) - 1) + 2;
      b = _random.nextInt((maxNumber ~/ a) - 1) + 2;
      correctAnswer = a * b;
      if (correctAnswer > maxNumber) return _generateBasicOperation(maxNumber);
    } else {
      // قسمة صحيحة ----
      b = _random.nextInt(maxNumber ~/ 3) + 2;
      correctAnswer = _random.nextInt(maxNumber ~/ b) + 2;
      a = b * correctAnswer;
    }

    String text = "$a $op $b = ?";
    List<int> options = _generateOptions(correctAnswer, maxNumber);
    return _Question(
      text: text,
      correctAnswer: correctAnswer,
      options: options,
      level: _currentLevel,
      operationType: op,
    );
  }

  _Question _generateMissingNumberQuestion(int maxNumber) {
    int a = _random.nextInt(maxNumber ~/ 2) + 5;
    int b = _random.nextInt(maxNumber - a) + 5;
    int result = a + b;
    bool missingFirst = _random.nextBool();
    String text;
    int correctAnswer;
    if (missingFirst) {
      text = "? + $b = $result";
      correctAnswer = a;
    } else {
      text = "$a + ? = $result";
      correctAnswer = b;
    }
    List<int> options = _generateOptions(correctAnswer, maxNumber);
    return _Question(
      text: text,
      correctAnswer: correctAnswer,
      options: options,
      level: _currentLevel,
      operationType: 'missing',
    );
  }

  _Question _generateFindOperationQuestion(int maxNumber) {
    int a = _random.nextInt(maxNumber ~/ 2) + 5;
    int b = _random.nextInt(maxNumber ~/ 3) + 5;
    List<String> possibleOps = ['+', '-', '*'];
    String correctOp = possibleOps[_random.nextInt(possibleOps.length)];
    int result;
    switch (correctOp) {
      case '+':
        result = a + b;
        break;
      case '-':
        result = a - b;
        break;
      default:
        result = a * b;
    }
    if (result < 0) result = a + b;
    String text = "$a ? $b = $result";
    List<int> options = [1, 2, 3];
    options.shuffle();
    int correctValue = correctOp == '+' ? 1 : (correctOp == '-' ? 2 : 3);
    return _Question(
      text: text,
      correctAnswer: correctValue,
      options: options,
      level: _currentLevel,
      operationType: 'findOp',
    );
  }

  List<int> _generateOptions(int correct, int maxRange) {
    Set<int> opts = {correct};
    while (opts.length < 4) {
      int offset = _random.nextInt((maxRange * 0.3).ceil()) + 3;
      int candidate = correct + (opts.length.isEven ? offset : -offset);
      if (candidate > 0 && candidate <= maxRange + 20) {
        opts.add(candidate);
      } else {
        opts.add(correct + opts.length);
      }
    }
    List<int> list = opts.toList();
    list.shuffle();
    return list;
  }

  void _checkAnswer(int selectedValue, int index) async {
    if (_isAnswered || _stageFailed || _levelCompleted) return;
    setState(() {
      _isAnswered = true;
      _selectedIndex = index;
    });
    await _scaleController.forward();
    await _scaleController.reverse();

    bool isCorrect = (selectedValue == _currentQuestion.correctAnswer);
    if (isCorrect) {
      _playCorrectSound();
      int basePoints = 5;
      int timeBonus = (_timeRemaining > _timeLimit ~/ 2) ? 5 : 2;
      int pointsGained = basePoints + timeBonus;
      setState(() {
        _totalScore += pointsGained;
        _brainPower = min(_brainPower + 1, 20);
        _feedbackMsg = "Good Job! +$pointsGained pts";
        _feedbackColor = Colors.green;
        _showFeedback = true;
      });
      if (_timeRemaining > _timeLimit * 0.7) {
        _difficultyModifier++;
      } else if (_timeRemaining < _timeLimit * 0.3) {
        _difficultyModifier = (_difficultyModifier - 1).clamp(0, 5);
      }
      await Future.delayed(const Duration(seconds: 1));
      _completedInLevel++;
      _loadNewQuestion();
    } else {
      _playWrongSound();
      _vibrate();
      _errorCount++;
      setState(() {
        _feedbackMsg = "Nice Try! Correct: ${_currentQuestion.correctAnswer}";
        _feedbackColor = Colors.red;
        _showFeedback = true;
      });
      if (_errorCount >= 3) {
        _stageFailed = true;
        _stageTimer.cancel();
        _failStage('Too many mistakes!');
      } else {
        await Future.delayed(const Duration(seconds: 1));
        _completedInLevel++;
        _loadNewQuestion();
      }
    }
  }

  // نافذة الخسارة باستخدام GlassCard (تم إصلاح overflow) ----
  void _failStage(String reason) {
    if (_levelCompleted) return;
    _stageTimer.cancel();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16), 
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
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
          child: SingleChildScrollView(  
            physics: const BouncingScrollPhysics(),
            child: GlassCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cancel, size: 56, color: Colors.redAccent),
                  const SizedBox(height: 12),
                  const Text(
                    'Stage Failed',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '$reason\nYou made $_errorCount mistakes.',
                    style: const TextStyle(fontSize: 14, color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          Navigator.pop(context);
                        },
                        child: const Text('Back to Game Details', style: TextStyle(color: Colors.white70)),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _restartLevel();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.deepPurple,
                        ),
                        child: const Text('Retry Level'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _restartLevel() {
    setState(() {
      _completedInLevel = 0;
      _errorCount = 0;
      _totalScore = 0;
      _difficultyModifier = 0;
      _stageFailed = false;
      _levelCompleted = false;
      _timeRemaining = _timeLimit;
      _stageTimer.cancel();
      _startStageTimer();
      _loadNewQuestion();
    });
  }

  // نافذة الفوز باستخدام GlassCard ----
  void _completeLevel() async {
    if (_levelCompleted) return;
    _levelCompleted = true;
    _stageTimer.cancel();

    final gameState = Provider.of<GameState>(context, listen: false);
    gameState.addPoints(_totalScore);
    int nextLevel = _currentLevel + 1;
    if (nextLevel <= 5) {
      gameState.unlockLevel(widget.gameName, nextLevel);
    }

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
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
                const Icon(Icons.emoji_events, size: 64, color: Colors.amber),
                const SizedBox(height: 16),
                const Text(
                  'Level Complete!',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Text(
                  'You completed Level $_currentLevel!\n\nYour score: $_totalScore points\nWell done!',
                  style: const TextStyle(fontSize: 16, color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.deepPurple,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: const Text('Continue'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _useHint() {
    if (_hintUsed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hint already used for this question')),
      );
      return;
    }
    if (_brainPower < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not enough Brain Power!')),
      );
      return;
    }
    setState(() {
      _brainPower -= 3;
      _hintUsed = true;
      _hintAnswer = _currentQuestion.correctAnswer;
      _feedbackMsg = 'Hint: The correct answer is $_hintAnswer';
      _feedbackColor = Colors.orange;
      _showFeedback = true;
    });
  }

  void _pauseGame() {
    _stageTimer.cancel();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PausePage(
          onResume: () {
            Navigator.pop(context);
            _startStageTimer();
          },
          onRestart: () {
            Navigator.pop(context);
            _restartLevel();
          },
          onExit: () {
            Navigator.pop(context);
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: Container(
        width: size.width,
        height: size.height,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Color(0xFFF3F0FF), Color(0xFFE3DAFF), Color(0xFFD2C6FF)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ---- Top bar with sound/vibration controls ----
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(color: Colors.purple.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2)),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF7B61FF),
                          ),
                          child: const Icon(Icons.star, color: Colors.white, size: 18),
                        ),
                        const SizedBox(width: 6),
                        Text('$_totalScore', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      // زر إيقاف/تشغيل الصوت ----
                      GestureDetector(
                        onTap: _toggleSound,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.8),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _soundEnabled ? Icons.volume_up : Icons.volume_off,
                            color: Colors.purple.shade700,
                            size: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // زر إيقاف/تشغيل الاهتزاز ----
                      GestureDetector(
                        onTap: _toggleVibration,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.8),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                           
                              _vibrationEnabled ? Icons.vibration : Icons.notifications_off,
                            color: Colors.purple.shade700,
                            size: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _pauseGame,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.8),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.pause, color: Color(0xFF1F1C2E), size: 24),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ---- Brain Power ----
              Column(
                children: [
                  const Text('Brain Power', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Container(
                    width: size.width * 0.5,
                    height: 12,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.grey.shade300,
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: (_brainPower / 20).clamp(0.0, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF7B61FF), Color(0xFF4DA6FF)],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('$_brainPower pts', style: const TextStyle(fontSize: 12)),
                ],
              ),
              const SizedBox(height: 12),

              // ---- Level & progress ----
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Level $_currentLevel', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  Text('Q${_completedInLevel + 1}/8', style: const TextStyle(fontSize: 16)),
                ],
              ),
              const SizedBox(height: 12),

              // ---- Timer bar ----
              Row(
                children: [
                  const Icon(Icons.timer, size: 20, color: Color(0xFF7B61FF)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: _timeRemaining / _timeLimit,
                      backgroundColor: Colors.grey.shade300,
                      color: _timeRemaining < 10 ? Colors.red : Colors.green,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('${_timeRemaining}s', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 20),

              // ---- Question card ----
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(32),
                    color: Colors.white,
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.calculate, size: 50, color: Color(0xFF7B61FF)),
                      const SizedBox(height: 8),
                      Text(
                        _currentQuestion.text,
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      if (_currentQuestion.operationType == 'findOp')
                        const Text('Choose the operation', style: TextStyle(fontSize: 16)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ---- Options grid ----
              GridView.count(
                shrinkWrap: true,
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 2.2,
                physics: const NeverScrollableScrollPhysics(),
                children: List.generate(_currentQuestion.options.length, (index) {
                  int value = _currentQuestion.options[index];
                  String displayText;
                  if (_currentQuestion.operationType == 'findOp') {
                    if (value == 1) displayText = '+';
                    else if (value == 2) displayText = '-';
                    else displayText = '*';
                  } else {
                    displayText = value.toString();
                  }
                  Color btnColor = Colors.purple.shade400;
                  if (_isAnswered && _selectedIndex == index) {
                    btnColor = (value == _currentQuestion.correctAnswer) ? Colors.green : Colors.red;
                  }
                  if (_hintAnswer != null && value == _hintAnswer && !_isAnswered) {
                    btnColor = Colors.orange;
                  }
                  return ScaleTransition(
                    scale: _scaleAnimation,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: btnColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: _isAnswered ? null : () => _checkAnswer(value, index),
                      child: Text(displayText, style: const TextStyle(fontSize: 24, color: Colors.white)),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),

              // ---- Hint & Next buttons ----
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: _useHint,
                    icon: const Icon(Icons.lightbulb),
                    label: Text('Hint (3⚡) (${_brainPower} left)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade700,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  if (_isAnswered && !_stageFailed && !_levelCompleted && _completedInLevel < 8)
                    ElevatedButton.icon(
                      onPressed: () {
                        _completedInLevel++;
                        _loadNewQuestion();
                      },
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('Next'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // ---- Feedback message ----
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _showFeedback
                    ? Container(
                        key: ValueKey(_feedbackMsg),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: _feedbackColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _feedbackColor.withOpacity(0.5)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_feedbackColor == Colors.green ? Icons.check_circle : Icons.cancel,
                                color: _feedbackColor, size: 20),
                            const SizedBox(width: 8),
                            Text(_feedbackMsg, style: TextStyle(color: _feedbackColor, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              const SizedBox(height: 8),
              if (_errorCount > 0)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (i) => Icon(
                    i < _errorCount ? Icons.error_outline : Icons.error_outline,
                    color: i < _errorCount ? Colors.red : Colors.grey,
                    size: 20,
                  )),
                ),
            ],
          ),
        ),
      ),
    );
  }
}