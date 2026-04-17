

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_drawing/path_drawing.dart';
import 'package:vibration/vibration.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/wilaya.dart';
import '../data/wilayas_data.dart';
import '../controllers/game_controller.dart';
import '../widgets/algeria_map_painter.dart';
import '../game_state.dart';

// ============================================================================
// GlassCard  ----
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

// ============================================================================
// PausePage 
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
// AlgeriaGameScreen الرئيسية
// ============================================================================

class AlgeriaGameScreen extends StatefulWidget {
  final int level;
  const AlgeriaGameScreen({super.key, required this.level});

  @override
  State<AlgeriaGameScreen> createState() => _AlgeriaGameScreenState();
}

class _AlgeriaGameScreenState extends State<AlgeriaGameScreen> {
  late GameController _controller;
  late List<Wilaya> _wilayas;
  bool _showAllNames = false;

  // منع تكرار ظهور الحوارات
  bool _dialogShown = false;

  // الصوت والاهتزاز
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  final AudioPlayer _audioCorrect = AudioPlayer();
  final AudioPlayer _audioWrong = AudioPlayer();

  // لون خلفية الكارد (يمكن تغييره يدويًا)
  Color _cardBackgroundColor = const Color(0xFFD8CBE1); // أزرق بنفسجي

  @override
  void initState() {
    super.initState();
    _wilayas = getAllWilayas();
    _initCenters();

    final gameState = Provider.of<GameState>(context, listen: false);
    _controller = GameController(
      globalGameState: gameState,
      currentLevel: widget.level,
      allWilayas: _wilayas,
    );
    _controller.addListener(_onControllerUpdate);
    _loadSettings();
    _preloadSounds();
  }

  void _initCenters() {
    for (var w in _wilayas) {
      if (w.pathString != null) {
        w.path = parseSvgPathData(w.pathString!);
      } else {
        w.path = _parsePolygonPoints(w.pointsString!);
      }
      if (w.translateX != 0 || w.translateY != 0) {
        final matrix = Matrix4.translationValues(w.translateX, w.translateY, 0);
        w.path = w.path.transform(matrix.storage);
      }
      w.center = w.path.getBounds().center;
    }
  }

  Path _parsePolygonPoints(String pointsStr) {
    final path = Path();
    final points = pointsStr.trim().split(RegExp(r'\s+'));
    for (int i = 0; i < points.length; i++) {
      final coords = points[i].split(',');
      if (coords.length != 2) continue;
      final x = double.parse(coords[0]);
      final y = double.parse(coords[1]);
      if (i == 0) path.moveTo(x, y);
      else path.lineTo(x, y);
    }
    path.close();
    return path;
  }

  void _onControllerUpdate() {
    setState(() {});
    if (_controller.phase == GamePhase.revealing) {
      _showAllNames = true;
      _dialogShown = false; // إعادة تعيين عند بدء مستوى جديد
    } else if (_controller.phase == GamePhase.playing && _showAllNames) {
      _showAllNames = false;
    }

    // التحقق من الفوز أو الخسارة وظهور الحوار
    if (_controller.phase == GamePhase.levelComplete && !_dialogShown) {
      _dialogShown = true;
      _onGameWin();
    } else if (_controller.phase == GamePhase.gameOver && !_dialogShown) {
      _dialogShown = true;
      _onGameLoss();
    }
  }

