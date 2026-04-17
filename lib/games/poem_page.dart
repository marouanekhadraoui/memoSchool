import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:vibration/vibration.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:provider/provider.dart';
import '../game_state.dart';

// ---------- Pause Page ----------
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
                style: ElevatedButton.styleFrom(backgroundColor: Colors.purple.shade400, foregroundColor: Colors.white),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onRestart,
                icon: const Icon(Icons.refresh),
                label: const Text('Restart Level'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade700, foregroundColor: Colors.white),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onExit,
                icon: const Icon(Icons.exit_to_app),
                label: const Text('Exit to Game Details'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade400, foregroundColor: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------- Curved Divider ----------
class CurvedDivider extends StatelessWidget {
  const CurvedDivider({super.key});
  @override
  Widget build(BuildContext context) => CustomPaint(size: const Size(double.infinity, 4), painter: _CurvedDividerPainter());
}
class _CurvedDividerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.grey.shade400..strokeWidth = 2..style = PaintingStyle.stroke;
    final path = Path();
    final y = size.height / 2;
    path.moveTo(0, y);
    path.quadraticBezierTo(40, y - 10, 30, y);
    path.lineTo(size.width - 20, y);
    path.quadraticBezierTo(size.width - 40, y - 15, size.width, y);
    canvas.drawPath(path, paint);
  }
  @override bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ---------- Glass Card for dialogs ----------
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

// ---------- Main Poem Page (Fill-in-the-blanks Game) ----------
class PoemPage extends StatefulWidget {
  final String gameName;
  final int level;
  final Map<String, dynamic> poem;
  const PoemPage({super.key, required this.gameName, required this.level, required this.poem});

  @override
  State<PoemPage> createState() => _PoemPageState();
}

class _PoemPageState extends State<PoemPage> with TickerProviderStateMixin {
  // ---------- Core data ----------
  late Map<String, dynamic> _currentPoem;
  List<String> _displayLines = [];
  List<String> _allLines = [];
  List<Map<String, dynamic>> _blanks = [];
  int _currentBlankIndex = 0;
  List<String?> _userAnswers = [];
  List<List<String>> _optionsList = [];

  // ---------- Game mechanics ----------
  int _score = 0;
  int _brainPower = 5;
  int _mistakes = 0;
  int _timeLeft = 60;
  Timer? _timer;
  bool _isGameOver = false;
  bool _isLevelComplete = false;
  bool _isPaused = false;

  // ---------- UI feedback ----------
  String _feedbackMessage = '';
  Color _feedbackColor = Colors.transparent;
  bool _showFeedback = false;
  int? _highlightedOptionIndex;

  // ---------- Layout control ----------
  double _optionsTopMargin = 4.0;

  // ---------- Sound & Vibration ----------
  final AudioPlayer _audioPlayerCorrect = AudioPlayer();
  final AudioPlayer _audioPlayerWrong = AudioPlayer();
  final int maxMistakes = 3;
  final int totalTime = 60;

  // ---------- Word banks from JSON ----------
  Map<String, List<String>> _poemWordsMap = {};
  List<String> _generalWordBank = [];

  // ---------- Feedback animation ----------
  late AnimationController _feedbackAnimationController;
  late Animation<double> _feedbackScaleAnimation;

