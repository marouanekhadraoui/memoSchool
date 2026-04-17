import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import '../game_state.dart';
import 'game_details_page.dart';
import '../services/notification_service.dart';

// Game pages
import '../games/calc_page.dart';
import '../games/sudoku_page.dart';
import '../games/poem_page.dart';
import '../games/algeria_page.dart';
import 'package:momoschool/pages/dialog_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late AnimationController pulseController;
  late AnimationController fadeController;
  late AnimationController statsController;
  late AnimationController _marqueeController;
  late Timer _suggestionTimer;

  bool showGameMenu = false;

  List<Map<String, dynamic>> games = [
    {
      "name": "Calcule",
      "image": "assets/Calculadora.jpg",
      "pageBuilder": (int level) => CalcPage(gameName: 'Calcule', level: level),
    },
    {
      "name": "Sudoku",
      "image": "assets/sudoku.jpg",
      "pageBuilder": (int level) => SudokuPage(level: level),
    },
    {
      "name": "poem",
      "image": "assets/lilac.png",
      "pageBuilder": (int level) => DialogPage(gameName: 'poem', level: level),
    },
    {
      "name": "Algeria",
      "image": "assets/algeria.jpg",
      "pageBuilder": (int level) => AlgeriaGameScreen(level: level),
    },
  ];

  int _currentSuggestionIndex = 0;
  final List<Map<String, dynamic>> _suggestions = [
    {
      "title": "Improve Focus",
      "desc": "Spend 5 minutes on a distraction-free task to strengthen your concentration.",
      "icon": Icons.center_focus_strong,
    },
    {
      "title": "Boost Memory",
      "desc": "Try recalling 10 items from memory without writing them down.",
      "icon": Icons.memory,
    },
    {
      "title": "Train Logic",
      "desc": "Solve a small logical problem to activate deeper thinking.",
      "icon": Icons.psychology,
    },
    {
      "title": "Reduce Distraction",
      "desc": "Avoid multitasking for the next activity and stay fully engaged.",
      "icon": Icons.block,
    },
  ];

  @override
  void initState() {
    super.initState();

    pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);

    fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))
      ..forward();

    statsController = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..forward();

    _marqueeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    _suggestionTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted) {
        setState(() {
          _currentSuggestionIndex = (_currentSuggestionIndex + 1) % _suggestions.length;
        });
      }
    });
  }

  @override
  void dispose() {
    pulseController.dispose();
    fadeController.dispose();
    statsController.dispose();
    _marqueeController.dispose();
    _suggestionTimer.cancel();
    super.dispose();
  }

  void openMenu() => setState(() => showGameMenu = true);
  void closeMenu() => setState(() => showGameMenu = false);

  void _navigateToGame(BuildContext context, Map<String, dynamic> game) {
    closeMenu();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GameDetailsPage(
          gameName: game['name'],
          gameImage: game['image'],
          gamePageBuilder: game['pageBuilder'],
        ),
      ),
    ).then((_) {
      setState(() {});
    });
  }

  void _onPlusButtonPressed(GameState gameState) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Play games to earn points! 🎮"),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.deepPurple,
      ),
    );
  }

  // ---- Press animation for buttons ----
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final gameState = Provider.of<GameState>(context);
    
    return Scaffold(
      body: Stack(
        children: [
          // BACKGROUND gradient ----
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFF3F0FF),
                  Color(0xFFE3DAFF),
                  Color(0xFFD2C6FF),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          const Positioned.fill(child: ParticlesBackground()),

        


          // MAIN CONTENT ----
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Column(
                children: [
                  // TOP BAR (with best streak) ----
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.local_fire_department, color: Colors.deepPurple, size: 24),
                          const SizedBox(width: 6),
                          Text("${gameState.streak}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                          const SizedBox(width: 12),
                          // Best streak trophy ----
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.emoji_events, color: Colors.amber, size: 16),
                                const SizedBox(width: 4),
                                Text("${gameState.bestStreak}", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.amber)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(.7),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.stars, color: Colors.deepPurple, size: 18),
                            const SizedBox(width: 4),
                            Text("${gameState.points}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: () => _onPlusButtonPressed(gameState),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.deepPurple,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.add, color: Colors.white, size: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 15), // increased spacing ----


        //         GestureDetector(
        //   onTap: () async {
        //     final notificationService = NotificationService();
        //     await notificationService.initialize();
        //     await notificationService.requestPermissions();
        //     await notificationService.scheduleTestNotification(delayInSeconds: 5);
        //     ScaffoldMessenger.of(context).showSnackBar(
        //       const SnackBar(content: Text('📢 Test notification in 5 sec')),
        //     );
        //   },
        //   child: Container(
        //     padding: const EdgeInsets.all(8),
        //     decoration: BoxDecoration(
        //       color: Colors.white.withOpacity(0.8),
        //       shape: BoxShape.circle,
        //     ),
        //     child: const Icon(Icons.notifications_active, color: Colors.purple, size: 24),
        //   ),
        // ),
        // const SizedBox(width: 8),



                  // Logo ----
                  Center(
                    child: Image.asset(
                      "assets/memoschool.png",
                      height: 200,
                      fit: BoxFit.contain,
                    ),
                  ),

                  const SizedBox(height: 12), // increased spacing ----

                  // PLAY GAMES button with press animation (3D press effect) ----
                  GestureDetector(
                    onTapDown: (_) => setState(() => _isPressed = true),
                    onTapUp: (_) => setState(() => _isPressed = false),
                    onTapCancel: () => setState(() => _isPressed = false),
                    onTap: openMenu,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 100),
                      transform: _isPressed
                          ? Matrix4.translationValues(0, 3, 0)
                          : Matrix4.identity(),
                      child: AnimatedBuilder(
                        animation: pulseController,
                        builder: (_, __) {
                          double scale = 1 + pulseController.value * 0.03;
                          return Transform.scale(
                            scale: scale,
                            child: Container(
                              width: 220,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF551092), Color(0xFF551092)],
                                ),
                                borderRadius: BorderRadius.circular(40),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black26,
                                    offset: Offset(0, _isPressed ? 2 : 6),
                                    blurRadius: _isPressed ? 4 : 10,
                                  ),
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    offset: const Offset(2, 2),
                                    blurRadius: 0,
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Text(
                                  "PLAY GAMES",
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 24), // increased spacing ----

                  // XP Progress Bar with Neumorphism style ----
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.3),
                          offset: const Offset(-2, -2),
                          blurRadius: 6,
                        ),
                        BoxShadow(
                          color: Colors.black12,
                          offset: const Offset(3, 3),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Level ${gameState.level}", style: const TextStyle(color: Colors.deepPurple, fontSize: 12, fontWeight: FontWeight.bold)),
                            Text("${gameState.pointsToNextLevel} XP to next level", style: const TextStyle(color: Colors.deepPurple, fontSize: 10)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: gameState.xpProgress,
                            backgroundColor: Colors.white.withOpacity(0.3),
                            color: Colors.deepPurple,
                            minHeight: 6,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20), // increased spacing ----

                  // Scrollable Dashboard + Suggestions ----
                  Expanded(
                    child: FadeTransition(
                      opacity: fadeController,
                      child: ListView(
                        shrinkWrap: true,
                        physics: const BouncingScrollPhysics(),
                        children: [
                          // DASHBOARD CARD with Neumorphism + slight 3D tilt ----
                          Transform(
                            transform: Matrix4.identity()
                              ..setEntry(3, 2, 0.001)   // perspective ----
                              ..rotateX(0.02)
                              ..rotateY(0.01),
                            alignment: Alignment.center,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF1E2A3E), Color(0xFF0F1722)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.white.withOpacity(0.1),
                                    offset: const Offset(-4, -4),
                                    blurRadius: 8,
                                  ),
                                  BoxShadow(
                                    color: Colors.black45,
                                    offset: const Offset(6, 6),
                                    blurRadius: 12,
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.dashboard, color: Color(0xFFA78BFA), size: 16),
                                      const SizedBox(width: 6),
                                      const Text(
                                        "DASHBOARD",
                                        style: TextStyle(
                                          color: Color(0xFFA78BFA),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                          letterSpacing: 1.0,
                                        ),
                                      ),
                                      const Spacer(),
                                      Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFA78BFA).withOpacity(0.2),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.diamond_outlined, color: Color(0xFFA78BFA), size: 12),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Text(
                                        "JUNIOR",
                                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFA78BFA).withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: Text(
                                          "LEVEL • ${gameState.level}",
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFA78BFA)),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  
                                  Container(
                                    height: 38,
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      physics: const BouncingScrollPhysics(),
                                      child: AnimatedBuilder(
                                        animation: _marqueeController,
                                        builder: (context, child) {
                                          return Transform.translate(
                                            offset: Offset(_marqueeController.value * -120, 0),
                                            child: Row(
                                              children: List.generate(2, (_) {
                                                return Row(
                                                  children: [
                                                    _buildStatChip(Icons.memory, "Memory", gameState.memory),
                                                    const SizedBox(width: 10),
                                                    _buildStatChip(Icons.center_focus_strong, "Focus", gameState.focus),
                                                    const SizedBox(width: 10),
                                                    _buildStatChip(Icons.calculate, "Math", gameState.math),
                                                    const SizedBox(width: 10),
                                                    _buildStatChip(Icons.psychology, "Logic", gameState.logic),
                                                  ],
                                                );
                                              }),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 24), 

                          // SUGGESTION CARD with 3D tilt and Neumorphism ----
                          Transform(
                            transform: Matrix4.identity()
                              ..setEntry(3, 2, 0.001)
                              ..rotateX(0.01)
                              ..rotateY(-0.01),
                            alignment: Alignment.center,
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 600),
                              transitionBuilder: (child, animation) {
                                return FadeTransition(
                                  opacity: animation,
                                  child: SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(0.2, 0),
                                      end: Offset.zero,
                                    ).animate(animation),
                                    child: child,
                                  ),
                                );
                              },
                              child: Container(
                                key: ValueKey(_currentSuggestionIndex),
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF6B4EFF), Color(0xFF8B6BFF)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.white.withOpacity(0.2),
                                      offset: const Offset(-3, -3),
                                      blurRadius: 6,
                                    ),
                                    BoxShadow(
                                      color: Colors.black38,
                                      offset: const Offset(5, 5),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.15),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        _suggestions[_currentSuggestionIndex]['icon'],
                                        color: Colors.white,
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _suggestions[_currentSuggestionIndex]['title'],
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 13,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _suggestions[_currentSuggestionIndex]['desc'],
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 11,
                                              height: 1.2,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // GAME SELECTION MENU (with 3D press effect on game items) ----
          if (showGameMenu) ...[
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(color: Colors.black.withOpacity(0.3)),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6F24CA).withOpacity(0.45),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.1),
                          offset: const Offset(-2, -2),
                          blurRadius: 4,
                        ),
                        BoxShadow(
                          color: Colors.black26,
                          offset: const Offset(4, 4),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Games Panel", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                            GestureDetector(
                              onTap: closeMenu,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close, size: 24, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.local_fire_department, color: Colors.white, size: 14),
                              const SizedBox(width: 4),
                              Text("${gameState.streak}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12)),
                              const SizedBox(width: 10),
                              const Icon(Icons.stars, color: Colors.white, size: 14),
                              const SizedBox(width: 4),
                              Text("${gameState.points}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        GridView.count(
                          shrinkWrap: true,
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          physics: const NeverScrollableScrollPhysics(),
                          children: games.map((g) => gameItem(g)).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(40),
                        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.1),
                            offset: const Offset(-1, -1),
                            blurRadius: 2,
                          ),
                          BoxShadow(
                            color: Colors.black12,
                            offset: const Offset(2, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: const Text(
                        "Select a game",
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String label, int value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.1),
            offset: const Offset(-1, -1),
            blurRadius: 2,
          ),
          BoxShadow(
            color: Colors.black12,
            offset: const Offset(1, 1),
            blurRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFA78BFA), size: 12),
          const SizedBox(width: 4),
          Text(
            "$label $value",
            style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget gameItem(Map<String, dynamic> game) {
    // Local press state for each game item (using StatefulBuilder or simple setState? 
    // We'll use a simple GestureDetector with local state via a StatefulBuilder in the grid? 
    // Easier: use a separate widget or manage with setState inside the builder.
    // For simplicity, I'll use a StatefulBuilder in the grid item builder? 
    // Actually, we can use a StatefulBuilder inside each gameItem by returning a StatefulBuilder widget.
    // To keep code clean, I'll create a small Stateful widget inside.
    return _GameItem(
      game: game,
      onTap: () => _navigateToGame(context, game),
    );
  }
}

// Helper Stateful widget for game item with press animation
class _GameItem extends StatefulWidget {
  final Map<String, dynamic> game;
  final VoidCallback onTap;

  const _GameItem({required this.game, required this.onTap});

  @override
  State<_GameItem> createState() => _GameItemState();
}

class _GameItemState extends State<_GameItem> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        transform: _isPressed
            ? Matrix4.translationValues(0, 2, 0)
            : Matrix4.identity(),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF7B61FF), Color(0xFF4DA6FF)],
          ).withOpacity(0.5),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withOpacity(0.2),
              offset: const Offset(-2, -2),
              blurRadius: 4,
            ),
            BoxShadow(
              color: Colors.black26,
              offset: Offset(0, _isPressed ? 2 : 4),
              blurRadius: _isPressed ? 4 : 8,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(widget.game['image'], width: 40, height: 40),
            const SizedBox(height: 8),
            Text(widget.game['name'],
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}


class ParticlesBackground extends StatefulWidget {
  const ParticlesBackground({super.key});

  @override
  State<ParticlesBackground> createState() => _ParticlesBackgroundState();
}

class _ParticlesBackgroundState extends State<ParticlesBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  final Random random = Random();
  final List<Offset> particles = [];

  @override
  void initState() {
    super.initState();
    controller = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();
    for (int i = 0; i < 100; i++) {
      particles.add(Offset(random.nextDouble(), random.nextDouble()));
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        return CustomPaint(
          painter: ParticlePainter(particles, controller.value),
        );
      },
    );
  }
}

class ParticlePainter extends CustomPainter {
  final List<Offset> particles;
  final double progress;

  ParticlePainter(this.particles, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF7B61FF).withOpacity(0.08);
    for (var p in particles) {
      double x = p.dx * size.width;
      double y = (p.dy * size.height + progress * 80) % size.height;
      canvas.drawCircle(Offset(x, y), 3, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class BrainStatBar extends StatelessWidget {
  final String title;
  final double value;

  const BrainStatBar({super.key, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Stack(
          children: [
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: Colors.white30,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            FractionallySizedBox(
              widthFactor: value,
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7B61FF), Color(0xFF4DA6FF)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 40),
      ],
    );
  }
}

extension LinearGradientOpacity on LinearGradient {
  LinearGradient withOpacity(double opacity) {
    return LinearGradient(
      colors: colors.map((c) => c.withOpacity(opacity)).toList(),
      begin: begin,
      end: end,
      stops: stops,
      tileMode: tileMode,
    );
  }
}