  // ========== إعدادات الصوت والاهتزاز ==========
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _soundEnabled = prefs.getBool('algeria_sound_enabled') ?? true;
      _vibrationEnabled = prefs.getBool('algeria_vibration_enabled') ?? true;
    });
  }

  Future<void> _saveSoundSetting(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('algeria_sound_enabled', value);
  }

  Future<void> _saveVibrationSetting(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('algeria_vibration_enabled', value);
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

  Future<void> _preloadSounds() async {
    try {
      await _audioCorrect.setSourceAsset('sounds/correct.wav');
      await _audioWrong.setSourceAsset('sounds/wrong.wav');
    } catch (e) {}
  }

  void _playCorrectSound() async {
    if (!_soundEnabled) return;
    try { await _audioCorrect.play(AssetSource('sounds/correct.wav')); } catch(e) {}
  }

  void _playWrongSound() async {
    if (!_soundEnabled) return;
    try { await _audioWrong.play(AssetSource('sounds/wrong.wav')); } catch(e) {}
  }

  void _vibrate() async {
    if (!_vibrationEnabled) return;
    try {
      if (await Vibration.hasVibrator() ?? false) Vibration.vibrate(duration: 100);
    } catch(e) {}
  }

  // ========== منطق الاختيار ==========
  double _distanceToPath(Path path, Offset point) {
    double minDist = double.infinity;
    final metrics = path.computeMetrics();
    for (var metric in metrics) {
      final length = metric.length;
      final steps = (length / 8).clamp(30, 120).toInt();
      for (int i = 0; i <= steps; i++) {
        final pos = metric.getTangentForOffset((i / steps) * length);
        if (pos != null) {
          final d = (pos.position - point).distance;
          if (d < minDist) minDist = d;
        }
      }
    }
    return minDist;
  }

  Wilaya? _getBestMatchWilaya(Offset point) {
    Wilaya? best;
    double bestScore = double.infinity;
    for (var w in _wilayas) {
      final bounds = w.path.getBounds();
      final expandedBounds = bounds.inflate(10);
      if (!expandedBounds.contains(point)) continue;
      final sizeFactor = (bounds.width * bounds.height).clamp(2000, 50000);
      final tolerance = (20000 / sizeFactor).clamp(8, 25);
      double score;
      if (w.path.contains(point)) {
        score = 0;
      } else {
        final edgeDist = _distanceToPath(w.path, point);
        final centerDist = (w.center - point).distance;
        score = edgeDist * 0.7 + centerDist * 0.3;
      }
      if (w.id == _controller.currentTargetId) score *= 0.6;
      if (score > tolerance * 5) continue;
      if (score < bestScore) {
        bestScore = score;
        best = w;
      }
    }
    return best;
  }

  Offset _screenToMap(Offset localPos, Size size) {
    final rect = _controller.viewRect;
    final scaleX = size.width / rect.width;
    final scaleY = size.height / rect.height;
    final scale = (scaleX < scaleY ? scaleX : scaleY) * _controller.zoom;
    final dx = (size.width - rect.width * scale) / 2;
    final dy = (size.height - rect.height * scale) / 2;
    return Offset(
      rect.left + (localPos.dx - dx) / scale,
      rect.top + (localPos.dy - dy) / scale,
    );
  }

  // ========== دوال الفوز والخسارة ( ==========
  void _onGameWin() {
    _playCorrectSound();
    _showWinDialog();
  }

  void _onGameLoss() {
    _playWrongSound();
    _vibrate();
    _showLossDialog();
  }

  void _showWinDialog() {
    showDialog(
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
                Text(
                  '🎉 Victory! 🎉',
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'PTSerif'),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Text(
                  'Congratulations!\nYou completed level ${widget.level} in ${_formatDuration(_controller.elapsedTime)}\nScore: ${_controller.score}\nMistakes: ${_controller.mistakes}',
                  style: const TextStyle(fontSize: 16, color: Colors.white70, fontFamily: 'PTSerif'),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLossDialog() {
    showDialog(
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
                const Icon(Icons.sentiment_dissatisfied, size: 64, color: Colors.redAccent),
                const SizedBox(height: 16),
                Text(
                  'Game Over',
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'PTSerif'),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Text(
                  'You made ${_controller.maxMistakes} mistakes.\nBetter luck next time!',
                  style: const TextStyle(fontSize: 16, color: Colors.white70, fontFamily: 'PTSerif'),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _controller.resetLevel();
                        _dialogShown = false;
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.deepPurple),
                      child: const Text('Try Again'),
                    ),
                    const SizedBox(width: 16),
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _pauseGame() {
    if (_controller.isGameFinished) return;
    _controller.pauseTimer();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => PausePage(
          onResume: () {
            Navigator.pop(ctx);
            _controller.resumeTimer();
            setState(() {});
          },
          onRestart: () {
            Navigator.pop(ctx);
            _controller.resetLevel();
            _dialogShown = false;
          },
          onExit: () {
            Navigator.pop(ctx);
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final targetName = _controller.currentTargetId != null
        ? _wilayas.firstWhere((w) => w.id == _controller.currentTargetId).name
        : '---';
    
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Algeria Map - Level ${widget.level}'),
          centerTitle: true,
          backgroundColor: Colors.white,
          foregroundColor: Colors.deepPurple,
          elevation: 0,
          actions: [
            IconButton(
              icon: Icon(_soundEnabled ? Icons.volume_up : Icons.volume_off, color: const Color(0xFF7B61FF)),
              onPressed: _toggleSound,
            ),
            IconButton(
              icon: Icon(_vibrationEnabled ? Icons.vibration : Icons.notifications_off, color: const Color(0xFF7B61FF)),
              onPressed: _toggleVibration,
            ),
            IconButton(
              icon: const Icon(Icons.pause_circle_filled, color: Color(0xFF7B61FF)),
              onPressed: _pauseGame,
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
              // شريط المعلومات العلوي
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _infoChip(Icons.score, '${_controller.score}'),
                    _infoChip(Icons.error_outline, '${_controller.mistakes}/${_controller.maxMistakes}'),
                    _infoChip(Icons.timer, _formatDuration(_controller.elapsedTime)),
                    _infoChip(Icons.bolt, '${_controller.hintEnergy}'),
                  ],
                ),
              ),
              // شريط التقدم + رسالة "تذكر أسماء الولايات" (يختفي فورًا دون حركة)
              if (_controller.phase == GamePhase.revealing)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.deepPurple.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.memory, size: 18, color: Colors.deepPurple),
                            SizedBox(width: 6),
                            Text(
                              'تذكر أسماء الولايات',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      LinearProgressIndicator(
                        value: _controller.revealSecondsLeft / _controller.revealDuration,
                        backgroundColor: Colors.grey[300],
                        color: Colors.deepPurple,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_controller.revealSecondsLeft} ثانية متبقية',
                        style: const TextStyle(fontSize: 12, color: Colors.deepPurple),
                      ),
                    ],
                  ),
                ),
              // إطار الخريطة (لون الخلفية قابل للتعديل)
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _cardBackgroundColor,
                        border: Border.all(width: 2, color: Colors.deepPurple.shade100),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(color: const Color(0xFF372C60), blurRadius: 0, offset: const Offset(6, 4)),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final size = constraints.biggest;
                            return GestureDetector(
                              onTapUp: (details) {
                                if (_controller.phase != GamePhase.playing || _controller.isGameFinished) return;
                                final mapPoint = _screenToMap(details.localPosition, size);
                                final selected = _getBestMatchWilaya(mapPoint);
                                if (selected != null) {
                                  if (selected.id == _controller.currentTargetId) {
                                    _playCorrectSound();
                                  } else {
                                    _playWrongSound();
                                    _vibrate();
                                  }
                                  _controller.onWilayaTap(selected);
                                }
                              },
                              child: CustomPaint(
                                size: size,
                                painter: AlgeriaMapPainter(
                                  wilayas: _wilayas,
                                  controller: _controller,
                                  viewRect: _controller.viewRect,
                                  zoom: _controller.zoom,
                                  showAllNames: _showAllNames,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // نص البحث أسفل الخريطة
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.search, color: Colors.deepPurple, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'ابحث عن: $targetName',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple, fontFamily: 'PTSerif'),
                      ),
                    ],
                  ),
                ),
              ),
              // أزرار التحكم
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
          BoxShadow(color: const Color(0xFF372C60), blurRadius: 0, offset: const Offset(1, 2)),
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

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _actionButton(
          icon: Icons.lightbulb_outline,
          label: 'Hint',
          onPressed: () {
            if (!_controller.useHint()) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Not enough hint energy!')),
              );
            } else {
              _playCorrectSound();
            }
          },
        ),
        _actionButton(
          icon: Icons.refresh,
          label: 'Reset',
          onPressed: () {
            _controller.resetLevel();
            _dialogShown = false;
          },
        ),
        _actionButton(
          icon: Icons.map,
          label: _showAllNames ? 'Hide Names' : 'Show Names',
          onPressed: () {
            setState(() {
              _showAllNames = !_showAllNames;
            });
          },
        ),
      ],
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Column(
      children: [
        IconButton(
          onPressed: onPressed,
          icon: Icon(icon, color: Colors.black54),
          style: IconButton.styleFrom(
            backgroundColor: Colors.white,
            padding: const EdgeInsets.all(12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontFamily: 'PTSerif', color: Colors.black54),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    _audioCorrect.dispose();
    _audioWrong.dispose();
    _controller.dispose();
    super.dispose();
  }
}