  @override
  void initState() {
    super.initState();
    _currentPoem = widget.poem;
    _allLines = List<String>.from(_currentPoem['lines']);
    _loadWordsData();
    _preloadSounds();
    
    _feedbackAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _feedbackScaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _feedbackAnimationController, curve: Curves.elasticOut),
    );
  }

  Future<void> _preloadSounds() async {
    try {
      await _audioPlayerCorrect.setSourceAsset('sounds/correct.wav');
      await _audioPlayerWrong.setSourceAsset('sounds/wrong.wav');
    } catch (e) { debugPrint('Error loading sound: $e'); }
  }

  Future<void> _loadWordsData() async {
    try {
      final String wordsJson = await rootBundle.loadString('assets/data/words.json');
      final Map<String, dynamic> wordsData = json.decode(wordsJson);
      _poemWordsMap = (wordsData['poem_words'] as Map).map((key, value) => MapEntry(key, List<String>.from(value)));
      _generalWordBank = List<String>.from(wordsData['general_words'] ?? []);
      _initGame();
    } catch (e) {
      _generalWordBank = ['علم', 'جهل', 'مجد', 'صبر', 'عز', 'نور'];
      _initGame();
    }
  }

  void _initGame() {
    _displayLines = List.from(_allLines);
    _selectWordsToHide();
    _generateAllOptions();
    _startTimer();
    setState(() {});
  }

  void _selectWordsToHide() {
    int wordsToHideCount = _getWordsCountForLevel();
    List<String> allWordsInDisplay = [];
    List<int> lineIndices = [];
    List<int> wordIndices = [];

    for (int i = 0; i < _displayLines.length; i++) {
      List<String> words = _displayLines[i].split(' ');
      for (int j = 0; j < words.length; j++) {
        String w = words[j].trim();
        if (w.isNotEmpty && w.length > 2 && !_isStopWord(w)) {
          allWordsInDisplay.add(w);
          lineIndices.add(i);
          wordIndices.add(j);
        }
      }
    }

    List<String> keywords = List<String>.from(_currentPoem['keywords'] ?? []);
    List<int> priorityIndices = [];
    for (int i = 0; i < allWordsInDisplay.length; i++) {
      if (keywords.contains(allWordsInDisplay[i])) priorityIndices.add(i);
    }

    List<int> chosenIndices = [];
    if (priorityIndices.length >= wordsToHideCount) {
      priorityIndices.shuffle();
      chosenIndices = priorityIndices.take(wordsToHideCount).toList();
    } else {
      chosenIndices.addAll(priorityIndices);
      List<int> remaining = List.generate(allWordsInDisplay.length, (i) => i).where((i) => !priorityIndices.contains(i)).toList();
      remaining.shuffle();
      chosenIndices.addAll(remaining.take(wordsToHideCount - priorityIndices.length));
    }
    chosenIndices.sort();

    _blanks.clear();
    for (int idx in chosenIndices) {
      _blanks.add({
        'lineIndex': lineIndices[idx],
        'wordIndex': wordIndices[idx],
        'word': allWordsInDisplay[idx],
      });
    }
    _userAnswers = List.filled(_blanks.length, null);
  }

  int _getWordsCountForLevel() {
    switch (widget.level) {
      case 1: return 2; case 2: return 3; case 3: return 4; case 4: return 5; case 5: return 6;
      default: return 2;
    }
  }

  bool _isStopWord(String word) {
    List<String> stopWords = ['من', 'في', 'على', 'إلى', 'عن', 'مع', 'بين', 'ب', 'ل', 'ك', 'و', 'ف', 'ثم', 'أو', 'قد', 'هل', 'ما', 'لا', 'إن', 'أن', 'إذا'];
    return stopWords.contains(word);
  }

  void _generateAllOptions() {
    _optionsList.clear();
    String poemId = _currentPoem['id'].toString();
    List<String> customWords = _poemWordsMap[poemId] ?? [];
    List<String> sourceWords = customWords.isNotEmpty ? customWords : _generalWordBank;

    for (var blank in _blanks) {
      String correct = blank['word'];
      int optionsCount = Random().nextInt(4) + 5;
      Set<String> optionsSet = {correct};
      List<String> candidates = List.from(sourceWords)..remove(correct);
      candidates.shuffle();
      for (String w in candidates) {
        if (optionsSet.length >= optionsCount) break;
        if (!optionsSet.contains(w)) optionsSet.add(w);
      }
      while (optionsSet.length < optionsCount) optionsSet.add('???');
      List<String> options = optionsSet.toList();
      options.shuffle();
      _optionsList.add(options);
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isPaused || _isGameOver || _isLevelComplete) return;
      if (_timeLeft <= 1) {
        _timer?.cancel();
        _gameOver('انتهى الوقت!');
      } else {
        setState(() => _timeLeft--);
      }
    });
  }

  void _gameOver(String message) {
    _isGameOver = true;
    _timer?.cancel();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _buildStyledDialog(
        title: 'انتهت اللعبة',
        content: message,
        icon: Icons.timer_off,
        iconColor: Colors.redAccent,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('خروج', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _resetGame();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.deepPurple),
            child: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }

  void _resetGame() {
    setState(() {
      _score = 0; _brainPower = 5; _mistakes = 0; _timeLeft = totalTime;
      _currentBlankIndex = 0; _userAnswers = List.filled(_blanks.length, null);
      _isGameOver = false; _isLevelComplete = false; _feedbackMessage = ''; _showFeedback = false;
      _highlightedOptionIndex = null; _isPaused = false;
      _displayLines = List.from(_allLines);
      _selectWordsToHide(); _generateAllOptions(); _startTimer();
    });
  }

  void _playCorrectSound() async {
    try { await _audioPlayerCorrect.play(AssetSource('sounds/correct.wav')); } catch (e) { debugPrint('Correct sound error: $e'); }
  }
  void _playWrongSound() async {
    try { await _audioPlayerWrong.play(AssetSource('sounds/wrong.wav')); } catch (e) { debugPrint('Wrong sound error: $e'); }
  }
  void _vibrate() async {
    try { if (await Vibration.hasVibrator() ?? false) Vibration.vibrate(duration: 100); } catch (e) { debugPrint('Vibration error: $e'); }
  }

  void _checkAnswer(int optionIndex) {
    if (_isGameOver || _isLevelComplete) return;
    String selected = _optionsList[_currentBlankIndex][optionIndex];
    String correct = _blanks[_currentBlankIndex]['word'];

    if (selected == correct) {
      _playCorrectSound();
      _userAnswers[_currentBlankIndex] = correct;
      int pointsGain = 10 + (_timeLeft > totalTime / 2 ? 5 : 0);
      _score += pointsGain;
      _brainPower = min(_brainPower + 1, 20);
      _showFeedbackMessage('صحيح! +$pointsGain', Colors.green, true);

      int lineIdx = _blanks[_currentBlankIndex]['lineIndex'];
      int wordIdx = _blanks[_currentBlankIndex]['wordIndex'];
      List<String> words = _displayLines[lineIdx].split(' ');
      if (wordIdx < words.length) words[wordIdx] = correct;
      _displayLines[lineIdx] = words.join(' ');

      _currentBlankIndex++;
      if (_currentBlankIndex >= _blanks.length) {
        _completeLevel();
      }
      setState(() {});
    } else {
      _playWrongSound(); _vibrate();
      _mistakes++;
      _showFeedbackMessage('خطأ! الإجابة الصحيحة: $correct', Colors.red, false);
      setState(() {});
      if (_mistakes >= maxMistakes) _gameOver('تجاوزت الحد الأقصى للأخطاء (3)');
    }
    Future.delayed(const Duration(seconds: 1), () { if (mounted) setState(() => _showFeedback = false); });
  }

  void _showFeedbackMessage(String msg, Color color, bool isCorrect) {
    _feedbackMessage = msg;
    _feedbackColor = color;
    _showFeedback = true;
    _feedbackAnimationController.forward(from: 0.0);
    setState(() {});
  }

  void _useHint() {
    if (_brainPower < 3) {
      _showFeedbackMessage('لا توجد طاقة كافية للتلميح (تحتاج 3)', Colors.orange, false);
      return;
    }
    if (_highlightedOptionIndex != null) return;
    String correct = _blanks[_currentBlankIndex]['word'];
    int correctIndex = _optionsList[_currentBlankIndex].indexOf(correct);
    setState(() { _highlightedOptionIndex = correctIndex; _brainPower -= 3; });
    _showFeedbackMessage('تلميح: الكلمة الصحيحة مُظللة', Colors.orange, false);
    Future.delayed(const Duration(seconds: 2), () { if (mounted) setState(() => _highlightedOptionIndex = null); });
  }

  void _completeLevel() async {
    if (_isLevelComplete) return;
    _isLevelComplete = true;
    _timer?.cancel();

    final gameState = Provider.of<GameState>(context, listen: false);
    final gameKey = 'poem';
    debugPrint('🔹 Adding points: $_score to game $gameKey');
    gameState.addPoints(_score);
    
    int nextLevel = widget.level + 1;
    if (nextLevel <= 5) {
      debugPrint('🔓 Unlocking level $nextLevel for game $gameKey');
      gameState.unlockLevel(gameKey, nextLevel);
      debugPrint('✅ After unlock: unlocked level = ${gameState.getUnlockedLevel(gameKey)}');
    } else {
      debugPrint('🏆 All levels completed!');
    }

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _buildStyledDialog(
        title: 'Level Complete!',
        content: 'لقد أكملت المستوى ${widget.level}!\n\nنقاطك: $_score\nطاقة العقل: $_brainPower\nالأخطاء: $_mistakes\nأحسنت!',
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

  Widget _buildStyledDialog({
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
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Text(
                content,
                style: const TextStyle(fontSize: 16, color: Colors.white70),
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

  void _pauseGame() {
    if (_isGameOver || _isLevelComplete) return;
    _timer?.cancel();
    _isPaused = true;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => PausePage(
          onResume: () { Navigator.pop(ctx); _resumeGame(); },
          onRestart: () { Navigator.pop(ctx); _resetGame(); },
          onExit: () { Navigator.pop(ctx); Navigator.pop(context); },
        ),
      ),
    );
  }

  void _resumeGame() { _isPaused = false; _startTimer(); setState(() {}); }

  Widget _buildPoemLine(String line, int lineIndex) {
    List<String> words = line.split(' ');
    List<TextSpan> spans = [];
    for (int i = 0; i < words.length; i++) {
      String word = words[i];
      if (word == '________') {
        spans.add(TextSpan(text: word, style: const TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold)));
      } else {
        spans.add(TextSpan(text: word, style: const TextStyle(color: Colors.black87)));
      }
      if (i < words.length - 1) spans.add(const TextSpan(text: ' '));
    }
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      alignment: lineIndex.isEven ? Alignment.centerRight : Alignment.centerLeft,
      child: RichText(
        text: TextSpan(children: spans, style: const TextStyle(fontSize: 20, fontFamily: 'Marhey', height: 1.6)),
        textAlign: lineIndex.isEven ? TextAlign.right : TextAlign.left,
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioPlayerCorrect.dispose();
    _audioPlayerWrong.dispose();
    _feedbackAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: Container(
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
              // ---- Top stats bar (same as CalcPage) ----
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF7B61FF)),
                        child: const Icon(Icons.star, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 6),
                      Text('$_score', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 16),
                      const Icon(Icons.favorite, color: Color(0xFF7B61FF), size: 24),
                      const SizedBox(width: 4),
                      Text('$_mistakes/$maxMistakes', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 16),
                      const Icon(Icons.bolt, color: Color(0xFF7B61FF), size: 24),
                      const SizedBox(width: 4),
                      Text('$_brainPower', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ]),
                    Row(children: [
                      const Icon(Icons.timer, color: Color(0xFF7B61FF), size: 24),
                      const SizedBox(width: 4),
                      Text('$_timeLeft ث', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 16),
                      IconButton(icon: const Icon(Icons.pause_circle_filled,color: Color(0xFF7B61FF), size: 32), onPressed: _pauseGame),
                    ]),
                  ],
                ),
              ),
              // ---- Progress bar ----
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: LinearProgressIndicator(
                  value: _blanks.isEmpty ? 0 : _currentBlankIndex / _blanks.length,
                  backgroundColor: Colors.grey[300],
                  color: Colors.deepPurple,
                ),
              ),
              // ---- Poem area (scrollable) ----
              Expanded(
                flex: 6,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: List.generate(_displayLines.length, (i) {
                            String line = _displayLines[i];
                            List<Map<String, dynamic>> blanksInThisLine = _blanks.where((b) => b['lineIndex'] == i).toList();
                            String displayText = line;
                            for (var blank in blanksInThisLine) {
                              int wi = blank['wordIndex'];
                              String? answer = _userAnswers[_blanks.indexOf(blank)];
                              if (answer == null) {
                                List<String> words = displayText.split(' ');
                                if (wi < words.length) words[wi] = '________';
                                displayText = words.join(' ');
                              }
                            }
                            return _buildPoemLine(displayText, i);
                          }),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const CurvedDivider(),
              // ---- Options area (dynamic height) ----
              if (_blanks.isNotEmpty && _currentBlankIndex < _blanks.length)
                Expanded(
                  flex: 2,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Padding(
                        padding: EdgeInsets.only(top: _optionsTopMargin),
                        child: Wrap(
                          spacing: 12, runSpacing: 12, alignment: WrapAlignment.center,
                          children: List.generate(_optionsList[_currentBlankIndex].length, (idx) {
                            bool isHighlighted = (_highlightedOptionIndex == idx);
                            return ElevatedButton(
                              onPressed: () => _checkAnswer(idx),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isHighlighted ? Colors.orange : Colors.white,
                                foregroundColor: Colors.deepPurple,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30), side: BorderSide(color: Colors.deepPurple.shade100)),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                              child: Text(_optionsList[_currentBlankIndex][idx], style: const TextStyle(fontSize: 18, fontFamily: 'Marhey')),
                            );
                          }),
                        ),
                      );
                    },
                  ),
                ),
              // ---- Feedback message (animated) ----
              if (_showFeedback)
                AnimatedScale(
                  scale: _feedbackScaleAnimation.value,
                  duration: const Duration(milliseconds: 300),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: _feedbackColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _feedbackMessage.contains('صحيح') ? Icons.check_circle : Icons.cancel,
                            color: _feedbackColor,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(_feedbackMessage, style: TextStyle(color: _feedbackColor, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
              // ---- Hint button ----
              Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton.icon(
                  onPressed: _useHint,
                  icon: const Icon(Icons.lightbulb),
                  label: Text('تلميح (3 طاقة) - ${_brainPower} متبقي'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}