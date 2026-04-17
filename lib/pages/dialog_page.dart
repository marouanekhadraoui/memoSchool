import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:momoschool/games/poem_page.dart';

class DialogPage extends StatefulWidget {
  final String gameName;
  final int level;

  const DialogPage({super.key, required this.gameName, required this.level});

  @override
  State<DialogPage> createState() => _DialogPageState();
}

class _DialogPageState extends State<DialogPage> with TickerProviderStateMixin {
  Map<String, dynamic>? _selectedPoem;
  bool _isLoading = true;
  String? _errorMessage;

  Timer? _timer;
  int _remainingSeconds = 20;

  // Animation controllers ----
  late AnimationController _pulseController;
  late AnimationController _progressController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    );
    _loadPoemForLevel();
  }

  Future<void> _loadPoemForLevel() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/data/poems.json');
      final List<dynamic> poems = json.decode(jsonString);
      final List<dynamic> filtered = poems.where((p) => p['level'] == widget.level).toList();

      if (filtered.isEmpty) {
        setState(() {
          _errorMessage = 'لا توجد قصائد للمستوى ${widget.level}';
          _isLoading = false;
        });
        return;
      }

      final randomIndex = DateTime.now().millisecondsSinceEpoch % filtered.length;
      setState(() {
        _selectedPoem = Map<String, dynamic>.from(filtered[randomIndex]);
        _isLoading = false;
      });
      _startTimer();
      _progressController.forward();
    } catch (e) {
      setState(() {
        _errorMessage = 'خطأ في تحميل القصائد: $e';
        _isLoading = false;
      });
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 1) {
        _timer?.cancel();
        if (mounted) _navigateToPoemPage();
      } else {
        setState(() => _remainingSeconds--);
      }
    });
  }

  void _skipReading() {
    _timer?.cancel();
    _navigateToPoemPage();
  }

  void _navigateToPoemPage() {
    if (_selectedPoem == null) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => PoemPage(
          gameName: widget.gameName,
          level: widget.level,
          poem: _selectedPoem!,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  BoxDecoration _gradientDecoration() {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.purple.shade900.withOpacity(0.95),
          Colors.deepPurple.shade700.withOpacity(0.95),
          Colors.indigo.shade900.withOpacity(0.95),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
          decoration: _gradientDecoration(),
          child: SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Colors.deepPurple),
                  const SizedBox(height: 20),
                  Text(
                    'جاري تحميل القصيدة للمستوى ${widget.level}...',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
          decoration: _gradientDecoration(),
          child: SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 60, color: Colors.redAccent),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.deepPurple,
                    ),
                    child: const Text('العودة'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final lines = List<String>.from(_selectedPoem!['lines'] ?? []);
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: _gradientDecoration(),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0), // Reduced padding for more space ----
              child: GlassCard(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header with timer and skip button ----
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Animated timer badge ----
                          AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, _) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2 + _pulseController.value * 0.1),
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(color: Colors.white38),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.timer, color: Colors.white70, size: 20),
                                    const SizedBox(width: 6),
                                    Text(
                                      '$_remainingSeconds ث',
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          TextButton.icon(
                            onPressed: _skipReading,
                            icon: const Icon(Icons.skip_next, color: Colors.white70),
                            label: const Text('تخطي القراءة', style: TextStyle(color: Colors.white70)),
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.1),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Poem title (if exists) ----
                    if (_selectedPoem!.containsKey('title') && _selectedPoem!['title'] != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          _selectedPoem!['title'],
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [Shadow(blurRadius: 6, color: Colors.black26)],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                    // Scrollable poem content with FIXED overflow solution ----
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          children: List.generate(lines.length, (index) {
                            return Container(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              alignment: index.isEven ? Alignment.centerRight : Alignment.centerLeft,
                              child: Text(
                                lines[index],
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontFamily: 'Marhey',
                                  color: Colors.white,
                                  height: 1.6,
                                ),
                                textAlign: index.isEven ? TextAlign.right : TextAlign.left,
                              ),
                            );
                          }),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Animated progress bar ----
                    AnimatedBuilder(
                      animation: _progressController,
                      builder: (context, _) {
                        return LinearProgressIndicator(
                          value: _remainingSeconds / 20,
                          backgroundColor: Colors.white24,
                          color: Colors.amber.shade300,
                          minHeight: 6,
                          borderRadius: BorderRadius.circular(3),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'اقرأ القصيدة جيداً قبل بدء التحدي',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 20),

                    // Start button with pulse animation ----
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, _) {
                        return ElevatedButton.icon(
                          onPressed: _skipReading,
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('ابدأ التحدي الآن'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.deepPurple,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            elevation: 4 + _pulseController.value * 4,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// GlassCard (unchanged but used properly) ----
class GlassCard extends StatelessWidget {
  final Widget child;
  const GlassCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700), // Limit height to prevent overflow on very large screens ----
      padding: const EdgeInsets.all(20),
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