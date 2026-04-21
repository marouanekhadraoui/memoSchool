import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF3F0FF), Color(0xFFE3DAFF), Color(0xFFD2C6FF)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              children: [
                // Hero Section
                const SizedBox(height: 10),
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7B61FF), Color(0xFF4DA6FF)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF7B61FF).withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.auto_stories,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Why Memoschool?',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E2A3E),
                  ),
                ),
                const SizedBox(height: 8),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    'A smart learning system to reduce forgetting\nand improve academic retention',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF555555),
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // Problem Card
                _buildStoryCard(
                  icon: Icons.error_outline,
                  title: 'The Problem',
                  description:
                      'Many students experience rapid forgetting of learned material shortly after classroom sessions. This reduces long-term academic performance and motivation.',
                  cardColor: Colors.red.shade50,
                  iconColor: Colors.red.shade700,
                ),
                const SizedBox(height: 12),

                // Gap Card
                _buildStoryCard(
                  icon: Icons.trending_up,
                  title: 'The Educational Gap',
                  description:
                      'Traditional teaching systems focus on delivery of knowledge, but lack continuous reinforcement mechanisms that help students retain what they learn.',
                  cardColor: Colors.amber.shade50,
                  iconColor: Colors.amber.shade800,
                ),
                const SizedBox(height: 12),

                // Solution Card (highlighted)
                _buildStoryCard(
                  icon: Icons.lightbulb_outline,
                  title: 'Our Solution',
                  description:
                      'Memoschool introduces an innovative activity-based learning system integrated into remedial sessions. It helps students reinforce knowledge through structured, interactive exercises designed to improve retention and understanding.',
                  cardColor: Colors.green.shade50,
                  iconColor: Colors.green.shade700,
                  isHighlighted: true,
                ),
                const SizedBox(height: 12),

                // Impact Card
                _buildStoryCard(
                  icon: Icons.analytics,
                  title: 'Expected Impact',
                  description:
                      'The system aims to improve memory retention, increase student engagement, and enhance learning motivation within Algerian educational institutions.',
                  cardColor: Colors.blue.shade50,
                  iconColor: Colors.blue.shade700,
                ),
                const SizedBox(height: 12),

                // Collaboration Card
                _buildCollaborationCard(),
                const SizedBox(height: 12),

                // Quote and Button
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7B61FF).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF7B61FF).withOpacity(0.3)),
                  ),
                  child: const Center(
                    child: Text(
                      '“We don’t just teach students — we help them remember.”',
                      style: TextStyle(
                        fontSize: 15,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1E2A3E),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Back Button
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Back to Home'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7B61FF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStoryCard({
    required IconData icon,
    required String title,
    required String description,
    required Color cardColor,
    required Color iconColor,
    bool isHighlighted = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: isHighlighted
            ? [
                BoxShadow(
                  color: Colors.green.withOpacity(0.2),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: GlassCard(
        backgroundColor: cardColor,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isHighlighted ? Colors.green.shade800 : const Color(0xFF1E2A3E),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: Color(0xFF333333),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCollaborationCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: GlassCard(
        backgroundColor: Colors.grey.shade50,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.people_outline,
                    color: Color(0xFF7B61FF),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Built Through Collaboration',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E2A3E),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'This project is the result of a collaboration between the Scientific Club of Lycée Miloua Maâchou and the ByteX Computer Science Club at the University of Sidi Bel Abbès.\n\n'
              'Both parties work together to provide innovative digital solutions that help overcome and reduce the lack of motivation to learn, addressing the problem of forgetting among learners in Algerian educational institutions.',
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: Color(0xFF444444),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildPartnerLogo('Lycée Miloua Maâchou', Icons.school),
                _buildPartnerLogo('ByteX Club', Icons.computer),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPartnerLogo(String name, IconData icon) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, size: 28, color: const Color(0xFF7B61FF)),
        ),
        const SizedBox(height: 6),
        Text(
          name,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF444444)),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// Custom GlassCard with optional backgroundColor
class GlassCard extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;

  const GlassCard({
    super.key,
    required this.child,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            (backgroundColor ?? Colors.white).withOpacity(0.15),
            (backgroundColor ?? Colors.white).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}