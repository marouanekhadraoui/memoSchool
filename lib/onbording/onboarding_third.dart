import 'dart:math';
import 'package:flutter/material.dart';

class OnboardingThird extends StatefulWidget {
  final PageController controller;
  const OnboardingThird({super.key, required this.controller});

  @override
  State<OnboardingThird> createState() => _OnboardingThirdState();
}

class _OnboardingThirdState extends State<OnboardingThird>
    with SingleTickerProviderStateMixin {
  final Random _random = Random();

  int totalQuestions = 4;
  int currentQuestion = 1;
  bool secondChance = false;

  int a = 0, b = 0, correctAnswer = 0;
  List<int> options = [];

  int brainPower = 0;

  bool answered = false;
  int? selectedIndex;
  Color feedbackColor = Colors.transparent;
  String feedbackText = "";

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      lowerBound: 0.95,
      upperBound: 1.0,
    );
    _scaleAnimation =
        Tween<double>(begin: 1, end: 0.95).animate(_animationController);
    generateQuestion();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void generateQuestion() {
    if (currentQuestion > totalQuestions) {
      widget.controller.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
      return;
    }

    // نطاق 0 - 99 ----
    a = _random.nextInt(10);
    b = _random.nextInt(10);
    correctAnswer = a + b;

    options = [
      correctAnswer,
      correctAnswer + _random.nextInt(5) + 1,
      correctAnswer - (_random.nextInt(5) + 1),
      correctAnswer + (_random.nextInt(5) + 6),
    ];
    options.shuffle();

    answered = false;
    selectedIndex = null;
    feedbackColor = Colors.transparent;
    feedbackText = "";
    secondChance = false;

    setState(() {});
  }

  void checkAnswer(int answer, int index) async {
    if (answered) return;

    setState(() {
      answered = true;
      selectedIndex = index;
    });

    await _animationController.forward();
    await _animationController.reverse();

    if (answer == correctAnswer) {
      setState(() {
        feedbackColor = Colors.green;
        feedbackText = "Brilliant! Your brain loves challenges.";
        brainPower = (brainPower + 1).clamp(0, 10);
        secondChance = false;
      });
      await Future.delayed(const Duration(seconds: 1));
      currentQuestion++;
      generateQuestion();
    } else {
      if (!secondChance) {
        setState(() {
          feedbackColor = Colors.red;
          feedbackText = "Oops! Try again — one more chance!";
          answered = false;
          secondChance = true;
        });
      } else {
        setState(() {
          feedbackColor = Colors.red;
          feedbackText = "Oops! The correct answer was $correctAnswer.";
          secondChance = false;
        });
        await Future.delayed(const Duration(seconds: 1));
        currentQuestion++;
        generateQuestion();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: size.width,
        height: size.height,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              Color(0xFFF3F0FF),
              Color(0xFFE3DAFF),
              Color(0xFFD2C6FF),
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min, 
              mainAxisAlignment: MainAxisAlignment.center, 
              crossAxisAlignment: CrossAxisAlignment.center, 
              children: [
                Text(
                  "Question $currentQuestion of $totalQuestions",
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),

                // Brain Power Meter ----
                Column(
                  children: [
                    const Text(
                      "Brain Power ⚡",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: size.width * 0.6,
                      height: 14,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Colors.grey.shade300,
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: brainPower / 4,
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
                  ],
                ),

                const SizedBox(height: 20),
                const Icon(Icons.psychology, size: 70, color: Color(0xFF7B61FF)),
                const SizedBox(height: 10),
                const Text(
                  "Brain Challenge",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  "What is $a + $b ?",
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                // Options horizontally
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(options.length, (index) {
                    final value = options[index];
                    Color buttonColor = Colors.purple.shade400;
                    if (answered && selectedIndex == index) {
                      buttonColor = feedbackColor;
                    }

                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: ScaleTransition(
                          scale: _scaleAnimation,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: buttonColor,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: () => checkAnswer(value, index),
                            child: Text(
                              "$value",
                              style: const TextStyle(
                                  fontSize: 20, color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 20),

                // Feedback message ----
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    feedbackText,
                    key: ValueKey(feedbackText),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: feedbackColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}