import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../game_state.dart';

class GameDetailsPage extends StatefulWidget {
  final String gameName;
  final String gameImage;
  final Widget Function(int level) gamePageBuilder;

  const GameDetailsPage({
    super.key,
    required this.gameName,
    required this.gameImage,
    required this.gamePageBuilder,
  });

  @override
  State<GameDetailsPage> createState() => _GameDetailsPageState();
}

class _GameDetailsPageState extends State<GameDetailsPage> {
  int _selectedLevel = 1;

  List<Map<String, dynamic>> getSkillsWithIcons() {
    switch (widget.gameName.toLowerCase()) {
      case 'calcule':
        return [
          {'title': 'Mental Math', 'desc': 'Improve speed and accuracy in arithmetic operations.', 'icon': Icons.calculate},
          {'title': 'Focus', 'desc': 'Enhance concentration under time pressure.', 'icon': Icons.center_focus_strong},
          {'title': 'Problem-solving', 'desc': 'Apply logic to find correct answers quickly.', 'icon': Icons.psychology},
        ];
      case 'sudoku':
        return [
          {'title': 'Logical Thinking', 'desc': 'Develop systematic deduction and pattern recognition.', 'icon': Icons.grid_on},
          {'title': 'Patience', 'desc': 'Learn to persist through complex puzzles.', 'icon': Icons.timer},
          {'title': 'Memory', 'desc': 'Remember numbers and constraints across the grid.', 'icon': Icons.memory},
        ];
      case 'poem':
        return [
          {'title': 'Creativity', 'desc': 'Explore language and express ideas artistically.', 'icon': Icons.brush},
          {'title': 'Vocabulary', 'desc': 'Expand your word bank and linguistic skills.', 'icon': Icons.menu_book},
          {'title': 'Emotional Intelligence', 'desc': 'Understand and convey emotions through poetry.', 'icon': Icons.favorite},
        ];
      case 'algeria':
        return [
          {'title': 'Cultural Knowledge', 'desc': 'Learn about Algeria’s history and geography.', 'icon': Icons.public},
          {'title': 'Memory', 'desc': 'Recall facts and landmarks accurately.', 'icon': Icons.memory},
          {'title': 'Curiosity', 'desc': 'Spark interest in world cultures.', 'icon': Icons.explore},
        ];
      default:
        return [
          {'title': 'Critical Thinking', 'desc': 'Sharpen analytical abilities.', 'icon': Icons.psychology},
          {'title': 'Adaptability', 'desc': 'Adjust strategies as challenges change.', 'icon': Icons.change_circle},
          {'title': 'Persistence', 'desc': 'Build resilience through practice.', 'icon': Icons.fitness_center},
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final gameState = Provider.of<GameState>(context);
    final unlockedLevel = gameState.getUnlockedLevel(widget.gameName);
debugPrint('🏠 GameDetailsPage: gameName=${widget.gameName}, unlockedLevel=$unlockedLevel');
    final skills = getSkillsWithIcons();
    

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF7B2F9D), Color(0xFF4A1D6E)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.local_fire_department, color: Colors.white, size: 24),
                          const SizedBox(width: 6),
                          Text('${gameState.streak}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 16),
                          const Icon(Icons.stars, color: Colors.white, size: 24),
                          const SizedBox(width: 6),
                          Text('${gameState.points}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.help_outline, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, color: Colors.white, size: 20),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  widget.gameName.toUpperCase(),
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.5),
                ),
                const SizedBox(height: 20),
                Container(
                  height: 150,
                  width: 150,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(30),
                    image: DecorationImage(
                      image: AssetImage(widget.gameImage),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                const Text('LEVEL', style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    int level = index + 1;
                    bool isUnlocked = level <= unlockedLevel;
                    bool isSelected = _selectedLevel == level;

                    return GestureDetector(
                      onTap: isUnlocked
                          ? () {
                              setState(() {
                                _selectedLevel = level;
                              });
                            }
                          : null,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? const Color(0xFFD9A7FF)
                              : Colors.white.withOpacity(isUnlocked ? 0.2 : 0.1),
                          border: Border.all(
                            color: isSelected ? Colors.white : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: isUnlocked
                              ? Text(
                                  '$level',
                                  style: TextStyle(
                                    color: isSelected ? Colors.deepPurple : Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : const Icon(Icons.lock, color: Colors.white54, size: 20),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 30),
                
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('SKILLS TRAINED', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 12),
                        Expanded(
                          child: ListView.builder(
                            itemCount: skills.length,
                            itemBuilder: (context, index) {
                              final skill = skills[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFD9A7FF).withOpacity(0.3),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(skill['icon'] as IconData, color: Colors.white, size: 24),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(skill['title'] as String, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                          const SizedBox(height: 4),
                                          Text(skill['desc'] as String, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // زر START (معدل) ----
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                  child: GestureDetector(
                    onTap: () async {
                      if (_selectedLevel <= unlockedLevel) {
                        final gamePage = widget.gamePageBuilder(_selectedLevel);
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => gamePage),
                        );
                        // تحديث الصفحة بعد العودة من اللعبة ----
                        setState(() {});
                        final newUnlocked = Provider.of<GameState>(context, listen: false).getUnlockedLevel(widget.gameName);
debugPrint('🔄 بعد العودة: unlockedLevel = $newUnlocked');
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Complete previous level first!')),
                        );
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFFD9A7FF), Color(0xFFB87BFF)]),
                        borderRadius: BorderRadius.circular(40),
                        boxShadow: [
                          BoxShadow(color: Colors.purple.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 5)),
                        ],
                      ),
                      child: const Center(child: Text('START', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white))),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}