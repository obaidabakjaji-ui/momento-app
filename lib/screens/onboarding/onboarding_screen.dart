import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../theme.dart';

/// Three-card swipeable intro shown the first time a user signs in.
/// Sets `hasSeenOnboarding: true` on the user doc when finished or skipped
/// so it never appears again. Always skippable.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  final _auth = AuthService();
  int _index = 0;
  bool _finishing = false;

  static const _pages = <_OnboardingPage>[
    _OnboardingPage(
      icon: Icons.celebration_outlined,
      title: 'Welcome to Momento',
      body:
          'Share unfiltered moments with the people closest to you. No likes counts, no algorithms — just little glimpses of your day.',
    ),
    _OnboardingPage(
      icon: Icons.meeting_room_outlined,
      title: 'Create or join Rooms',
      body:
          'A Room is a private space for sharing photos. Start one for your family, your trip, your group of friends — and invite people with a 6-character code.',
    ),
    _OnboardingPage(
      icon: Icons.timer_outlined,
      title: 'Photos disappear in 6 hours',
      body:
          'Every photo expires automatically. Snap, share, and move on — no archive, no pressure.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    if (_finishing) return;
    setState(() => _finishing = true);
    try {
      final uid = _auth.currentUser!.uid;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({'hasSeenOnboarding': true});
    } catch (_) {
      // If the write fails we still proceed — the gate will retry next time.
    }
    // The AuthGate stream will rebuild on the user-doc change and route us forward.
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _index == _pages.length - 1;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _finishing ? null : _finish,
                child: const Text('Skip'),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (_, i) => _OnboardingCard(page: _pages[i]),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (i) {
                final selected = i == _index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: selected ? 18 : 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: selected
                        ? MomentoTheme.coral
                        : MomentoTheme.deepPlum.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _finishing
                      ? null
                      : () {
                          if (isLast) {
                            _finish();
                          } else {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeOut,
                            );
                          }
                        },
                  child: _finishing
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(isLast ? 'Get Started' : 'Next'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage {
  final IconData icon;
  final String title;
  final String body;
  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.body,
  });
}

class _OnboardingCard extends StatelessWidget {
  final _OnboardingPage page;
  const _OnboardingCard({required this.page});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [MomentoTheme.coral, MomentoTheme.warmOrange],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(40),
            ),
            child: Icon(page.icon, size: 64, color: Colors.white),
          ),
          const SizedBox(height: 32),
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: MomentoTheme.deepPlum,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            page.body,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: MomentoTheme.deepPlum.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
