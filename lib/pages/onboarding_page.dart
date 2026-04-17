import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_page.dart';
import 'dart:ui' as ui; 
import 'dart:math';
import '../onbording/onboarding_first.dart';
import '../onbording/onboarding_second.dart';
import '../onbording/onboarding_fourth.dart';
import '../onbording/onboarding_third.dart';
// import 'package:font_awesome_flutter/font_awesome_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final firstTime = prefs.getBool('first_time') ?? true;

  runApp(MemoSchoolApp(firstTime: firstTime));
}

class MemoSchoolApp extends StatelessWidget {
  final bool firstTime;
  const MemoSchoolApp({super.key, required this.firstTime});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Memoschool',
      theme: ThemeData(
        primarySwatch: Colors.purple,
      ),
      home: firstTime ? const OnboardingScreen() : const HomePage(),
    );
  }
}

// ------------------ Onboarding ------------------
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}


class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _controller = PageController();
  int currentPage = 0;

  // ------------  Brain Challenge -------------
  final Random _random = Random();
   
  int totalQuestions = 4;      
  int currentQuestion = 0;     
  bool secondChance = false;   

  int a = 0;
  int b = 0;
  int correctAnswer = 0;
  List<int> options = [];

  int brainPower = 0; // من 0 إلى 10
  int secondsLeft = 5;

  bool answered = false;
  int? selectedIndex;
  Color feedbackColor = Colors.transparent;
  String feedbackText = "";

  // Animation للوغو بسيط ----
  late AnimationController _logoController;
  late Animation<double> _logoScale;

  // Animation for brain pulse ----
  late AnimationController _brainPulseController;

  // Progress for neural network (0.0 to 1.0) ----
  double _networkProgress = 0.0;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _logoScale = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOut),
    );

    // Initialize brain pulse controller ----
    _brainPulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    // Simulate network progress for demo ----
    _simulateNetworkProgress();

    generateQuestion(); 
  }

  void _simulateNetworkProgress() async {
    // Simulate progress increasing over time
    for (int i = 1; i <= 10; i++) {
      await Future.delayed(const Duration(milliseconds: 300));
      setState(() {
        _networkProgress = i / 10;
      });
    }
  }

  void _startTraining() {
    _completeOnboarding();
  }

  @override
  void dispose() {
    _controller.dispose();
    _logoController.dispose();
    _brainPulseController.dispose();
    super.dispose();
  }

  
  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('first_time', false);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomePage()),
    );
  }

  // ---------------- Brain Challenge Logic ----------------
  void generateQuestion() {
    if (currentQuestion >= totalQuestions) {
      
      _controller.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
      return;
    }

    a = _random.nextInt(8) + 2;
    b = _random.nextInt(8) + 2;

    correctAnswer = a + b;

    options = [
      correctAnswer,
      correctAnswer + _random.nextInt(3) + 1,
      correctAnswer - (_random.nextInt(3) + 1),
    ];

    options.shuffle();

    answered = false;
    selectedIndex = null;
    feedbackColor = Colors.transparent;
    feedbackText = "";
    secondsLeft = 5;
    secondChance = false;

    currentQuestion++; 

    setState(() {});
  }

  void checkAnswer(int answer, int index) {
    if (answered) return;

    setState(() {
      answered = true;
      selectedIndex = index;
    });

    if (answer == correctAnswer) {
      setState(() {
        feedbackColor = Colors.green;
        feedbackText = "Brilliant! Your brain loves challenges.";
        brainPower = (brainPower + 1).clamp(0, 10);
        secondChance = false;
      });

      Future.delayed(const Duration(seconds: 1), () {
        generateQuestion();
      });

    } else {
      if (!secondChance) {
        
        setState(() {
          feedbackColor = Colors.red;
          feedbackText = "Oops! Try again — you have one more chance!";
          answered = false; 
          secondChance = true;
        });
      } else {
        
        setState(() {
          feedbackColor = Colors.red;
          feedbackText = "Oops! The correct answer was $correctAnswer.";
          secondChance = false;
        });

        Future.delayed(const Duration(seconds: 1), () {
          generateQuestion();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: PageView(
        controller: _controller,
        onPageChanged: (index) {
          setState(() => currentPage = index);
        },
        children: [
          // ---------- الشاشة 1: الترحيب ----------
          OnboardingFirst(controller: _controller),

          // ---------- الشاشة 2: الفكرة الأساسية ----------
          OnboardingSecond(controller: _controller),

          // ---------- الشاشة 3: Brain Challenge ----------
          OnboardingThird(controller: _controller),

// ---------- الشاشة 4: Neural Brain Network ----------
          OnboardingFourth(controller: _controller),

        ],
      ),
    );
  }
}


/// ---------- Painter ----------
class NeuralPainterWithSparksCurved extends CustomPainter {
  final List<Offset> nodesPositions;
  final double sparkAnimation;

  NeuralPainterWithSparksCurved({
    required this.nodesPositions,
    required this.sparkAnimation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blueAccent
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final sparkPaint = Paint()
      ..color = Colors.yellow
      ..style = PaintingStyle.fill;

    
    for (int i = 0; i < nodesPositions.length; i++) {
      for (int j = i + 1; j < nodesPositions.length; j++) {
        final p1 = nodesPositions[i];
        final p2 = nodesPositions[j];

        
        final mid = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2 - 20);
        final path = Path()..moveTo(p1.dx, p1.dy);
        path.quadraticBezierTo(mid.dx, mid.dy, p2.dx, p2.dy);
        canvas.drawPath(path, paint);

        
        final t = sparkAnimation;
        final dx = (1 - t) * (1 - t) * p1.dx + 2 * (1 - t) * t * mid.dx + t * t * p2.dx;
        final dy = (1 - t) * (1 - t) * p1.dy + 2 * (1 - t) * t * mid.dy + t * t * p2.dy;
        canvas.drawCircle(Offset(dx, dy), 4, sparkPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant NeuralPainterWithSparksCurved oldDelegate) => true;
}

class NeuralPainterWithSparks extends CustomPainter {
  final List<Offset> nodesPositions;
  final double progress;
  final double sparkAnimation; 

  NeuralPainterWithSparks({
    required this.nodesPositions,
    required this.progress,
    required this.sparkAnimation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 1.5;

    final sparkPaint = Paint()
      ..color = Colors.yellow
      ..style = PaintingStyle.fill;

    for (int i = 0; i < nodesPositions.length; i++) {
      for (int j = i + 1; j < nodesPositions.length; j++) {
      
        canvas.drawLine(nodesPositions[i], nodesPositions[j], paint);

        
        final dx = nodesPositions[i].dx +
            (nodesPositions[j].dx - nodesPositions[i].dx) * sparkAnimation;
        final dy = nodesPositions[i].dy +
            (nodesPositions[j].dy - nodesPositions[i].dy) * sparkAnimation;

        canvas.drawCircle(Offset(dx, dy), 4, sparkPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant NeuralPainterWithSparks oldDelegate) => true;
}

class NeuralPainterFull extends CustomPainter {
  final List<Offset> nodesPositions;

  NeuralPainterFull({required this.nodesPositions});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 1.5;

    for (int i = 0; i < nodesPositions.length; i++) {
      for (int j = i + 1; j < nodesPositions.length; j++) {
        canvas.drawLine(nodesPositions[i], nodesPositions[j], paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant NeuralPainterFull oldDelegate) => false;
}






// ------------------ أزرار تجربة اللعبة ------------------
class _AnswerButton extends StatelessWidget {
  final String text;
  final bool correct;
  const _AnswerButton({required this.text, required this.correct, super.key});
  Color get _feedbackColor => correct ? Colors.green : Colors.red;
  String get _feedbackText => correct ? 'صحيح!' : 'خطأ!';
  Color get _buttonColor => correct ? Colors.green.shade100 : Colors.blue.shade100;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final color = correct ? Colors.green : Colors.red;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(correct ? 'صحيح!' : 'خطأ!'),
            backgroundColor: color,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.blue.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(text, style: const TextStyle(fontSize: 22)),
      ),
    );
  }
}

// ------------------ أزرار اختيار التفضيلات ------------------
class _PreferenceButton extends StatelessWidget {
  final IconData icon;
  final String label;
  const _PreferenceButton({required this.icon, required this.label, super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [Colors.blue.shade200, Colors.purple.shade200]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, size: 40, color: Colors.white),
          ),
          const SizedBox(height: 10),
          Text(label, style: const TextStyle(fontSize: 18)),
        ],
      ),
    );
  }
}


